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
  const events = { MPV_EVENT_FILE_LOADED: 8, MPV_EVENT_PLAYBACK_RESTART: 21,
    MPV_EVENT_END_FILE: 7, MPV_EVENT_SHUTDOWN: 1 };
  class Player {
    constructor() {
      player = this;
      this.destroyed = false;
      this.playCalls = 0;
      this.pauseCalls = 0;
      this.seekCalls = 0;
      this.state = { duration: 60, position: 0, eof: false,
        tracks: { audio: [{ id: '2' }, { id: '3' }], video: [], subs: [] },
        track: { audio: { id: '2' }, video: { id: 'no' }, subs: { id: 'no' } } };
      this.stream = Object.fromEntries(['duration', 'position', 'playing', 'eof', 'buffering',
        'bufferingPercentage', 'buffer', 'videoParams', 'tracks', 'track', 'error',
        'volume', 'speed', 'playlistMode'].map(name => {
        let listener;
        return [name, { listen(callback) { listener = callback; }, add(value) { listener(value); } }];
      }));
      this.properties = new Map();
      this.native = { getProperty: name => this.properties.get(name),
        getPropertyBool: name => this.properties.get(name),
        getPropertyString: name => this.properties.get(name),
        addEventObserver: observer => { this.events = observer; },
        removeEventObserver() {}, attachSurface() {}, detachSurface() {}, setProperty: (name, value) => this.properties.set(name, value) };
    }
    open() {}
    play() { this.playCalls++; }
    pause() { this.pauseCalls++; }
    stop() { this.stopped = true; }
    setSpeed(value) { this.requestedSpeed = value; }
    setVolume(value) { this.requestedVolume = value; }
    setLoopMode(value) { this.requestedLoop = value; }
    setAudioTrack(track) { this.requestedAudioTrack = track; }
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
      if (name === '@mpv-ohos/mpv-arkts') return { Player, Media: class {}, MpvEvent: events,
        PlaylistMode: { None: 0, File: 1, Playlist: 2, Random: 3 } };
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
    get player() { return player; }, states, errors, core, timers, observer,
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

test('MPV maps confirmed property values and loop mode, not requested controls', async () => {
  const f = fixture(), port = await f.create(), rates = [], volumes = [], loops = [];
  f.observer.onPlaybackRateChange = value => rates.push(value);
  f.observer.onVolumeChange = value => volumes.push(value);
  f.observer.onLoopChange = value => loops.push(value);
  const pending = port.prepare(); f.loaded(); await pending;
  port.setPlaybackRate(1.5); port.setVolume(0.25); port.setLoop(true);
  assert.deepEqual(rates, []); assert.deepEqual(volumes, []); assert.deepEqual(loops, []);
  f.player.stream.speed.add(1.5); f.player.stream.volume.add(25); f.player.stream.playlistMode.add(1);
  assert.deepEqual(rates, [1.5]); assert.deepEqual(volumes, [0.25]); assert.deepEqual(loops, [true]);
  await port.release();
  f.player.stream.speed.add(2); f.player.stream.volume.add(100); f.player.stream.playlistMode.add(0);
  assert.deepEqual(rates, [1.5]); assert.deepEqual(volumes, [0.25]); assert.deepEqual(loops, [true]);
});

test('MPV selects an existing native audio track and rejects unknown ids', async () => {
  const f = fixture(), port = await f.create();
  const pending = port.prepare(); f.loaded(); await pending;
  await port.selectAudioTrack('3');
  assert.equal(f.player.requestedAudioTrack.id, '3');
  await assert.rejects(port.selectAudioTrack('file://injected'));
  await port.release();
});

test('MPV unload before FILE_LOADED rejects preparation without waiting for timeout', { timeout: 1000 }, async () => {
  const f = fixture(), port = await f.create();
  const pending = assert.rejects(port.prepare(), error => error.detail.includes('before preparation'));
  f.player.events.onEvent(7, 'end-file');
  await pending; assert.equal(f.timers.size, 0);
  await port.release();
});

test('MPV unknown unload is not misreported as EOF or a guessed fatal error', async () => {
  const f = fixture(), port = await f.create(), ends = [];
  f.observer.onStreamEnd = value => ends.push(value);
  const pending = port.prepare(); f.loaded(); await pending; await port.play();
  f.player.events.onEvent(7, 'end-file');
  assert.equal(ends.at(-1).reason, 'unknown');
  assert.equal(f.states.at(-1), 'stopped'); assert.equal(f.errors.length, 0);
  await port.release();
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


test('MPV late streams are fenced and release failure remains a failure', async () => {
  const f = fixture(), port = await f.create(), positions = [];
  f.observer.onPositionChange = value => positions.push(value);
  f.player.native.detachSurface = () => { throw Error('detach failed'); };
  await assert.rejects(port.release());
  await assert.rejects(port.release());
  f.player.stream.position.add(2);
  assert.deepEqual(positions, []);
  assert.equal(f.states.includes('released'), false);
  assert.equal(f.player.destroyed, true);
});

test('MPV file loop reports EOF without one-shot completion', async () => {
  const f = fixture(), port = await f.create(), ends = [];
  f.observer.onStreamEnd = value => ends.push(value);
  const preparing = port.prepare(); f.loaded(); await preparing;
  await port.play(); port.setLoop(true); f.player.stream.playlistMode.add(1);
  f.player.stream.eof.add(true); f.player.stream.playing.add(false);
  assert.equal(f.states.at(-1), 'playing');
  assert.equal(ends.at(-1).reason, 'eof'); assert.equal(ends.at(-1).looping, true);
  assert.notEqual(f.states.at(-1), 'completed');
  await port.release();
});


test('explicit MPV stop after EOF publishes its own distinct end reason', async () => {
  const f = fixture(), port = await f.create(), ends = [];
  f.observer.onStreamEnd = value => ends.push(value.reason);
  const preparing = port.prepare(); f.loaded(); await preparing;
  await port.play(); f.player.stream.eof.add(true);
  await port.stop(); f.player.events.onEvent(7, 'end-file');
  assert.deepEqual(ends, ['eof', 'stop']);
  await port.release();
});


test('MPV EOF arriving after an unknown unload cannot make an unprepared port replayable', async () => {
  const f = fixture(), port = await f.create();
  const preparing = port.prepare(); f.loaded(); await preparing;
  await port.play(); f.player.events.onEvent(7, 'end-file');
  f.player.stream.eof.add(true);
  assert.equal(f.states.at(-1), 'stopped');
  await port.release();
});


test('MPV switches the three native display modes and resets prior crop/stretch state', async () => {
  const f = fixture(), port = await f.create(), modes = [];
  f.observer.onDisplayModeChange = value => modes.push(value);
  const preparing = port.prepare(); f.loaded(); await preparing;
  for (const [mode, aspect, pan] of [['fit', true, 0], ['crop', true, 1], ['stretch', false, 0], ['fit', true, 0]]) {
    port.setDisplayMode(mode);
    assert.equal(f.player.properties.get('keepaspect'), aspect);
    assert.equal(f.player.properties.get('panscan'), pan);
    assert.equal(f.player.properties.get('video-unscaled'), 'no');
    assert.equal(modes.at(-1), mode);
  }
  assert.throws(() => port.setDisplayMode('invalid'), error => error.code === 401);
  await port.release(); assert.throws(() => port.setDisplayMode('fit'));
  assert.equal(modes.length, 4);
});

test('MPV does not acknowledge a display mode when native readback disagrees', async () => {
  const f = fixture(), port = await f.create(), modes = [];
  f.observer.onDisplayModeChange = value => modes.push(value);
  const preparing = port.prepare(); f.loaded(); await preparing;
  f.player.native.getProperty = () => 0;
  assert.throws(() => port.setDisplayMode('crop'), error => error.code === 5400102);
  assert.deepEqual(modes, []); await port.release();
});
