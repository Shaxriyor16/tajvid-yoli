"use strict";

const fs = require('node:fs');
const path = require('node:path');
const { createGroqProvider } = require('./groq_provider');

function readLocalApiKey() {
  const filename = path.join(__dirname, '.secret.local');
  if (!fs.existsSync(filename)) return '';
  const line = fs.readFileSync(filename, 'utf8')
    .split(/\r?\n/)
    .find((item) => item.startsWith('GROQ_API_KEY='));
  return line?.slice('GROQ_API_KEY='.length).trim() || '';
}

async function main() {
  const apiKey = readLocalApiKey();
  if (!apiKey) {
    console.error('FAIL: functions/.secret.local is missing GROQ_API_KEY');
    process.exitCode = 1;
    return;
  }

  try {
    const provider = createGroqProvider({ apiKey });
    const result = await provider.generate({
      action: 'question',
      question: 'Tajvid nima? Bir jumlada o‘zbekcha javob ber.',
    });
    if (typeof result.answer !== 'string' || !result.answer.trim()) {
      throw new Error('invalid-response');
    }
    console.log('PASS: Groq chat API returned valid JSON (answer hidden)');
  } catch (error) {
    console.error(`FAIL: Groq chat API smoke test (${error.kind || 'network-or-timeout'})`);
    process.exitCode = 1;
  }
}

main();
