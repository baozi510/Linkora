'use strict';
// Production window-policy owner; no native sensor/device claim.
const assert = require('node:assert/strict');
const { test } = require('node:test');
const fs = require('node:fs'), path = require('node:path'), vm = require('node:vm');
const ts = require('C:/Program Files/Huawei/DevEco Studio/sdk/default/openharmony/ets/build-tools/ets-loader/node_modules/typescript');

function fixture() {
  const file = path.resolve(__dirname, '../entry/src/main/ets/playback/WindowOrientationController.ets');
  assert.ok(fs.existsSync(file), 'Screen direction controller is not implemented');
  const calls = [], bars = [], appWindow = { orientation: 3,
    getPreferredOrientation() { return this.orientation; },
    async setWindowSystemBarEnable(names) { bars.push(Array.from(names)); },
    async setPreferredOrientation(value) { calls.push(value); this.orientation = value; } };
  let lookup = async () => appWindow;
  const code = ts.transpileModule(fs.readFileSync(file, 'utf8'), {
    compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022 }
  }).outputText;
  const module = { exports: {} };
  vm.runInNewContext(`(function(require,module,exports){${code}\n})`, {}, { filename: file })(name => {
    if (name === '@kit.ArkUI') return { window: {
      getLastWindow: context => { assert.equal(context, 'context'); return lookup(); },
      Orientation: { LOCKED: 11, AUTO_ROTATION_RESTRICTED: 8 }
    } };
    throw Error('Unexpected dependency: ' + name);
  }, module, module.exports);
  return { calls, bars, appWindow, set lookup(value) { lookup = value; },
    create: () => new module.exports.WindowOrientationController('context') };
}

test('Follow and current-direction lock remain immersive; leaving restores normal app bars', async () => {
  const f = fixture(), owner = f.create();
  await owner.set('follow_system');
  await owner.set('lock_current');
  assert.deepEqual(f.bars, [[]], 'hide system bars once, independently of direction');
  await owner.restore();
  assert.deepEqual(f.bars, [[], ['status', 'navigation']]);
});

test('Orientation restoration failure still restores normal app system bars', async () => {
  const f = fixture(), owner = f.create();
  await owner.set('lock_current');
  f.appWindow.setPreferredOrientation = async () => { throw Error('restore denied'); };
  await assert.rejects(owner.restore(), /restore denied/);
  assert.deepEqual(f.bars, [[], ['status', 'navigation']]);
});

test('Direction policies respect the system rotation lock and restore the exact entry policy', async () => {
  const f = fixture(), owner = f.create();
  for (const [mode, native] of [['follow_system', 8], ['lock_current', 11], ['follow_system', 8]]) {
    assert.equal(await owner.set(mode), mode);
    assert.equal(f.appWindow.orientation, native);
  }
  await owner.restore(); await owner.restore();
  assert.deepEqual(f.calls, [8, 11, 8, 3]);
  await assert.rejects(owner.set('lock_current'));
});

test('Rapid direction requests serialize and acknowledge only after the native operation', async () => {
  const f = fixture(), owner = f.create(); let finish, confirmed = false;
  f.appWindow.setPreferredOrientation = value => {
    f.calls.push(value);
    if (value === 11) return new Promise(resolve => { finish = () => { f.appWindow.orientation = value; resolve(); }; });
    f.appWindow.orientation = value; return Promise.resolve();
  };
  const first = owner.set('lock_current').then(() => { confirmed = true; });
  const second = owner.set('follow_system');
  await new Promise(setImmediate);
  assert.equal(confirmed, false); assert.deepEqual(f.calls, [11]);
  finish(); await first; await second;
  assert.deepEqual(f.calls, [11, 8]);
  await owner.restore();
});

test('Leave during a pending rotation drains it, fences queued writes, then restores', async () => {
  const f = fixture(), owner = f.create(); let finish;
  const original = f.appWindow.setPreferredOrientation.bind(f.appWindow);
  f.appWindow.setPreferredOrientation = value => value === 11 ? new Promise(resolve => {
    f.calls.push(value); finish = () => { f.appWindow.orientation = value; resolve(); };
  }) : original(value);
  const first = assert.rejects(owner.set('lock_current'));
  const queued = assert.rejects(owner.set('follow_system'));
  await new Promise(setImmediate);
  let restored = false; const closing = owner.restore().then(() => { restored = true; });
  await new Promise(setImmediate); assert.equal(restored, false);
  finish(); await first; await queued; await closing;
  assert.deepEqual(f.calls, [11, 3]);
});

test('Leave before window lookup finishes prevents a late requested orientation', async () => {
  const f = fixture(); let finish;
  f.lookup = () => new Promise(resolve => { finish = resolve; });
  const owner = f.create(), pending = assert.rejects(owner.set('lock_current'));
  await new Promise(setImmediate);
  const closing = owner.restore(); finish(f.appWindow);
  await pending; await closing;
  assert.deepEqual(f.calls, [3]);
});

test('Native failure or unapplied policy cannot be acknowledged as success', async () => {
  const f = fixture(), owner = f.create();
  const original = f.appWindow.setPreferredOrientation.bind(f.appWindow);
  f.appWindow.setPreferredOrientation = async () => { throw Error('window denied'); };
  await assert.rejects(owner.set('lock_current'), /window denied/);
  f.appWindow.setPreferredOrientation = async () => {};
  await assert.rejects(owner.set('lock_current'), /applied/i);
  f.appWindow.setPreferredOrientation = original;
  assert.equal(await owner.set('follow_system'), 'follow_system');
  await assert.rejects(owner.set('diagonal'));
  await assert.rejects(owner.set('landscape'));
  await assert.rejects(owner.set('portrait'));
  assert.deepEqual(f.calls, [8]);
  await owner.restore();
});

test('Restoration failure stays rejected and is never retried as a false success', async () => {
  const f = fixture(), owner = f.create();
  await owner.set('lock_current');
  f.appWindow.setPreferredOrientation = async value => { f.calls.push(value); throw Error('restore denied'); };
  await assert.rejects(owner.restore(), /restore denied/);
  await assert.rejects(owner.restore(), /restore denied/);
  assert.deepEqual(f.calls, [11, 3]);
});

test('A reopened player waits for the preceding page restoration before capturing or changing policy', async () => {
  const f = fixture(), first = f.create(); let finish;
  const original = f.appWindow.setPreferredOrientation.bind(f.appWindow);
  f.appWindow.setPreferredOrientation = value => value === 11 ? new Promise(resolve => {
    f.calls.push(value); finish = () => { f.appWindow.orientation = value; resolve(); };
  }) : original(value);
  const setting = assert.rejects(first.set('lock_current'));
  await new Promise(setImmediate);
  const closing = first.restore(), second = f.create(), next = second.set('follow_system');
  await new Promise(setImmediate);
  assert.deepEqual(f.calls, [11], 'a new page cannot interleave with a pending old window write');
  finish(); await setting; await closing; await next;
  assert.deepEqual(f.calls, [11, 3, 8]);
  await second.restore(); assert.deepEqual(f.calls, [11, 3, 8, 3]);
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
