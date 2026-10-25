"use strict";

// Admin panel uchun sof (toza) yordamchi funksiyalar — Firebase'ga bog'liq emas,
// shuning uchun oddiy `node --test` bilan tekshiriladi.

function parseAdminUids(value) {
  return String(value || '')
    .split(',')
    .map((e) => e.trim())
    .filter(Boolean);
}

// Admin EMAIL bilan emas, hisob UID raqami bilan aniqlanadi (firestore.rules dagi isAdmin() bilan bir xil).
function isAdminUid(uid, adminUids) {
  return typeof uid === 'string' && uid.length > 0 && adminUids.includes(uid);
}

function providerOf(providerIds, profileProvider) {
  if (['google', 'apple', 'email'].includes(profileProvider)) return profileProvider;
  const ids = providerIds || [];
  if (ids.includes('apple.com')) return 'apple';
  if (ids.includes('google.com')) return 'google';
  return 'email';
}

// Auth foydalanuvchisi + (bo'lsa) Firestore profilidan panel uchun ixcham obyekt.
function toAdminUser(u, profile) {
  const p = profile || {};
  const providerIds = (u.providerData || []).map((x) => x.providerId);
  const meta = u.metadata || {};
  const created = meta.creationTime ? new Date(meta.creationTime) : null;
  const last = meta.lastSignInTime ? new Date(meta.lastSignInTime) : null;
  return {
    uid: u.uid,
    email: u.email || p.email || '',
    displayName: u.displayName || '',
    firstName: typeof p.firstName === 'string' ? p.firstName : '',
    lastName: typeof p.lastName === 'string' ? p.lastName : '',
    age: Number.isInteger(p.age) ? p.age : null,
    photoUrl: typeof p.photoUrl === 'string' && p.photoUrl.startsWith('https://') ? p.photoUrl : (u.photoURL || ''),
    provider: providerOf(providerIds, p.provider),
    providerIds,
    emailVerified: u.emailVerified === true,
    disabled: u.disabled === true,
    createdAt: created && !isNaN(created) ? created.toISOString() : null,
    lastSignInAt: last && !isNaN(last) ? last.toISOString() : null,
  };
}

module.exports = { parseAdminUids, isAdminUid, providerOf, toAdminUser };
