const { test } = require('node:test');
const assert = require('node:assert/strict');
const {
  validateInput,
  validateResult,
  nextQuota,
  isUnverifiedPasswordUser,
  hasSupportedAuthProvider,
} = require('./validation');

test('rejects arbitrary actions and oversized prompts', () => {
  assert.throws(() => validateInput({ action: 'admin' }));
  assert.throws(() => validateInput({ action: 'question', question: 'x'.repeat(2001) }));
  assert.equal(validateInput({ action: 'question', question: ' Tajvid? ' }).question, 'Tajvid?');
});
test('rejects malformed and non-audio base64', () => {
  assert.throws(() => validateInput({ action: 'identify', audio: '*not audio*' }));
  assert.throws(() => validateInput({ action: 'identify', audio: Buffer.from('this is not m4a audio').toString('base64') }));
});
test('accepts recorder M4A container', () => {
  const audio = Buffer.concat([Buffer.from([0, 0, 0, 24]), Buffer.from('ftypM4A ')]).toString('base64');
  assert.equal(validateInput({ action: 'identify', audio }).audio, audio);
});
test('silent recording is an error rather than a failing grade', () => {
  assert.equal(validateResult('pronunciation', { transcription: '', score: 0, feedback: '' }).error, true);
});
test('normalizes scores and rejects fabricated surah indices', () => {
  assert.equal(validateResult('pronunciation', { transcription: 'ب', score: 150, feedback: 'Mashq' }).score, 100);
  const result = validateResult('identify', { found: true, surah_number: 115,
    ayah_number: 1, confidence: 80, note: '', surah_name: '', surah_name_arabic: '' });
  assert.equal(result.found, false);
  assert.equal(result.surah_number, null);
});
test('enforces burst and daily quotas with predictable resets', () => {
  const now = 86400000;
  assert.equal(nextQuota({ day: 1, minute: 1440, dailyCount: 3, minuteCount: 4 }, now), null);
  assert.equal(nextQuota({ day: 1, minute: 1439, dailyCount: 30, minuteCount: 0 }, now), null);
  assert.equal(nextQuota({ day: 0, minute: 0, dailyCount: 30, minuteCount: 4 }, now).dailyCount, 1);
});
test('email/password accounts must verify before protected callables', () => {
  assert.equal(isUnverifiedPasswordUser({ token: {
    firebase: { sign_in_provider: 'password' }, email_verified: false,
  } }), true);
  assert.equal(isUnverifiedPasswordUser({ token: {
    firebase: { sign_in_provider: 'password' }, email_verified: true,
  } }), false);
  assert.equal(isUnverifiedPasswordUser({ token: {
    firebase: { sign_in_provider: 'google.com' }, email_verified: false,
  } }), false);
  assert.equal(hasSupportedAuthProvider({ token: {
    firebase: { sign_in_provider: 'apple.com' },
  } }), true);
  assert.equal(hasSupportedAuthProvider({ token: {
    firebase: { sign_in_provider: 'anonymous' },
  } }), false);
});
