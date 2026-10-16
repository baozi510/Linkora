'use strict';
// Production window-policy owner; no native sensor/device claim.
const assert = require('node:assert/strict');
const { test } = require('node:test');
const fs = require('node:fs'), path = require('node:path'), vm = require('node:vm');
const ts = require('C:/Program Files/Huawei/DevEco Studio/sdk/default/openharmony/ets/build-tools/ets-loader/node_modules/typescript');

function fixture() {
  const file = path.resolve(__dirname, '../entry/src/main/ets/playback/WindowOrientationController.ets');
  assert.ok(fs.existsSync(file), 'Screen direction controller is not implemented');
  const calls = [], appWindow = { orientation: 3,
    getPreferredOrientation() { return this.orientation; },
    async setPreferredOrientation(value) { calls.push(value); this.orientation = value; } };
  let lookup = async () => appWindow;
  const code = ts.transpileModule(fs.readFileSync(file, 'utf8'), {
    compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022 }
  }).outputText;
  const module = { exports: {} };
  vm.runInNewContext(`(function(require,module,exports){${code}\n})`, {}, { filename: file })(name => {
    if (name === '@kit.ArkUI') return { window: {
      getLastWindow: context => { assert.equal(context, 'context'); return lookup(); },
      Orientation: { PORTRAIT: 1, LANDSCAPE: 2, AUTO_ROTATION_RESTRICTED: 8 }
    } };
    throw Error('Unexpected dependency: ' + name);
  }, module, module.exports);
  return { calls, appWindow, set lookup(value) { lookup = value; },
    create: () => new module.exports.WindowOrientationController('context') };
}

test('Direction policies respect the system rotation lock and restore the exact entry policy', async () => {
  const f = fixture(), owner = f.create();
  for (const [mode, native] of [['follow_system', 8], ['landscape', 2], ['portrait', 1]]) {
    assert.equal(await owner.set(mode), mode);
    assert.equal(f.appWindow.orientation, native);
  }
  await owner.restore(); await owner.restore();
  assert.deepEqual(f.calls, [8, 2, 1, 3]);
  await assert.rejects(owner.set('landscape'));
});

test('Rapid direction requests serialize and acknowledge only after the native operation', async () => {
  const f = fixture(), owner = f.create(); let finish, confirmed = false;
  f.appWindow.setPreferredOrientation = value => {
    f.calls.push(value);
    if (value === 2) return new Promise(resolve => { finish = () => { f.appWindow.orientation = value; resolve(); }; });
    f.appWindow.orientation = value; return Promise.resolve();
  };
  const first = owner.set('landscape').then(() => { confirmed = true; });
  const second = owner.set('portrait');
  await new Promise(setImmediate);
  assert.equal(confirmed, false); assert.deepEqual(f.calls, [2]);
  finish(); await first; await second;
  assert.deepEqual(f.calls, [2, 1]);
  await owner.restore();
});

test('Leave during a pending rotation drains it, fences queued writes, then restores', async () => {
  const f = fixture(), owner = f.create(); let finish;
  const original = f.appWindow.setPreferredOrientation.bind(f.appWindow);
  f.appWindow.setPreferredOrientation = value => value === 2 ? new Promise(resolve => {
    f.calls.push(value); finish = () => { f.appWindow.orientation = value; resolve(); };
  }) : original(value);
  const first = assert.rejects(owner.set('landscape'));
  const queued = assert.rejects(owner.set('portrait'));
  await new Promise(setImmediate);
  let restored = false; const closing = owner.restore().then(() => { restored = true; });
  await new Promise(setImmediate); assert.equal(restored, false);
  finish(); await first; await queued; await closing;
  assert.deepEqual(f.calls, [2, 3]);
});

test('Leave before window lookup finishes prevents a late requested orientation', async () => {
  const f = fixture(); let finish;
  f.lookup = () => new Promise(resolve => { finish = resolve; });
  const owner = f.create(), pending = assert.rejects(owner.set('landscape'));
  await new Promise(setImmediate);
  const closing = owner.restore(); finish(f.appWindow);
  await pending; await closing;
  assert.deepEqual(f.calls, [3]);
});

test('Native failure or unapplied policy cannot be acknowledged as success', async () => {
  const f = fixture(), owner = f.create();
  const original = f.appWindow.setPreferredOrientation.bind(f.appWindow);
  f.appWindow.setPreferredOrientation = async () => { throw Error('window denied'); };
  await assert.rejects(owner.set('landscape'), /window denied/);
  f.appWindow.setPreferredOrientation = async () => {};
  await assert.rejects(owner.set('portrait'), /applied/i);
  f.appWindow.setPreferredOrientation = original;
  assert.equal(await owner.set('follow_system'), 'follow_system');
  await assert.rejects(owner.set('diagonal'));
  assert.deepEqual(f.calls, [8]);
  await owner.restore();
});

test('Restoration failure stays rejected and is never retried as a false success', async () => {
  const f = fixture(), owner = f.create();
  await owner.set('landscape');
  f.appWindow.setPreferredOrientation = async value => { f.calls.push(value); throw Error('restore denied'); };
  await assert.rejects(owner.restore(), /restore denied/);
  await assert.rejects(owner.restore(), /restore denied/);
  assert.deepEqual(f.calls, [2, 3]);
});

test('A reopened player waits for the preceding page restoration before capturing or changing policy', async () => {
  const f = fixture(), first = f.create(); let finish;
  const original = f.appWindow.setPreferredOrientation.bind(f.appWindow);
  f.appWindow.setPreferredOrientation = value => value === 2 ? new Promise(resolve => {
    f.calls.push(value); finish = () => { f.appWindow.orientation = value; resolve(); };
  }) : original(value);
  const setting = assert.rejects(first.set('landscape'));
  await new Promise(setImmediate);
  const closing = first.restore(), second = f.create(), next = second.set('portrait');
  await new Promise(setImmediate);
  assert.deepEqual(f.calls, [2], 'a new page cannot interleave with a pending old window write');
  finish(); await setting; await closing; await next;
  assert.deepEqual(f.calls, [2, 3, 1]);
  await second.restore(); assert.deepEqual(f.calls, [2, 3, 1, 3]);
});

test('Repeated page Back waits for restoration and navigates only once', async () => {
  const file = path.resolve(__dirname, '../entry/src/main/ets/pages/PlayerPage.ets');
  const ast = ts.createSourceFile(file, fs.readFileSync(file, 'utf8'), ts.ScriptTarget.Latest, true, ts.ScriptKind.ETS);
  const page = ast.statements.find(node => node.name?.text === 'PlayerPage');
  const close = page.members.find(node => node.name?.text === 'close');
  // Execute the actual page close method without rendering ArkUI components.
  const code = ts.transpileModule('class Page {' + close.getText(ast) + '} module.exports=Page;', {
    compilerOptions: { target: ts.ScriptTarget.ES2022 }
  }).outputText;
  const module = { exports: {} };
  vm.runInNewContext(`(function(module){${code}})`, { console })(module);
  const instance = new module.exports(); let finish, restores = 0, backs = 0;
  instance.active = true;
  instance.orientationController = { restore: () => { restores++; return new Promise(resolve => { finish = resolve; }); } };
  instance.onBack = () => { backs++; };
  instance.close(); instance.close();
  await new Promise(setImmediate);
  assert.equal(backs, 0); assert.equal(restores, 1);
  finish(); await new Promise(setImmediate);
  assert.equal(backs, 1);
});
