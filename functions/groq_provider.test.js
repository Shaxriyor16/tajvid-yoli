"use strict";

const assert = require('node:assert/strict');
const test = require('node:test');
const { createGroqProvider, GroqProviderError } = require('./groq_provider');

const jsonResponse = (body, status = 200) => new Response(JSON.stringify(body), {
  status,
  headers: { 'Content-Type': 'application/json' },
});

test('text questions use Groq chat completions and parse JSON', async () => {
  let request;
  const provider = createGroqProvider({
    apiKey: 'test-secret',
    fetchImpl: async (url, options) => {
      request = { url, options, body: JSON.parse(options.body) };
      return jsonResponse({
        choices: [{ message: { content: '{"answer":"Javob"}' } }],
      });
    },
  });

  assert.deepEqual(await provider.generate({
    action: 'question',
    question: 'Tajvid nima?',
  }), { answer: 'Javob' });
  assert.equal(request.url, 'https://api.groq.com/openai/v1/chat/completions');
  assert.equal(request.options.headers.Authorization, 'Bearer test-secret');
  assert.equal(request.body.model, 'openai/gpt-oss-20b');
  assert.deepEqual(request.body.response_format, { type: 'json_object' });
});

test('audio is transcribed first and its transcript is evaluated', async () => {
  const requests = [];
  const provider = createGroqProvider({
    apiKey: 'test-secret',
    fetchImpl: async (url, options) => {
      requests.push({ url, options });
      if (url.endsWith('/audio/transcriptions')) {
        return jsonResponse({ text: 'بسم الله الرحمن الرحيم' });
      }
      const body = JSON.parse(options.body);
      const userData = JSON.parse(body.messages[1].content);
      assert.equal(userData.transcription, 'بسم الله الرحمن الرحيم');
      return jsonResponse({
        choices: [{ message: { content: '{"feedback":"Matn bo‘yicha mos tushdi."}' } }],
      });
    },
  });

  const result = await provider.generate({
    action: 'pronunciation',
    audio: Buffer.from('test-audio').toString('base64'),
    targetText: 'بسم الله الرحمن الرحيم',
  });
  assert.equal(result.transcription, 'بسم الله الرحمن الرحيم');
  assert.equal(result.score, 100);
  assert.match(result.feedback, /Matn/);
  assert.equal(requests.length, 2);
  assert.ok(requests[0].url.endsWith('/audio/transcriptions'));
  assert.equal(requests[0].options.headers.Authorization, 'Bearer test-secret');
  assert.ok(requests[0].options.body instanceof FormData);
});

test('pronunciation score is based on Arabic word sequence, not the model output', async () => {
  const provider = createGroqProvider({
    apiKey: 'test-secret',
    fetchImpl: async (url) => url.endsWith('/audio/transcriptions')
      ? jsonResponse({ text: 'بسم الله' })
      : jsonResponse({ choices: [{ message: { content: '{"feedback":"Matn bo‘yicha tekshirildi."}' } }] }),
  });

  const result = await provider.generate({
    action: 'pronunciation',
    audio: Buffer.from('test-audio').toString('base64'),
    targetText: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
  });
  assert.equal(result.score, 50);
});

test('silent audio returns a safe empty result without a chat request', async () => {
  let calls = 0;
  const provider = createGroqProvider({
    apiKey: 'test-secret',
    fetchImpl: async () => {
      calls++;
      return jsonResponse({ text: '   ' });
    },
  });

  const result = await provider.generate({
    action: 'identify',
    audio: Buffer.from('test-audio').toString('base64'),
  });
  assert.equal(calls, 1);
  assert.equal(result.found, false);
  assert.equal(result.confidence, 0);
});

test('Groq rate limits are classified without exposing the upstream body', async () => {
  const provider = createGroqProvider({
    apiKey: 'test-secret',
    fetchImpl: async () => new Response('private provider detail', { status: 429 }),
  });

  await assert.rejects(
    provider.generate({ action: 'question', question: 'Test' }),
    (error) => error instanceof GroqProviderError && error.kind === 'rate-limit' &&
      !error.message.includes('private provider detail'),
  );
});

test('missing Groq secrets fail closed', () => {
  assert.throws(
    () => createGroqProvider({ apiKey: '' }),
    (error) => error instanceof GroqProviderError && error.kind === 'missing-key',
  );
});
