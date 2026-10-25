"use strict";

function validateInput(data) {
  if (!data || !['question', 'pronunciation', 'identify'].includes(data.action)) {
    throw new Error('Unsupported action');
  }
  if (data.action === 'question') {
    if (typeof data.question !== 'string' || !data.question.trim() || data.question.length > 2000) {
      throw new Error('Question must contain 1–2000 characters');
    }
    return { action: data.action, question: data.question.trim() };
  }
  if (typeof data.audio !== 'string' || data.audio.length > 4 * 1024 * 1024 ||
      data.audio.length < 16 || !/^[A-Za-z0-9+/]+={0,2}$/.test(data.audio)) {
    throw new Error('Invalid audio payload');
  }
  const audio = Buffer.from(data.audio, 'base64');
  if (audio.length > 3 * 1024 * 1024 || audio.toString('base64') !== data.audio ||
      audio.toString('ascii', 4, 8) !== 'ftyp') {
    throw new Error('Expected an M4A recording, at most 3 MB');
  }
  if (data.action === 'pronunciation' &&
      (typeof data.targetText !== 'string' || !data.targetText.trim() || data.targetText.length > 2000)) {
    throw new Error('Invalid target text');
  }
  return { action: data.action, audio: data.audio, targetText: data.targetText };
}

function validateResult(action, data) {
  if (!data || typeof data !== 'object') throw new Error('Invalid AI response');
  const text = (key, limit = 4000) => {
    if (typeof data[key] !== 'string' || data[key].length > limit) throw new Error('Invalid AI text');
    return data[key];
  };
  const percentage = (key) => {
    if (!Number.isFinite(data[key])) throw new Error('Invalid AI score');
    return Math.max(0, Math.min(100, Math.round(data[key])));
  };
  if (action === 'question') return { answer: text('answer', 8000) };
  if (action === 'pronunciation') {
    const transcription = text('transcription');
    const feedback = text('feedback');
    if (!transcription.trim()) return { error: true, transcription: '', score: 0,
      feedback: 'Ovoz aniq eshitilmadi. Qayta yozib oling.' };
    return { transcription, score: percentage('score'), feedback };
  }
  const found = data.found === true && Number.isInteger(data.surah_number) &&
    data.surah_number >= 1 && data.surah_number <= 114 &&
    Number.isInteger(data.ayah_number) && data.ayah_number >= 1 && data.ayah_number <= 286;
  return { found, surah_number: found ? data.surah_number : null,
    ayah_number: found ? data.ayah_number : null,
    confidence: percentage('confidence'), note: text('note'),
    surah_name: text('surah_name', 150), surah_name_arabic: text('surah_name_arabic', 150) };
}

function nextQuota(previous, now) {
  const day = Math.floor(now / 86400000);
  const minute = Math.floor(now / 60000);
  const dailyCount = previous?.day === day ? previous.dailyCount : 0;
  const minuteCount = previous?.minute === minute ? previous.minuteCount : 0;
  if (dailyCount >= 30 || minuteCount >= 4) return null;
  return { day, minute, dailyCount: dailyCount + 1, minuteCount: minuteCount + 1 };
}

function isUnverifiedPasswordUser(auth) {
  const provider = auth?.token?.firebase?.sign_in_provider;
  return (provider === 'password' || provider === 'emailLink') &&
    auth.token.email_verified !== true;
}

function hasSupportedAuthProvider(auth) {
  const provider = auth?.token?.firebase?.sign_in_provider;
  return ['password', 'emailLink', 'google.com', 'apple.com'].includes(provider);
}

module.exports = {
  validateInput,
  validateResult,
  nextQuota,
  isUnverifiedPasswordUser,
  hasSupportedAuthProvider,
};
