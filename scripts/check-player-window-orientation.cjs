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
    rect: { width: 2760, height: 1256 },
    getWindowProperties() { return { windowRect: this.rect }; },
    getPreferredOrientation() { return this.orientation; },
    async setWindowSystemBarEnable(names) { bars.push(Array.from(names)); },
    async setPreferredOrientation(value) { calls.push(value); this.orientation = value; } };
  const properties = [], indicators = [];
  appWindow.setSpecificSystemBarEnabled = async (name, enabled) => { indicators.push([name, enabled]); };
  appWindow.setWindowLayoutFullScreen = async value => { appWindow.fullscreen = value; };
  appWindow.setWindowSystemBarProperties = async value => { properties.push(value); };
  let lookup = async () => appWindow;
  let theme;
  function load(file) {
  const code = ts.transpileModule(fs.readFileSync(file, 'utf8'), {
    compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022 }
  }).outputText;
  const module = { exports: {} };
  vm.runInNewContext(`(function(require,module,exports){${code}\n})`, { $r: () => ({ id: 1 }) }, { filename: file })(name => {
    if (name === '@kit.ArkUI') return { window: {
      getLastWindow: context => { assert.equal(context, 'context'); return lookup(); },
      Orientation: { LOCKED: 11, AUTO_ROTATION_LANDSCAPE: 7, AUTO_ROTATION_PORTRAIT: 6,
        AUTO_ROTATION_RESTRICTED: 8 }
    } };
    if (name === '../ui/AppThemeController') return { AppThemeController: theme };
    if (name === '@kit.AbilityKit') return { ConfigurationConstant: { ColorMode: { COLOR_MODE_LIGHT: 0, COLOR_MODE_DARK: 1, COLOR_MODE_NOT_SET: -1 } } };
    if (name === '@kit.LocalizationKit') return { resourceManager: { ColorMode: { DARK: 1, LIGHT: 0 } } };
    if (name === '@kit.BasicServicesKit') return { deviceInfo: { distributionOSApiVersion: 26 } };
    if (name === 'linkora_core') return { AppThemeMode: { SYSTEM: 'system', LIGHT: 'light', DARK: 'dark' } };
    throw Error('Unexpected dependency: ' + name);
  }, module, module.exports);
  return module.exports;
  }
  theme = load(path.resolve(__dirname, '../entry/src/main/ets/ui/AppThemeController.ets')).AppThemeController;
  const { WindowOrientationController } = load(file);
  return { calls, bars, properties, indicators, theme, appWindow, set lookup(value) { lookup = value; },
    create: () => new WindowOrientationController('context') };
}

test('Ordinary pages use native safe layout and both pages show system bars', async () => {
  const f = fixture();
  f.theme.apply('context', 'light'); await new Promise(setImmediate);
  assert.deepEqual(f.bars.at(-1), ['status', 'navigation']);
  assert.equal(f.appWindow.fullscreen, false);
  assert.deepEqual(f.indicators.at(-1), ['navigationIndicator', true]);
  const owner = f.create(); await owner.set('follow_system');
  assert.deepEqual(f.bars.at(-1), ['status', 'navigation']);
  assert.equal(f.properties.at(-1).statusBarContentColor, '#F4F5F7');
  f.theme.refreshSystemBars('context'); await new Promise(setImmediate);
  assert.deepEqual(f.bars.at(-1), ['status', 'navigation']);
  assert.equal(f.properties.at(-1).statusBarColor, '#00000000');
  assert.equal(f.properties.at(-1).statusBarContentColor, '#F4F5F7');
  await owner.restore(); assert.deepEqual(f.bars.at(-1), ['status', 'navigation']);
});

test('A delayed ordinary-theme refresh cannot hide status after playback takes ownership', async () => {
  const f = fixture(); let finish;
  f.lookup = () => new Promise(resolve => { finish = resolve; });
  f.theme.apply('context', 'light'); await new Promise(setImmediate);
  f.lookup = async () => f.appWindow;
  const owner = f.create(), entering = owner.set('follow_system');
  await new Promise(setImmediate);
  finish(f.appWindow); await entering; await new Promise(setImmediate);
  assert.deepEqual(f.bars.at(-1), ['status', 'navigation']);
  assert.equal(f.properties.at(-1).statusBarContentColor, '#F4F5F7');
  await owner.restore(); assert.deepEqual(f.bars.at(-1), ['status', 'navigation']);
});

test('Late ordinary-theme properties cannot overwrite playback status color', async () => {
  const f = fixture(); let finish, delayOnce = true;
  f.appWindow.setWindowSystemBarProperties = value => {
    if (delayOnce && value.statusBarContentColor === '#171A21') return new Promise(resolve => {
      delayOnce = false;
      finish = () => { f.properties.push(value); resolve(); };
    });
    f.properties.push(value); return Promise.resolve();
  };
  f.theme.apply('context', 'light'); await new Promise(setImmediate);
  const owner = f.create(), entering = owner.set('follow_system');
  await new Promise(setImmediate); finish(); await entering; await new Promise(setImmediate);
  assert.equal(f.properties.at(-1).statusBarContentColor, '#F4F5F7');
  await owner.restore();
});

test('Late playback-theme enable cannot reshow status after leaving', async () => {
  const f = fixture(), owner = f.create(); let finish, delayOnce = true;
  await owner.set('follow_system');
  f.appWindow.setWindowSystemBarEnable = names => {
    if (delayOnce && names.includes('status')) return new Promise(resolve => {
      delayOnce = false;
      finish = () => { f.bars.push(Array.from(names)); resolve(); };
    });
    f.bars.push(Array.from(names)); return Promise.resolve();
  };
  f.theme.refreshSystemBars('context'); await new Promise(setImmediate);
  const closing = owner.restore(); await new Promise(setImmediate);
  finish(); await closing; await new Promise(setImmediate);
  assert.deepEqual(f.bars.at(-1), ['status', 'navigation']);
});

test('Playback controls own both system bars, including theme refresh and exit while hidden', async () => {
  const f = fixture(), owner = f.create();
  f.theme.apply('context', 'light'); await new Promise(setImmediate);
  await owner.set('follow_system'); assert.equal(f.appWindow.fullscreen, true);
  await owner.setControlsVisible(false);
  assert.deepEqual(f.bars.at(-1), []);
  assert.deepEqual(f.indicators.at(-1), ['navigationIndicator', false]);
  f.theme.refreshSystemBars('context'); await new Promise(setImmediate);
  assert.deepEqual(f.bars.at(-1), []);
  await owner.setControlsVisible(true);
  assert.deepEqual(f.bars.at(-1), ['status', 'navigation']);
  await owner.setControlsVisible(false); await owner.restore();
  assert.deepEqual(f.bars.at(-1), ['status', 'navigation']);
  assert.equal(f.appWindow.fullscreen, false);
  assert.equal(f.properties.at(-1).statusBarContentColor, '#171A21');
  await assert.rejects(owner.setControlsVisible(false), /closed/);
});

test('Native system-bar failure remains rejected during entry and restoration', async () => {
  const f = fixture(), owner = f.create();
  f.appWindow.setWindowSystemBarEnable = async () => { throw Error('bars denied'); };
  await assert.rejects(owner.set('follow_system'), /bars denied/);
  assert.deepEqual(f.calls, []);
  await assert.rejects(owner.restore(), /bars denied/);
});

test('Lock current selects the native sensor policy for its axis, permitting 180-degree flips', async () => {
  for (const [width, height, policy] of [[2760, 1256, 7], [1256, 2760, 6]]) {
    const f = fixture(), owner = f.create();
    f.appWindow.rect = { width, height };
    assert.equal(await owner.set('lock_current'), 'lock_current');
    assert.deepEqual(f.calls, [policy]);
    await owner.set('follow_system');
    assert.equal(f.appWindow.orientation, 8);
    await owner.restore();
    assert.equal(f.appWindow.orientation, 3);
  }
});

test('An unavailable or ambiguous window size cannot acknowledge an axis lock', async () => {
  for (const [width, height] of [[0, 1256], [2760, 0], [100, 100]]) {
    const f = fixture(), owner = f.create();
    f.appWindow.rect = { width, height };
    await assert.rejects(owner.set('lock_current'), /window size/i);
    assert.deepEqual(f.calls, []);
    await owner.restore();
  }
});

test('Playback and ordinary pages retain system bars when controls are visible', async () => {
  const f = fixture(), owner = f.create();
  await owner.set('follow_system');
  await owner.set('lock_current');
  assert.deepEqual(f.bars, [['status', 'navigation']], 'show playback system bars once, independently of direction');
  await owner.restore();
  assert.deepEqual(f.bars, [['status', 'navigation'], ['status', 'navigation']]);
});

test('Orientation restoration failure still restores ordinary app system bars', async () => {
  const f = fixture(), owner = f.create();
  await owner.set('lock_current');
  f.appWindow.setPreferredOrientation = async () => { throw Error('restore denied'); };
  await assert.rejects(owner.restore(), /restore denied/);
  assert.deepEqual(f.bars, [['status', 'navigation'], ['status', 'navigation']]);
});

test('Direction policies respect the system rotation lock and restore the exact entry policy', async () => {
  const f = fixture(), owner = f.create();
  for (const [mode, native] of [['follow_system', 8], ['lock_current', 7], ['follow_system', 8]]) {
    assert.equal(await owner.set(mode), mode);
    assert.equal(f.appWindow.orientation, native);
  }
  await owner.restore(); await owner.restore();
  assert.deepEqual(f.calls, [8, 7, 8, 3]);
  await assert.rejects(owner.set('lock_current'));
});

test('Rapid direction requests serialize and acknowledge only after the native operation', async () => {
  const f = fixture(), owner = f.create(); let finish, confirmed = false;
  f.appWindow.setPreferredOrientation = value => {
    f.calls.push(value);
    if (value === 7) return new Promise(resolve => { finish = () => { f.appWindow.orientation = value; resolve(); }; });
    f.appWindow.orientation = value; return Promise.resolve();
  };
  const first = owner.set('lock_current').then(() => { confirmed = true; });
  const second = owner.set('follow_system');
  await new Promise(setImmediate);
  assert.equal(confirmed, false); assert.deepEqual(f.calls, [7]);
  finish(); await first; await second;
  assert.deepEqual(f.calls, [7, 8]);
  await owner.restore();
});

test('Leave during a pending rotation drains it, fences queued writes, then restores', async () => {
  const f = fixture(), owner = f.create(); let finish;
  const original = f.appWindow.setPreferredOrientation.bind(f.appWindow);
  f.appWindow.setPreferredOrientation = value => value === 7 ? new Promise(resolve => {
    f.calls.push(value); finish = () => { f.appWindow.orientation = value; resolve(); };
  }) : original(value);
  const first = assert.rejects(owner.set('lock_current'));
  const queued = assert.rejects(owner.set('follow_system'));
  await new Promise(setImmediate);
  let restored = false; const closing = owner.restore().then(() => { restored = true; });
  await new Promise(setImmediate); assert.equal(restored, false);
  finish(); await first; await queued; await closing;
  assert.deepEqual(f.calls, [7, 3]);
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
  assert.deepEqual(f.calls, [7, 3]);
});

test('A reopened player waits for the preceding page restoration before capturing or changing policy', async () => {
  const f = fixture(), first = f.create(); let finish;
  const original = f.appWindow.setPreferredOrientation.bind(f.appWindow);
  f.appWindow.setPreferredOrientation = value => value === 7 ? new Promise(resolve => {
    f.calls.push(value); finish = () => { f.appWindow.orientation = value; resolve(); };
  }) : original(value);
  const setting = assert.rejects(first.set('lock_current'));
  await new Promise(setImmediate);
  const closing = first.restore(), second = f.create(), next = second.set('follow_system');
  await new Promise(setImmediate);
  assert.deepEqual(f.calls, [7], 'a new page cannot interleave with a pending old window write');
  finish(); await setting; await closing; await next;
  assert.deepEqual(f.calls, [7, 3, 8]);
  await second.restore(); assert.deepEqual(f.calls, [7, 3, 8, 3]);
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

test('Page restores controls and makes one bounded show-bars request after a current native failure', async () => {
  const file = path.resolve(__dirname, '../entry/src/main/ets/pages/PlayerPage.ets');
  const ast = ts.createSourceFile(file, fs.readFileSync(file, 'utf8'), ts.ScriptTarget.Latest, true, ts.ScriptKind.ETS);
  const page = ast.statements.find(node => node.name?.text === 'PlayerPage');
  const method = page.members.find(node => node.name?.text === 'setControlsVisible');
  const code = ts.transpileModule('class Page {' + method.getText(ast) + '} module.exports=Page;', {
    compilerOptions: { target: ts.ScriptTarget.ES2022 }
  }).outputText;
  const module = { exports: {} };
  vm.runInNewContext('(function(module){'+code+'})', { console: { error() {} } })(module);
  const instance = new module.exports(), requests = [];
  instance.active = true; instance.controlsRequestId = 0; instance.controlsVisible = true;
  instance.orientationController = { async setControlsVisible(value) {
    requests.push(value); if (!value) throw Error('native hide denied');
  } };
  instance.setControlsVisible(false); await new Promise(setImmediate);
  assert.equal(instance.controlsVisible, true);
  assert.deepEqual(requests, [false, true]);
  let finish;
  const old = { setControlsVisible() { return new Promise((_resolve, reject) => { finish = reject; }); } };
  instance.orientationController = old; instance.setControlsVisible(false);
  instance.orientationController = { async setControlsVisible(value) { requests.push(value); } };
  instance.controlsVisible = false; finish(Error('old page rejected')); await new Promise(setImmediate);
  assert.equal(instance.controlsVisible, false, 'old-owner errors cannot reopen a new page controls');
  assert.deepEqual(requests, [false, true]);
});
