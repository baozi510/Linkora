'use strict';
// Production lazy owner/resolver; storage, credentials and loopback sockets are controlled boundaries.
const assert = require('node:assert/strict');
const { test } = require('node:test');
const fs = require('node:fs'), path = require('node:path'), vm = require('node:vm');
const root = path.resolve(__dirname, '..');
const ts = require('C:/Program Files/Huawei/DevEco Studio/sdk/default/openharmony/ets/build-tools/ets-loader/node_modules/typescript');

function fixture() {
  const cache = new Map(), opened = [], readers = [], proxies = [], timers = [];
  let live = 0, maximumLive = 0, open = async index => makeReader(index);
  const core = {};
  function makeReader(index, size = 100) {
    const reader = { index, closed: 0, cancelled: 0, id: () => String(index), size: () => size,
      capabilities: () => new core.SourceCapabilities(),
      readAt: async (_offset, length) => new ArrayBuffer(length),
      cancel() { this.cancelled++; }, async close() { this.closed++; live--; } };
    readers.push(reader); live++; maximumLive = Math.max(maximumLive, live); return reader;
  }
  class Proxy {
    constructor(config) { this.config = config; this.sources = []; this.closes = 0; proxies.push(this); }
    async buildSourceUrl(source) {
      this.sources.push(source);
      return { url: 'http://127.0.0.1:1234/opaque-' + this.sources.length,
        release: async () => { source.cancel(); await source.close(); } };
    }
    async close() {
      this.closes++;
      await Promise.all(this.sources.map(async source => { source.cancel(); await source.close(); }));
    }
  }
  function load(relative) {
    const file = path.resolve(root, relative);
    if (cache.has(file)) return cache.get(file);
    if (relative.endsWith('/NetworkServerStore.ets')) return {
      NetworkServerStore: class { async load() { return [{ id: 7 }]; } }
    };
    if (relative.endsWith('/NetworkDirectoryService.ets')) return {
      NetworkDirectoryService: class { async openSource(locator, _fingerprint, setupObserver) {
        const index = Number(locator.match(/(\d+)\.mp4$/)[1]); opened.push(index); return open(index, setupObserver);
      } }
    };
    assert.ok(fs.existsSync(file), 'Network native playlist ownership is not implemented: ' + relative);
    const module = { exports: {} }; cache.set(file, module.exports);
    const code = ts.transpileModule(fs.readFileSync(file, 'utf8'), {
      compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022 }
    }).outputText;
    vm.runInNewContext(`(function(require,module,exports){${code}\n})`, {
      ArrayBuffer, setTimeout: callback => { timers.push(callback); return timers.length; }, clearTimeout() {}
    }, { filename: file })(name => {
      if (name === 'linkora_core') return core;
      if (name === '@kit.NetworkKit') return { connection: {} };
      if (name === 'linkora_proxy') return { NetworkFileProxy: Proxy,
        NetworkFileProxyConfig: class { constructor(_block, _timeout, maxSources = 8) { this.maxSources = maxSources; } } };
      if (name.startsWith('.')) return load(path.relative(root, path.resolve(path.dirname(file), name + '.ets')).replaceAll('\\', '/'));
      throw Error('Unexpected dependency: ' + name);
    }, module, module.exports);
    return module.exports;
  }
  for (const name of ['contracts/StoragePorts', 'models/MediaLink', 'models/MediaSource', 'models/PlaybackPlaylist']) {
    Object.assign(core, load('linkora_core/src/main/ets/' + name + '.ets'));
  }
  const { NetworkPlaylistSources } = load('entry/src/main/ets/playback/NetworkPlaylistSources.ets');
  const { NetworkPlaybackSourceResolver } = load('entry/src/main/ets/playback/NetworkPlaybackSourceResolver.ets');
  const items = Array.from({ length: 12 }, (_, index) => new core.PlaybackPlaylistItem('item-' + index,
    core.MediaSource.fromRemoteFile('/video-' + index + '.mp4', 'video-' + index + '.mp4', 'Saved server',
      100, 'network-server:7', 'credential-reference')));
  return { core, items, opened, readers, proxies, makeReader,
    get maximumLive() { return maximumLive; },
    set open(value) { open = value; },
    nativeReader: () => load('entry/src/main/ets/services/NativeRemoteReadSession.ets'),
    expireSetup: () => timers.at(-1)(),
    owner: () => new NetworkPlaylistSources(items.map(item => item.source), async (index, setupObserver) => {
      opened.push(index); return open(index, setupObserver);
    }),
    resolver: () => new NetworkPlaybackSourceResolver({}, new Proxy()) };
}

test('Network metadata registration is lazy and switching/backward reads retain at most one reader', async () => {
  const f = fixture(), owner = f.owner();
  const sources = owner.sources();
  assert.equal(sources.length, 12); assert.equal(f.opened.length, 0);
  assert.equal(sources[5].size(), 100);
  await sources[5].readAt(0, 4); await sources[5].readAt(4, 4);
  assert.deepEqual(f.opened, [5]);
  await sources[6].readAt(0, 4); await sources[5].readAt(0, 4);
  assert.deepEqual(f.opened, [5, 6, 5]); assert.equal(f.maximumLive, 1);
  await owner.release(); await owner.release();
  assert.ok(f.readers.every(reader => reader.closed === 1));
  await assert.rejects(sources[5].readAt(0, 4));
});

test('Network concurrent item reads serialize, and release cancels the active read before queued opens', async () => {
  const f = fixture(), owner = f.owner(), sources = owner.sources();
  let began, rejectRead;
  const started = new Promise(resolve => { began = resolve; });
  f.open = async index => {
    const reader = f.makeReader(index);
    reader.readAt = () => { began(); return new Promise((_resolve, reject) => { rejectRead = reject; }); };
    reader.cancel = () => rejectRead?.(Error('cancelled'));
    return reader;
  };
  const reading = assert.rejects(sources[0].readAt(0, 4)); await started;
  const queued = assert.rejects(sources[1].readAt(0, 4));
  await owner.release(); await reading; await queued;
  assert.deepEqual(f.opened, [0]); assert.equal(f.readers[0].closed, 1);
});

test('Network release owns an upstream open that returns after cancellation', async () => {
  const f = fixture(), owner = f.owner(); let finish, began;
  const started = new Promise(resolve => { began = resolve; });
  f.open = index => { began(); return new Promise(resolve => { finish = () => resolve(f.makeReader(index)); }); };
  const reading = assert.rejects(owner.sources()[0].readAt(0, 4)); await started;
  let released = false; const closing = owner.release().then(() => { released = true; });
  await new Promise(setImmediate); assert.equal(released, false);
  finish(); await reading; await closing;
  assert.equal(f.readers[0].closed, 1); assert.equal(f.readers[0].cancelled, 1);
});

test('Network changed size and invalid ranges are rejected without leaking a reader', async () => {
  const f = fixture(), owner = f.owner(), source = owner.sources()[0];
  await assert.rejects(source.readAt(-1, 2)); assert.equal(f.opened.length, 0);
  f.open = async index => f.makeReader(index, 101);
  await assert.rejects(source.readAt(0, 4), /changed|size/i);
  assert.equal(f.readers[0].closed, 1); await owner.release();
  assert.throws(() => new (owner.constructor)([f.core.MediaSource.fromRemoteFile('/unknown.mp4', '', '')], async () => {}), /size/i);
});

test('Network release rejects a late successful read even when the upstream ignores cancellation', async () => {
  const f = fixture(), owner = f.owner(); let finish, began;
  const started = new Promise(resolve => { began = resolve; });
  f.open = async index => {
    const reader = f.makeReader(index);
    reader.readAt = () => { began(); return new Promise(resolve => { finish = resolve; }); };
    return reader;
  };
  const reading = assert.rejects(owner.sources()[0].readAt(0, 4), /cancelled|unavailable/); await started;
  let released = false; const closing = owner.release().then(() => { released = true; });
  await new Promise(setImmediate); assert.equal(released, false);
  finish(new ArrayBuffer(4)); await reading; await closing;
  assert.equal(f.readers[0].closed, 1);
});

test('Network disposal failure stops later opens and remains visible on owner release', async () => {
  const f = fixture(), owner = f.owner(), sources = owner.sources();
  f.open = async index => { const r = f.makeReader(index); r.close = async () => { throw Error('close failed'); }; return r; };
  await sources[0].readAt(0, 4);
  await assert.rejects(sources[1].readAt(0, 4), /close failed/);
  await assert.rejects(owner.release(), /close failed/);
  assert.deepEqual(f.opened, [0]);
});

test('Network ownership closes an opened reader when metadata access throws', async () => {
  const f = fixture(), owner = f.owner();
  f.open = async index => { const r = f.makeReader(index); r.size = () => { throw Error('metadata failed'); }; return r; };
  await assert.rejects(owner.sources()[0].readAt(0, 4), /metadata failed/);
  await owner.release(); assert.equal(f.readers[0].closed, 1);
});

test('Network ownership still closes after a cancel method throws, and reports the cleanup failure', async () => {
  const f = fixture(), owner = f.owner();
  f.open = async index => { const r = f.makeReader(index); r.cancel = () => { throw Error('cancel failed'); }; return r; };
  await owner.sources()[0].readAt(0, 4);
  await assert.rejects(async () => owner.release(), /cancel failed/);
  assert.equal(f.readers[0].closed, 1);
});

for (const closeFails of [false, true]) {
  test(`Network native setup timeout stays owned through late cleanup (close failure=${closeFails})`, async () => {
    const f = fixture(), owner = f.owner(), sources = owner.sources(), native = f.nativeReader();
    let finishOpen, finishClose, lateHandle = false;
    f.open = (index, setupObserver) => {
      if (index > 0) { assert.equal(lateHandle, false); return Promise.resolve(f.makeReader(index)); }
      return native.openNativeRemoteReader('127.0.0.1', () => new Promise(resolve => {
        finishOpen = () => { lateHandle = true; resolve(new native.NativeRemoteFile(1, 100)); };
      }), async (_handle, _offset, length) => new ArrayBuffer(length), () => {},
      () => new Promise((resolve, reject) => { finishClose = () => {
        if (closeFails) reject(Error('late native close failed'));
        else { lateHandle = false; resolve(); }
      }; }), setupObserver).then(session => new f.core.RemoteReadSessionAdapter('native', session));
    };
    let rejected = false;
    const first = assert.rejects(sources[0].readAt(0, 4), closeFails ? /late native close failed/ : /timed out/)
      .then(() => { rejected = true; });
    await new Promise(setImmediate); f.expireSetup(); await new Promise(setImmediate);
    const next = closeFails ? assert.rejects(sources[1].readAt(0, 4), /late native close failed/) : sources[1].readAt(0, 4);
    await new Promise(setImmediate);
    assert.equal(rejected, false); assert.deepEqual(f.opened, [0]);
    finishOpen(); await new Promise(setImmediate);
    assert.equal(lateHandle, true); assert.deepEqual(f.opened, [0]);
    finishClose(); await first; await next;
    if (closeFails) await assert.rejects(owner.release(), /late native close failed/);
    else { await owner.release(); assert.equal(f.readers[0].closed, 1); }
  });
}

test('Resolver forwards ordered opaque URLs for more than eight remote items without opening files', async () => {
  const f = fixture(), playlist = new f.core.PlaybackPlaylist(f.items, 9, true);
  const resolved = await f.resolver().resolve(f.items[9].source, playlist);
  assert.equal(resolved.playlist?.items.length, 12);
  assert.equal(resolved.playlist.startIndex, 9); assert.equal(resolved.playlist.complete, true);
  assert.equal(resolved.playlist.items[9].id, f.items[9].id);
  assert.equal(resolved.source.locator, resolved.playlist.items[9].source.locator);
  assert.ok(resolved.playlist.items.every(item => item.source.kind === 'network_link'));
  assert.equal(f.opened.length, 0); assert.equal(f.proxies[0].sources.length, 0);
  assert.equal(f.proxies[1].sources.length, 12); assert.equal(f.proxies[1].config.maxSources, 12);
  await f.proxies[1].sources[9].readAt(0, 4); assert.deepEqual(f.opened, [9]);
  await resolved.release(); await resolved.release();
  assert.equal(f.proxies[1].closes, 1); assert.equal(f.readers[0].closed, 1);
});

test('Resolver rejects mixed or changed server identities before creating queue URLs', async () => {
  const f = fixture(); f.items[1] = new f.core.PlaybackPlaylistItem('other',
    f.core.MediaSource.fromRemoteFile('/video-1.mp4', 'video-1.mp4', '', 100, 'network-server:8'));
  await assert.rejects(f.resolver().resolve(f.items[0].source, new f.core.PlaybackPlaylist(f.items, 0, true)));
  assert.equal(f.opened.length, 0);
});
