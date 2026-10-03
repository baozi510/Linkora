'use strict';
const assert = require('node:assert/strict');
const { test } = require('node:test');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');

function check(t, relative, source) {
  const tempRoot = path.resolve(os.tmpdir());
  const root = fs.mkdtempSync(path.join(tempRoot, 'linkora-architecture-'));
  t.after(() => {
    // Only remove the exact temporary fixture created by this test.
    assert.equal(path.dirname(root), tempRoot);
    assert.ok(path.basename(root).startsWith('linkora-architecture-'));
    fs.rmSync(root, { recursive: true, force: true });
  });
  fs.mkdirSync(path.join(root, 'scripts'));
  fs.copyFileSync(path.join(__dirname, 'check-architecture-boundaries.cjs'),
    path.join(root, 'scripts/check-architecture-boundaries.cjs'));
  const file = path.join(root, relative);
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, source);
  const result = spawnSync(process.execPath, [path.join(root, 'scripts/check-architecture-boundaries.cjs')],
    { encoding: 'utf8' });
  assert.ifError(result.error);
  return result;
}

test('generated .test platform imports are outside production roots', t => {
  assert.equal(check(t, 'linkora_core/.test/testability/Index.ets',
    "import { media } from '@kit.MediaKit';").status, 0);
});

test('core production platform imports fail', t => {
  const result = check(t, 'linkora_core/src/main/ets/Bad.ets', "import { media } from '@kit.MediaKit';");
  assert.equal(result.status, 1);
  assert.match(result.stderr, /core-platform-free/);
});

test('core production implementation imports fail', t => {
  const result = check(t, 'linkora_core/src/main/ets/Bad.ets', "import { Probe } from 'linkora_media_probe';");
  assert.equal(result.status, 1);
  assert.match(result.stderr, /core-no-implementation-dependency/);
});

test('production build directory cannot hide a platform import', t => {
  const result = check(t, 'linkora_core/src/main/ets/build/Bad.ets', "import { media } from '@kit.MediaKit';");
  assert.equal(result.status, 1);
  assert.match(result.stderr, /src\/main\/ets\/build\/Bad.ets/);
});

test('module production export entry is also guarded', t => {
  const result = check(t, 'linkora_core/Index.ets', "export { Probe } from 'linkora_proxy';");
  assert.equal(result.status, 1);
  assert.match(result.stderr, /core-no-implementation-dependency/);
});
