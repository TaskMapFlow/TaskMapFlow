// Targeted verification of callable function logic and assertions
const assert = require('assert');

// 1. Verify Regex for invite code format
const INVITE_CODE_REGEX = /^[23456789ABCDEFGHJKLMNPQRSTUVWXYZ]{8}$/i;

// Valid codes
assert(INVITE_CODE_REGEX.test('ABCD2345'), 'Valid 8-char uppercase should pass');
assert(INVITE_CODE_REGEX.test('abcd2345'), 'Valid 8-char lowercase should pass');
assert(INVITE_CODE_REGEX.test('23456789'), 'Valid 8-char numbers should pass');

// Invalid codes
assert(!INVITE_CODE_REGEX.test('ABCD234'), '7-char code should fail');
assert(!INVITE_CODE_REGEX.test('ABCD23456'), '9-char code should fail');
assert(!INVITE_CODE_REGEX.test('ABCD1234'), 'Codes with 1 should fail');
assert(!INVITE_CODE_REGEX.test('ABCD0234'), 'Codes with 0 should fail');
assert(!INVITE_CODE_REGEX.test('ABCD!@#$'), 'Special chars should fail');
console.log('✓ Davet kodu biçim ve uzunluk doğrulaması başarılı');

// 2. Verify Auth check logic for acceptInvite
function validateAccountStatus(auth) {
  if (!auth) {
    throw new Error('unauthenticated');
  }
  const signInProvider = auth.token.firebase?.sign_in_provider;
  const isAnonymous = signInProvider === 'anonymous';
  const isEmailVerified = !!auth.token.email_verified;

  if (isAnonymous || !isEmailVerified) {
    throw new Error('permission-denied: Yalnızca e-posta adresi doğrulanmış kalıcı hesaplar');
  }
}

// Anonymous user check
assert.throws(() => {
  validateAccountStatus({
    uid: 'anon_1',
    token: { firebase: { sign_in_provider: 'anonymous' }, email_verified: false },
  });
}, /permission-denied/, 'Anonymous user must be rejected');
console.log('✓ Anonim hesap davet kabul reddi başarılı');

// Unverified email check
assert.throws(() => {
  validateAccountStatus({
    uid: 'unverified_1',
    token: { firebase: { sign_in_provider: 'password' }, email_verified: false },
  });
}, /permission-denied/, 'Unverified email user must be rejected');
console.log('✓ Doğrulanmamış hesap davet kabul reddi başarılı');

// Verified permanent user check
assert.doesNotThrow(() => {
  validateAccountStatus({
    uid: 'verified_1',
    token: { firebase: { sign_in_provider: 'password' }, email_verified: true },
  });
}, 'Verified user should be accepted');
console.log('✓ Doğrulanmış kalıcı hesap kabul doğrulaması başarılı');

// 3. Verify Admin restricted fields check
function validateAdminWorkspaceUpdate(beforeData, afterData) {
  const allowedKeys = ['description', 'tags', 'resources', 'updatedAt'];
  const affectedKeys = Object.keys(afterData).filter(
    (key) => JSON.stringify(afterData[key]) !== JSON.stringify(beforeData[key])
  );
  const hasOnlyAllowed = affectedKeys.every((key) => allowedKeys.includes(key));
  if (!hasOnlyAllowed) {
    throw new Error('permission-denied: Admin can only update ' + allowedKeys.join(', '));
  }
}

const beforeWs = {
  id: 'ws_1',
  name: 'Workspace',
  description: 'Old desc',
  memberIds: ['u1', 'u2'],
  tags: ['flutter'],
};

// Admin modifying description: allowed
assert.doesNotThrow(() => {
  validateAdminWorkspaceUpdate(beforeWs, {
    ...beforeWs,
    description: 'New desc',
    updatedAt: new Date(),
  });
});

// Admin trying to modify memberIds: rejected
assert.throws(() => {
  validateAdminWorkspaceUpdate(beforeWs, {
    ...beforeWs,
    memberIds: ['u1', 'u2', 'hacker'],
    updatedAt: new Date(),
  });
}, /permission-denied/);
console.log('✓ Admin memberIds değiştirme reddi başarılı');

// Admin trying to modify name: rejected
assert.throws(() => {
  validateAdminWorkspaceUpdate(beforeWs, {
    ...beforeWs,
    name: 'New Name',
    updatedAt: new Date(),
  });
}, /permission-denied/);
console.log('✓ Admin workspace adı/türü değiştirme reddi başarılı');

// 4. Verify Subtask preservation logic
function areSubtaskTitlesAndIdsPreserved(oldList, newList) {
  if (oldList == null && newList == null) return true;
  if (!Array.isArray(oldList) || !Array.isArray(newList)) return false;
  if (oldList.length !== newList.length) return false;
  return oldList.every((oldItem, idx) => {
    const newItem = newList[idx];
    return (
      newItem &&
      typeof newItem === 'object' &&
      newItem.id === oldItem.id &&
      newItem.title === oldItem.title &&
      typeof newItem.isCompleted === 'boolean'
    );
  });
}

const originalSubtasks = [
  { id: 's1', title: 'Task 1', isCompleted: false },
  { id: 's2', title: 'Task 2', isCompleted: false },
];

// Toggling completion: allowed
assert(
  areSubtaskTitlesAndIdsPreserved(originalSubtasks, [
    { id: 's1', title: 'Task 1', isCompleted: true },
    { id: 's2', title: 'Task 2', isCompleted: false },
  ])
);

// Changing title: rejected
assert(
  !areSubtaskTitlesAndIdsPreserved(originalSubtasks, [
    { id: 's1', title: 'Hacked Title', isCompleted: true },
    { id: 's2', title: 'Task 2', isCompleted: false },
  ])
);

// Changing id: rejected
assert(
  !areSubtaskTitlesAndIdsPreserved(originalSubtasks, [
    { id: 's_other', title: 'Task 1', isCompleted: true },
    { id: 's2', title: 'Task 2', isCompleted: false },
  ])
);

// Adding subtask: rejected
assert(
  !areSubtaskTitlesAndIdsPreserved(originalSubtasks, [
    ...originalSubtasks,
    { id: 's3', title: 'Task 3', isCompleted: false },
  ])
);
console.log('✓ Atanan üye alt görev başlık/kimlik koruması doğrulaması başarılı');

console.log('\n=== TÜM ERİŞİM MANTIĞI KONTROLLERİ BAŞARIYLA GEÇTİ ===');
