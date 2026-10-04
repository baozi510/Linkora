'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');
const vm = require('node:vm');
const { createHash } = require('node:crypto');
const { DatabaseSync } = require('node:sqlite');
const ts = require('C:/Program Files/Huawei/DevEco Studio/sdk/default/openharmony/ets/build-tools/ets-loader/node_modules/typescript');
const root = path.resolve(__dirname, '..');
const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'linkora-media-'));
const modules = new Map();
const context = { cacheDir: path.join(temp, 'cache'), filesDir: path.join(temp, 'files') };
fs.mkdirSync(context.cacheDir); fs.mkdirSync(context.filesDir);
let databaseFailure = false;
let fileWriteFailure = false;
let unlinkFailure = false;
global.ObservedV2 = value => value;
global.Trace = () => {};
let calls = 0, active = 0, maximum = 0, cancels = 0, opened = 0, closed = 0, framesReleased = 0;
const probeModes = [];
let hold = false, unblock = () => {}, fail = false, packFail = false;
let holdKey = false, releaseKey = () => {};
let holdImageRelease = false, releaseImageSource = () => {};
let decodedReleased = 0, webpSupported = true, webpFailure = false;
let deadline = () => {}, captureDeadline = false, setupHold = false, releaseSetup = () => {};
const nativeSetTimeout = global.setTimeout;
global.setTimeout = (callback, ms, ...args) => {
  if (captureDeadline && ms === 8000) deadline = callback;
  return nativeSetTimeout(callback, ms, ...args);
};
const png = new Uint8Array([1, 2, 3, 4]).buffer;
const fileIo = {
  OpenMode: { READ_ONLY: fs.constants.O_RDONLY, READ_WRITE: fs.constants.O_RDWR,
    CREATE: fs.constants.O_CREAT, TRUNC: fs.constants.O_TRUNC, WRITE_ONLY: fs.constants.O_WRONLY },
  accessSync: p => fs.existsSync(p),
  mkdirSync: (p, recursive) => { if (fs.existsSync(p)) throw Error('Harmony mkdir existing directory'); return fs.mkdirSync(p, { recursive }); },
  openSync: (p, flags) => ({ fd: fs.openSync(p, flags) }), closeSync: fd => fs.closeSync(fd),
  writeSync: (fd, data) => { if (fileWriteFailure) throw Error('disk full'); return fs.writeSync(fd, typeof data === 'string' ? data : Buffer.from(data)); },
  readSync: (fd, data) => fs.readSync(fd, Buffer.from(data)),
  readTextSync: p => fs.readFileSync(p, 'utf8'), listFileSync: p => fs.readdirSync(p),
  statSync: p => ({ size: fs.statSync(p).size, mtime: fs.statSync(p).mtimeMs }),
  renameSync: (a, b) => fs.renameSync(a, b), unlinkSync: p => { if (unlinkFailure) throw Error('unlink denied'); fs.unlinkSync(p); }
};
const image = {
  createImagePacker: () => ({ supportedFormats: webpSupported ? ['image/webp', 'image/jpeg'] : ['image/jpeg'],
    packing: async (frame, opts) => {
      assert.equal(opts.format, 'image/webp', 'new thumbnails never use JPEG');
      assert.equal(opts.quality, 80);
      if (packFail || (webpFailure && opts.format === 'image/webp')) throw Error('image encoding');
      return png;
    }, release: async () => {} }),
  createImageSource: data => { if (new Uint8Array(data)[0] === 0) throw Error('corrupt image'); return ({ createPixelMap: async () => ({ release: async () => { decodedReleased++; } }),
    release: async () => { if (holdImageRelease) await new Promise(resolve => { releaseImageSource = resolve; }); } }); }
};
class Probe {
  cancelled = false;
  abort = () => {};
  partial = false;
  async inspect(_source, _headers, options = {}) {
    calls++; active++; maximum = Math.max(maximum, active);
    probeModes.push(options.mode || 'both');
    try {
      if (!this.partial && !fail && options.mode !== 'thumbnail') options.onMetadata?.({ durationMs: 10000, width: 640, height: 360 });
      if (hold) await Promise.race([new Promise(resolve => { unblock = resolve; }),
        new Promise(resolve => { this.abort = resolve; })]);
      if (this.cancelled && this.partial) return { durationMs: 1234, width: 640, height: 360, thumbnail: null };
      if (this.cancelled || fail) return { status: this.cancelled ? 'cancelled' : 'unavailable', durationMs: 0, width: 0, height: 0, thumbnail: null };
      return { status: 'complete', durationMs: 10000, width: 640, height: 360,
        thumbnail: { release: async () => { framesReleased++; } } };
    } finally { active--; }
  }
  cancel() { this.cancelled = true; cancels++; if (this.partial) this.abort(); }
  async close() {}
}
const kits = {
  '@kit.AbilityKit': {}, '@kit.BasicServicesKit': { systemDateTime: { TimeType: { STARTUP: 0 }, getUptime: () => performance.now() } }, '@kit.CoreFileKit': { fileIo }, '@kit.ImageKit': { image },
  '@kit.ArkData': { relationalStore: { SecurityLevel: { S2: 2 }, getRdbStore: async () => rdb } }, '@kit.NetworkKit': { connection: {} },
  linkora_core: { LocalFileCategory: { VIDEO: 'video' }, LocalFileFilter: class { categoryOf(name) { return name.endsWith('.mp4') ? 'video' : 'other'; } } },
  linkora_media_probe: { NetworkMediaProbe: Probe, ProbeMode: { BOTH: 'both', METADATA: 'metadata', THUMBNAIL: 'thumbnail' } },
  linkora_proxy: { NetworkFileProxy: class {
    diagnostics() { return { bytesRead: 0, readRequests: 0 }; }
    async buildSourceUrl(source) { let closing; return { url: 'http://127.0.0.1/test', release: () => closing ??= source.close() }; }
    async close() {}
  } }
};
function load(file) {
  if (kits[file]) return kits[file];
  if (!file.endsWith('.ets')) file += '.ets';
  if (kits[file]) return kits[file];
  if (modules.has(file)) return modules.get(file).exports;
  const module = { exports: {} }; modules.set(file, module);
  const code = ts.transpileModule(fs.readFileSync(file, 'utf8'), {
    compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022 }
  }).outputText;
  vm.runInThisContext('(function(require,module,exports){' + code + '\n})', { filename: file })(
    name => load(name.startsWith('.') ? path.resolve(path.dirname(file), name) : name), module, module.exports);
  return module.exports;
}
const serviceDir = path.join(root, 'entry/src/main/ets/services');
Object.assign(kits.linkora_core, load(path.join(root, 'linkora_core/src/main/ets/thumbnail/ThumbnailPolicy.ets')));
kits[path.join(serviceDir, 'SourceIdentity.ets')] = { SourceIdentity: { value: async value => {
  if (holdKey) await new Promise(resolve => { releaseKey = resolve; });
  return createHash('sha256').update(value).digest('hex');
} } };
kits[path.join(serviceDir, 'NetworkDirectoryService.ets')] = { NetworkDirectoryService: class {
  async openSource(p, fingerprint, onSetup) {
    opened++;
    if (setupHold) {
      const settled = new Promise(resolve => { releaseSetup = resolve; }).then(() => { closed++; });
      onSetup(settled); throw Error('setup deadline');
    }
    return { close: async () => { closed++; }, cancel() {} };
  }
} };
kits[path.join(serviceDir, 'NetworkCredentialStore.ets')] = { NetworkCredentialStore: class { async remove() {} } };
const sqlite = new DatabaseSync(':memory:');
const rdb = {
  get version() { return sqlite.prepare('PRAGMA user_version').get().user_version; },
  set version(v) { sqlite.exec('PRAGMA user_version=' + v); },
  beginTransaction() { sqlite.exec('BEGIN'); }, commit() { sqlite.exec('COMMIT'); }, rollBack() { sqlite.exec('ROLLBACK'); },
  async execute(sql, args = []) { if (databaseFailure && sql.includes('network_media_metadata')) throw Error('storage unavailable'); return sqlite.prepare(sql).run(...args); },
  async querySql(sql, args = []) {
    const statement = sqlite.prepare(sql), names = statement.columns().map(c => c.name), rows = statement.all(...args); let i = -1;
    return { goToNextRow: () => ++i < rows.length, getColumnIndex: n => names.indexOf(n),
      getLong: c => rows[i][names[c]] || 0, getString: c => rows[i][names[c]] || '', close() {} };
  }
};
const server = { id: 1, updatedAt: 2, protocol: 'smb' };
const entry = (p = '/video.mp4', size = 99) => ({ path: p, displayName: path.basename(p), kind: 'file', size, modifiedAt: 5 });
const tick = () => new Promise(resolve => setImmediate(resolve));
async function check() {
  const { NetworkMediaCache, CachedNetworkMedia } = load(path.join(serviceDir, 'NetworkMediaCache.ets'));
  const { NetworkMediaLoader } = load(path.join(serviceDir, 'NetworkMediaLoader.ets'));
  const { NetworkThumbnailCache } = load(path.join(serviceDir, 'NetworkThumbnailCache.ets'));
  const thumbnails = new NetworkThumbnailCache(context, server.id);
  const policy = new kits.linkora_core.DefaultThumbnailTimePolicy();
  const { LinkoraDatabase } = load(path.join(serviceDir, 'LinkoraDatabase.ets'));
  await LinkoraDatabase.shared(context).store();
  await rdb.execute("INSERT INTO network_server(id,display_name,protocol,host,port,created_at,updated_at) VALUES (1,'test','smb','host',445,1,2)");
  const cache = new NetworkMediaCache(context, 1);
  const key = await cache.key(server, entry());
  await cache.put(key, new CachedNetworkMedia(10000, 640, 360, png, 1));
  assert.ok(fs.existsSync(path.join(context.filesDir, 'network-media', key + '.webp')), 'thumbnail in persistent files directory');
  assert.equal(sqlite.prepare('SELECT duration_ms FROM network_media_metadata WHERE cache_key=?').get(key).duration_ms, 10000);
  assert.equal((await cache.get(key)).durationMs, 10000);
  assert.notEqual(await cache.key(server, entry('/video.mp4', 100)), key);
  assert.notEqual(await cache.key({ ...server, updatedAt: 3 }, entry()), key);
  const disk = new NetworkMediaCache(context, 1);
  assert.equal((await disk.get(key)).width, 640, 'cold database cache never expires');
  assert.notEqual(await cache.decode(await cache.get(key)), await cache.decode(await cache.get(key)), 'separate ownership');
  holdImageRelease = true; let decoded = false;
  const decoding = cache.decode(await cache.get(key)).then(() => { decoded = true; });
  await tick(); assert.equal(decoded, false, 'decode waits for native ImageSource release');
  holdImageRelease = false; releaseImageSource(); await decoding;
  const legacyKey = await cache.key(server, entry('/legacy.mp4'));
  const oldDir = path.join(context.cacheDir, 'network-media'); fs.mkdirSync(oldDir, { recursive: true });
  fs.writeFileSync(path.join(oldDir, legacyKey + '.json'), JSON.stringify({ durationMs: 42, width: 2, height: 3, savedAt: 1 }));
  fs.writeFileSync(path.join(oldDir, legacyKey + '.jpg'), Buffer.from(png));
  assert.equal((await disk.get(legacyKey)).durationMs, 42, 'old expired JSON/JPEG migrates without network');
  assert.ok(!fs.existsSync(path.join(oldDir, legacyKey + '.json')));
  assert.ok(fs.existsSync(path.join(context.filesDir, 'network-media', legacyKey + '.jpg')));
  const legacyRetryKey = await cache.key(server, entry('/legacy-retry.mp4'));
  fs.writeFileSync(path.join(oldDir, legacyRetryKey + '.json'), JSON.stringify({ durationMs: 43, width: 2, height: 3, savedAt: 1 }));
  fs.writeFileSync(path.join(oldDir, legacyRetryKey + '.jpg'), Buffer.from(png));
  fileWriteFailure = true;
  assert.equal((await disk.get(legacyRetryKey)).durationMs, 43);
  assert.ok(fs.existsSync(path.join(oldDir, legacyRetryKey + '.json')), 'failed migration retains old files');
  assert.equal((await new NetworkMediaCache(context, 1).get(legacyRetryKey)).durationMs, 43, 'disk full preserves committed metadata');
  fileWriteFailure = false;
  assert.ok((await new NetworkMediaCache(context, 1).get(legacyRetryKey)).imageData, 'retry old thumbnail migration after storage recovers');
  await cache.put(key, new CachedNetworkMedia(1, 1, 1, new ArrayBuffer(262145)));
  assert.ok((await new NetworkMediaCache(context, 1).get(key)).imageData === null, 'metadata persists independently of oversized/missing image');
  databaseFailure = true;
  const failureKey = await cache.key(server, entry('/storage-failure.mp4'));
  await cache.put(failureKey, new CachedNetworkMedia(99, 1, 1, png));
  assert.equal((await cache.get(failureKey)).durationMs, 99, 'database failure keeps useful in-memory values'); databaseFailure = false;
  const { NetworkAdvancedOptions } = load(path.join(serviceDir, 'NetworkServerStore.ets'));
  const advanced = new NetworkAdvancedOptions(); advanced.sftpFingerprint = 'SHA256:known';
  assert.equal(NetworkAdvancedOptions.deserialize(advanced.serialize()).sftpFingerprint, 'SHA256:known');
  assert.equal(NetworkAdvancedOptions.deserialize('||||||||').sftpFingerprint, '', 'old server options supported');
  for (let i = 0; i < 140; i++) await cache.put(i.toString(16).padStart(64, '0'), new CachedNetworkMedia(1, 1, 1, png, 1));
  assert.ok(fs.readdirSync(path.join(context.filesDir, 'network-media')).length >= 140, 'no thumbnail quantity limit');
  assert.ok((await new NetworkMediaCache(context, 1).get('0'.repeat(64))).imageData, 'first image survives memory eviction and age');
  const updates = [];
  const loader = new NetworkMediaLoader(context, server, (e, info) => updates.push([e.path, info.durationMs]));
  loader.reset([entry('/a.mp4'), entry('/b.mp4'), entry('/cancel.mp4'), entry('/bad.mp4'), entry('/pack.mp4')], false);
  hold = true;
  const a = loader.load(entry('/a.mp4')); const secondA = loader.load(entry('/a.mp4'));
  const b = loader.load(entry('/b.mp4'));
  await tick(); await tick(); assert.equal(calls, 1);
  assert.equal(updates.length, 0, 'metadata stays hidden while frame is pending');
  const earlyKey = await cache.key(server, entry('/a.mp4'));
  assert.equal(sqlite.prepare('SELECT duration_ms FROM network_media_metadata WHERE cache_key=?').get(earlyKey)?.duration_ms,
    10000, 'metadata persisted while frame is still pending');
  hold = false; unblock();
  const [one, two, three] = await Promise.all([a, secondA, b]);
  assert.ok(one && two && three); assert.notEqual(one, two);
  assert.equal(calls, 2); assert.equal(maximum, 1);
  assert.equal(updates.length, 3); assert.equal(framesReleased, 2);
  holdImageRelease = true; releaseImageSource = null;
  const beforeCachedDecode = updates.length;
  const cachedDecode = loader.load(entry('/a.mp4'), 'cached-decode');
  for (let i = 0; i < 20 && releaseImageSource === null; i++) await tick();
  assert.ok(releaseImageSource, 'cached image reached asynchronous decode cleanup');
  assert.equal(updates.length, beforeCachedDecode, 'cached metadata waits for usable decoded image');
  holdImageRelease = false; releaseImageSource(); assert.ok(await cachedDecode);
  assert.equal(updates.length, beforeCachedDecode + 1, 'cached metadata delivered with ready image');
  loader.reset([entry('/owners.mp4'), entry('/late-decode.mp4')], false);
  hold = true;
  const ownerA = loader.load(entry('/owners.mp4'), 'first');
  const ownerB = loader.load(entry('/owners.mp4'), 'second');
  await tick(); await tick(); loader.cancel('/owners.mp4', 'first');
  assert.equal(await ownerA, null);
  hold = false; unblock();
  assert.ok(await ownerB, 'one disappearing consumer must not cancel the other');
  holdImageRelease = true;
  releaseImageSource = null;
  const beforeLateRelease = decodedReleased;
  const beforeLateUpdates = updates.length;
  const lateDecode = loader.load(entry('/late-decode.mp4'), 'decode');
  for (let i = 0; i < 20 && releaseImageSource === null; i++) await tick();
  assert.ok(releaseImageSource, 'fresh decode reached its asynchronous release');
  assert.equal(updates.length, beforeLateUpdates, 'fresh metadata waits for decoded image');
  loader.cancel('/late-decode.mp4', 'decode');
  holdImageRelease = false; releaseImageSource();
  assert.equal(await lateDecode, null, 'fresh decode cannot return a cancelled image');
  await tick(); assert.equal(decodedReleased, beforeLateRelease + 1, 'late fresh image released exactly once');
  assert.equal(updates.length, beforeLateUpdates, 'cancelled decode never publishes metadata');
  loader.reset([entry('/a.mp4'), entry('/b.mp4'), entry('/cancel.mp4'), entry('/bad.mp4'), entry('/pack.mp4')], false);
  const count = calls; assert.ok(await loader.load(entry('/a.mp4'))); assert.equal(calls, count);
  const refreshKey = await cache.key(server, entry('/a.mp4'));
  const refreshThumbnailKey = await thumbnails.key(server, entry('/a.mp4'), policy.plan(10000, 640, 360));
  const refreshPath = path.join(context.cacheDir, 'network-thumbnails', String(server.id), refreshThumbnailKey + '.webp');
  const refreshImage = fs.readFileSync(refreshPath);
  const refreshMetadata = sqlite.prepare('SELECT * FROM network_media_metadata WHERE cache_key=?').get(refreshKey);
  const refreshTime = fs.statSync(refreshPath).mtimeMs;
  loader.reset([entry('/a.mp4')], true);
  assert.ok(await loader.load(entry('/a.mp4')));
  assert.equal(calls, count, 'refresh reuses cached thumbnail without extracting video again');
  assert.deepEqual(sqlite.prepare('SELECT * FROM network_media_metadata WHERE cache_key=?').get(refreshKey), refreshMetadata,
    'refresh retains cached metadata unchanged');
  assert.deepEqual(fs.readFileSync(refreshPath), refreshImage);
  assert.equal(fs.statSync(refreshPath).mtimeMs, refreshTime, 'refresh does not rewrite thumbnail file');
  const changedEntry = entry('/a.mp4', 100);
  loader.reset([changedEntry], true); assert.ok(await loader.load(changedEntry));
  assert.equal(calls, count + 1, 'changed file version uses a new cache key');
  assert.ok(fs.existsSync(refreshPath), 'refresh retains previous version thumbnail');
  loader.reset([entry('/a.mp4'), entry('/b.mp4'), entry('/cancel.mp4'), entry('/bad.mp4'), entry('/pack.mp4')], false);
  hold = true;
  const abandoned = loader.load(entry('/cancel.mp4'));
  await tick(); await tick(); loader.cancel('/cancel.mp4');
  assert.equal(await abandoned, null, 'cancel returns before native exit');
  const updateCount = updates.length; hold = false; unblock(); await tick(); await tick();
  assert.equal(updates.length, updateCount, 'no late metadata delivery');
  fail = true; assert.equal(await loader.load(entry('/bad.mp4')), null); const failedCalls = calls;
  assert.equal(await loader.load(entry('/bad.mp4')), null); assert.equal(calls, failedCalls, 'failure backoff');
  fail = false; packFail = true; assert.equal(await loader.load(entry('/pack.mp4')), null);
  assert.ok(updates.some(([p, duration]) => p === '/pack.mp4' && duration === 10000), 'metadata survives encoding failure');
  packFail = false;
  assert.equal(await loader.load({ ...entry('/subtitle.srt'), displayName: 'subtitle.srt' }), null);
  assert.equal(await loader.load({ ...entry('/folder.mp4'), kind: 'directory' }), null);
  loader.close(); await tick();
  assert.equal(opened, closed, 'all readers closed'); assert.ok(cancels > 0);
  assert.equal(await loader.load(entry('/a.mp4')), null, 'closed loader inert');
  const raceLoader = new NetworkMediaLoader(context, server, () => { throw Error('late delivery'); });
  const raceEntry = entry('/late-key.mp4'); raceLoader.reset([raceEntry], false);
  holdKey = true; const race = raceLoader.load(raceEntry); await tick();
  const beforeRace = calls; raceLoader.cancel(raceEntry.path); holdKey = false; releaseKey();
  assert.equal(await race, null); assert.equal(calls, beforeRace, 'cancel before async key prevents native open');
  raceLoader.close();
  const partialLoader = new NetworkMediaLoader(context, server, (e, info) => updates.push([e.path, info.durationMs]));
  const partialEntry = entry('/deadline.mp4'); partialLoader.reset([partialEntry], false);
  const originalInspect = Probe.prototype.inspect;
  Probe.prototype.inspect = function() { this.partial = true; return originalInspect.call(this); };
  captureDeadline = true; hold = true;
  const timed = partialLoader.load(partialEntry); await tick(); await tick(); deadline();
  assert.equal(await timed, null); assert.ok(updates.some(([p, d]) => p === partialEntry.path && d === 1234));
  const beforeTimeoutRetry = calls;
  assert.equal(await partialLoader.load(partialEntry), null); assert.equal(calls, beforeTimeoutRetry, 'timeout backoff retains partial metadata');
  captureDeadline = false; hold = false; unblock(); partialLoader.close(); await tick();
  Probe.prototype.inspect = originalInspect;
  const setupLoader = new NetworkMediaLoader(context, server, () => {});
  setupLoader.reset([entry('/setup.mp4'), entry('/queued.mp4')], false);
  setupHold = true;
  const firstSetup = setupLoader.load(entry('/setup.mp4')); await tick(); await tick();
  const beforeQueued = opened;
  setupHold = false; const queued = setupLoader.load(entry('/queued.mp4')); await tick(); await tick();
  assert.equal(opened, beforeQueued, 'worker waits for actual native setup cleanup');
  releaseSetup(); assert.equal(await firstSetup, null); assert.ok(await queued); setupLoader.close(); await tick();
  const { openNativeRemoteReader, NativeRemoteFile } = load(path.join(serviceDir, 'NativeRemoteReadSession.ets'));
  let actualSetupDone = false, nativeClosed = false, releaseNative;
  captureDeadline = true;
  const nativeSetup = openNativeRemoteReader('127.0.0.1', () => new Promise(resolve => { releaseNative = resolve; }),
    async () => png, () => {}, async () => { nativeClosed = true; }, settled => settled.then(() => { actualSetupDone = true; }));
  deadline(); await assert.rejects(nativeSetup, /timed out/);
  assert.equal(actualSetupDone, false);
  releaseNative(new NativeRemoteFile(1, 99)); await tick();
  assert.ok(actualSetupDone && nativeClosed, 'completion includes closing a late native handle'); captureDeadline = false;
  let trustArgs;
  kits['liblinkora_sftp.so'] = { default: { list: async (...args) => { trustArgs = args; } } };
  kits.linkora_core.RemoteProtocol = { SFTP: 'sftp' };
  kits.linkora_core.ProtocolTestResult = class { constructor(succeeded) { this.succeeded = succeeded; } };
  const { SftpProtocolTestAdapter } = load(path.join(root, 'entry/src/main/ets/adapters/SftpProtocolTestAdapter.ets'));
  const adapter = new SftpProtocolTestAdapter();
  const trustRequest = { host: 'example', port: 22, rootPath: '/', username: 'user', password: 'secret', strictSftp: true, sftpFingerprint: '' };
  assert.equal((await adapter.test(trustRequest)).succeeded, false); assert.equal(trustArgs, undefined, 'strict missing trust sends no credentials');
  assert.equal((await adapter.test({ ...trustRequest, sftpFingerprint: 'SHA256:trusted' })).succeeded, true);
  assert.equal(trustArgs[7], 'SHA256:trusted'); assert.equal(trustArgs[8], 1);
  const pageSource = fs.readFileSync(path.join(root, 'entry/src/main/ets/pages/NetworkPage.ets'), 'utf8');
  assert.match(pageSource, /this\.sftpFingerprint\.trim\(\), this\.sftpHostKeyPolicy === SftpHostKeyPolicy\.STRICT/);
  assert.match(pageSource, /server\.advancedOptions\.sftpFingerprint, server\.advancedOptions\.sftpHostKeyPolicy === SftpHostKeyPolicy\.STRICT/);
  const fallbackEntry = entry('/webp-unavailable.mp4'); webpSupported = false;
  const fallbackLoader = new NetworkMediaLoader(context, server, () => {}); fallbackLoader.reset([fallbackEntry], false);
  assert.equal(await fallbackLoader.load(fallbackEntry), null, 'missing WebP encoder fails thumbnail without JPEG fallback');
  const fallbackKey = await cache.key(server, fallbackEntry);
  assert.equal((await new NetworkMediaCache(context, 1).get(fallbackKey)).imageData, null);
  assert.ok(!fs.existsSync(path.join(context.filesDir, 'network-media', fallbackKey + '.jpg')));
  assert.equal(thumbnails.get(await thumbnails.key(server, fallbackEntry, policy.plan(10000, 640, 360))), null);
  webpSupported = true; fallbackLoader.close(); await tick();
  webpFailure = true;
  const rejectedEntry = entry('/webp-rejected.mp4');
  const rejectedLoader = new NetworkMediaLoader(context, server, () => {}); rejectedLoader.reset([rejectedEntry], false);
  assert.equal(await rejectedLoader.load(rejectedEntry), null, 'WebP encode failure never falls back to JPEG');
  const rejectedKey = await cache.key(server, rejectedEntry);
  assert.equal((await new NetworkMediaCache(context, 1).get(rejectedKey)).imageData, null);
  assert.ok(!fs.existsSync(path.join(context.filesDir, 'network-media', rejectedKey + '.jpg')));
  assert.equal(thumbnails.get(await thumbnails.key(server, rejectedEntry, policy.plan(10000, 640, 360))), null);
  webpFailure = false; rejectedLoader.close(); await tick();
  assert.equal(opened, closed, 'including delayed setup, all readers closed');
  const { NetworkServerStore } = load(path.join(serviceDir, 'NetworkServerStore.ets'));
  const normalInspect = Probe.prototype.inspect;
  for (const [name, imageData, numbers, expected] of [
    ['missing', null, [0, 0, 0], [12000, 1920, 1080]],
    ['corrupt', new Uint8Array([0, 0]).buffer, [9000, 0, 0], [9000, 1920, 1080]],
    ['dimensions', null, [0, 1280, 720], [12000, 1280, 720]],
    ['incomplete-dimensions', null, [0, 640, 0], [12000, 1920, 1080]]
  ]) {
    const retryEntry = entry('/retry-' + name + '.mp4'), retryKey = await cache.key(server, retryEntry);
    await cache.put(retryKey, new CachedNetworkMedia(12000, 1920, 1080, imageData));
    Probe.prototype.inspect = async function() { const result = await normalInspect.call(this);
      return { ...result, durationMs: numbers[0], width: numbers[1], height: numbers[2] }; };
    const retryUpdates = [];
    const retryLoader = new NetworkMediaLoader(context, server,
      (e, info) => retryUpdates.push([info.durationMs, info.width, info.height]));
    retryLoader.reset([retryEntry], false); assert.ok(await retryLoader.load(retryEntry));
    assert.deepEqual(retryUpdates.at(-1), expected, 'thumbnail retry preserves previously known fields: ' + name);
    const retained = await new NetworkMediaCache(context, 1).get(retryKey);
    assert.deepEqual([retained.durationMs, retained.width, retained.height], expected, 'retry retains persistent metadata');
    retryLoader.close(); await tick();
  }
  const timedRetryEntry = entry('/retry-timeout.mp4'), timedRetryKey = await cache.key(server, timedRetryEntry);
  await cache.put(timedRetryKey, new CachedNetworkMedia(12000, 1920, 1080, null));
  Probe.prototype.inspect = async function() { this.partial = true; const result = await normalInspect.call(this);
    return { ...result, durationMs: 0, width: 0, height: 0 }; };
  const timedRetryUpdates = [];
  const timedRetryLoader = new NetworkMediaLoader(context, server,
    (e, info) => timedRetryUpdates.push([info.durationMs, info.width, info.height]));
  timedRetryLoader.reset([timedRetryEntry], false); captureDeadline = true; hold = true;
  const timedRetry = timedRetryLoader.load(timedRetryEntry); await tick(); await tick(); deadline();
  assert.equal(await timedRetry, null); await tick(); await tick();
  assert.ok(timedRetryUpdates.every(values => values.join(',') === '12000,1920,1080'), 'timeout retry preserves known metadata');
  const timedRetained = await new NetworkMediaCache(context, 1).get(timedRetryKey);
  assert.deepEqual([timedRetained.durationMs, timedRetained.width, timedRetained.height], [12000, 1920, 1080]);
  captureDeadline = false; hold = false; unblock(); timedRetryLoader.close(); await tick();
  Probe.prototype.inspect = normalInspect;
  const imageOnlyEntry = entry('/image-only.mp4'), imageOnlyKey = await cache.key(server, imageOnlyEntry);
  await cache.put(imageOnlyKey, new CachedNetworkMedia(12000, 1920, 1080, null));
  const imageOnlyUpdates = [];
  const imageOnlyLoader = new NetworkMediaLoader(context, server, (_entry, info) => imageOnlyUpdates.push(info));
  imageOnlyLoader.reset([imageOnlyEntry], false); hold = true;
  const imageOnlyLoad = imageOnlyLoader.load(imageOnlyEntry); await tick(); await tick();
  assert.equal(imageOnlyUpdates.length, 0, 'metadata-only cache stays hidden while missing image is loading');
  hold = false; unblock(); assert.ok(await imageOnlyLoad);
  assert.equal(imageOnlyUpdates.length, 1, 'metadata-only cache published after missing image completes');
  assert.equal(probeModes.at(-1), 'thumbnail', 'valid metadata cache only extracts the missing thumbnail');
  imageOnlyLoader.close(); await tick();
  unlinkFailure = true;
  await assert.rejects(new NetworkServerStore(context).remove(1), /unlink denied/, 'failed cleanup keeps server deletion retryable');
  assert.equal(sqlite.prepare('SELECT count(*) AS n FROM network_server WHERE id=1').get().n, 1);
  assert.ok(sqlite.prepare('SELECT count(*) AS n FROM network_media_metadata').get().n > 0, 'retain cleanup inventory');
  unlinkFailure = false;
  await new NetworkServerStore(context).remove(1);
  assert.equal(sqlite.prepare('SELECT count(*) AS n FROM network_media_metadata').get().n, 0);
  assert.equal(fs.readdirSync(path.join(context.filesDir, 'network-media')).length, 0, 'explicit server deletion removes owned thumbnails');
  console.log('PASS media cache and loader checks');
  if (process.argv.includes('--backend')) return;
  const preview = fs.readFileSync(path.join(root, 'entry/src/main/ets/components/FileMediaPreview.ets'), 'utf8');
  const browser = fs.readFileSync(path.join(root, 'entry/src/main/ets/components/NetworkDirectoryBrowser.ets'), 'utf8');
  const factory = fs.readFileSync(path.join(root, 'entry/src/main/ets/foundation/LinkoraFeatures.ets'), 'utf8');
  // Compile the existing lifecycle methods; native ArkUI build() is verified on the simulator.
  const previewLifecycle = preview.slice(0, preview.indexOf('  build() {'))
    .replace('@ComponentV2', '').replace('export struct FileMediaPreview', 'export class FileMediaPreview') + '\n}';
  const previewModule = { exports: {} };
  const previewCode = ts.transpileModule(previewLifecycle, { compilerOptions: {
    module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022, experimentalDecorators: true
  } }).outputText;
  const decoration = () => {};
  vm.runInNewContext('(function(require,module,exports){' + previewCode + '\n})', {
    Param: decoration, Event: decoration, Local: decoration, Monitor: () => decoration
  })(name => name === '@kit.ArkTS' ? { util: { generateRandomUUID: () => 'preview-test' } } :
    name === '../ui/AppTheme' ? { MediaLayout: {} } : kits[name] || {}, previewModule, previewModule.exports);
  const previewReady = [];
  const readyFrame = { release: async () => {} };
  const readyPreview = new previewModule.exports.FileMediaPreview();
  let finishPreview;
  readyPreview.uri = 'preview'; readyPreview.thumbnailEnabled = true;
  readyPreview.load = () => new Promise(resolve => { finishPreview = resolve; });
  readyPreview.onReadyChanged = ready => {
    if (ready) assert.equal(readyPreview.thumbnail, readyFrame, 'image assigned before metadata is revealed');
    previewReady.push(ready);
  };
  readyPreview.aboutToAppear(); assert.deepEqual(previewReady, [false]);
  finishPreview(readyFrame); await tick(); assert.deepEqual(previewReady, [false, true]);
  readyPreview.aboutToDisappear(); assert.deepEqual(previewReady, [false, true, false]);
  assert.match(browser, /entry\.mediaPreviewReady && entry\.width/);
  assert.match(browser, /onReadyChanged:\s*\(ready: boolean\) => \{\s*entry\.mediaPreviewReady = ready/);
  assert.match(preview, /visibleOnly/); assert.match(preview, /onVisibleAreaChange/); assert.match(preview, /cancelLoad/);
  assert.match(browser, /createNetworkMediaLoader/); assert.match(browser, /mediaLoader\?\.cancel/);
  assert.match(browser, /entry\.modifiedAt, this\.previewGeneration/); assert.match(browser, /\+\+this\.previewGeneration/);
  assert.match(factory, /NETWORK_MEDIA_ENABLED/); assert.match(factory, /NetworkMediaLoader \| null/);
  console.log('PASS permanent database metadata, WebP storage, legacy migration, refresh cache reuse, serial/coalesced load, cancellation/late results, partial metadata, independent images, UI boundary and nullable factory');
}
check().catch(error => { console.error(error); process.exitCode = 1; }).finally(() => fs.rmSync(temp, { recursive: true, force: true }));
