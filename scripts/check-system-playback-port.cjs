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
  let timerId = 0;
  const receiver = { closes: 0, getReceivingSurfaceId: async () => 'surface',
    release: async () => { receiver.closes++; } };
  const player = {
    state: 'idle', duration: 60000, closes: 0,
    on: (name, callback) => listeners.set(name, callback),
    emit(name, ...args) {
      if (name === 'stateChange') this.state = args[0];
      listeners.get(name)(...args);
    },
    set url(value) { this.source = value; this.emit('stateChange', 'initialized'); },
    prepare: async () => player.emit('stateChange', 'prepared'),
    play: async () => player.emit('stateChange', 'playing'),
    pause: async () => player.emit('stateChange', 'paused'),
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
      if (name === '@kit.MediaKit') return { media: { createAVPlayer: async () => player, SeekMode: { SEEK_CLOSEST: 0 } } };
      if (name === '@kit.CoreFileKit') return { fileIo: {} };
      if (name === '@kit.AudioKit') return { audio: { InterruptHint: { INTERRUPT_HINT_PAUSE: 1, INTERRUPT_HINT_STOP: 2 } } };
      if (name === '@kit.ImageKit') return { image: { createImageReceiver: () => receiver, ImageFormat: { JPEG: 0 } } };
      if (['@kit.NetworkKit', '@kit.PerformanceAnalysisKit', 'linkora_ffmpeg/Native', 'linkora_ffmpeg', 'linkora_proxy'].includes(name)) return {};
      if (name.endsWith('/SystemWebPEncoder') || name === './FfmpegRuntimeSmoke') return {};
      if (name === './ProgressiveDownloadRegistry') return { ProgressiveDownloadRegistry: { get: () => { throw Error('Unexpected progressive source'); } } };
      if (name.startsWith('.')) return load(path.relative(root, path.resolve(path.dirname(file), name + '.ets')));
      throw Error('Unexpected dependency: ' + name);
    }, module, module.exports);
    return module.exports;
  }
  const core = Object.assign({}, ...['models/MediaSource', 'models/MediaLink', 'playback/PlaybackPort', 'playback/PlaybackBackend']
    .map(name => load('linkora_core/src/main/ets/' + name + '.ets')));
  const { SystemPlaybackPort } = load('entry/src/main/ets/playback/SystemPlaybackPort.ets');
  return { player, receiver, states, positions, timers,
    hlsHarness: () => load('entry/src/simulator/ets/diagnostics/MediaFunctionSmoke.ets').MediaFunctionSmoke,
    async create() {
    const observer = new core.PlaybackPortObserver(value => states.push(value), () => {}, () => {},
      value => positions.push(value), () => {}, () => {}, () => {}, () => {});
    const port = await SystemPlaybackPort.create(observer);
    port.configure(new core.MediaSource(core.MediaSourceKind.NETWORK_LINK, 'http://fixture/video.mp4', 'video.mp4', '', 'mp4'), 'surface');
    return port;
  } };
}
test('System controls use milliseconds and preserve play/pause states', async () => {
  const f = fixture(), port = await f.create();
  await port.prepare(); await port.play(); await port.pause();
  port.seek(4567); f.player.emit('timeUpdate', 6123);
  assert.equal(f.player.seekMs, 4567); assert.deepEqual(f.positions, [6123]);
  assert.deepEqual(f.states.slice(-2), ['playing', 'paused']);
  await port.release(); assert.equal(f.timers.size, 0);
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
