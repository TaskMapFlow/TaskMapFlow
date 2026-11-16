import * as admin from 'firebase-admin';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import * as crypto from 'crypto';

admin.initializeApp();
const db = admin.firestore();

const ALPHABET = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';

function generateInviteCode(length = 8): string {
  const bytes = crypto.randomBytes(length);
  let result = '';
  for (let i = 0; i < length; i++) {
    result += ALPHABET[bytes[i] % ALPHABET.length];
  }
  return result;
}

/**
 * Creates a secure, single-use, time-limited invite code for a workspace.
 */
export const createInvite = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Oturum açmanız gerekiyor.');
  }

  const { workspaceId, role = 'member' } = request.data || {};
  if (!workspaceId || typeof workspaceId !== 'string') {
    throw new HttpsError('invalid-argument', 'Geçersiz çalışma alanı.');
  }

  const callerUid = request.auth.uid;
  const wsRef = db.collection('workspaces').doc(workspaceId);
  const wsSnap = await wsRef.get();
  if (!wsSnap.exists) {
    throw new HttpsError('not-found', 'Çalışma alanı bulunamadı.');
  }

  const wsData = wsSnap.data()!;
  if (!wsData.isTeamEnabled) {
    throw new HttpsError('failed-precondition', 'Bu alanda ekip çalışması etkinleştirilmemiş.');
  }

  // Check caller role
  const callerMemberSnap = await wsRef.collection('members').doc(callerUid).get();
  if (!callerMemberSnap.exists) {
    throw new HttpsError('permission-denied', 'Bu çalışma alanının üyesi değilsiniz.');
  }

  const callerRole = callerMemberSnap.data()?.role;
  if (callerRole !== 'owner' && callerRole !== 'admin') {
    throw new HttpsError('permission-denied', 'Davet oluşturma yetkiniz bulunmuyor.');
  }

  // Admin can only invite normal members
  const assignedRole = callerRole === 'admin' ? 'member' : (role === 'admin' ? 'admin' : 'member');

  const code = generateInviteCode(8);
  const now = admin.firestore.Timestamp.now();
  const expiresAt = admin.firestore.Timestamp.fromMillis(now.toMillis() + 7 * 24 * 60 * 60 * 1000); // 7 days

  const inviteData = {
    code,
    workspaceId,
    workspaceName: wsData.name || '',
    role: assignedRole,
    createdBy: callerUid,
    createdAt: now,
    expiresAt,
    isUsed: false,
    usedBy: null,
    usedAt: null,
    isRevoked: false,
  };

  const batch = db.batch();
  batch.set(db.collection('invites').doc(code), inviteData);
  batch.set(wsRef.collection('invites').doc(code), inviteData);
  await batch.commit();

  return {
    code,
    workspaceId,
    role: assignedRole,
    expiresAt: expiresAt.toDate().toISOString(),
  };
});

/**
 * Accepts an invite code and joins the workspace.
 * Requires a permanent verified account (anonymous users are rejected).
 */
export const acceptInvite = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Oturum açmanız gerekiyor.');
  }

  // Check anonymous status
  const signInProvider = request.auth.token.firebase?.sign_in_provider;
  if (signInProvider === 'anonymous') {
    throw new HttpsError(
      'permission-denied',
      'Misafir hesaplar ekip davetlerini kabul edemez. Lütfen önce hesabınızı kalıcılaştırın veya kayıt olun.'
    );
  }

  const rawCode = request.data?.code;
  if (!rawCode || typeof rawCode !== 'string') {
    throw new HttpsError('invalid-argument', 'Geçerli bir davet kodu girin.');
  }

  const code = rawCode.trim().toUpperCase();
  const callerUid = request.auth.uid;

  // Resolve caller display name
  let callerDisplayName = request.auth.token.name || '';
  if (!callerDisplayName) {
    const userDoc = await db.collection('users').doc(callerUid).get();
    if (userDoc.exists) {
      callerDisplayName = userDoc.data()?.displayName || '';
    }
  }
  if (!callerDisplayName && request.auth.token.email) {
    callerDisplayName = request.auth.token.email.split('@')[0];
  }
  if (!callerDisplayName) {
    callerDisplayName = 'Ekip Üyesi';
  }

  const inviteRef = db.collection('invites').doc(code);

  return await db.runTransaction(async (tx) => {
    const inviteSnap = await tx.get(inviteRef);
    if (!inviteSnap.exists) {
      throw new HttpsError('not-found', 'Davet kodu bulunamadı. Lütfen kodu kontrol edin.');
    }

    const invite = inviteSnap.data()!;
    if (invite.isRevoked) {
      throw new HttpsError('failed-precondition', 'Bu davet kodu iptal edilmiş.');
    }

    if (invite.isUsed) {
      throw new HttpsError('failed-precondition', 'Bu davet kodu daha önce kullanılmış.');
    }

    const now = admin.firestore.Timestamp.now();
    if (invite.expiresAt && invite.expiresAt.toMillis() < now.toMillis()) {
      throw new HttpsError('failed-precondition', 'Bu davet kodunun geçerlilik süresi dolmuş.');
    }

    const workspaceId = invite.workspaceId;
    const wsRef = db.collection('workspaces').doc(workspaceId);
    const wsSnap = await tx.get(wsRef);
    if (!wsSnap.exists) {
      throw new HttpsError('not-found', 'Çalışma alanı bulunamadı.');
    }

    const wsData = wsSnap.data()!;
    if (wsData.isArchived) {
      throw new HttpsError('failed-precondition', 'Arşivlenmiş bir çalışma alanına katılamazsınız.');
    }

    const memberRef = wsRef.collection('members').doc(callerUid);
    const memberSnap = await tx.get(memberRef);

    if (memberSnap.exists) {
      return {
        workspaceId,
        workspaceName: wsData.name,
        role: memberSnap.data()?.role || invite.role,
        alreadyMember: true,
      };
    }

    // Mark invite used
    tx.update(inviteRef, {
      isUsed: true,
      usedBy: callerUid,
      usedAt: now,
    });

    const wsInviteRef = wsRef.collection('invites').doc(code);
    tx.set(
      wsInviteRef,
      {
        isUsed: true,
        usedBy: callerUid,
        usedAt: now,
      },
      { merge: true }
    );

    // Add member
    const newMemberData = {
      id: callerUid,
      workspaceId,
      userId: callerUid,
      displayName: callerDisplayName,
      role: invite.role || 'member',
      joinedAt: now,
      addedBy: invite.createdBy || '',
    };

    tx.set(memberRef, newMemberData);

    // Update workspace memberIds
    tx.update(wsRef, {
      memberIds: admin.firestore.FieldValue.arrayUnion(callerUid),
      updatedAt: now,
    });

    return {
      workspaceId,
      workspaceName: wsData.name,
      role: invite.role || 'member',
      alreadyMember: false,
    };
  });
});

/**
 * Revokes an invite code.
 */
export const revokeInvite = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Oturum açmanız gerekiyor.');
  }

  const { workspaceId, code } = request.data || {};
  if (!workspaceId || !code) {
    throw new HttpsError('invalid-argument', 'Eksik parametre.');
  }

  const callerUid = request.auth.uid;
  const wsRef = db.collection('workspaces').doc(workspaceId);
  const memberSnap = await wsRef.collection('members').doc(callerUid).get();
  if (!memberSnap.exists) {
    throw new HttpsError('permission-denied', 'Bu çalışma alanının üyesi değilsiniz.');
  }

  const role = memberSnap.data()?.role;
  if (role !== 'owner' && role !== 'admin') {
    throw new HttpsError('permission-denied', 'Davet iptal etme yetkiniz bulunmuyor.');
  }

  const batch = db.batch();
  batch.update(db.collection('invites').doc(code), { isRevoked: true });
  batch.update(wsRef.collection('invites').doc(code), { isRevoked: true });
  await batch.commit();

  return { success: true };
});

/**
 * Updates a member's role (promote/demote admin).
 * Only the owner can perform this.
 */
export const updateMemberRole = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Oturum açmanız gerekiyor.');
  }

  const { workspaceId, targetUid, newRole } = request.data || {};
  if (!workspaceId || !targetUid || !['admin', 'member'].includes(newRole)) {
    throw new HttpsError('invalid-argument', 'Geçersiz parametreler.');
  }

  const callerUid = request.auth.uid;
  const wsRef = db.collection('workspaces').doc(workspaceId);
  const wsSnap = await wsRef.get();
  if (!wsSnap.exists) {
    throw new HttpsError('not-found', 'Çalışma alanı bulunamadı.');
  }

  if (wsSnap.data()?.ownerId !== callerUid) {
    throw new HttpsError('permission-denied', 'Yalnızca alan sahibi rolleri değiştirebilir.');
  }

  if (targetUid === callerUid) {
    throw new HttpsError('invalid-argument', 'Kendi rolünüzü değiştiremezsiniz.');
  }

  await wsRef.collection('members').doc(targetUid).update({
    role: newRole,
  });

  return { success: true };
});

/**
 * Removes a member or leaves the workspace.
 */
export const removeMember = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Oturum açmanız gerekiyor.');
  }

  const { workspaceId, targetUid } = request.data || {};
  if (!workspaceId || !targetUid) {
    throw new HttpsError('invalid-argument', 'Eksik parametre.');
  }

  const callerUid = request.auth.uid;
  const wsRef = db.collection('workspaces').doc(workspaceId);
  const wsSnap = await wsRef.get();
  if (!wsSnap.exists) {
    throw new HttpsError('not-found', 'Çalışma alanı bulunamadı.');
  }

  const wsData = wsSnap.data()!;
  if (targetUid === wsData.ownerId) {
    throw new HttpsError('failed-precondition', 'Alan sahibi çalışma alanından çıkarılamaz.');
  }

  const callerMemberSnap = await wsRef.collection('members').doc(callerUid).get();
  if (!callerMemberSnap.exists) {
    throw new HttpsError('permission-denied', 'Bu alana erişiminiz yok.');
  }

  const callerRole = callerMemberSnap.data()?.role;

  // Check permission
  if (callerUid === targetUid) {
    // Leaving own membership: allowed for admin/member, not owner
    if (callerRole === 'owner') {
      throw new HttpsError('failed-precondition', 'Alan sahibi çalışma alanından ayrılamaz.');
    }
  } else {
    // Removing another member
    const targetMemberSnap = await wsRef.collection('members').doc(targetUid).get();
    if (!targetMemberSnap.exists) {
      throw new HttpsError('not-found', 'Üye bulunamadı.');
    }
    const targetRole = targetMemberSnap.data()?.role;

    if (callerRole === 'owner') {
      // Owner can remove anyone except self
    } else if (callerRole === 'admin') {
      // Admin can ONLY remove normal members
      if (targetRole === 'owner' || targetRole === 'admin') {
        throw new HttpsError('permission-denied', 'Yöneticiler diğer yöneticileri veya sahibini çıkaramaz.');
      }
    } else {
      throw new HttpsError('permission-denied', 'Üye çıkarma yetkiniz bulunmuyor.');
    }
  }

  const batch = db.batch();
  batch.delete(wsRef.collection('members').doc(targetUid));
  batch.update(wsRef, {
    memberIds: admin.firestore.FieldValue.arrayRemove(targetUid),
    updatedAt: admin.firestore.Timestamp.now(),
  });

  await batch.commit();

  return { success: true };
});
