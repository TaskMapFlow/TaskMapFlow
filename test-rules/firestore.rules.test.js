/**
 * Firestore Security Rules – baseline deny-all tests.
 *
 * Run with:
 *   firebase emulators:exec --only firestore,auth --project taskmapflow-test \
 *     "cd test-rules && npm test"
 */

const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const { readFileSync } = require('fs');
const { resolve } = require('path');

const PROJECT_ID = 'taskmapflow-test';
const FIRESTORE_RULES = readFileSync(resolve(__dirname, '../firestore.rules'), 'utf8');

let testEnv;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: FIRESTORE_RULES,
      host: 'localhost',
      port: 8080,
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

afterEach(async () => {
  await testEnv.clearFirestore();
});

// Unauthenticated client tests

describe('Unauthenticated client', () => {
  let unauthedDb;

  beforeEach(() => {
    unauthedDb = testEnv.unauthenticatedContext().firestore();
  });

  test('cannot read any user document', async () => {
    await assertFails(unauthedDb.collection('users').doc('someUserId').get());
  });

  test('cannot write any user document', async () => {
    await assertFails(
      unauthedDb.collection('users').doc('someUserId').set({ displayName: 'Eve' })
    );
  });

  test('cannot read any workspace document', async () => {
    await assertFails(unauthedDb.collection('workspaces').doc('ws1').get());
  });

  test('cannot write any workspace document', async () => {
    await assertFails(
      unauthedDb.collection('workspaces').doc('ws1').set({ name: 'Test WS' })
    );
  });

  test('cannot read workspace tasks', async () => {
    await assertFails(
      unauthedDb.collection('workspaces').doc('ws1').collection('tasks').doc('t1').get()
    );
  });

  test('cannot read workspace map nodes', async () => {
    await assertFails(
      unauthedDb.collection('workspaces').doc('ws1').collection('map_nodes').doc('n1').get()
    );
  });

  test('cannot read workspace notes', async () => {
    await assertFails(
      unauthedDb.collection('workspaces').doc('ws1').collection('notes').doc('note1').get()
    );
  });

  test('cannot read user performance notes', async () => {
    await assertFails(
      unauthedDb
        .collection('users').doc('someUserId')
        .collection('performance_notes').doc('pn1')
        .get()
    );
  });
});

// Authenticated non-member tests

describe('Authenticated non-member client', () => {
  const AUTH_USER_ID = 'authUser1';
  let authedDb;

  beforeEach(() => {
    authedDb = testEnv.authenticatedContext(AUTH_USER_ID).firestore();
  });

  test('cannot read another user profile', async () => {
    await assertFails(authedDb.collection('users').doc('anotherUser').get());
  });

  test('cannot write another user profile', async () => {
    await assertFails(
      authedDb.collection('users').doc('anotherUser').set({ displayName: 'Hacker' })
    );
  });

  test('cannot read workspace they are not a member of', async () => {
    await assertFails(authedDb.collection('workspaces').doc('ws1').get());
  });

  test('cannot read tasks in workspace they are not a member of', async () => {
    await assertFails(
      authedDb.collection('workspaces').doc('ws1').collection('tasks').doc('t1').get()
    );
  });

  test('cannot read map nodes in workspace they are not a member of', async () => {
    await assertFails(
      authedDb.collection('workspaces').doc('ws1').collection('map_nodes').doc('n1').get()
    );
  });

  test('cannot read sprints in workspace they are not a member of', async () => {
    await assertFails(
      authedDb.collection('workspaces').doc('ws1').collection('sprints').doc('s1').get()
    );
  });

  test('cannot read notes in workspace they are not a member of', async () => {
    await assertFails(
      authedDb.collection('workspaces').doc('ws1').collection('notes').doc('note1').get()
    );
  });

  test("cannot read another user's performance notes", async () => {
    await assertFails(
      authedDb
        .collection('users').doc('anotherUser')
        .collection('performance_notes').doc('pn1')
        .get()
    );
  });

  test("cannot write another user's performance notes", async () => {
    await assertFails(
      authedDb
        .collection('users').doc('anotherUser')
        .collection('performance_notes').doc('pn1')
        .set({ content: 'secret note' })
    );
  });

  test('can read own user profile', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore()
        .collection('users').doc(AUTH_USER_ID)
        .set({ displayName: 'Auth User', email: 'auth@example.com' });
    });
    await assertSucceeds(authedDb.collection('users').doc(AUTH_USER_ID).get());
  });

  test('can write own user profile', async () => {
    await assertSucceeds(
      authedDb.collection('users').doc(AUTH_USER_ID).set({
        displayName: 'Auth User',
        email: 'auth@example.com',
        createdAt: new Date(),
        updatedAt: new Date(),
      })
    );
  });

  test('can read own performance notes', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore()
        .collection('users').doc(AUTH_USER_ID)
        .collection('performance_notes').doc('myNote')
        .set({ content: 'my note', writtenBy: AUTH_USER_ID, createdAt: new Date() });
    });
    await assertSucceeds(
      authedDb
        .collection('users').doc(AUTH_USER_ID)
        .collection('performance_notes').doc('myNote')
        .get()
    );
  });
});

// Default deny for uncovered paths

describe('Default deny for uncovered paths', () => {
  test('authenticated user cannot read arbitrary top-level collection', async () => {
    const db = testEnv.authenticatedContext('anyUser').firestore();
    await assertFails(db.collection('someRandomCollection').doc('doc1').get());
  });
});
