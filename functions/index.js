"use strict";
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret, defineString } = require('firebase-functions/params');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');
const { getStorage } = require('firebase-admin/storage');
const {
  validateInput,
  validateResult,
  nextQuota,
  isUnverifiedPasswordUser,
  hasSupportedAuthProvider,
} = require('./validation');
const { createGroqProvider, GroqProviderError } = require('./groq_provider');
const { parseAdminEmails, isAdminToken, toAdminUser } = require('./admin');
initializeApp();
const groqApiKey = defineSecret('GROQ_API_KEY');
// Admin panel uchun ruxsat etilgan Google emaillar (vergul bilan): functions/.env ichida
// ADMIN_EMAILS=siz@gmail.com
const adminEmails = defineString('ADMIN_EMAILS', { default: '' });
const groqChatModel = defineString('GROQ_CHAT_MODEL', {
  default: 'openai/gpt-oss-20b',
});
const groqTranscriptionModel = defineString('GROQ_TRANSCRIPTION_MODEL', {
  default: 'whisper-large-v3',
});

exports.deleteAccount = onCall({ region: 'us-central1', enforceAppCheck: true,
  timeoutSeconds: 60, maxInstances: 3 }, async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required');
  if (!hasSupportedAuthProvider(request.auth)) {
    throw new HttpsError('permission-denied', 'Unsupported sign-in provider');
  }
  if (isUnverifiedPasswordUser(request.auth)) {
    throw new HttpsError('permission-denied', 'Verify your email before deleting your account');
  }
  if (Date.now() / 1000 - Number(request.auth.token.auth_time || 0) > 300) {
    throw new HttpsError('failed-precondition', 'Sign in again before deleting your account');
  }
  if (request.data?.confirm !== true) throw new HttpsError('invalid-argument', 'Confirmation required');
  const uid = request.auth.uid;
  // Scope every deletion to the authenticated user; never accept a client UID.
  await getFirestore().recursiveDelete(getFirestore().collection('users').doc(uid));
  await getFirestore().collection('_aiQuota').doc(uid).delete();
  try {
    await getStorage().bucket().file(`users/${uid}/profile.jpg`).delete({ ignoreNotFound: true });
  } catch (error) {
    if (Number(error.code) !== 404) throw new HttpsError('unavailable', 'Please retry account deletion');
  }
  await getAuth().deleteUser(uid);
  return { deleted: true };
});

exports.tajvidAi = onCall({
  region: 'us-central1', enforceAppCheck: true, secrets: [groqApiKey],
  timeoutSeconds: 55, memory: '256MiB', maxInstances: 5, concurrency: 20,
}, async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required');
  if (!hasSupportedAuthProvider(request.auth)) {
    throw new HttpsError('permission-denied', 'Unsupported sign-in provider');
  }
  if (isUnverifiedPasswordUser(request.auth)) {
    throw new HttpsError('permission-denied', 'Verify your email before using AI features');
  }
  let input;
  try { input = validateInput(request.data); }
  catch (_) { throw new HttpsError('invalid-argument', 'Invalid request'); }

  // Server-owned counters are atomic across instances. Clients cannot write
  // these documents under the default-deny Firestore rules.
  const db = getFirestore();
  const quotaRef = db.collection('_aiQuota').doc(request.auth.uid);
  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(quotaRef);
    const quota = nextQuota(snapshot.data(), Date.now());
    if (!quota) throw new HttpsError('resource-exhausted', 'Please try later');
    transaction.set(quotaRef, quota);
  });

  try {
    const provider = createGroqProvider({
      apiKey: groqApiKey.value(),
      chatModel: groqChatModel.value(),
      transcriptionModel: groqTranscriptionModel.value(),
    });
    const result = await provider.generate(input);
    return validateResult(input.action, result);
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    if (error instanceof GroqProviderError && error.kind === 'rate-limit') {
      throw new HttpsError('resource-exhausted', 'AI capacity reached');
    }
    if (error instanceof GroqProviderError && error.kind === 'invalid-input') {
      throw new HttpsError('invalid-argument', 'Invalid audio input');
    }
    // Never log audio, transcripts, tokens, API keys, or upstream bodies.
    throw new HttpsError('unavailable', 'AI analysis could not be completed');
  }
});

// Admin panel: Firebase Auth'dagi BARCHA foydalanuvchilar (tasdiqlanmaganlari ham),
// Firestore profili bilan birlashtirilgan. Faqat tasdiqlangan admin email chaqira oladi.
// Faqat o'qiydi — hech narsani o'zgartirmaydi/o'chirmaydi.
exports.adminListUsers = onCall({
  region: 'us-central1', timeoutSeconds: 120, memory: '512MiB', maxInstances: 2,
}, async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required');
  if (!isAdminToken(request.auth.token, parseAdminEmails(adminEmails.value()))) {
    throw new HttpsError('permission-denied', 'Admin only');
  }
  const MAX_USERS = 20000;
  const auth = getAuth();
  const authUsers = [];
  let pageToken;
  do {
    const page = await auth.listUsers(1000, pageToken);
    authUsers.push(...page.users);
    pageToken = page.pageToken;
  } while (pageToken && authUsers.length < MAX_USERS);

  const db = getFirestore();
  const profiles = new Map();
  for (let i = 0; i < authUsers.length; i += 300) {
    const refs = authUsers.slice(i, i + 300).map((u) => db.collection('users').doc(u.uid));
    const docs = await db.getAll(...refs);
    docs.forEach((d) => { if (d.exists) profiles.set(d.id, d.data()); });
  }
  const users = authUsers
    .map((u) => toAdminUser(u, profiles.get(u.uid)))
    .sort((a, b) => String(b.createdAt || '').localeCompare(String(a.createdAt || '')));
  return { users, truncated: pageToken !== undefined && pageToken !== null };
});
