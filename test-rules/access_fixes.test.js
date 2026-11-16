const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const { readFileSync } = require('fs');
const { resolve } = require('path');

const PROJECT_ID = 'demo-taskmapflow';
const FIRESTORE_RULES = readFileSync(resolve(__dirname, '../firestore.rules'), 'utf8');

let testEnv;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: FIRESTORE_RULES,
      host: '127.0.0.1',
      port: 8080,
    },
  });
});

afterAll(async () => {
  if (testEnv) {
    await testEnv.cleanup();
  }
});

afterEach(async () => {
  if (testEnv) {
    await testEnv.clearFirestore();
  }
});

describe('Erişim Düzeltmeleri – Dar Emulator Doğrulaması', () => {
  const ownerUid = 'owner_1';
  const adminUid = 'admin_1';
  const memberUid = 'member_1';
  const exMemberUid = 'ex_member_1';
  const strangerUid = 'stranger_1';
  const workspaceId = 'ws_team_1';
  const now = new Date();

  beforeEach(async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();

      // Workspace with team enabled
      await db.collection('workspaces').doc(workspaceId).set({
        id: workspaceId,
        name: 'Team Workspace',
        description: 'Test workspace',
        type: 'project',
        color: '#8A2BE2',
        ownerId: ownerUid,
        isTeamEnabled: true,
        isArchived: false,
        memberIds: [ownerUid, adminUid, memberUid], // exMemberUid is NOT in memberIds
        createdAt: now,
        updatedAt: now,
      });

      // Active members subcollection
      await db.collection('workspaces').doc(workspaceId).collection('members').doc(ownerUid).set({
        id: ownerUid,
        workspaceId,
        userId: ownerUid,
        role: 'owner',
        joinedAt: now,
      });

      await db.collection('workspaces').doc(workspaceId).collection('members').doc(adminUid).set({
        id: adminUid,
        workspaceId,
        userId: adminUid,
        role: 'admin',
        joinedAt: now,
      });

      await db.collection('workspaces').doc(workspaceId).collection('members').doc(memberUid).set({
        id: memberUid,
        workspaceId,
        userId: memberUid,
        role: 'member',
        joinedAt: now,
      });

      // Existing task created earlier by exMemberUid
      await db.collection('workspaces').doc(workspaceId).collection('tasks').doc('task_ex_1').set({
        id: 'task_ex_1',
        workspaceId,
        ownerId: exMemberUid, // Created by ex-member
        title: 'Task by ex member',
        description: 'Desc',
        status: 'todo',
        priority: 'medium',
        dueDate: null,
        sprintId: null,
        subtasks: null,
        assigneeId: exMemberUid, // Assigned to ex-member
        createdAt: now,
        updatedAt: now,
      });

      // Existing note created earlier by exMemberUid
      await db.collection('workspaces').doc(workspaceId).collection('notes').doc('note_ex_1').set({
        id: 'note_ex_1',
        workspaceId,
        ownerId: exMemberUid,
        title: 'Note by ex member',
        content: 'Content',
        createdAt: now,
        updatedAt: now,
      });

      // Root invite document
      await db.collection('invites').doc('ABCD2345').set({
        code: 'ABCD2345',
        workspaceId,
        role: 'member',
        isUsed: false,
        isRevoked: false,
        createdAt: now,
      });

      // Workspace invite copy
      await db.collection('workspaces').doc(workspaceId).collection('invites').doc('ABCD2345').set({
        code: 'ABCD2345',
        workspaceId,
        role: 'member',
        isUsed: false,
        isRevoked: false,
        createdAt: now,
      });
    });
  });

  // 1. Davet listeleme reddi
  test('1. Davet listeleme reddi: istemci get/list dahil /invites erişimi tamamen reddedilmeli', async () => {
    const authClient = testEnv.authenticatedContext(memberUid).firestore();
    const ownerClient = testEnv.authenticatedContext(ownerUid).firestore();

    // Member cannot get or list top-level /invites
    await assertFails(authClient.collection('invites').doc('ABCD2345').get());
    await assertFails(authClient.collection('invites').get());

    // Even owner cannot read top-level /invites directly (backend only)
    await assertFails(ownerClient.collection('invites').doc('ABCD2345').get());
    await assertFails(ownerClient.collection('invites').get());

    // Neither member nor owner can write to workspace invites subcollection (backend only)
    await assertFails(
      authClient
        .collection('workspaces')
        .doc(workspaceId)
        .collection('invites')
        .doc('ABCD2345')
        .update({ isRevoked: true })
    );
  });

  // 2. Ayrılan üyenin okuma/yazma reddi
  test('2. Ayrılan üyenin okuma/yazma reddi: eski görev/not sahibi olsa bile erişim engellenmeli', async () => {
    const exClient = testEnv.authenticatedContext(exMemberUid).firestore();

    // Cannot read tasks subcollection
    await assertFails(
      exClient.collection('workspaces').doc(workspaceId).collection('tasks').doc('task_ex_1').get()
    );
    await assertFails(
      exClient.collection('workspaces').doc(workspaceId).collection('tasks').get()
    );

    // Cannot update or delete task even though exMemberUid is the ownerId and assigneeId
    await assertFails(
      exClient
        .collection('workspaces')
        .doc(workspaceId)
        .collection('tasks')
        .doc('task_ex_1')
        .update({
          status: 'completed',
          updatedAt: new Date(),
        })
    );
    await assertFails(
      exClient.collection('workspaces').doc(workspaceId).collection('tasks').doc('task_ex_1').delete()
    );

    // Cannot read, update or delete note even though exMemberUid is ownerId
    await assertFails(
      exClient.collection('workspaces').doc(workspaceId).collection('notes').doc('note_ex_1').get()
    );
    await assertFails(
      exClient
        .collection('workspaces')
        .doc(workspaceId)
        .collection('notes')
        .doc('note_ex_1')
        .update({ content: 'Modified' })
    );
    await assertFails(
      exClient.collection('workspaces').doc(workspaceId).collection('notes').doc('note_ex_1').delete()
    );
  });

  // 3. Admin’in memberIds değiştirme reddi
  test('3. Admin memberIds değiştirme reddi: admin sadece description, tags, resources, updatedAt güncelleyebilir', async () => {
    const adminClient = testEnv.authenticatedContext(adminUid).firestore();

    // Allowed: admin updating description and updatedAt
    await assertSucceeds(
      adminClient.collection('workspaces').doc(workspaceId).update({
        description: 'Updated by admin',
        updatedAt: new Date(),
      })
    );

    // Rejected: admin trying to modify memberIds
    await assertFails(
      adminClient.collection('workspaces').doc(workspaceId).update({
        memberIds: [ownerUid, adminUid, memberUid, strangerUid],
        updatedAt: new Date(),
      })
    );

    // Rejected: admin trying to modify name or color
    await assertFails(
      adminClient.collection('workspaces').doc(workspaceId).update({
        name: 'New Name by Admin',
        updatedAt: new Date(),
      })
    );
  });

  // 4. Göreve atanan kişinin alan üyesi olma zorunluluğu ve alt görev kısıtlaması
  test('4. Göreve atanan kişi alan üyesi/sahibi olmalı; atanan üye alt görev başlığını değiştirememeli', async () => {
    const adminClient = testEnv.authenticatedContext(adminUid).firestore();
    const memberClient = testEnv.authenticatedContext(memberUid).firestore();

    // Rejected: assigning strangerUid who is not a member or owner
    await assertFails(
      adminClient.collection('workspaces').doc(workspaceId).collection('tasks').doc('task_stranger').set({
        id: 'task_stranger',
        workspaceId,
        ownerId: adminUid,
        title: 'Illegal task',
        description: '',
        status: 'todo',
        priority: 'medium',
        dueDate: null,
        sprintId: null,
        subtasks: null,
        assigneeId: strangerUid, // strangerUid is NOT in members or owner
        createdAt: new Date(),
        updatedAt: new Date(),
      })
    );

    // Create a task assigned to memberUid with 1 subtask
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('workspaces').doc(workspaceId).collection('tasks').doc('task_sub_1').set({
        id: 'task_sub_1',
        workspaceId,
        ownerId: ownerUid,
        title: 'Task with subtasks',
        description: '',
        status: 'todo',
        priority: 'medium',
        dueDate: null,
        sprintId: null,
        subtasks: [{ id: 's1', title: 'Original Subtask', isCompleted: false }],
        assigneeId: memberUid,
        createdAt: now,
        updatedAt: now,
      });
    });

    // Allowed: assigned member toggles isCompleted
    await assertSucceeds(
      memberClient.collection('workspaces').doc(workspaceId).collection('tasks').doc('task_sub_1').update({
        status: 'in_progress',
        subtasks: [{ id: 's1', title: 'Original Subtask', isCompleted: true }],
        updatedAt: new Date(),
      })
    );

    // Rejected: assigned member alters subtask title
    await assertFails(
      memberClient.collection('workspaces').doc(workspaceId).collection('tasks').doc('task_sub_1').update({
        subtasks: [{ id: 's1', title: 'Hacked Title', isCompleted: true }],
        updatedAt: new Date(),
      })
    );

    // Rejected: assigned member adds a new subtask
    await assertFails(
      memberClient.collection('workspaces').doc(workspaceId).collection('tasks').doc('task_sub_1').update({
        subtasks: [
          { id: 's1', title: 'Original Subtask', isCompleted: true },
          { id: 's2', title: 'New Subtask', isCompleted: false },
        ],
        updatedAt: new Date(),
      })
    );
  });
});
