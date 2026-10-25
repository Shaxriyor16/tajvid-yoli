const { test } = require('node:test');
const assert = require('node:assert/strict');
const { parseAdminEmails, isAdminToken, providerOf, toAdminUser } = require('./admin');

test('parses a comma separated admin list case-insensitively', () => {
  assert.deepEqual(parseAdminEmails(' A@Gmail.com, ,b@x.uz '), ['a@gmail.com', 'b@x.uz']);
  assert.deepEqual(parseAdminEmails(''), []);
  assert.deepEqual(parseAdminEmails(undefined), []);
});

test('only verified listed emails are admins', () => {
  const list = ['boss@gmail.com'];
  assert.equal(isAdminToken({ email: 'Boss@Gmail.com', email_verified: true }, list), true);
  assert.equal(isAdminToken({ email: 'boss@gmail.com', email_verified: false }, list), false);
  assert.equal(isAdminToken({ email: 'other@gmail.com', email_verified: true }, list), false);
  assert.equal(isAdminToken({ email_verified: true }, list), false);
  assert.equal(isAdminToken(null, list), false);
  // bo'sh ro'yxat hech kimni admin qilmaydi
  assert.equal(isAdminToken({ email: 'boss@gmail.com', email_verified: true }, []), false);
});

test('provider is detected from profile or sign-in providers', () => {
  assert.equal(providerOf(['google.com'], undefined), 'google');
  assert.equal(providerOf(['apple.com'], undefined), 'apple');
  assert.equal(providerOf(['password'], undefined), 'email');
  assert.equal(providerOf([], undefined), 'email');
  assert.equal(providerOf(['password'], 'google'), 'google');
  assert.equal(providerOf(['google.com'], 'hacker'), 'google');
});

test('maps an auth user plus profile to the compact admin shape', () => {
  const u = {
    uid: 'u1',
    email: 'a@b.uz',
    displayName: 'Ali Valiyev',
    emailVerified: true,
    disabled: false,
    providerData: [{ providerId: 'google.com' }],
    metadata: { creationTime: 'Sat, 24 Oct 2026 10:00:00 GMT', lastSignInTime: 'Sat, 24 Oct 2026 12:00:00 GMT' },
  };
  const out = toAdminUser(u, { firstName: 'Ali', lastName: 'Valiyev', age: 21, photoUrl: 'https://x/y.jpg', provider: 'google' });
  assert.equal(out.provider, 'google');
  assert.equal(out.age, 21);
  assert.equal(out.firstName, 'Ali');
  assert.equal(out.createdAt, '2026-10-24T10:00:00.000Z');
  assert.equal(out.lastSignInAt, '2026-10-24T12:00:00.000Z');
  assert.equal(out.emailVerified, true);
});

test('never trusts non-https photos or bad ages from profile', () => {
  const out = toAdminUser({ uid: 'u2', providerData: [], metadata: {} }, { photoUrl: 'javascript:alert(1)', age: '12' });
  assert.equal(out.photoUrl, '');
  assert.equal(out.age, null);
  assert.equal(out.createdAt, null);
  assert.equal(out.provider, 'email');
});
