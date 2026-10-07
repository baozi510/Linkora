'use strict';
// Execute the production adapter with a wrapper double and a controlled clock.
// This is an event-mapping regression, not native MPV/device validation.
const assert = require('node:assert/strict');
const { test } = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const studio = process.argv[2] || 'C:/Program Files/Huawei/DevEco Studio';
const ts = require(path.join(studio, 'sdk/default/openharmony/ets/build-tools/ets-loader/node_modules/typescript'));
const root = path.resolve(__dirname, '..');

function fixture() {
  const timers = new Map();
  let timerId = 0, player;
  const events = { MPV_EVENT_FILE_LOADED: 8, MPV_EVENT_PLAYBACK_RESTART: 21 };
  class Player {
    constructor() {
      player = this;
      this.destroyed = false;
      this.playCalls = 0;
      this.pauseCalls = 0;
      this.seekCalls = 0;
      this.state = { duration: 60, position: 0 };
      this.stream = Object.fromEntries(['duration', 'position', 'playing', 'eof', 'buffering',
        'bufferingPercentage', 'buffer', 'videoParams', 'tracks', 'track', 'error'].map(name => {
        let listener;
        return [name, { listen(callback) { listener = callback; }, add(value) { listener(value); } }];
      }));
      this.native = { addEventObserver: observer => { this.events = observer; },
        removeEventObserver() {}, attachSurface() {}, detachSurface() {}, setProperty() {} };
    }
    open() {}
    play() { this.playCalls++; }
    pause() { this.pauseCalls++; }
    seek(seconds) {
      this.seekCalls++;
      this.state.position = seconds;
      this.stream.eof.add(false);
    }
    destroy() { this.destroyed = true; }
  }
  const loaded = new Map();
  function load(relative) {
    const file = path.resolve(root, relative);
    if (loaded.has(file)) return loaded.get(file);
    const module = { exports: {} };
    loaded.set(file, module.exports);
    const code = ts.transpileModule(fs.readFileSync(file, 'utf8'), {
      compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022 }
    }).outputText;
    vm.runInNewContext(`(function(require,module,exports){${code}\n})`, {
      setTimeout(callback, milliseconds) {
        assert.equal(milliseconds, 12000);
        timers.set(++timerId, callback); return timerId;
      },
      clearTimeout(id) { timers.delete(id); }
    }, { filename: file })(name => {
      if (name.startsWith('.')) return load(path.relative(root, path.resolve(path.dirname(file), name + '.ets')));
      if (name === '@mpv-ohos/mpv-arkts') return { Player, Media: class {}, MpvEvent: events };
      if (name === 'linkora_core') return core;
      throw new Error(`Unexpected adapter dependency: ${name}`);
    }, module, module.exports);
    return module.exports;
  }
  const core = Object.assign({},
    load('linkora_core/src/main/ets/models/MediaSource.ets'),
    load('linkora_core/src/main/ets/playback/PlaybackPort.ets'),
    load('linkora_core/src/main/ets/playback/PlaybackBackend.ets'));
  const { MpvPlaybackPort } = load('entry/src/main/ets/playback/MpvPlaybackPort.ets');
  const states = [], errors = [];
  const observer = new core.PlaybackPortObserver(state => states.push(state), error => errors.push(error),
    () => {}, () => {}, () => {}, () => {}, () => {}, () => {});
  return {
    async create() {
      const port = await MpvPlaybackPort.create(observer);
      port.configure(core.MediaSource.fromLocalDocument('file://fixture.mp4'), 'surface');
      return port;
    },
    get player() { return player; }, states, errors, core, timers,
    loaded() { player.events.onEvent(events.MPV_EVENT_FILE_LOADED, 'file-loaded'); },
    timeout() { assert.equal(timers.size, 1); [...timers.values()][0](); }
  };
}

test('error log before FILE_LOADED leaves prepare pending', async () => {
  const f = fixture(), port = await f.create();
  let settled = false;
  const pending = port.prepare().then(() => { settled = true; }, () => { settled = true; });
  f.player.stream.error.add('recoverable decoder warning');
  for (let i = 0; i < 10; i++) await Promise.resolve();
  assert.equal(settled, false);
  assert.equal(f.errors.length, 0);
  assert.equal(f.timers.size, 1);
  await port.release(); await pending;
});

test('FILE_LOADED after error log succeeds and clears prepare timer', async () => {
  const f = fixture(), port = await f.create();
  const pending = port.prepare();
  f.player.stream.error.add('recoverable decoder warning');
  f.loaded(); await pending;
  assert.equal(f.states.at(-1), f.core.PortPlaybackState.PREPARED);
  assert.equal(f.errors.length, 0);
  assert.equal(f.timers.size, 0);
  await port.release();
});

test('prepare timeout reports the latest error log', async () => {
  const f = fixture(), port = await f.create();
  const pending = port.prepare();
  const rejected = assert.rejects(pending, error => {
    assert.equal(error.detail, 'MPV prepare timed out: latest diagnostic'); return true;
  });
  f.player.stream.error.add('older diagnostic');
  f.player.stream.error.add('latest diagnostic');
  f.timeout(); await rejected;
  assert.equal(f.errors.length, 0);
  assert.equal(f.timers.size, 0);
  await port.release();
});

test('post-prepare error log neither emits fatal error nor tears down playback', async () => {
  const f = fixture(), port = await f.create();
  const pending = port.prepare(); f.loaded(); await pending; await port.play();
  f.player.stream.error.add('recoverable output warning');
  assert.equal(f.errors.length, 0);
  assert.equal(f.states.at(-1), f.core.PortPlaybackState.PLAYING);
  assert.equal(f.player.destroyed, false);
  await port.play(); assert.equal(f.player.playCalls, 2);
  await port.release();
});


test('explicit play and pause commands publish unified state without wrapper property callbacks', async () => {
  const f = fixture(), port = await f.create();
  const pending = port.prepare();
  // mpv-arkts START_FILE can publish playing=true before FILE_LOADED.
  f.player.stream.playing.add(true);
  f.loaded(); await pending;
  assert.equal(f.states.at(-1), f.core.PortPlaybackState.PREPARED);

  await port.play();
  assert.equal(f.player.playCalls, 1);
  assert.equal(f.states.at(-1), f.core.PortPlaybackState.PLAYING);

  await port.pause();
  assert.equal(f.player.pauseCalls, 1);
  assert.equal(f.states.at(-1), f.core.PortPlaybackState.PAUSED);
  await port.release();
});

test('EOF completion survives trailing playing false and replay clears the terminal guard', async () => {
  const f = fixture(), port = await f.create();
  const pending = port.prepare(); f.loaded(); await pending; await port.play();

  f.player.stream.eof.add(true);
  assert.equal(f.states.at(-1), f.core.PortPlaybackState.COMPLETED);
  // mpv-arkts emits this immediately after eof=true.
  f.player.stream.playing.add(false);
  assert.equal(f.states.at(-1), f.core.PortPlaybackState.COMPLETED);

  port.seek(0);
  await port.play();
  assert.equal(f.player.seekCalls, 1);
  assert.equal(f.states.at(-1), f.core.PortPlaybackState.PLAYING);
  await port.release();
});

test('unverified advanced capabilities are reported conservatively', async () => {
  const f = fixture(), port = await f.create();
  const caps = port.capabilities();
  for (const name of ['assSubtitle', 'pgsSubtitle', 'hdr10', 'hlg', 'dolbyVisionAware',
    'nativeDolbyVisionOutput', 'audioPassthrough']) assert.equal(caps[name], false, name);
  await port.release();
});
