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
    assert.ok(fs.existsSync(file), 'Audio track preferences are not implemented: ' + file);
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
        ...load('linkora_core/src/main/ets/playback/AudioTrackPreferences.ets') };
      if (name.startsWith('.')) return load(path.resolve(path.dirname(file), name + '.ets'));
      throw Error('Unexpected dependency: ' + name);
    }, module, module.exports);
    return module.exports;
  }
  return { load, timers, ...load('linkora_core/src/main/ets/playback/PlaybackPort.ets'),
    ...load('linkora_core/src/main/ets/playback/AudioTrackPreferences.ets') };
}

test('Ordered languages normalize ISO tags and select the first available preference', () => {
  const f = fixture(), p = new f.AudioTrackPreferences(['eng', 'zh-CN', 'en']);
  assert.deepEqual(Array.from(p.languages), ['en', 'zh-cn']);
  const en = new f.PortTrack('9', 'audio', 'aac', 'en-US');
  const zh = new f.PortTrack('2', 'audio', 'aac', 'zho');
  assert.equal(p.choose([zh, en], null)?.id, '9');
  assert.equal(new f.AudioTrackPreferences(['ja', 'zh']).choose([en, zh], null)?.id, '2');
  assert.equal(new f.AudioTrackPreferences(['fr']).choose([zh, en], null), null);
  assert.throws(() => new f.AudioTrackPreferences(['http://unexpected']));
  assert.throws(() => new f.AudioTrackPreferences(Array(9).fill('en')));
});

test('Memory matches semantic audio metadata across backend IDs and never guesses ambiguous tracks', () => {
  const f = fixture(), p = new f.AudioTrackPreferences(['en']);
  const remembered = f.AudioTrackChoice.from(new f.PortTrack('3', 'audio', 'audio/ac3', 'zho', 'Main', true, 6));
  const same = new f.PortTrack('21', 'audio', 'ac3', 'zh', 'Main', false, 6);
  const other = new f.PortTrack('3', 'audio', 'aac', 'en', 'English');
  assert.equal(p.choose([other, same], remembered)?.id, '21');
  assert.equal(p.choose([same, new f.PortTrack('22', 'audio', 'ac3', 'zh', 'Main', false, 6)], remembered), null);
  assert.equal(new f.AudioTrackPreferences(['en'], false).choose([other, same], remembered)?.id, '3');
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

async function playerFixture(preferences, memory = null, withPlaylist = false) {
  const f = fixture(), choices = [], requests = [], savedPreferences = [];
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
  let activeIndex = withPlaylist ? 0 : -1;
  const tracks = [new f.PortTrack('2', 'audio', 'aac', 'en', 'Main', true),
    new f.PortTrack('3', 'audio', 'ac3', 'zh', 'Main')];
  function emit(selected = '2', index = activeIndex) {
    activeIndex = index;
    current = new PlaybackSnapshot('playing', 10000, 120000, 0, 1920, 1080, null, true, 0, 'system',
      tracks.map(track => new f.PortTrack(track.id, track.kind, track.codec, track.language, track.title,
        track.id === selected, track.channels, track.sampleRate, track.bitrate, track.isDefault)));
    current.playlistIndex = index;
    notify(current);
  }
  const engine = { setSurfaceSize() {}, async open() { emit(); }, async release() {},
    async selectAudioTrack(id) {
      requests.push(id);
      if (acknowledge && accepted) emit(id === 'auto' ? '2' : id);
      return accepted;
    } };
  const repository = { async loadPreferences() { return preferences ?? new f.AudioTrackPreferences(); },
    async savePreferences(value) { savedPreferences.push(value); }, async loadChoice() { return choiceLoader(); },
    async saveChoice(source, value) { choices.push({ source, value }); } };
  const feature = new PlayerFeatureController(source, observer => { notify = observer; return engine; },
    { async load() { return null; }, async save() {}, async clear() {} }, new AppSettings(), () => {}, null, playlist, repository);
  feature.attachSurface('surface'); await new Promise(setImmediate);
  return { ...f, feature, source, sourceB, choices, requests, savedPreferences, emit, notify, tracks,
    set choiceLoader(value) { choiceLoader = value; },
    set acknowledge(value) { acknowledge = value; }, set accepted(value) { accepted = value; } };
}

test('Player applies language preference once; native selection updates do not loop', async () => {
  const f = fixture(), p = await playerFixture(new f.AudioTrackPreferences(['zh']));
  assert.deepEqual(p.requests, ['3']);
  assert.equal(p.feature.currentState().audioSelection, 'auto');
  assert.equal(p.feature.currentState().audioBusy, false);
  p.emit('3'); await new Promise(setImmediate);
  assert.deepEqual(p.requests, ['3']); assert.equal(p.choices.length, 0);
  p.feature.stop();
});

test('Manual track memory is saved only after a native selected-track acknowledgement', async () => {
  const p = await playerFixture(); p.acknowledge = false;
  p.feature.selectAudioTrack('3'); await new Promise(setImmediate);
  assert.equal(p.choices.length, 0); assert.equal(p.feature.currentState().audioBusy, true);
  p.emit('3'); await new Promise(setImmediate);
  assert.equal(p.choices.length, 1); assert.equal(p.choices[0].source, p.source);
  assert.equal(p.choices[0].value.language, 'zh');
  assert.equal(p.feature.currentState().audioSelection, '3');
  p.feature.stop();
});

test('Auto clears the current file memory and asks the native default when no language matches', async () => {
  const f = fixture(), memory = new f.AudioTrackChoice('zh', 'Main', 0);
  const p = await playerFixture(new f.AudioTrackPreferences(), memory);
  assert.deepEqual(p.requests, ['3']);
  p.feature.selectAudioTrack('auto'); await new Promise(setImmediate);
  assert.equal(p.requests.at(-1), 'auto');
  assert.equal(p.choices.at(-1).value, null);
  assert.equal(p.feature.currentState().audioSelection, 'auto');
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

test('Invalid preference input is rejected and remember=false prevents manual persistence', async () => {
  const p = await playerFixture();
  p.feature.setAudioPreferences('not a tag', true); await new Promise(setImmediate);
  assert.equal(p.savedPreferences.length, 0); assert.equal(p.feature.currentState().audioError, true);
  p.feature.setAudioPreferences('eng,zh', false); await new Promise(setImmediate);
  assert.deepEqual(Array.from(p.savedPreferences[0].languages), ['en', 'zh']);
  p.feature.selectAudioTrack('3'); await new Promise(setImmediate);
  assert.equal(p.choices.length, 0);
  p.feature.stop();
});

test('A native playlist transition fences an old manual selection before persistence', async () => {
  const p = await playerFixture(null, null, true); p.acknowledge = false;
  p.feature.selectAudioTrack('3');
  p.emit('3', 1); await new Promise(setImmediate);
  assert.equal(p.choices.length, 0, 'old track id must not be saved for either playlist source');
  p.feature.stop();
});

test('Editing preferences during a delayed playlist load keeps the latest value and remember policy', async () => {
  const p = await playerFixture(null, null, true);
  let finishLoad;
  p.choiceLoader = () => new Promise(resolve => { finishLoad = resolve; });
  p.emit('2', 1);
  p.feature.setAudioPreferences('zh', false);
  await new Promise(setImmediate);
  finishLoad(new p.AudioTrackChoice('en', 'Main', 0));
  await new Promise(setImmediate);
  assert.deepEqual(Array.from(p.feature.currentState().audioPreferences.languages), ['zh']);
  assert.equal(p.feature.currentState().audioPreferences.remember, false);
  assert.equal(p.requests.at(-1), '3');
  assert.equal(p.feature.currentState().audioBusy, false);
  p.feature.stop();
});

test('Enriched default flags reevaluate automatic language selection', async () => {
  const f = fixture(), p = await playerFixture(new f.AudioTrackPreferences(['en']));
  p.tracks[1] = new p.PortTrack('3', 'audio', 'aac', 'eng', 'Main');
  p.emit(); await new Promise(setImmediate);
  assert.equal(p.requests.at(-1), '2');
  p.tracks[1] = new p.PortTrack('3', 'audio', 'aac', 'eng', 'Main', false, 0, 0, 0, true);
  p.emit(); await new Promise(setImmediate);
  assert.equal(p.requests.at(-1), '3');
  p.feature.stop();
});

test('ISO 639-2 terminology and bibliographic tags match two-letter preferences', () => {
  const f = fixture();
  for (const [preference, language] of [['it', 'ita'], ['nl', 'nld'], ['nl', 'dut'], ['cs', 'ces'],
    ['cs', 'cze'], ['el', 'ell'], ['el', 'gre'], ['sv', 'swe'], ['ar', 'ara'], ['he', 'heb'], ['uk', 'ukr']]) {
    assert.equal(new f.AudioTrackPreferences([preference]).choose([
      new f.PortTrack('1', 'audio', 'aac', language)], null)?.id, '1', `${preference}/${language}`);
  }
});

test('Preferences store isolates media keys, serializes writes, and clears a saved choice', async () => {
  const values = new Map(); let fail = false;
  const store = { async get(key, fallback) { return values.get(key) ?? fallback; },
    async put(key, value) { values.set(key, value); }, async delete(key) { values.delete(key); },
    async flush() { if (fail) throw Error('disk full'); } };
  const f = fixture({ '@kit.ArkData': { preferences: { getPreferences: async () => store } },
    './SourceIdentity': { SourceIdentity: { key: async source => require('node:crypto').createHash('sha256')
      .update(source.sourceId + ':' + source.locator).digest('hex') } } });
  const { AudioTrackPreferencesStore } = f.load('entry/src/main/ets/services/AudioTrackPreferencesStore.ets');
  const repository = new AudioTrackPreferencesStore({});
  const a = { sourceId: 'server-a', locator: '/video.mkv', fingerprint: '' };
  const b = { sourceId: 'server-b', locator: '/video.mkv', fingerprint: '' };
  await Promise.all([repository.savePreferences(new f.AudioTrackPreferences(['en'])),
    repository.savePreferences(new f.AudioTrackPreferences(['zh'], false))]);
  assert.deepEqual(Array.from((await repository.loadPreferences()).languages), ['zh']);
  assert.equal((await repository.loadPreferences()).remember, false);
  await repository.saveChoice(a, new f.AudioTrackChoice('en', 'Main', 2));
  assert.equal((await repository.loadChoice(a)).language, 'en');
  assert.equal(await repository.loadChoice(b), null);
  assert.equal(Array.from(values.keys()).some(key => key.includes('video.mkv')), false);
  await repository.saveChoice(a, null); assert.equal(await repository.loadChoice(a), null);
  fail = true; await assert.rejects(repository.savePreferences(new f.AudioTrackPreferences(['ja'])));
  fail = false; await repository.savePreferences(new f.AudioTrackPreferences(['en']));
  assert.equal((await repository.loadPreferences()).languages[0], 'en');
});
