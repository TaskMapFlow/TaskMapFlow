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

  describe('Workspace & MapNode Private Owner Security Tests', () => {
    const ownerUid = 'ws_owner_1';
    const strangerUid = 'ws_stranger_2';
    const now = new Date();

    const validWorkspace = (id, owner = ownerUid) => ({
      id,
      name: 'Mobile App Project',
      description: 'Flutter app development',
      type: 'project',
      color: '#7C5CE8',
      ownerId: owner,
      createdAt: now,
      updatedAt: now,
    });

    const validMapNode = (id, wsId, owner = ownerUid) => ({
      id,
      workspaceId: wsId,
      ownerId: owner,
      positionX: 100,
      positionY: 150,
      width: 180,
      height: 120,
      createdAt: now,
      updatedAt: now,
    });

    test('sahip kendi çalışma alanını ve bağlı harita düğümünü oluşturabilir', async () => {
      const ownerDb = testEnv.authenticatedContext(ownerUid).firestore();
      const wsRef = ownerDb.collection('workspaces').doc('my_ws_1');
      await wsRef.set(validWorkspace('my_ws_1'));

      const nodeRef = ownerDb.collection('map_nodes').doc('my_node_1');
      await nodeRef.set(validMapNode('my_node_1', 'my_ws_1'));

      const fetchedWs = await wsRef.get();
      expect(fetchedWs.exists).toBe(true);
      expect(fetchedWs.data().name).toBe('Mobile App Project');
    });

    test('başka kullanıcı başkasının çalışma alanını veya harita düğümünü okuyamaz/yazamaz/silemez', async () => {
      // Önce sahibi ile oluştur
      const ownerDb = testEnv.authenticatedContext(ownerUid).firestore();
      await ownerDb.collection('workspaces').doc('secret_ws').set(validWorkspace('secret_ws'));
      await ownerDb.collection('map_nodes').doc('secret_node').set(validMapNode('secret_node', 'secret_ws'));

      // Yabancı kullanıcı erişmeyi dener
      const strangerDb = testEnv.authenticatedContext(strangerUid).firestore();
      await assertFails(strangerDb.collection('workspaces').doc('secret_ws').get());
      await assertFails(strangerDb.collection('workspaces').doc('secret_ws').update({ name: 'Hacked' }));
      await assertFails(strangerDb.collection('workspaces').doc('secret_ws').delete());

      await assertFails(strangerDb.collection('map_nodes').doc('secret_node').get());
      await assertFails(strangerDb.collection('map_nodes').doc('secret_node').update({ positionX: 999 }));
      await assertFails(strangerDb.collection('map_nodes').doc('secret_node').delete());
    });

    test('harita düğümü var olmayan veya başkasına ait çalışma alanına bağlanamaz', async () => {
      const ownerDb = testEnv.authenticatedContext(ownerUid).firestore();
      await ownerDb.collection('workspaces').doc('owner_ws').set(validWorkspace('owner_ws'));

      const strangerDb = testEnv.authenticatedContext(strangerUid).firestore();
      // Stranger tries to link their node to owner's workspace
      await assertFails(
        strangerDb.collection('map_nodes').doc('stranger_node').set(validMapNode('stranger_node', 'owner_ws', strangerUid))
      );

      // Owner tries to link to non-existent workspace
      await assertFails(
        ownerDb.collection('map_nodes').doc('orphan_node').set(validMapNode('orphan_node', 'non_existent_ws'))
      );
    });

    test('geçersiz alanlar, bilinmeyen özellikler veya değiştirilen ownerId reddedilir', async () => {
      const ownerDb = testEnv.authenticatedContext(ownerUid).firestore();
      
      // Geçersiz renk formatı
      await assertFails(
        ownerDb.collection('workspaces').doc('bad_color_ws').set({
          ...validWorkspace('bad_color_ws'),
          color: 'not-a-hex',
        })
      );

      // Geçersiz tür
      await assertFails(
        ownerDb.collection('workspaces').doc('bad_type_ws').set({
          ...validWorkspace('bad_type_ws'),
          type: 'invalid_type',
        })
      );

      // Beklenmeyen fazladan alan
      await assertFails(
        ownerDb.collection('workspaces').doc('extra_field_ws').set({
          ...validWorkspace('extra_field_ws'),
          extraDangerousField: true,
        })
      );

      // Doğru oluşturup ardından ownerId değiştirmeyi deneme
      await ownerDb.collection('workspaces').doc('locked_owner_ws').set(validWorkspace('locked_owner_ws'));
      await assertFails(
        ownerDb.collection('workspaces').doc('locked_owner_ws').update({
          ownerId: strangerUid,
        })
      );
    });

    test('anonim misafir kullanıcı da yalnızca kendi alanlarını oluşturup yönetebilir', async () => {
      const anonUid = 'anon_guest_xyz';
      const anonDb = testEnv.authenticatedContext(anonUid, { provider_id: 'anonymous' }).firestore();

      await anonDb.collection('workspaces').doc('anon_ws').set(validWorkspace('anon_ws', anonUid));
      await anonDb.collection('map_nodes').doc('anon_node').set(validMapNode('anon_node', 'anon_ws', anonUid));

      const readWs = await anonDb.collection('workspaces').doc('anon_ws').get();
      expect(readWs.exists).toBe(true);

      // Başka kullanıcı anonim kullanıcının verisine erişemez
      const strangerDb = testEnv.authenticatedContext(strangerUid).firestore();
      await assertFails(strangerDb.collection('workspaces').doc('anon_ws').get());
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
