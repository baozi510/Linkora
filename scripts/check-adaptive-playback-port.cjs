'use strict';
// Actual AdaptivePlaybackPort; native backends and source resolution are controlled boundaries.
// These checks prove adapter contracts, not device playback or network resolution.
const assert = require('node:assert/strict');
const { test } = require('node:test');
const fs = require('node:fs'), path = require('node:path'), vm = require('node:vm');
const studio = process.argv[2] || 'C:/Program Files/Huawei/DevEco Studio';
const ts = require(path.join(studio, 'sdk/default/openharmony/ets/build-tools/ets-loader/node_modules/typescript'));
const root = path.resolve(__dirname, '..');

function fixture(preference = 'auto') {
  const cache = new Map(), trace = [], backends = [];
  let sourceCloses = 0, lease, resolvedPlaylist = null;
  function load(relative) {
    if (relative.endsWith('/NetworkPlaybackSourceResolver.ets')) return {
      NetworkPlaybackSourceResolver: class {
        async resolve(source, playlist) {
          lease = { source: resolvedPlaylist?.currentItem().source ?? source,
            playlist: resolvedPlaylist, originalPlaylist: playlist, release: async () => { sourceCloses++; } };
          return lease;
        }
      }
    };
    for (const name of ['SystemPlaybackPort', 'MpvPlaybackPort']) {
      if (relative.endsWith('/' + name + '.ets')) return {
        [name]: { create: async () => { throw Error('Unexpected native factory'); } }
      };
    }
    const file = path.resolve(root, relative);
    if (cache.has(file)) return cache.get(file);
    const module = { exports: {} }; cache.set(file, module.exports);
    const code = ts.transpileModule(fs.readFileSync(file, 'utf8'), {
      compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022 }
    }).outputText;
    vm.runInNewContext(`(function(require,module,exports){${code}\n})`, {}, { filename: file })(name => {
      if (name === 'linkora_core') return core;
      if (name.startsWith('.')) return load(path.relative(root, path.resolve(path.dirname(file), name + '.ets')).replaceAll('\\', '/'));
      throw Error('Unexpected dependency: ' + name);
    }, module, module.exports);
    return module.exports;
  }
  const core = Object.assign({}, ...['models/MediaSource', 'models/PlaybackPlaylist', 'playback/PlaybackPort',
    'playback/PlaybackBackend', 'playback/PlaybackBackendSelector', 'playback/PlaybackEngine',
    'playback/PlaybackModels', 'models/AppSettings', 'features/PlayerFeatureController']
    .map(name => load('linkora_core/src/main/ets/' + name + '.ets')));
  const { AdaptivePlaybackPort } = load('entry/src/main/ets/playback/AdaptivePlaybackPort.ets');
  const observer = new core.PlaybackPortObserver(
    state => trace.push(['state', state]), error => trace.push(['error', error.code]),
    value => trace.push(['duration', value]), value => trace.push(['position', value]),
    (event, value) => trace.push(['buffer', event, value]), () => trace.push(['frame']),
    (w, h) => trace.push(['size', w, h]), () => trace.push(['interrupt']),
    value => trace.push(['seek', value]), value => trace.push(['tracks', value.length]),
    () => trace.push(['info']), value => trace.push(['backend', value]));
  function factory(kind, prepare = async () => {}) {
    return async events => {
      const backend = {
        events, closes: 0, backendKind: () => kind,
        capabilities: () => new core.PlayerBackendCapabilities(),
        configure(source, surface, playlist) { backend.source = source; backend.playlist = playlist; }, setSurfaceSize() {}, getDuration: () => 120000,
        selectPlaylistItem: async index => { backend.requestedIndex = index; },
        prepare: () => prepare(events), play: async () => events.onStateChange('playing'),
        pause: async () => events.onStateChange('paused'), seek: value => events.onSeekComplete(value),
        stop: async () => events.onStateChange('stopped'),
        setLoopMode: value => events.onLoopModeChange(value),
        setDisplayMode: value => events.onDisplayModeChange(value), selectAudioTrack: async () => {},
        setPlaybackRate() {}, setVolume() {},
        release: async () => { backend.closes++; events.onStateChange('released'); }
      };
      backends.push(backend); return backend;
    };
  }
  return {
    core, observer, trace, backends, factory, get sourceCloses() { return sourceCloses; }, get lease() { return lease; },
    set resolvedPlaylist(value) { resolvedPlaylist = value; },
    port(system, mpv, extension = 'mp4') {
      const port = new AdaptivePlaybackPort({}, {}, observer, preference, undefined, system, mpv);
      port.configure(core.MediaSource.fromLocalDocument('file://fixture.' + extension), 'surface');
      return port;
    }
  };
}

test('Adaptive forwards audio delay only to a backend that supports it', async () => {
  const f = fixture('mpv'), port = f.port(f.factory('system'), f.factory('mpv'));
  await port.prepare();
  const backend = f.backends.at(-1); backend.setAudioDelay = value => value;
  assert.equal(port.setAudioDelay(-50), -50);
  delete backend.setAudioDelay;
  assert.throws(() => port.setAudioDelay(0), error => error.code === 801);
  await port.release(); assert.throws(() => port.setAudioDelay(0));
});

test('Engine rejects invalid or unsupported delay without stopping playback or inventing readback', async () => {
  const f = fixture(), snapshots = [], requests = []; let events, readback;
  const port = { configure() {}, getDuration: () => 10000,
    async prepare() { events.onStateChange('prepared'); }, async play() { events.onStateChange('playing'); },
    setDisplayMode() {}, async release() {},
    setAudioDelay(value) { requests.push(value); return readback === undefined ? value : readback; } };
  const engine = new f.core.PlaybackEngine(value => snapshots.push(value), async observer => { events = observer; return port; });
  await engine.open(f.core.MediaSource.fromLocalDocument('file://test.mp4'), 'surface');
  assert.equal(engine.setAudioDelay(-50), -50);
  readback = 0; assert.equal(engine.setAudioDelay(50), null);
  assert.equal(snapshots.at(-1).warningOperation, 'audio-delay');
  assert.equal(snapshots.at(-1).status, 'playing');
  readback = undefined; assert.equal(engine.setAudioDelay(50), 50);
  assert.equal(snapshots.at(-1).warningOperation, '');
  assert.equal(snapshots.at(-1).warning, null);
  const count=requests.length;
  assert.equal(engine.setAudioDelay(NaN), null); assert.equal(engine.setAudioDelay(10001), null);
  assert.equal(requests.length,count);
  delete port.setAudioDelay; assert.equal(engine.setAudioDelay(0), null);
  assert.equal(snapshots.at(-1).warning.code, 801);
  await engine.release(); assert.equal(engine.setAudioDelay(0), null);
});

test('Adaptive passes the resolved remote queue to native while retaining original item identities', async () => {
  const f = fixture('system'), c = f.core;
  const items = [0, 1].map(index => new c.PlaybackPlaylistItem('remote-' + index,
    c.MediaSource.fromRemoteFile('/video-' + index + '.mp4', 'video-' + index + '.mp4', 'Saved server',
      100, 'network-server:7')));
  const original = new c.PlaybackPlaylist(items, 1, true);
  const resolved = new c.PlaybackPlaylist(items.map(item => new c.PlaybackPlaylistItem(item.id,
    new c.MediaSource(c.MediaSourceKind.NETWORK_LINK, 'http://127.0.0.1/opaque-' + item.id,
      item.source.displayName, item.source.originLabel, item.source.format))), 1, true);
  f.resolvedPlaylist = resolved;
  const port = f.port(f.factory('system'), f.factory('mpv'));
  port.configure(items[1].source, 'surface', original);
  await port.prepare();
  assert.equal(f.lease.originalPlaylist, original);
  assert.equal(f.backends[0].playlist, resolved);
  assert.equal(f.backends[0].source, resolved.currentItem().source);
  await port.release(); assert.equal(f.sourceCloses, 1);
});

test('Engine native playlist index follows acknowledgements, resets item state and fences old callbacks', async () => {
  const f = fixture(), snapshots = [], c = f.core;
  const items = ['a', 'b', 'c'].map(id => new c.PlaybackPlaylistItem(id, c.MediaSource.fromLocalDocument('file://' + id + '.mp4')));
  const playlist = new c.PlaybackPlaylist(items, 1, true);
  const engine = new c.PlaybackEngine(value => snapshots.push(value), f.factory('system'));
  await engine.open(items[1].source, 'surface', 0, playlist);
  assert.equal(f.backends[0].playlist, playlist);
  assert.equal(snapshots.at(-1).playlistIndex, -1);
  f.backends[0].events.onPlaylistIndexChange(1);
  f.backends[0].events.onPositionChange(800);
  f.backends[0].events.onDurationChange(2000);
  f.backends[0].events.onFirstFrame();
  await engine.selectPlaylistItem(2);
  assert.equal(f.backends[0].requestedIndex, 2);
  assert.equal(snapshots.at(-1).playlistIndex, 1);
  f.backends[0].events.onPlaylistIndexChange(2);
  assert.equal(snapshots.at(-1).playlistIndex, 2);
  assert.equal(snapshots.at(-1).position, 0);
  assert.equal(snapshots.at(-1).duration, 0);
  assert.equal(snapshots.at(-1).firstFrameRendered, false);
  await engine.selectPlaylistItem(99);
  assert.equal(f.backends[0].requestedIndex, 2);
  await engine.stop(); await engine.togglePlayback();
  assert.equal(f.backends[1].playlist.startIndex, 2);
  await engine.release();
  const count = snapshots.length;
  f.backends[0].events.onPlaylistIndexChange(0);
  assert.equal(snapshots.length, count);
});

test('Player queue controls use acknowledged index and save bookmarks against the departing item', async () => {
  const f = fixture(), c = f.core, saved = [], cleared = [];
  const items = ['a', 'b', 'c'].map(id => new c.PlaybackPlaylistItem(id, c.MediaSource.fromLocalDocument('file://' + id + '.mp4')));
  const controller = new c.PlayerFeatureController(items[1].source,
    observer => new c.PlaybackEngine(observer, f.factory('system')),
    { load: async () => null, save: async (source, bookmark) => saved.push([source.locator, bookmark.position]),
      clear: async source => cleared.push(source.locator) }, new c.AppSettings(), () => {}, null,
    new c.PlaybackPlaylist(items, 1, true));
  controller.attachSurface('surface');
  await new Promise(setImmediate);
  assert.equal(f.backends[0].playlist.startIndex, 1);
  f.backends[0].events.onPlaylistIndexChange(1);
  f.backends[0].events.onDurationChange(120000);
  f.backends[0].events.onPositionChange(20000);
  controller.nextPlaylistItem(); await new Promise(setImmediate);
  assert.equal(f.backends[0].requestedIndex, 2);
  assert.equal(controller.currentState().playback.playlistIndex, 1);
  f.backends[0].events.onPlaylistIndexChange(2);
  assert.equal(saved.at(-1)[0], 'file://b.mp4');
  f.backends[0].events.onDurationChange(120000);
  f.backends[0].events.onPositionChange(30000);
  controller.stopPlayback(); await new Promise(setImmediate);
  assert.equal(saved.at(-1)[0], 'file://c.mp4');
  controller.togglePlayback(); await new Promise(setImmediate);
  assert.equal(f.backends[1].playlist.startIndex, 2);
  controller.stop();
});

test('Auto disposes failed System candidate and commits only MPV events', async () => {
  const f = fixture();
  const port = f.port(f.factory('system', async events => {
    events.onPositionChange(999); events.onFirstFrame();
    throw new f.core.PlaybackPortError(5400106, 'unsupported');
  }), f.factory('mpv', async events => { events.onDurationChange(120000); }));
  await port.prepare();
  assert.equal(f.backends[0].closes, 1);
  assert.deepEqual(f.trace.filter(item => ['position', 'frame', 'backend'].includes(item[0])), [['backend', 'mpv']]);
  assert.equal(port.getDuration(), 120000);
  await port.release();
  assert.equal(f.backends[1].closes, 1); assert.equal(f.sourceCloses, 1);
});

test('Engine snapshots use acknowledged settings and fence old settings events', async () => {
  const f = fixture(), snapshots = [];
  const engine = new f.core.PlaybackEngine(value => snapshots.push(value), f.factory('system'));
  await engine.open(f.core.MediaSource.fromLocalDocument('file://one.mp4'), 'surface');
  engine.setPlaybackRate(1.5); engine.setVolume(0.25);
  assert.equal(snapshots.at(-1).playbackRate, 1); assert.equal(snapshots.at(-1).volume, 1);
  f.backends[0].events.onPlaybackRateChange(1.5); f.backends[0].events.onVolumeChange(0.25);
  assert.equal(snapshots.at(-1).playbackRate, 1.5); assert.equal(snapshots.at(-1).volume, 0.25);
  await engine.open(f.core.MediaSource.fromLocalDocument('file://two.mp4'), 'surface');
  const before = snapshots.length;
  f.backends[0].events.onPlaybackRateChange(2); f.backends[0].events.onVolumeChange(1);
  assert.equal(snapshots.length, before);
  await engine.release();
});

test('Engine loop mode waits for acknowledgement, survives replay and fences stale callbacks', async () => {
  const f = fixture(), snapshots = [], requested = [];
  const factory = f.factory('system');
  const engine = new f.core.PlaybackEngine(value => snapshots.push(value), async events => {
    const backend = await factory(events);
    backend.setLoopMode = mode => requested.push(mode);
    return backend;
  });
  const source = f.core.MediaSource.fromLocalDocument('file://one.mp4');
  await engine.open(source, 'surface');
  engine.setLoopMode('list');
  assert.equal(snapshots.at(-1).loopMode, 'sequence');
  f.backends[0].events.onLoopModeChange('list');
  assert.equal(snapshots.at(-1).loopMode, 'list');
  await engine.stop(); await engine.togglePlayback();
  assert.deepEqual(requested, ['list', 'list']);
  const before = snapshots.length;
  f.backends[0].events.onLoopModeChange('single'); assert.equal(snapshots.length, before);
  f.backends[1].events.onLoopModeChange('list');
  assert.equal(snapshots.at(-1).loopMode, 'list');
  await engine.release();
});

test('Controller cycles sequence, single and list through acknowledged playback state', async () => {
  const f = fixture(), c = f.core;
  const controller = new c.PlayerFeatureController(c.MediaSource.fromLocalDocument('file://one.mp4'),
    observer => new c.PlaybackEngine(observer, f.factory('system')), { load: async () => null, save: async () => {} },
    new c.AppSettings(), () => {});
  controller.attachSurface('surface'); await new Promise(setImmediate);
  for (const mode of ['single', 'list', 'sequence']) {
    controller.cycleLoopMode();
    assert.equal(controller.currentState().playback.loopMode, mode);
  }
  controller.stop(); await new Promise(setImmediate);
});

test('Engine stop/replay allocates only after disposal and preserves requested loop', async () => {
  const f = fixture(), snapshots = [];
  const engine = new f.core.PlaybackEngine(value => snapshots.push(value), f.factory('system'));
  await engine.open(f.core.MediaSource.fromLocalDocument('file://one.mp4'), 'surface');
  engine.setLoopMode('single');
  assert.equal(snapshots.at(-1).loopMode, 'single');
  await engine.stop(); assert.equal(snapshots.at(-1).status, 'stopped');
  await engine.togglePlayback();
  assert.equal(f.backends.length, 2); assert.equal(f.backends[0].closes, 1);
  assert.equal(snapshots.at(-1).status, 'playing'); assert.equal(snapshots.at(-1).loopMode, 'single');
  await engine.release();
});

test('Adaptive forwards settings only from the committed current candidate', async () => {
  const f = fixture(); const rates = [];
  f.observer.onPlaybackRateChange = value => rates.push(value);
  const port = f.port(f.factory('system', async events => {
    events.onPlaybackRateChange(1.25);
    throw new f.core.PlaybackPortError(5400106, 'unsupported');
  }), f.factory('mpv'));
  await port.prepare(); f.backends[1].events.onPlaybackRateChange(1.5);
  assert.deepEqual(rates, [1.5]);
  await port.release(); f.backends[1].events.onPlaybackRateChange(2);
  assert.deepEqual(rates, [1.5]);
});

test('explicit System failure does not invoke MPV fallback', async () => {
  const f = fixture('system');
  const port = f.port(f.factory('system', async () => { throw new f.core.PlaybackPortError(5400106, 'unsupported'); }),
    async () => { throw Error('MPV fallback must not run'); });
  await assert.rejects(port.prepare(), error => error.code === 5400106);
  assert.equal(f.backends.length, 1); assert.equal(f.backends[0].closes, 1);
  assert.equal(f.sourceCloses, 1);
});

test('release during candidate preparation closes once and never commits', async () => {
  const f = fixture();
  let finish, started;
  const begin = new Promise(resolve => { started = resolve; });
  const port = f.port(f.factory('system', async () => {
    started(); await new Promise(resolve => { finish = resolve; });
  }), async () => { throw Error('Cancelled preparation must not fallback'); });
  const pending = port.prepare();
  const cancelled = assert.rejects(pending, error => error.code === 5400104);
  await begin; await port.release(); finish(); await cancelled;
  assert.equal(f.backends[0].closes, 1); assert.equal(f.sourceCloses, 1);
  assert.equal(f.trace.some(item => item[0] === 'backend' || item[1] === 'prepared'), false);
});

test('released committed backend cannot leak late events', async () => {
  const f = fixture();
  const port = f.port(f.factory('system'), f.factory('mpv'));
  await port.prepare(); await port.release();
  const before = f.trace.length, events = f.backends[0].events;
  events.onStateChange('playing'); events.onPositionChange(55000); events.onFirstFrame();
  events.onError(new f.core.PlaybackPortError(5400104, 'late'));
  assert.equal(f.trace.length, before);
});

test('release fences events before awaiting native disposal', async () => {
  const f = fixture();
  const port = f.port(f.factory('system'), f.factory('mpv'));
  await port.prepare();
  let finish;
  f.backends[0].release = () => new Promise(resolve => { finish = resolve; });
  const pending = port.release(), before = f.trace.length;
  let secondCompleted = false;
  const second = port.release().then(() => { secondCompleted = true; });
  try {
    await new Promise(setImmediate);
    assert.equal(secondCompleted, false, 'concurrent callers must wait for pending disposal');
    f.backends[0].events.onPositionChange(88000);
    assert.equal(f.trace.length, before);
  } finally { finish(); await pending; await second; }
  assert.equal(f.trace.filter(item => item[1] === 'released').length, 1);
});

test('native release failure still closes lease and cannot claim RELEASED', async () => {
  const f = fixture();
  const port = f.port(f.factory('system'), f.factory('mpv'));
  await port.prepare();
  f.backends[0].release = async () => { throw new f.core.PlaybackPortError(5400104, 'native disposal failed'); };
  const failedRelease = port.release();
  const concurrentFailure = assert.rejects(port.release(), error => error.code === 5400104);
  await assert.rejects(failedRelease, error => error.code === 5400104);
  await concurrentFailure;
  await assert.rejects(port.release(), error => error.code === 5400104);
  assert.equal(f.sourceCloses, 1);
  assert.equal(f.trace.some(item => item[1] === 'released'), false);
});

test('failed candidate disposal blocks fallback and remains a release failure', async () => {
  const f = fixture();
  let fallbacks = 0;
  const port = f.port(f.factory('system', async () => {
    f.backends[0].release = async () => {
      f.backends[0].closes++;
      throw new f.core.PlaybackPortError(5400104, 'candidate disposal failed');
    };
    throw new f.core.PlaybackPortError(5400106, 'unsupported');
  }), async () => { fallbacks++; throw Error('unsafe fallback'); });
  await assert.rejects(port.prepare(), error => error.detail === 'candidate disposal failed');
  assert.equal(fallbacks, 0);
  await assert.rejects(port.release(), error => error.detail === 'candidate disposal failed');
  await assert.rejects(port.release(), error => error.detail === 'candidate disposal failed');
  assert.equal(f.backends[0].closes, 1);
  assert.equal(f.sourceCloses, 1);
  assert.equal(f.trace.some(item => item[1] === 'released'), false);
});

test('source lease disposal failure cannot claim RELEASED', async () => {
  const f = fixture();
  const port = f.port(f.factory('system'), f.factory('mpv'));
  await port.prepare();
  f.lease.release = async () => { throw new f.core.PlaybackPortError(5400104, 'lease disposal failed'); };
  await assert.rejects(port.release(), error => error.detail === 'lease disposal failed');
  assert.equal(f.backends[0].closes, 1);
  assert.equal(f.trace.some(item => item[1] === 'released'), false);
});

test('release from backend-change callback stops the rest of the commit events', async () => {
  const f = fixture();
  const port = f.port(f.factory('system', async events => {
    events.onDurationChange(120000); events.onVideoSizeChange(1920, 1080);
  }), f.factory('mpv'));
  let released;
  f.observer.onBackendChange = backend => { f.trace.push(['backend', backend]); released = port.release(); };
  await port.prepare(); await released;
  assert.equal(f.trace.some(item => ['duration', 'size', 'info'].includes(item[0])), false);
  assert.equal(f.trace.filter(item => item[1] === 'released').length, 1);
});

for (const fails of [false, true]) {
  test(`release waits for failed-prepare candidate disposal (reject=${fails})`, async () => {
    const f = fixture('system');
    let finish, fail, started;
    const began = new Promise(resolve => { started = resolve; });
    const port = f.port(f.factory('system', async () => {
      f.backends[0].release = () => {
        f.backends[0].closes++;
        started();
        return new Promise((resolve, reject) => { finish = resolve; fail = reject; });
      };
      throw new f.core.PlaybackPortError(5400106, 'unsupported');
    }), f.factory('mpv'));
    const preparation = assert.rejects(port.prepare(), error =>
      error.code === (fails ? 5400104 : 5400106));
    await began;
    let settled = false, closeError;
    const closed = port.release().then(() => { settled = true; }, error => {
      settled = true; closeError = error;
    });
    // Drain ready Promise jobs while native disposal is deliberately unresolved.
    await new Promise(setImmediate);
    const sourceClosesBeforeDisposal = f.sourceCloses;
    const settledBeforeDisposal = settled;
    if (fails) fail(new f.core.PlaybackPortError(5400104, 'candidate disposal failed'));
    else finish();
    await preparation; await closed;
    assert.equal(sourceClosesBeforeDisposal, 0);
    assert.equal(settledBeforeDisposal, false);
    assert.equal(closeError?.code, fails ? 5400104 : undefined);
    assert.equal(f.backends[0].closes, 1);
    assert.equal(f.sourceCloses, 1);
    assert.equal(f.trace.some(item => item[1] === 'released'), !fails);
  });
}

test('release shares source cleanup already owned by failed preparation', async () => {
  const f = fixture('system');
  let finish, started;
  const began = new Promise(resolve => { started = resolve; });
  const port = f.port(f.factory('system', async () => {
    f.lease.release = () => {
      started();
      return new Promise(resolve => { finish = resolve; });
    };
    throw new f.core.PlaybackPortError(5400106, 'unsupported');
  }), f.factory('mpv'));
  const preparation = assert.rejects(port.prepare(), error => error.code === 5400106);
  await began;
  let disposed = false;
  const closed = port.release().then(() => { disposed = true; });
  await new Promise(setImmediate);
  const completedBeforeLease = disposed;
  finish(); await preparation; await closed;
  assert.equal(completedBeforeLease, false);
});


test('invalid settings and rejected audio selection do not destroy active playback', async () => {
  const f = fixture(), snapshots = [];
  const engine = new f.core.PlaybackEngine(value => snapshots.push(value), f.factory('system'));
  await engine.open(f.core.MediaSource.fromLocalDocument('file://one.mp4'), 'surface');
  engine.setPlaybackRate(NaN); engine.setVolume(NaN); engine.seek(NaN);
  const backend = f.backends[0];
  backend.events.onTracksChange([new f.core.PortTrack('2', f.core.PortTrackKind.AUDIO)]);
  backend.selectAudioTrack = async () => { throw new f.core.PlaybackPortError(5400102); };
  await engine.selectAudioTrack('2');
  assert.equal(snapshots.at(-1).status, 'playing');
  assert.equal(snapshots.at(-1).warningOperation, 'audio-track');
  assert.equal(backend.closes, 0);
  await engine.release();
});


test('live playback does not require optional loop support', async () => {
  const f = fixture(), snapshots = [];
  const make = f.factory('system');
  const engine = new f.core.PlaybackEngine(value => snapshots.push(value), async observer => {
    const port = await make(observer);
    port.setLoopMode = () => { throw new f.core.PlaybackPortError(5400102); };
    return port;
  });
  await engine.open(f.core.MediaSource.fromLocalDocument('file://live.m3u8'), 'surface');
  assert.equal(snapshots.at(-1).status, 'playing');
  engine.setLoopMode('single');
  assert.equal(snapshots.at(-1).status, 'playing');
  assert.equal(snapshots.at(-1).warningOperation, 'loop');
  assert.equal(f.backends[0].closes, 0);
  await engine.release();
});


test('display mode defaults to fit, survives reopening, and fences old callbacks', async () => {
  const f = fixture(), snapshots = [];
  const engine = new f.core.PlaybackEngine(value => snapshots.push(value), f.factory('system'));
  const source = f.core.MediaSource.fromLocalDocument('file://one.mp4');
  await engine.open(source, 'surface');
  assert.equal(snapshots.at(-1).displayMode, 'fit');
  engine.setDisplayMode('crop'); assert.equal(snapshots.at(-1).displayMode, 'crop');
  await engine.open(source, 'surface'); assert.equal(snapshots.at(-1).displayMode, 'crop');
  const before = snapshots.length;
  f.backends[0].events.onDisplayModeChange('stretch'); assert.equal(snapshots.length, before);
  const port = f.backends[1];
  port.setDisplayMode = () => { throw new f.core.PlaybackPortError(5400102); };
  engine.setDisplayMode('stretch');
  assert.equal(snapshots.at(-1).displayMode, null);
  assert.equal(snapshots.at(-1).warningOperation, 'display-mode');
  assert.equal(snapshots.at(-1).status, 'playing'); assert.equal(port.closes, 0);
  await engine.release();
});

test('Adaptive display-mode feedback comes only from its committed candidate', async () => {
  const f = fixture(), modes = [];
  f.observer.onDisplayModeChange = value => modes.push(value);
  const port = f.port(f.factory('system', async events => {
    events.onDisplayModeChange('stretch');
    throw new f.core.PlaybackPortError(5400106);
  }), f.factory('mpv'));
  await port.prepare(); port.setDisplayMode('crop');
  assert.deepEqual(modes, ['crop']);
  await port.release(); f.backends[1].events.onDisplayModeChange('fit');
  assert.deepEqual(modes, ['crop']);
});


test('a rejected initial display mode does not prevent playback or claim an applied mode', async () => {
  const f = fixture(), snapshots = [], make = f.factory('system');
  const engine = new f.core.PlaybackEngine(value => snapshots.push(value), async observer => {
    const port = await make(observer);
    port.setDisplayMode = () => { throw new f.core.PlaybackPortError(5400102); };
    return port;
  });
  await engine.open(f.core.MediaSource.fromLocalDocument('file://video.mp4'), 'surface');
  assert.equal(snapshots.at(-1).displayMode, null);
  assert.equal(snapshots.at(-1).warningOperation, 'display-mode');
  assert.equal(snapshots.at(-1).status, 'playing'); assert.equal(f.backends[0].closes, 0);
  await engine.release();
});
