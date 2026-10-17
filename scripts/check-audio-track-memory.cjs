'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs'), path = require('node:path'), vm = require('node:vm');
const ts = require('C:/Program Files/Huawei/DevEco Studio/sdk/default/openharmony/ets/build-tools/ets-loader/node_modules/typescript');
const root = path.resolve(__dirname, '..');

function fixture(overrides = {}) {
  const cache = new Map(), timers = new Map(); let timerId = 0;
  function load(file) {
    file = path.resolve(root, file);
    if (cache.has(file)) return cache.get(file);
    assert.ok(fs.existsSync(file), 'Audio track memory is not implemented: ' + file);
    const module = { exports: {} }; cache.set(file, module.exports);
    const code = ts.transpileModule(fs.readFileSync(file, 'utf8'), {
      compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022 }
    }).outputText;
    vm.runInNewContext(`(function(require,module,exports){${code}\n})`, {
      console, setTimeout: callback => { timers.set(++timerId, callback); return timerId; },
      clearTimeout: id => timers.delete(id)
    }, { filename: file })(name => {
      if (Object.hasOwn(overrides, name)) return overrides[name];
      if (name === 'linkora_core') return { ...load('linkora_core/src/main/ets/playback/PlaybackPort.ets'),
        ...load('linkora_core/src/main/ets/playback/AudioTrackMemory.ets') };
      if (name.startsWith('.')) return load(path.resolve(path.dirname(file), name + '.ets'));
      throw Error('Unexpected dependency: ' + name);
    }, module, module.exports);
    return module.exports;
  }
  return { load, timers, ...load('linkora_core/src/main/ets/playback/PlaybackPort.ets'),
    ...load('linkora_core/src/main/ets/playback/AudioTrackMemory.ets') };
}

test('Memory matches semantic audio metadata across backend IDs and never guesses ambiguous tracks', () => {
  const f = fixture();
  const remembered = f.AudioTrackChoice.from(new f.PortTrack('3', 'audio', 'audio/ac3', 'zho', 'Main', true, 6));
  const same = new f.PortTrack('21', 'audio', 'ac3', 'zh', 'Main', false, 6);
  const other = new f.PortTrack('3', 'audio', 'aac', 'en', 'English');
  assert.equal(remembered.match([other, same])?.id, '21');
  assert.equal(remembered.match([same, new f.PortTrack('22', 'audio', 'ac3', 'zh', 'Main', false, 6)]), null);
  assert.equal(f.AudioTrackChoice.from(new f.PortTrack('1', 'audio')).match([new f.PortTrack('2', 'audio')]), null);
});

test('Track details preserve unknowns and remembered choices cannot contain executable IDs', () => {
  const f = fixture(), track = new f.PortTrack('7', 'audio', 'aac', 'en', 'Main', true, 2, 48000, 192000, true);
  assert.equal(track.channels, 2); assert.equal(track.sampleRate, 48000); assert.equal(track.bitrate, 192000);
  assert.equal(track.isDefault, true);
  const empty = new f.PortTrack('1', 'audio');
  assert.equal(empty.channels, 0); assert.equal(empty.isDefault, null);
  const value = f.AudioTrackChoice.from(track).encode();
  assert.equal(f.AudioTrackChoice.decode(value).match([track])?.id, '7');
  assert.equal(value.includes('"id"'), false);
  assert.equal(f.AudioTrackChoice.decode('not-json'), null);
  assert.equal(f.AudioTrackChoice.decode('{"language":1,"title":"Main","channels":2}'), null);
});

async function playerFixture(memory = null, withPlaylist = false, initialStatus = 'playing') {
  const f = fixture(), choices = [], requests = [], delays = [];
  const { MediaSource } = f.load('linkora_core/src/main/ets/models/MediaSource.ets');
  const { AppSettings } = f.load('linkora_core/src/main/ets/models/AppSettings.ets');
  const { PlaybackSnapshot } = f.load('linkora_core/src/main/ets/playback/PlaybackModels.ets');
  const { PlayerFeatureController } = f.load('linkora_core/src/main/ets/features/PlayerFeatureController.ets');
  const source = MediaSource.fromLocalDocument('file://fixture/a.mkv');
  const sourceB = MediaSource.fromLocalDocument('file://fixture/b.mkv');
  const { PlaybackPlaylist, PlaybackPlaylistItem } = f.load('linkora_core/src/main/ets/models/PlaybackPlaylist.ets');
  const playlist = withPlaylist ? new PlaybackPlaylist([
    new PlaybackPlaylistItem('a', source), new PlaybackPlaylistItem('b', sourceB)], 0, true) : null;
  let notify, current, acknowledge = true, accepted = true, choiceLoader = async () => memory;
  let activeIndex = withPlaylist ? 0 : -1, backend = 'system', delayResult, status = initialStatus;
  const tracks = [new f.PortTrack('2', 'audio', 'aac', 'en', 'Main', true),
    new f.PortTrack('3', 'audio', 'ac3', 'zh', 'Main')];
  function emit(selected = '2', index = activeIndex) {
    activeIndex = index;
    current = new PlaybackSnapshot(status, 10000, 120000, 0, 1920, 1080, null, true, 0, backend,
      tracks.map(track => new f.PortTrack(track.id, track.kind, track.codec, track.language, track.title,
        track.id === selected, track.channels, track.sampleRate, track.bitrate, track.isDefault)));
    current.playlistIndex = index;
    notify(current);
  }
  const engine = { setSurfaceSize() {}, async open() { emit(); }, async release() {},
    setAudioDelay(value) { delays.push(value); return delayResult === undefined ? value : delayResult; },
    async selectAudioTrack(id) {
      requests.push(id);
      if (acknowledge && accepted) emit(id === 'auto' ? '2' : id);
      return accepted;
    } };
  const repository = { async loadPreferences() { throw Error('Removed global settings must never be read'); },
    async loadChoice() { return choiceLoader(); },
    async saveChoice(source, value) { choices.push({ source, value }); } };
  const feature = new PlayerFeatureController(source, observer => { notify = observer; return engine; },
    { async load() { return null; }, async save() {}, async clear() {} }, new AppSettings(), () => {}, null, playlist, repository);
  feature.attachSurface('surface'); await new Promise(setImmediate);
  return { ...f, feature, source, sourceB, choices, requests, delays, emit, notify, tracks,
    set status(value) { status = value; }, set backend(value) { backend = value; }, set delayResult(value) { delayResult = value; },
    set choiceLoader(value) { choiceLoader = value; },
    set acknowledge(value) { acknowledge = value; }, set accepted(value) { accepted = value; } };
}

test('Fresh media retains the native default and a saved manual choice restores once', async () => {
  const p = await playerFixture();
  assert.deepEqual(p.requests, []);
  assert.equal(p.feature.currentState().audioBusy, false);
  assert.equal(p.feature.currentState().audioError, false);
  assert.equal(p.feature.currentState().playback.tracks.find(t => t.selected).id, '2');
  p.feature.stop();
  const f = fixture(), restored = await playerFixture(new f.AudioTrackChoice('zh', 'Main', 0));
  assert.deepEqual(restored.requests, ['3']);
  restored.emit('3'); await new Promise(setImmediate);
  assert.deepEqual(restored.requests, ['3']);
  assert.equal(restored.choices.length, 0);
  restored.feature.stop();
});

test('Saved audio waits for native readiness even when metadata arrives during preparation', async () => {
  const f = fixture(), p = await playerFixture(new f.AudioTrackChoice('zh', 'Main', 0), false, 'preparing');
  assert.deepEqual(p.requests, []);
  p.status = 'ready'; p.emit(); await new Promise(setImmediate);
  assert.deepEqual(p.requests, ['3']);
  assert.equal(p.feature.currentState().audioError, false);
  p.feature.stop();
});

test('Manual track memory is saved only after a native selected-track acknowledgement', async () => {
  const p = await playerFixture(); p.acknowledge = false;
  p.feature.selectAudioTrack('3'); await new Promise(setImmediate);
  assert.equal(p.choices.length, 0); assert.equal(p.feature.currentState().audioBusy, true);
  p.emit('3'); await new Promise(setImmediate);
  assert.equal(p.choices.length, 1); assert.equal(p.choices[0].source, p.source);
  assert.equal(p.choices[0].value.language, 'zh');
  p.feature.stop();
});

test('Rejected, unacknowledged, or departed selections never become remembered successes', async () => {
  const p = await playerFixture(); p.accepted = false;
  p.feature.selectAudioTrack('3'); await new Promise(setImmediate);
  assert.equal(p.choices.length, 0); assert.equal(p.feature.currentState().audioError, true);
  p.accepted = true; p.acknowledge = false;
  p.feature.selectAudioTrack('3'); await new Promise(setImmediate);
  Array.from(p.timers.values()).at(-1)();
  assert.equal(p.feature.currentState().audioBusy, false); assert.equal(p.choices.length, 0);
  p.feature.selectAudioTrack('3'); p.feature.stop(); p.emit('3'); await new Promise(setImmediate);
  assert.equal(p.choices.length, 0);
});

test('A native playlist transition fences an old manual selection before persistence', async () => {
  const p = await playerFixture(null, true); p.acknowledge = false;
  p.feature.selectAudioTrack('3');
  p.emit('3', 1); await new Promise(setImmediate);
  assert.equal(p.choices.length, 0, 'old track id must not be saved for either playlist source');
  p.feature.stop();
});

test('Only MPV applies signed delay and resets each new video; rejected changes keep the last value', async () => {
  const p = await playerFixture(null, true);
  p.feature.setAudioDelay(50); assert.deepEqual(p.delays, []);
  p.backend = 'mpv'; p.emit();
  assert.deepEqual(p.delays, [0]);
  p.feature.setAudioDelay(-50); assert.equal(p.feature.currentState().audioDelay, -50);
  p.feature.setAudioDelay(50); assert.equal(p.feature.currentState().audioDelay, 50);
  p.delayResult = null; p.feature.setAudioDelay(100);
  assert.equal(p.feature.currentState().audioDelay, 50);
  assert.equal(p.feature.currentState().audioDelayError, true);
  p.delayResult = undefined; p.emit('2', 1); await new Promise(setImmediate);
  assert.equal(p.delays.at(-1), 0); assert.equal(p.feature.currentState().audioDelay, 0);
  p.emit('2', 1); assert.equal(p.delays.filter(v => v === 0).length, 2);
  p.feature.setAudioDelay(50);
  p.delayResult = null; p.emit('2', 0); await new Promise(setImmediate);
  assert.equal(p.feature.currentState().audioDelay, null, 'a rejected reset must not present zero as confirmed');
  assert.equal(p.feature.currentState().audioDelayError, true);
  p.delayResult = undefined; p.feature.setAudioDelay(0);
  assert.equal(p.feature.currentState().audioDelay, 0);
  assert.equal(p.feature.currentState().audioDelayError, false);
  const before=p.delays.length;
  p.feature.setAudioDelay(NaN); p.feature.setAudioDelay(10001);
  assert.equal(p.delays.length,before);
  p.feature.stop(); p.feature.setAudioDelay(50); assert.equal(p.delays.length,before);
});

test('A late saved-choice load cannot cross a playlist transition', async () => {
  const p=await playerFixture(null,true);let finish;
  p.choiceLoader=()=>new Promise(resolve=>{finish=resolve;});p.emit('2',1);
  p.choiceLoader=async()=>new p.AudioTrackChoice('en','Main',0);p.emit('2',0);
  await new Promise(setImmediate);finish(new p.AudioTrackChoice('zh','Main',0));
  await new Promise(setImmediate);assert.deepEqual(p.requests,['2']);p.feature.stop();
});

test('Memory store isolates media keys, serializes writes, and clears a saved choice', async () => {
  const values = new Map(); let fail = false;
  const store = { async get(key, fallback) { return values.get(key) ?? fallback; },
    async put(key, value) { values.set(key, value); }, async delete(key) { values.delete(key); },
    async flush() { if (fail) throw Error('disk full'); } };
  const f = fixture({ '@kit.ArkData': { preferences: { getPreferences: async () => store } },
    './SourceIdentity': { SourceIdentity: { key: async source => require('node:crypto').createHash('sha256')
      .update(source.sourceId + ':' + source.locator).digest('hex') } } });
  const { AudioTrackMemoryStore } = f.load('entry/src/main/ets/services/AudioTrackMemoryStore.ets');
  const repository = new AudioTrackMemoryStore({});
  const a = { sourceId: 'server-a', locator: '/video.mkv', fingerprint: '' };
  const b = { sourceId: 'server-b', locator: '/video.mkv', fingerprint: '' };
  await repository.saveChoice(a, new f.AudioTrackChoice('en', 'Main', 2));
  assert.equal((await repository.loadChoice(a)).language, 'en');
  assert.equal(await repository.loadChoice(b), null);
  assert.equal(Array.from(values.keys()).some(key => key.includes('video.mkv')), false);
  await repository.saveChoice(a, null); assert.equal(await repository.loadChoice(a), null);
  fail = true; await assert.rejects(repository.saveChoice(a, new f.AudioTrackChoice('ja', 'Main', 2)));
  fail = false; await repository.saveChoice(a, new f.AudioTrackChoice('en', 'Main', 2));
  assert.equal((await repository.loadChoice(a)).language, 'en');
});
