const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { doc, setDoc, getDoc, updateDoc, deleteDoc, collection, writeBatch, serverTimestamp, Timestamp, getDocs, query, limit } = require('firebase/firestore');
const fs = require('fs');

const ADMIN = 'b4QUKm9lBbS5jccsVeBpFwBInCD2';
let env, passed = 0, failed = 0;
async function t(name, fn) {
  try { await fn(); passed++; console.log('  ok  ', name); }
  catch (e) { failed++; console.log('  FAIL', name, '->', String(e.message).split('\n')[0]); }
}

const verified = (uid) => env.authenticatedContext(uid, { email: `${uid}@x.com`, email_verified: true, firebase: { sign_in_provider: 'google.com' } }).firestore();
const unverified = (uid) => env.authenticatedContext(uid, { email: `${uid}@x.com`, email_verified: false, firebase: { sign_in_provider: 'password' } }).firestore();
const entry = (uid, over = {}) => ({ uid, name: 'A', email: 'a@b.c', rating: 5, category: 'idea', message: 'hello', appVersion: '1.0', platform: 'android', locale: 'uz', status: 'new', createdAt: serverTimestamp(), ...over });

async function send(db, uid, over = {}) {
  const b = writeBatch(db);
  b.set(doc(db, 'feedbackMeta', uid), { lastAt: serverTimestamp() });
  b.set(doc(collection(db, 'feedback')), entry(uid, over));
  return b.commit();
}
async function seedFeedback(uid) {
  let id;
  await env.withSecurityRulesDisabled(async (c) => {
    const r = doc(collection(c.firestore(), 'feedback'));
    id = r.id;
    await setDoc(r, entry(uid, { createdAt: Timestamp.now() }));
  });
  return id;
}

(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-rules',
    firestore: { rules: fs.readFileSync(__dirname + '/../firestore.rules', 'utf8'), host: '127.0.0.1', port: 8080 },
  });

  console.log('feedback');
  await t('verified user can send one feedback', async () => { await env.clearFirestore(); await assertSucceeds(send(verified('u1'), 'u1')); });
  await t('second feedback within 60s is blocked (throttle)', async () => { await assertFails(send(verified('u1'), 'u1')); });
  await t('after 60s the next one is allowed', async () => {
    await env.withSecurityRulesDisabled(async (c) => { await setDoc(doc(c.firestore(), 'feedbackMeta', 'u1'), { lastAt: Timestamp.fromMillis(Date.now() - 120000) }); });
    await assertSucceeds(send(verified('u1'), 'u1'));
  });
  await t('cannot write feedback WITHOUT meta in same batch', async () => { await assertFails(setDoc(doc(collection(verified('u2'), 'feedback')), entry('u2'))); });
  await t('cannot write as another uid', async () => { await assertFails(send(verified('u3'), 'u4')); });
  await t('unverified password user is blocked', async () => { await assertFails(send(unverified('u5'), 'u5')); });
  await t('anonymous is blocked', async () => { await assertFails(send(env.unauthenticatedContext().firestore(), 'u6')); });
  await t('bad rating rejected', async () => { await assertFails(send(verified('u7'), 'u7', { rating: 9 })); });
  await t('oversized message rejected', async () => { await assertFails(send(verified('u8'), 'u8', { message: 'x'.repeat(1001) })); });
  await t('extra field rejected', async () => { await assertFails(send(verified('u9'), 'u9', { isAdmin: true })); });
  await t('client cannot forge status=done', async () => { await assertFails(send(verified('u10'), 'u10', { status: 'done' })); });
  await t('client cannot set a fake createdAt', async () => { await assertFails(send(verified('u11'), 'u11', { createdAt: Timestamp.fromMillis(1) })); });
  await t('user cannot READ feedback', async () => { await assertFails(getDocs(query(collection(verified('u1'), 'feedback'), limit(1)))); });
  await t('user cannot read feedbackMeta', async () => { await assertFails(getDoc(doc(verified('u1'), 'feedbackMeta', 'u1'))); });
  await t('user cannot delete/update feedback', async () => {
    const id = await seedFeedback('u1');
    await assertFails(deleteDoc(doc(verified('u1'), 'feedback', id)));
    await assertFails(updateDoc(doc(verified('u1'), 'feedback', id), { status: 'done' }));
  });

  console.log('admin (by UID, no email verification needed)');
  await t('admin (unverified email, correct UID) can read feedback', async () => { await assertSucceeds(getDocs(query(collection(unverified(ADMIN), 'feedback'), limit(1)))); });
  await t('admin can read users', async () => { await assertSucceeds(getDocs(query(collection(unverified(ADMIN), 'users'), limit(1)))); });
  await t('admin can change ONLY status, and delete', async () => {
    const id = await seedFeedback('u1');
    const a = unverified(ADMIN);
    await assertSucceeds(updateDoc(doc(a, 'feedback', id), { status: 'read' }));
    await assertFails(updateDoc(doc(a, 'feedback', id), { message: 'edited' }));
    await assertFails(updateDoc(doc(a, 'feedback', id), { status: 'hacked' }));
    await assertSucceeds(deleteDoc(doc(a, 'feedback', id)));
  });
  await t('same EMAIL but another UID is NOT admin', async () => {
    const db = env.authenticatedContext('evil', { email: 'admin@tajvidyoli.uz', email_verified: true, firebase: { sign_in_provider: 'google.com' } }).firestore();
    await assertFails(getDocs(query(collection(db, 'feedback'), limit(1))));
    await assertFails(getDocs(query(collection(db, 'users'), limit(1))));
  });
  await t('random verified user cannot list users', async () => { await assertFails(getDocs(query(collection(verified('u1'), 'users'), limit(1)))); });

  console.log('users');
  const prof = (uid, over = {}) => ({ uid, email: 'a@b.c', firstName: 'A', lastName: 'B', provider: 'google', createdAt: '2026-10-25T00:00:00Z', ...over });
  await t('owner can create own profile', async () => { await assertSucceeds(setDoc(doc(verified('p1'), 'users', 'p1'), prof('p1'))); });
  await t('owner reads own profile, others cannot', async () => { await assertSucceeds(getDoc(doc(verified('p1'), 'users', 'p1'))); await assertFails(getDoc(doc(verified('p2'), 'users', 'p1'))); });
  await t('cannot create profile for someone else', async () => { await assertFails(setDoc(doc(verified('p3'), 'users', 'p4'), prof('p4'))); });
  await t('cannot inject extra fields into profile', async () => { await assertFails(setDoc(doc(verified('p5'), 'users', 'p5'), prof('p5', { isAdmin: true }))); });
  await t('cannot change provider after creation', async () => { await assertFails(updateDoc(doc(verified('p1'), 'users', 'p1'), { provider: 'apple' })); });
  await t('clients cannot delete a profile', async () => { await assertFails(deleteDoc(doc(verified('p1'), 'users', 'p1'))); });
  await t('server-only _aiQuota is closed', async () => { await assertFails(getDoc(doc(verified('p1'), '_aiQuota', 'p1'))); await assertFails(setDoc(doc(verified('p1'), '_aiQuota', 'p1'), { x: 1 })); });
  await t('unknown collection is closed', async () => { await assertFails(getDoc(doc(verified('p1'), 'anything', 'x'))); });

  await env.cleanup();
  console.log(`\n${passed} passed, ${failed} failed`);
  process.exit(failed ? 1 : 0);
})();
