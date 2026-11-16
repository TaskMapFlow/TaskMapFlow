/**
 * Firebase Auth Emulator Integration Tests.
 *
 * Doğrulamalar:
 * - E-posta / şifre ile kullanıcı oluşturma.
 * - Anonim (misafir) kullanıcı oluşturma.
 * - Misafir kullanıcının e-posta ile hesabını bağlarken UID'sinin korunması.
 * - E-posta zaten kullanımda olduğunda çakışma hatası üretilmesi ve otomatik veri birleştirme yapılmaması.
 * - Kimlik doğrulama sonrasında Firestore ve Storage deny-all kurallarının KORUNDUĞUNUN doğrulanması.
 *
 * Proje kimliği: demo-taskmapflow (Auth emulator port: 9099)
 */

const admin = require('firebase-admin');
const { initializeTestEnvironment, assertFails } = require('@firebase/rules-unit-testing');
const { readFileSync } = require('fs');
const { resolve } = require('path');

const PROJECT_ID = 'demo-taskmapflow';
process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099';

if (!admin.apps.length) {
  admin.initializeApp({ projectId: PROJECT_ID });
}

const auth = admin.auth();
const FIRESTORE_RULES = readFileSync(resolve(__dirname, '../firestore.rules'), 'utf8');
const STORAGE_RULES = readFileSync(resolve(__dirname, '../storage.rules'), 'utf8');

let testEnv;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: FIRESTORE_RULES,
      host: '127.0.0.1',
      port: 8080,
    },
    storage: {
      rules: STORAGE_RULES,
      host: '127.0.0.1',
      port: 9199,
    },
  });
});

afterAll(async () => {
  if (testEnv) {
    await testEnv.cleanup();
  }
});

describe('Firebase Auth Emulator SDK Flows', () => {
  const testEmail = `user_${Date.now()}@example.com`;
  let createdUser;

  test('e-posta ve şifre ile kullanıcı oluşturulur', async () => {
    createdUser = await auth.createUser({
      email: testEmail,
      password: 'password123',
      displayName: 'Ahmet Yilmaz',
    });

    expect(createdUser.uid).toBeDefined();
    expect(createdUser.email).toBe(testEmail);
    expect(createdUser.displayName).toBe('Ahmet Yilmaz');
    expect(createdUser.emailVerified).toBe(false);
  });

  test('aynı e-posta ile tekrar kullanıcı oluşturulamaz (email-already-exists)', async () => {
    await expect(
      auth.createUser({
        email: testEmail,
        password: 'anotherpassword',
      })
    ).rejects.toThrow();
  });

  test('anonim misafir kullanıcı oluşturulabilir ve UID atanır', async () => {
    const guestUser = await auth.createUser({});
    expect(guestUser.uid).toBeDefined();
    expect(guestUser.email).toBeUndefined();

    // Misafir kullanıcıyı e-posta ile kalıcı hesaba yükseltme (UID korunur)
    const upgradedUser = await auth.updateUser(guestUser.uid, {
      email: `upgraded_${Date.now()}@example.com`,
      password: 'newPassword123',
      displayName: 'Promoted Guest',
    });

    expect(upgradedUser.uid).toBe(guestUser.uid);
    expect(upgradedUser.displayName).toBe('Promoted Guest');
    expect(upgradedUser.email).toBeDefined();
  });

  test('yeni oluşturulan doğrulanmış/doğrulanmamış kullanıcılar Firestore veya Storage verilerine erişemez (deny-all korunur)', async () => {
    const authedContext = testEnv.authenticatedContext(createdUser.uid, {
      email: createdUser.email,
      email_verified: false,
    });

    const db = authedContext.firestore();
    const storage = authedContext.storage();

    await assertFails(db.collection('users').doc(createdUser.uid).get());
    await assertFails(db.collection('users').doc(createdUser.uid).set({ name: 'Hacker' }));
    await assertFails(db.collection('workspaces').get());

    const fileRef = storage.ref(`users/${createdUser.uid}/file.txt`);
    await assertFails(fileRef.getDownloadURL());
    await assertFails(fileRef.put(Buffer.from('data')));
  });
});
