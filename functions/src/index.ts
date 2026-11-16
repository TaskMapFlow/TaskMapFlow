import * as admin from 'firebase-admin';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import * as crypto from 'crypto';

admin.initializeApp();
const db = admin.firestore();

const ALPHABET = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
const INVITE_CODE_REGEX = /^[23456789ABCDEFGHJKLMNPQRSTUVWXYZ]{8}$/i;
const MAX_INVITE_ATTEMPTS = 5;
const RATE_LIMIT_WINDOW_MS = 15 * 60 * 1000; // 15 minutes

function generateInviteCode(length = 8): string {
  const bytes = crypto.randomBytes(length);
  let result = '';
  for (let i = 0; i < length; i++) {
    result += ALPHABET[bytes[i] % ALPHABET.length];
  }
  return result;
}

/**
 * Checks and increments failed rate-limit attempts in Firestore.
 */
async function checkRateLimit(uid: string): Promise<void> {
  const ref = db.collection('_rateLimits').doc(`invite_${uid}`);
  const now = Date.now();
  const snap = await ref.get();

  if (snap.exists) {
    const data = snap.data()!;
    const lastAttempt = data.lastAttempt?.toMillis() || 0;
    const attempts = data.attempts || 0;

    if (now - lastAttempt < RATE_LIMIT_WINDOW_MS) {
      if (attempts >= MAX_INVITE_ATTEMPTS) {
        throw new HttpsError(
          'resource-exhausted',
          'Çok fazla hatalı davet kodu denemesi yapıldı. Lütfen 15 dakika sonra tekrar deneyin.'
        );
      }
    } else {
      // Reset window
      await ref.set({
        attempts: 0,
        lastAttempt: admin.firestore.Timestamp.fromMillis(now),
      });
    }
  }
}

async function recordFailedAttempt(uid: string): Promise<void> {
  const ref = db.collection('_rateLimits').doc(`invite_${uid}`);
  const now = Date.now();
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) {
      tx.set(ref, {
        attempts: 1,
        lastAttempt: admin.firestore.Timestamp.fromMillis(now),
      });
    } else {
      const data = snap.data()!;
      const lastAttempt = data.lastAttempt?.toMillis() || 0;
      const isWindowValid = now - lastAttempt < RATE_LIMIT_WINDOW_MS;
      const newAttempts = isWindowValid ? (data.attempts || 0) + 1 : 1;
      tx.set(ref, {
        attempts: newAttempts,
        lastAttempt: admin.firestore.Timestamp.fromMillis(now),
      });
    }
  });
}

async function resetRateLimit(uid: string): Promise<void> {
  const ref = db.collection('_rateLimits').doc(`invite_${uid}`);
  await ref.delete().catch(() => {});
}

/**
 * Creates a secure, single-use, time-limited invite code for a workspace.
 * All invites are for normal 'member' role only (no admin invites).
 */
export const createInvite = onCall(
  {
    // App Check support prepared; enforcement is configurable in Firebase Console
    enforceAppCheck: false,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Oturum açmanız gerekiyor.');
    }

    const { workspaceId } = request.data || {};
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
    if (wsData.isArchived) {
      throw new HttpsError('failed-precondition', 'Arşivlenmiş bir çalışma alanında davet oluşturulamaz.');
    }

    if (!wsData.isTeamEnabled) {
      throw new HttpsError('failed-precondition', 'Bu alanda ekip çalışması etkinleştirilmemiş.');
    }

    // Check caller role directly via workspace ownerId or members subcollection
    const isOwner = wsData.ownerId === callerUid;
    let isAdmin = false;
    if (!isOwner) {
      const callerMemberSnap = await wsRef.collection('members').doc(callerUid).get();
      if (!callerMemberSnap.exists) {
        throw new HttpsError('permission-denied', 'Bu çalışma alanının üyesi değilsiniz.');
      }
      isAdmin = callerMemberSnap.data()?.role === 'admin';
    }

    if (!isOwner && !isAdmin) {
      throw new HttpsError('permission-denied', 'Davet oluşturma yetkiniz bulunmuyor.');
    }

    // All invitees join as standard 'member' only
    const assignedRole = 'member';
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
      workspaceName: wsData.name || '',
      role: assignedRole,
      expiresAt: expiresAt.toDate().toISOString(),
    };
  }
);

/**
 * Accepts an invite code and joins the workspace.
 * Requires a verified permanent account (anonymous or unverified accounts rejected).
 * Validates format, length, server-side rate limits, active workspace, and team status.
 */
export const acceptInvite = onCall(
  {
    // App Check support prepared
    enforceAppCheck: false,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Oturum açmanız gerekiyor.');
    }

    const callerUid = request.auth.uid;

    // 1. Verify permanent and verified account
    const signInProvider = request.auth.token.firebase?.sign_in_provider;
    const isAnonymous = signInProvider === 'anonymous';
    const isEmailVerified = !!request.auth.token.email_verified;

    if (isAnonymous || !isEmailVerified) {
      throw new HttpsError(
        'permission-denied',
        'Yalnızca e-posta adresi doğrulanmış kalıcı hesaplar ekip davetlerini kabul edebilir.'
      );
    }

    // 2. Validate code format and length
    const rawCode = request.data?.code;
    if (!rawCode || typeof rawCode !== 'string') {
      throw new HttpsError('invalid-argument', 'Geçerli bir davet kodu girin.');
    }

    const code = rawCode.trim().toUpperCase();
    if (!INVITE_CODE_REGEX.test(code)) {
      throw new HttpsError('invalid-argument', 'Geçersiz davet kodu biçimi. Kod 8 karakter olmalıdır.');
    }

    // 3. Server-side rate limiting check
    await checkRateLimit(callerUid);

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

    try {
      const result = await db.runTransaction(async (tx) => {
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

        if (!wsData.isTeamEnabled) {
          throw new HttpsError('failed-precondition', 'Bu alanda ekip modu artık aktif değil.');
        }

        const memberRef = wsRef.collection('members').doc(callerUid);
        const memberSnap = await tx.get(memberRef);

        if (memberSnap.exists) {
          return {
            workspaceId,
            workspaceName: wsData.name,
            role: memberSnap.data()?.role || 'member',
            alreadyMember: true,
          };
        }

        // Mark invite used in both root and workspace subcollection
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

        // Add member with enforced role: 'member'
        const newMemberData = {
          id: callerUid,
          workspaceId,
          userId: callerUid,
          displayName: callerDisplayName,
          role: 'member',
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
          role: 'member',
          alreadyMember: false,
        };
      });

      // On success, reset rate limit
      await resetRateLimit(callerUid);
      return result;
    } catch (err) {
      // Record failed attempt for rate limiting
      await recordFailedAttempt(callerUid);
      throw err;
    }
  }
);

/**
 * Revokes an invite code inside a transaction.
 * Strictly verifies the invite code belongs to the specified workspace,
 * and validates that caller is the owner (via workspace.ownerId) or admin.
 */
export const revokeInvite = onCall(
  {
    enforceAppCheck: false,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Oturum açmanız gerekiyor.');
    }

    const { workspaceId, code } = request.data || {};
    if (!workspaceId || !code || typeof workspaceId !== 'string' || typeof code !== 'string') {
      throw new HttpsError('invalid-argument', 'Eksik veya geçersiz parametre.');
    }

    const callerUid = request.auth.uid;
    const cleanCode = code.trim().toUpperCase();
    const wsRef = db.collection('workspaces').doc(workspaceId);
    const inviteRef = db.collection('invites').doc(cleanCode);

    return await db.runTransaction(async (tx) => {
      const wsSnap = await tx.get(wsRef);
      if (!wsSnap.exists) {
        throw new HttpsError('not-found', 'Çalışma alanı bulunamadı.');
      }

      const wsData = wsSnap.data()!;
      // Verify owner directly against workspace.ownerId
      const isOwner = wsData.ownerId === callerUid;
      let isAdmin = false;
      if (!isOwner) {
        const callerMemberSnap = await tx.get(wsRef.collection('members').doc(callerUid));
        if (!callerMemberSnap.exists) {
          throw new HttpsError('permission-denied', 'Bu çalışma alanının üyesi değilsiniz.');
        }
        isAdmin = callerMemberSnap.data()?.role === 'admin';
      }

      if (!isOwner && !isAdmin) {
        throw new HttpsError('permission-denied', 'Davet iptal etme yetkiniz bulunmuyor.');
      }

      // Fetch invite and verify it actually belongs to this workspace
      const inviteSnap = await tx.get(inviteRef);
      if (!inviteSnap.exists) {
        throw new HttpsError('not-found', 'Davet kodu bulunamadı.');
      }

      const inviteData = inviteSnap.data()!;
      if (inviteData.workspaceId !== workspaceId) {
        throw new HttpsError('invalid-argument', 'Bu davet kodu belirtilen çalışma alanına ait değil.');
      }

      const now = admin.firestore.Timestamp.now();
      tx.update(inviteRef, { isRevoked: true, revokedAt: now, revokedBy: callerUid });

      const wsInviteRef = wsRef.collection('invites').doc(cleanCode);
      tx.set(wsInviteRef, { isRevoked: true, revokedAt: now, revokedBy: callerUid }, { merge: true });

      return { success: true };
    });
  }
);

/**
 * Updates a member's role (promote/demote admin).
 * Strictly verified inside a transaction; owner verified via workspace.ownerId.
 */
export const updateMemberRole = onCall(
  {
    enforceAppCheck: false,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Oturum açmanız gerekiyor.');
    }

    const { workspaceId, targetUid, newRole } = request.data || {};
    if (!workspaceId || !targetUid || !['admin', 'member'].includes(newRole)) {
      throw new HttpsError('invalid-argument', 'Geçersiz parametreler.');
    }

    const callerUid = request.auth.uid;
    const wsRef = db.collection('workspaces').doc(workspaceId);

    return await db.runTransaction(async (tx) => {
      const wsSnap = await tx.get(wsRef);
      if (!wsSnap.exists) {
        throw new HttpsError('not-found', 'Çalışma alanı bulunamadı.');
      }

      const wsData = wsSnap.data()!;
      // Owner strictly verified via workspace.ownerId
      if (wsData.ownerId !== callerUid) {
        throw new HttpsError('permission-denied', 'Yalnızca alan sahibi rolleri değiştirebilir.');
      }

      if (targetUid === callerUid || targetUid === wsData.ownerId) {
        throw new HttpsError('invalid-argument', 'Alan sahibinin rolü değiştirilemez.');
      }

      const targetMemberRef = wsRef.collection('members').doc(targetUid);
      const targetMemberSnap = await tx.get(targetMemberRef);
      if (!targetMemberSnap.exists) {
        throw new HttpsError('not-found', 'Hedef üye bulunamadı.');
      }

      tx.update(targetMemberRef, {
        role: newRole,
        updatedAt: admin.firestore.Timestamp.now(),
      });

      return { success: true };
    });
  }
);

/**
 * Removes a member or allows a member to leave the workspace.
 * All permission checks and removals are executed inside a transaction.
 * Owner verified via workspace.ownerId.
 */
export const removeMember = onCall(
  {
    enforceAppCheck: false,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Oturum açmanız gerekiyor.');
    }

    const { workspaceId, targetUid } = request.data || {};
    if (!workspaceId || !targetUid) {
      throw new HttpsError('invalid-argument', 'Eksik parametre.');
    }

    const callerUid = request.auth.uid;
    const wsRef = db.collection('workspaces').doc(workspaceId);

    return await db.runTransaction(async (tx) => {
      const wsSnap = await tx.get(wsRef);
      if (!wsSnap.exists) {
        throw new HttpsError('not-found', 'Çalışma alanı bulunamadı.');
      }

      const wsData = wsSnap.data()!;
      // Owner cannot be removed
      if (targetUid === wsData.ownerId) {
        throw new HttpsError('failed-precondition', 'Alan sahibi çalışma alanından çıkarılamaz.');
      }

      const isCallerOwner = wsData.ownerId === callerUid;
      let callerRole: string | undefined;

      if (!isCallerOwner) {
        const callerMemberSnap = await tx.get(wsRef.collection('members').doc(callerUid));
        if (!callerMemberSnap.exists) {
          throw new HttpsError('permission-denied', 'Bu çalışma alanına erişiminiz yok.');
        }
        callerRole = callerMemberSnap.data()?.role;
      } else {
        callerRole = 'owner';
      }

      // Check permission
      if (callerUid === targetUid) {
        // User leaving own membership
        if (isCallerOwner) {
          throw new HttpsError('failed-precondition', 'Alan sahibi çalışma alanından ayrılamaz.');
        }
      } else {
        // Removing someone else
        const targetMemberRef = wsRef.collection('members').doc(targetUid);
        const targetMemberSnap = await tx.get(targetMemberRef);
        if (!targetMemberSnap.exists) {
          throw new HttpsError('not-found', 'Üye bulunamadı.');
        }
        const targetRole = targetMemberSnap.data()?.role;

        if (isCallerOwner) {
          // Owner can remove anyone except self
        } else if (callerRole === 'admin') {
          // Admin can ONLY remove normal members
          if (targetRole !== 'member') {
            throw new HttpsError('permission-denied', 'Yöneticiler yalnızca normal üyeleri çıkarabilir.');
          }
        } else {
          throw new HttpsError('permission-denied', 'Üye çıkarma yetkiniz bulunmuyor.');
        }
      }

      const targetMemberRef = wsRef.collection('members').doc(targetUid);
      tx.delete(targetMemberRef);
      tx.update(wsRef, {
        memberIds: admin.firestore.FieldValue.arrayRemove(targetUid),
        updatedAt: admin.firestore.Timestamp.now(),
      });

      return { success: true };
    });
  }
);
