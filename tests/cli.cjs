// End-to-end checks for the Node adapter. Run after `moon build --target js`.
const { spawnSync } = require('node:child_process');
const assert = require('node:assert/strict');
const path = require('node:path');
const target = path.join(__dirname, '..', '_build', 'js', 'debug', 'build', 'cmd', 'scan', 'scan.js');
const cases = [
  { name: 'safe', input: 'name,value\r\nAlice,hello\r\n', code: 0, contains: 'No formula-like cells' },
  { name: 'quoted multiline', input: 'name,note\r\nAlice,"a,b\nsecond"\r\nBob,"=1"', code: 1, contains: 'row 3, column 2' },
  { name: 'malformed', input: 'a,"unfinished', code: 2, contains: 'unclosed quote' },
  { name: 'invalid UTF-8', input: Buffer.from([0xff]), code: 2, stderr: 'UTF-8' },
  { name: 'byte limit', input: Buffer.alloc(4000001, 0x61), code: 2, stderr: 'byte limit' },
];
for (const test of cases) {
  const result = spawnSync(process.execPath, [target], {input: test.input, encoding: 'utf8', maxBuffer: 1024 * 1024});
  assert.equal(result.status, test.code, `${test.name}: ${result.stderr}`);
  if (test.contains) assert.ok(result.stdout.includes(test.contains), test.name);
  if (test.stderr) assert.ok(result.stderr.includes(test.stderr), test.name);
  console.log(`${test.name}: OK`);
}
