'use strict';
// Production System adapter with a controlled AVPlayer boundary; no native playback claim.
const assert = require('node:assert/strict');
const { test } = require('node:test');
const fs = require('node:fs'), path = require('node:path'), vm = require('node:vm');
const studio = process.argv[2] || 'C:/Program Files/Huawei/DevEco Studio';
const ts = require(path.join(studio, 'sdk/default/openharmony/ets/build-tools/ets-loader/node_modules/typescript'));
const root = path.resolve(__dirname, '..');
function fixture() {
  const cache = new Map(), listeners = new Map(), timers = new Map(), states = [], positions = [];
  let timerId = 0, observer, nextFd = 10, currentId = '';
  const closedFiles = [], queue = [];
  const receiver = { closes: 0, getReceivingSurfaceId: async () => 'surface',
    release: async () => { receiver.closes++; } };
  const player = {
    state: 'idle', duration: 60000, closes: 0, loop: false, trackDescriptions: [], selectedTracks: [],
    on: (name, callback) => listeners.set(name, callback),
    emit(name, ...args) {
      if (name === 'stateChange') this.state = args[0];
      listeners.get(name)(...args);
    },
    set url(value) { this.source = value; this.emit('stateChange', 'initialized'); },
    onPlaybackContentChanged(callback) { this.contentChanged = callback; },
    async addPlaybackMediaSource(source, before) {
      const id = 'native-' + source.fdSrc.fd;
      const index = before === undefined ? queue.length : queue.findIndex(item => item.id === before);
      queue.splice(index, 0, { id, source });
      if (queue.length === 1) { currentId = id; this.emit('stateChange', 'initialized'); this.contentChanged(id); }
      return id;
    },
    getCurrentMediaSource() { return { getID: () => currentId }; },
    async advanceToMediaSource(id) {
      this.requestedId = id; currentId = id;
      if (!this.deferAdvanceEvents) { this.contentChanged(id); this.emit('stateChange', 'prepared'); }
    },
    prepare: async () => { if (queue.length) currentId = queue[0].id; player.emit('stateChange', 'prepared'); },
    play: async () => player.emit('stateChange', 'playing'),
    pause: async () => player.emit('stateChange', 'paused'),
    stop: async () => player.emit('stateChange', 'stopped'),
    getTrackDescription: async () => player.trackDescriptions,
    getSelectedTracks: async () => player.selectedTracks,
    selectTrack: async index => { player.selectedTracks = [index]; },
    setPlaybackRate: rate => { player.requestedRate = rate; },
    seek: value => { player.seekMs = value; }, setSpeed() {}, setVolume() {},
    release: async () => { player.closes++; player.emit('stateChange', 'released'); }
  };
  function load(relative) {
    const file = path.resolve(root, relative);
    if (cache.has(file)) return cache.get(file);
    const module = { exports: {} }; cache.set(file, module.exports);
    const code = ts.transpileModule(fs.readFileSync(file, 'utf8'), {
      compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022 }
    }).outputText;
    vm.runInNewContext(`(function(require,module,exports){${code}\n})`, {
      console, setTimeout: (callback, ms) => { timers.set(++timerId, { callback, ms }); return timerId; },
      clearTimeout: id => timers.delete(id)
    }, { filename: file })(name => {
      if (name === 'linkora_core') return core;
      if (name === '@kit.MediaKit') return { media: { createAVPlayer: async () => player,
        createMediaSourceWithFd: fdSrc => ({ fdSrc }), PlaylistLoopMode: { PLAYLIST_LOOP_MODE_NONE: 4, PLAYLIST_LOOP_MODE_ONE: 2, PLAYLIST_LOOP_MODE_ALL: 1 },
        SeekMode: { SEEK_CLOSEST: 0 }, VideoScaleType: { VIDEO_SCALE_TYPE_FIT: 0, VIDEO_SCALE_TYPE_FIT_CROP: 1, VIDEO_SCALE_TYPE_SCALED_ASPECT: 2 } } };
      if (name === '@kit.BasicServicesKit') return { deviceInfo: { sdkApiVersion: 26 } };
      if (name === '@kit.CoreFileKit') return { fileIo: { OpenMode: { READ_ONLY: 0 },
        openSync: uri => ({ fd: ++nextFd, uri }), statSync: () => ({ size: 3000 }), closeSync: fd => closedFiles.push(fd) } };
      if (name === '@kit.AudioKit') return { audio: { InterruptHint: {
        INTERRUPT_HINT_PAUSE: 2, INTERRUPT_HINT_STOP: 3, INTERRUPT_HINT_RESUME: 1,
        INTERRUPT_HINT_DUCK: 4, INTERRUPT_HINT_UNDUCK: 5 }, InterruptForceType: { INTERRUPT_FORCE: 0 } } };
      if (name === '@kit.ImageKit') return { image: { createImageReceiver: () => receiver, ImageFormat: { JPEG: 0 } } };
      if (['@kit.NetworkKit', '@kit.PerformanceAnalysisKit', 'linkora_ffmpeg/Native', 'linkora_ffmpeg', 'linkora_proxy'].includes(name)) return {};
      if (name.endsWith('/SystemWebPEncoder') || name === './FfmpegRuntimeSmoke') return {};
      if (name === './ProgressiveDownloadRegistry') return { ProgressiveDownloadRegistry: { get: () => { throw Error('Unexpected progressive source'); } } };
      if (name.startsWith('.')) return load(path.relative(root, path.resolve(path.dirname(file), name + '.ets')));
      throw Error('Unexpected dependency: ' + name);
    }, module, module.exports);
    return module.exports;
  }
  const core = Object.assign({}, ...['models/MediaSource', 'models/MediaLink', 'models/PlaybackPlaylist', 'playback/PlaybackPort', 'playback/PlaybackBackend']
    .map(name => load('linkora_core/src/main/ets/' + name + '.ets')));
  const { SystemPlaybackPort } = load('entry/src/main/ets/playback/SystemPlaybackPort.ets');
  return { player, receiver, states, positions, timers, core, queue, closedFiles, get observer() { return observer; },
    hlsHarness: () => load('entry/src/simulator/ets/diagnostics/MediaFunctionSmoke.ets').MediaFunctionSmoke,
    async create(playlist = null) {
    observer = new core.PlaybackPortObserver(value => states.push(value), () => {}, () => {},
      value => positions.push(value), () => {}, () => {}, () => {}, () => {});
    const port = await SystemPlaybackPort.create(observer);
    port.configure(playlist?.currentItem().source ?? new core.MediaSource(core.MediaSourceKind.NETWORK_LINK, 'http://fixture/video.mp4', 'video.mp4', '', 'mp4'), 'surface', playlist);
    return port;
  } };
}

test('System native queue preserves source order and selected start, uses real IDs and closes every FD', async () => {
  const f = fixture(), c = f.core, changes = [];
  const items = ['a', 'b', 'c'].map(id => new c.PlaybackPlaylistItem(id, c.MediaSource.fromLocalDocument('file://' + id + '.mp4')));
  const port = await f.create(new c.PlaybackPlaylist(items, 1, true));
  f.observer.onPlaylistIndexChange = index => changes.push(index);
  await port.prepare();
  assert.equal(f.queue.length, 3);
  assert.deepEqual(f.queue.map(item => item.source.fdSrc.fd), [11, 12, 13]);
  assert.deepEqual(changes, [1]);
  assert.equal(f.player.playlistLoopMode, 4);
  f.player.advanceToMediaSource = async id => { f.player.requestedId = id; };
  await port.selectPlaylistItem(2);
  assert.equal(f.player.requestedId, f.queue[2].id);
  assert.deepEqual(changes, [1], 'a request is not a native acknowledgement');
  f.player.state = 'playing';
  const stateCount = f.states.length;
  f.player.contentChanged(f.queue[2].id);
  assert.deepEqual(changes, [1, 2]);
  assert.deepEqual(f.states.slice(stateCount), ['playing'], 'a seamless change must restore actual native playback state');
  await assert.rejects(port.selectPlaylistItem(-1));
  await assert.rejects(port.selectPlaylistItem(3));
  port.setLoopMode('single'); assert.equal(f.player.playlistLoopMode, 2);
  await port.release();
  assert.deepEqual(f.closedFiles.sort(), [11, 12, 13]);
  f.player.contentChanged(f.queue[0].id);
  assert.deepEqual(changes, [1, 2]);
});

test('System maps all three loop modes and acknowledges the native queue readback', async () => {
  const f = fixture(), c = f.core, modes = [], ends = [];
  const items = ['a', 'b'].map(id => new c.PlaybackPlaylistItem(id, c.MediaSource.fromLocalDocument('file://' + id + '.mp4')));
  const port = await f.create(new c.PlaybackPlaylist(items, 1, true));
  f.observer.onLoopModeChange = value => modes.push(value);
  f.observer.onStreamEnd = value => ends.push(value);
  await port.prepare();
  for (const [mode, native] of [['list', 1], ['single', 2], ['sequence', 4]]) {
    port.setLoopMode(mode);
    assert.equal(f.player.playlistLoopMode, native);
    await new Promise(setImmediate);
    assert.equal(modes.at(-1), mode);
    f.player.emit('endOfStream');
    assert.equal(ends.at(-1).looping, mode !== 'sequence');
  }
  assert.throws(() => port.setLoopMode('shuffle'));
  await port.release();
  assert.throws(() => port.setLoopMode('list'));
});

test('System single-source list repeat uses native repeat and preserves the selected mode', async () => {
  const f = fixture(), port = await f.create(), modes = [];
  f.observer.onLoopModeChange = value => modes.push(value);
  await port.prepare();
  for (const mode of ['single', 'list', 'sequence']) {
    port.setLoopMode(mode);
    assert.equal(f.player.loop, mode !== 'sequence');
    assert.equal(modes.at(-1), mode);
  }
  await port.release();
});

test('System failed native append closes all files already owned by that queue', async () => {
  const f = fixture(), c = f.core;
  const items = ['a', 'b'].map(id => new c.PlaybackPlaylistItem(id, c.MediaSource.fromLocalDocument('file://' + id + '.mp4')));
  const port = await f.create(new c.PlaybackPlaylist(items, 0, true));
  const add = f.player.addPlaybackMediaSource.bind(f.player);
  let calls = 0;
  f.player.addPlaybackMediaSource = async (...args) => {
    if (++calls === 2) throw { code: 5400103, message: 'Unavailable file' };
    return add(...args);
  };
  const preparing = port.prepare();
  await new Promise(setImmediate);
  for (const [id, timer] of f.timers) {
    if (timer.ms === 80) { f.timers.delete(id); timer.callback(); }
  }
  await assert.rejects(preparing);
  await port.release();
  assert.deepEqual(f.closedFiles.sort(), [11, 12]);
});

test('System confirms initial current source with the native query when no initial change event arrives', async () => {
  const f = fixture(), c = f.core, changes = [];
  f.player.onPlaybackContentChanged = () => { f.player.contentChanged = () => {}; };
  const items = ['a', 'b'].map(id => new c.PlaybackPlaylistItem(id, c.MediaSource.fromLocalDocument('file://' + id + '.mp4')));
  const port = await f.create(new c.PlaybackPlaylist(items, 0, true));
  f.observer.onPlaylistIndexChange = value => changes.push(value);
  await port.prepare();
  assert.deepEqual(changes, [0]);
  await port.release();
});

test('System selected-start barrier cannot treat the old prepared state as readiness of the new source', async () => {
  const f = fixture(), c = f.core;
  f.player.deferAdvanceEvents = true;
  const items = ['a', 'b'].map(id => new c.PlaybackPlaylistItem(id, c.MediaSource.fromLocalDocument('file://' + id + '.mp4')));
  const port = await f.create(new c.PlaybackPlaylist(items, 1, true));
  let settled = false;
  const preparing = port.prepare().then(() => { settled = true; });
  await new Promise(setImmediate);
  assert.equal(settled, false);
  f.player.contentChanged(f.player.requestedId);
  await new Promise(setImmediate);
  assert.equal(settled, false, 'content ID alone does not confirm that the new source prepared');
  f.player.emit('stateChange', 'prepared');
  await preparing;
  await port.release();
});

test('System queue repeat reads back after the queued native setter, not its old value', async () => {
  const f = fixture(), c = f.core, loops = [];
  const item = new c.PlaybackPlaylistItem('a', c.MediaSource.fromLocalDocument('file://a.mp4'));
  const port = await f.create(new c.PlaybackPlaylist([item], 0, true));
  await port.prepare();
  let applied = 4, pending = 4;
  Object.defineProperty(f.player, 'playlistLoopMode', { get: () => applied, set: value => { pending = value; } });
  f.player.getTrackDescription = async () => { applied = pending; return []; };
  f.observer.onLoopModeChange = value => loops.push(value);
  port.setLoopMode('single');
  assert.deepEqual(loops, []);
  await new Promise(setImmediate);
  assert.deepEqual(loops, ['single']);
  await port.release();
});

test('System release rejects the pending initial selected-source barrier and closes its descriptors', async () => {
  const f = fixture(), c = f.core;
  f.player.deferAdvanceEvents = true;
  const items = ['a', 'b'].map(id => new c.PlaybackPlaylistItem(id, c.MediaSource.fromLocalDocument('file://' + id + '.mp4')));
  const port = await f.create(new c.PlaybackPlaylist(items, 1, true));
  const preparing = port.prepare(), rejected = assert.rejects(preparing);
  await new Promise(setImmediate);
  await port.release(); await rejected;
  assert.deepEqual(f.closedFiles.sort(), [11, 12]);
  assert.equal(f.timers.size, 0);
});

test('System loop readback ignores superseded and released native queries', async () => {
  const f = fixture(), c = f.core, loops = [], finish = [];
  const item = new c.PlaybackPlaylistItem('a', c.MediaSource.fromLocalDocument('file://a.mp4'));
  const port = await f.create(new c.PlaybackPlaylist([item], 0, true));
  await port.prepare(); await new Promise(setImmediate);
  f.player.getTrackDescription = () => new Promise(resolve => finish.push(resolve));
  f.observer.onLoopModeChange = value => loops.push(value);
  port.setLoopMode('single'); port.setLoopMode('sequence');
  finish[1]([]); await new Promise(setImmediate);
  finish[0]([]); await new Promise(setImmediate);
  assert.deepEqual(loops, ['sequence']);
  port.setLoopMode('single'); await port.release();
  finish[2]([]); await new Promise(setImmediate);
  assert.deepEqual(loops, ['sequence']);
});

test('System release during an awaited native append fences acknowledgements and owns each FD once', async () => {
  const f = fixture(), c = f.core, changes = [];
  const items = ['a', 'b'].map(id => new c.PlaybackPlaylistItem(id, c.MediaSource.fromLocalDocument('file://' + id + '.mp4')));
  const port = await f.create(new c.PlaybackPlaylist(items, 0, true));
  f.observer.onPlaylistIndexChange = value => changes.push(value);
  let finish;
  const add = f.player.addPlaybackMediaSource.bind(f.player);
  f.player.addPlaybackMediaSource = async (...args) => {
    const id = await add(...args); await new Promise(resolve => { finish = resolve; }); return id;
  };
  const preparing = port.prepare(); preparing.catch(() => {});
  await new Promise(setImmediate);
  await port.release(); finish();
  await assert.rejects(preparing);
  assert.deepEqual(changes, []);
  assert.deepEqual(f.closedFiles, [11]);
});
test('System controls use milliseconds and preserve play/pause states', async () => {
  const f = fixture(), port = await f.create();
  await port.prepare(); await port.play(); await port.pause();
  port.seek(4567); f.player.emit('timeUpdate', 6123);
  assert.equal(f.player.seekMs, 4567); assert.deepEqual(f.positions, [6123]);
  assert.deepEqual(f.states.slice(-2), ['playing', 'paused']);
  await port.release(); assert.equal(f.timers.size, 0);
});

test('System reports acknowledged speed/volume changes rather than requested settings', async () => {
  const f = fixture(), port = await f.create(), rates = [], volumes = [];
  f.observer.onPlaybackRateChange = value => rates.push(value);
  f.observer.onVolumeChange = value => volumes.push(value);
  await port.prepare();
  port.setPlaybackRate(1.5); port.setVolume(0.25);
  assert.deepEqual(rates, []); assert.deepEqual(volumes, []);
  f.player.emit('playbackRateDone', 1.5);
  f.player.emit('volumeChange', 0.25);
  assert.deepEqual(rates, [1.5]); assert.deepEqual(volumes, [0.25]);
  await port.release();
  f.player.emit('playbackRateDone', 2); f.player.emit('volumeChange', 1);
  assert.deepEqual(rates, [1.5]); assert.deepEqual(volumes, [0.25]);
});

test('System discovers and selects only actual audio track ids', async () => {
  const f = fixture(), port = await f.create(), updates = [];
  f.observer.onTracksChange = value => updates.push(value);
  f.player.trackDescriptions = [
    { track_index: 0, track_type: 1, codec_mime: 'video/avc' },
    { track_index: 2, track_type: 0, codec_mime: 'audio/mp4a-latm', language: 'en', track_name: 'English' },
    { track_index: 3, track_type: 0, codec_mime: 'audio/ac3', language: 'zh', track_name: 'Chinese' }
  ];
  f.player.selectedTracks = [0, 2];
  await port.prepare();
  await new Promise(setImmediate);
  assert.equal(updates.at(-1).find(track => track.id === '2').selected, true);
  await port.selectAudioTrack('3');
  assert.equal(updates.at(-1).find(track => track.id === '3').selected, true);
  await assert.rejects(port.selectAudioTrack('0'));
  await assert.rejects(port.selectAudioTrack('999'));
  await port.release();
});

test('System loop/EOS and stop stay distinct from one-shot completion', async () => {
  const f = fixture(), port = await f.create(), loops = [], ends = [];
  f.observer.onLoopModeChange = value => loops.push(value);
  f.observer.onStreamEnd = value => ends.push(value);
  await port.prepare(); port.setLoopMode('single');
  assert.equal(f.player.loop, true); assert.deepEqual(loops, ['single']);
  f.player.emit('endOfStream');
  assert.equal(ends.at(-1).reason, 'eof'); assert.equal(ends.at(-1).looping, true);
  assert.notEqual(f.states.at(-1), 'completed');
  await port.stop(); assert.equal(f.states.at(-1), 'stopped');
  assert.equal(ends.at(-1).reason, 'stop');
  await port.release();
});

test('System preserves interruption and output-device details without exposing device ids', async () => {
  const f = fixture(), port = await f.create(), interruptions = [], outputs = [];
  f.observer.onAudioInterruption = value => interruptions.push(value);
  f.observer.onAudioOutputChange = value => outputs.push(value);
  f.player.emit('audioInterrupt', { eventType: 1, forceType: 0, hintType: 2 });
  f.player.emit('audioOutputDeviceChangeWithInfo', { devices: [{ deviceType: 3, id: 'private' }], changeReason: 1 });
  assert.equal(interruptions.at(-1).hint, 'pause');
  assert.equal(interruptions.at(-1).forced, true);
  assert.deepEqual(Array.from(outputs.at(-1).deviceTypes), [3]);
  assert.equal(JSON.stringify(outputs).includes('private'), false);
  await port.release();
});
test('release cancels pending native prepare and rejects late completion', async () => {
  const f = fixture(), port = await f.create();
  let finish, started;
  const begin = new Promise(resolve => { started = resolve; });
  f.player.prepare = () => { started(); return new Promise(resolve => { finish = resolve; }); };
  const pending = assert.rejects(port.prepare(), error => error.code === 5400104);
  await begin; await port.release(); finish(); await pending;
  assert.equal(f.player.closes, 1); assert.equal(f.timers.size, 0);
});
test('System release failure propagates instead of confirming disposal', async () => {
  const f = fixture(), port = await f.create();
  f.player.release = async () => { throw { code: 5400105, message: 'native release failed' }; };
  await assert.rejects(port.release(), error => error.code === 5400105);
  assert.equal(f.timers.size, 0);
});
test('concurrent System release owns one native disposal', async () => {
  const f = fixture(), port = await f.create();
  const finishes = [];
  f.player.release = () => { f.player.closes++; return new Promise(resolve => { finishes.push(resolve); }); };
  const first = port.release(), second = port.release();
  try { assert.equal(f.player.closes, 1); }
  finally { finishes.forEach(finish => finish()); }
  await Promise.all([first, second]);
});
test('late System position events after release cannot reach the observer', async () => {
  const f = fixture(), port = await f.create();
  await port.release(); f.player.emit('timeUpdate', 12345);
  assert.deepEqual(f.positions, []);
});
test('HLS harness disposes both owned objects before early and late sampling', async () => {
  const f = fixture(), smoke = f.hlsHarness(), samples = [];
  f.player.prepare = () => new Promise(() => {});
  smoke.emit = async (_endpoint, data) => { samples.push(data.case); };
  smoke.delay = async ms => {
    if (ms === 3500 || ms === 21000) {
      assert.equal(f.player.closes, 1);
      assert.equal(f.receiver.closes, 1);
    }
  };
  await smoke.hls('http://fixture');
  assert.equal(f.receiver.closes, 1);
  assert.deepEqual(samples, ['hls-before-cancel', 'hls-early', 'hls-later', 'hls-resource-recovery']);
});


test('optional System track metadata cannot hold up prepared playback', async () => {
  const f = fixture(), port = await f.create();
  f.player.getTrackDescription = () => new Promise(() => {});
  const result = await Promise.race([port.prepare().then(() => 'ready'), new Promise(resolve => setImmediate(() => resolve('blocked')))]);
  assert.equal(result, 'ready');
  await port.play(); assert.equal(f.states.at(-1), 'playing');
  await port.release();
});

test('System metadata failure is nonfatal and an old refresh cannot publish after release', async () => {
  const f = fixture(), port = await f.create(), warnings = [], tracks = [];
  f.observer.onWarning = (operation, error) => warnings.push(operation);
  f.observer.onTracksChange = value => tracks.push(value);
  f.player.getTrackDescription = async () => { throw { code: 5400102 }; };
  await port.prepare(); await new Promise(setImmediate);
  assert.deepEqual(warnings, ['tracks']); await port.play();
  let finish;
  f.player.getTrackDescription = () => new Promise(resolve => { finish = resolve; });
  f.player.emit('trackChange', 1, true);
  await port.release(); finish([{ track_index: 2, track_type: 0 }]);
  await new Promise(setImmediate);
  assert.deepEqual(tracks, []);
});


test('System display modes use native enums, not the misleading FIT name', async () => {
  const f = fixture(), port = await f.create(), modes = [];
  f.observer.onDisplayModeChange = value => modes.push(value);
  await port.prepare();
  for (const [mode, expected] of [['fit', 2], ['crop', 1], ['stretch', 0], ['fit', 2]]) {
    port.setDisplayMode(mode);
    assert.equal(f.player.videoScaleType, expected);
    assert.equal(modes.at(-1), mode);
  }
  assert.throws(() => port.setDisplayMode('invalid'), error => error.code === 401);
  await port.release(); assert.throws(() => port.setDisplayMode('fit'));
  assert.equal(modes.length, 4);
});

test('System cannot acknowledge a display mode the backend did not accept', async () => {
  const f = fixture(), port = await f.create(), modes = [];
  f.observer.onDisplayModeChange = value => modes.push(value);
  await port.prepare();
  Object.defineProperty(f.player, 'videoScaleType', { get: () => 0, set() {} });
  assert.throws(() => port.setDisplayMode('crop'), error => error.code === 5400102);
  assert.deepEqual(modes, []);
  await port.release();
});


test('System display-mode failure keeps the platform diagnostic code and detail', async () => {
  const f = fixture(), port = await f.create(); await port.prepare();
  Object.defineProperty(f.player, 'videoScaleType', { set() { throw { code: 5400102, message: 'native scale rejected' }; } });
  assert.throws(() => port.setDisplayMode('crop'), error => error.code === 5400102 && error.detail === 'native scale rejected');
  await port.release();
});
