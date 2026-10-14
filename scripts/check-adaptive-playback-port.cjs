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
  let sourceCloses = 0, lease;
  function load(relative) {
    if (relative.endsWith('/NetworkPlaybackSourceResolver.ets')) return {
      NetworkPlaybackSourceResolver: class {
        async resolve(source) { lease = { source, release: async () => { sourceCloses++; } }; return lease; }
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
  const core = Object.assign({}, ...['models/MediaSource', 'playback/PlaybackPort',
    'playback/PlaybackBackend', 'playback/PlaybackBackendSelector'].map(name => load('linkora_core/src/main/ets/' + name + '.ets')));
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
        configure() {}, setSurfaceSize() {}, getDuration: () => 120000,
        prepare: () => prepare(events), play: async () => events.onStateChange('playing'),
        pause: async () => events.onStateChange('paused'), seek: value => events.onSeekComplete(value),
        setPlaybackRate() {}, setVolume() {},
        release: async () => { backend.closes++; events.onStateChange('released'); }
      };
      backends.push(backend); return backend;
    };
  }
  return {
    core, observer, trace, backends, factory, get sourceCloses() { return sourceCloses; }, get lease() { return lease; },
    port(system, mpv, extension = 'mp4') {
      const port = new AdaptivePlaybackPort({}, {}, observer, preference, undefined, system, mpv);
      port.configure(core.MediaSource.fromLocalDocument('file://fixture.' + extension), 'surface');
      return port;
    }
  };
}

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
  try {
    f.backends[0].events.onPositionChange(88000);
    assert.equal(f.trace.length, before);
  } finally { finish(); await pending; }
  assert.equal(f.trace.filter(item => item[1] === 'released').length, 1);
});

test('native release failure still closes lease and cannot claim RELEASED', async () => {
  const f = fixture();
  const port = f.port(f.factory('system'), f.factory('mpv'));
  await port.prepare();
  f.backends[0].release = async () => { throw new f.core.PlaybackPortError(5400104, 'native disposal failed'); };
  await assert.rejects(port.release(), error => error.code === 5400104);
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
