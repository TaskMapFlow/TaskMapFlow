/**
 * Firestore & Storage Security Rules – Baseline Deny-All Tests.
 *
 * Doğrulamalar:
 * - Oturumsuz (unauthenticated)
 * - Anonim (anonymous)
 * - Normal kimliği doğrulanmış (authenticated)
 * İstemcilerin tüm korumalı, iç içe veya bilinmeyen yollarda:
 * - Firestore: get, list, create, update, delete erişimlerinin reddedildiğini,
 * - Storage: read (get/download), list, create (upload), update (overwrite), delete
 *   erişimlerinin reddedildiğini doğrular.
 *
 * Güncelleme ve silme testleri öncesinde veriler rules-disabled context ile hazırlanır.
 *
 * Proje kimliği: demo-taskmapflow (gerçek Firebase projesine bağlanmaz)
 */

const {
  initializeTestEnvironment,
  assertFails,
} = require('@firebase/rules-unit-testing');
const { readFileSync } = require('fs');
const { resolve } = require('path');

const PROJECT_ID = 'demo-taskmapflow';
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

afterEach(async () => {
  if (testEnv) {
    await testEnv.clearFirestore();
    await testEnv.clearStorage();
  }
});

// İstemci tipleri matrisi: Unauthenticated, Anonymous, Authenticated
const clientContexts = [
  { name: 'Oturumsuz (unauthenticated)', getCtx: () => testEnv.unauthenticatedContext() },
  { name: 'Anonim (anonymous)', getCtx: () => testEnv.authenticatedContext('anon_user', { provider_id: 'anonymous' }) },
  { name: 'Doğrulanmış (authenticated)', getCtx: () => testEnv.authenticatedContext('auth_user_1', { email: 'user@example.com' }) },
];

describe('Firestore Deny-All Baseline Tests', () => {
  beforeEach(async () => {
    // Önceden var olan belgeleri rules-disabled context (test setup) ile oluştur
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.collection('users').doc('target_user').set({ name: 'Alice' });
      await db.collection('users').doc('target_user').collection('performance_notes').doc('pn1').set({ note: 'Confidential' });
      await db.collection('workspaces').doc('ws1').set({ name: 'Project Alpha' });
      await db.collection('workspaces').doc('ws1').collection('members').doc('target_user').set({ role: 'owner' });
      await db.collection('workspaces').doc('ws1').collection('tasks').doc('task1').set({ title: 'Task 1', isPrivate: false });
      await db.collection('workspaces').doc('ws1').collection('map_nodes').doc('node1').set({ x: 10, y: 20 });
      await db.collection('unknown_collection').doc('doc1').set({ random: true });
    });
  });

  clientContexts.forEach(({ name, getCtx }) => {
    describe(`${name} istemci`, () => {
      let db;

      beforeEach(() => {
        db = getCtx().firestore();
      });

      test('kullanıcı profiline get/list/create/update/delete yapamaz', async () => {
        await assertFails(db.collection('users').doc('target_user').get());
        await assertFails(db.collection('users').get());
        await assertFails(db.collection('users').doc('new_user').set({ name: 'Bob' }));
        await assertFails(db.collection('users').doc('target_user').update({ name: 'Alice 2' }));
        await assertFails(db.collection('users').doc('target_user').delete());
      });

      test('performans notlarına get/list/create/update/delete yapamaz', async () => {
        const pnRef = db.collection('users').doc('target_user').collection('performance_notes');
        await assertFails(pnRef.doc('pn1').get());
        await assertFails(pnRef.get());
        await assertFails(pnRef.doc('pn2').set({ note: 'New note' }));
        await assertFails(pnRef.doc('pn1').update({ note: 'Updated note' }));
        await assertFails(pnRef.doc('pn1').delete());
      });

      test('çalışma alanına ve alt koleksiyonlarına get/list/create/update/delete yapamaz', async () => {
        const wsRef = db.collection('workspaces').doc('ws1');
        await assertFails(wsRef.get());
        await assertFails(db.collection('workspaces').get());
        await assertFails(db.collection('workspaces').doc('new_ws').set({ name: 'New WS' }));
        await assertFails(wsRef.update({ name: 'WS Renamed' }));
        await assertFails(wsRef.delete());

        // Görevler
        await assertFails(wsRef.collection('tasks').doc('task1').get());
        await assertFails(wsRef.collection('tasks').get());
        await assertFails(wsRef.collection('tasks').doc('task2').set({ title: 'T2' }));
        await assertFails(wsRef.collection('tasks').doc('task1').update({ title: 'T1 modified' }));
        await assertFails(wsRef.collection('tasks').doc('task1').delete());

        // Harita düğümleri
        await assertFails(wsRef.collection('map_nodes').doc('node1').get());
        await assertFails(wsRef.collection('map_nodes').get());
        await assertFails(wsRef.collection('map_nodes').doc('node2').set({ x: 0, y: 0 }));
        await assertFails(wsRef.collection('map_nodes').doc('node1').update({ x: 100 }));
        await assertFails(wsRef.collection('map_nodes').doc('node1').delete());
      });

      test('bilinmeyen ve rastgele iç içe yollara get/list/create/update/delete yapamaz', async () => {
        const unknownRef = db.collection('unknown_collection').doc('doc1');
        await assertFails(unknownRef.get());
        await assertFails(db.collection('unknown_collection').get());
        await assertFails(db.collection('unknown_collection').doc('doc2').set({ a: 1 }));
        await assertFails(unknownRef.update({ a: 2 }));
        await assertFails(unknownRef.delete());

        const deepNested = db.collection('a').doc('b').collection('c').doc('d');
        await assertFails(deepNested.get());
        await assertFails(deepNested.set({ deep: true }));
      });
    });
  });
});

describe('Firebase Storage Deny-All Baseline Tests', () => {
  beforeEach(async () => {
    // Rules-disabled ile önceden bir dosya yükle
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const storage = context.storage();
      const existingRef = storage.ref('users/target_user/profile/photo.png');
      await existingRef.put(Buffer.from('fake image content'), { contentType: 'image/png' });
    });
  });

  clientContexts.forEach(({ name, getCtx }) => {
    describe(`${name} istemci`, () => {
      let storage;

      beforeEach(() => {
        storage = getCtx().storage();
      });

      test('profil dosyalarını okuyamaz (getDownloadURL / getBytes)', async () => {
        const ref = storage.ref('users/target_user/profile/photo.png');
        await assertFails(ref.getDownloadURL());
      });

      test('profil klasörünü listeleyemez (list / listAll)', async () => {
        const folderRef = storage.ref('users/target_user/profile');
        await assertFails(folderRef.listAll());
      });

      test('yeni profil fotoğrafı yükleyemez (upload)', async () => {
        const newRef = storage.ref('users/target_user/profile/new.png');
        await assertFails(newRef.put(Buffer.from('bytes'), { contentType: 'image/png' }));
      });

      test('mevcut dosyanın üzerine yazamaz (overwrite)', async () => {
        const existingRef = storage.ref('users/target_user/profile/photo.png');
        await assertFails(existingRef.put(Buffer.from('overwritten'), { contentType: 'image/png' }));
      });

      test('mevcut dosyayı silemez (delete)', async () => {
        const existingRef = storage.ref('users/target_user/profile/photo.png');
        await assertFails(existingRef.delete());
      });

      test('çalışma alanı dosyaları ve bilinmeyen yollarda read/write/delete yapamaz', async () => {
        const wsFileRef = storage.ref('workspaces/ws1/files/document.pdf');
        await assertFails(wsFileRef.getDownloadURL());
        await assertFails(wsFileRef.put(Buffer.from('data'), { contentType: 'application/pdf' }));
        await assertFails(wsFileRef.delete());

        const unknownRef = storage.ref('unknown_folder/nested/random.txt');
        await assertFails(unknownRef.getDownloadURL());
        await assertFails(unknownRef.put(Buffer.from('data')));
      });
    });
  });
});
