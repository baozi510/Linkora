'use strict';
const fs = require('node:fs');
const path = require('node:path');
const http = require('node:http');
const assert = require('node:assert/strict');
const { randomUUID, randomBytes } = require('node:crypto');
const { execFileSync } = require('node:child_process');
const hdc = 'C:/Program Files/Huawei/DevEco Studio/sdk/default/openharmony/toolchains/hdc.exe';
const cache = '/data/app/el2/100/base/com.linkora.player/haps/entry/cache';
const target = process.env.LINKORA_HDC_TARGET || '127.0.0.1:5555';
const out = path.resolve('artifacts/media-probe');
const delay = ms => new Promise(resolve => setTimeout(resolve, ms));
async function unitChecks() {
  // Same ETS/VM approach as check-local-persistence; this tests production range checks, not a reimplementation.
  const ts = require('C:/Program Files/Huawei/DevEco Studio/sdk/default/openharmony/ets/build-tools/ets-loader/node_modules/typescript');
  const vm = require('node:vm');
  let badRange = false, ignoreRange = false, requests = 0;
  const http = { RequestMethod: { HEAD: 'HEAD', GET: 'GET' }, HttpDataType: { ARRAY_BUFFER: 2 }, createHttp: () => ({
    destroy() {}, async request(source, options) {
      requests++; assert.equal(source, 'http://example.com/v'); assert.equal(options.header.authorization, 'Basic test');
      if (options.method === 'HEAD') return { responseCode: 200, header: { 'Content-Length': '100' } };
      assert.equal(options.header.Range, 'bytes=10-14'); assert.equal(options.maxLimit, 5);
      return { responseCode: ignoreRange ? 200 : 206, result: new ArrayBuffer(5),
        header: { 'Content-Range': badRange ? 'bytes 0-4/100' : 'bytes 10-14/100' } };
    }
  }) };
  const file = path.resolve(__dirname, '../entry/src/main/ets/services/HttpRemoteReadSession.ets');
  const code = ts.transpileModule(fs.readFileSync(file, 'utf8'), {
    compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022 }
  }).outputText;
  const module = { exports: {} };
  vm.runInThisContext(`(function(require,module,exports){${code}\n})`, { filename: file })(
    () => ({ http }), module, module.exports);
  const reader = await module.exports.HttpRemoteReadSession.open('http://example.com/v', { authorization: 'Basic test' });
  assert.equal(reader.size(), 100); assert.equal((await reader.read(10, 5)).byteLength, 5);
  badRange = true; await assert.rejects(reader.read(10, 5));
  badRange = false; ignoreRange = true; await assert.rejects(reader.read(10, 5));
  const count = requests;
  await assert.rejects(reader.read(-1, 5)); await assert.rejects(reader.read(0, 262145));
  assert.equal(requests, count);
  ignoreRange = false; await reader.read(10, 5); await reader.close(); await reader.close();
  await assert.rejects(reader.read(10, 5));
  console.log('PASS bounded authenticated HTTP ranges, wrong positions, ignored Range, reuse and close');
  const probeFile = path.resolve(__dirname, '../linkora_media_probe/src/main/ets/NetworkMediaProbe.ets');
  let clock = 1000;
  const probeImports = { '@kit.ArkTS': { url: { URL: { parseURL: value => new URL(value) } } },
    '@kit.BasicServicesKit': { systemDateTime: { TimeType: { STARTUP: 0 }, getUptime: () => clock } },
    '@kit.MediaKit': { media: { AVImageQueryOptions: { AV_IMAGE_QUERY_CLOSEST_SYNC: 0 } } } };
  function loadProbe(file) {
    const code = ts.transpileModule(fs.readFileSync(file, 'utf8'), {
      compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022 }
    }).outputText;
    const module = { exports: {} };
    vm.runInThisContext(`(function(require,module,exports){${code}\n})`, { filename: file })(
      name => name.startsWith('.') ? loadProbe(path.resolve(path.dirname(file), name + '.ets')) :
        probeImports[name] || {}, module, module.exports);
    return module.exports;
  }
  const probeModule = { exports: loadProbe(probeFile) };
  const frame = { release: async () => {} };
  const extractor = { setUrlSource() { clock += 3; },
    async fetchMetadata() { clock += 17; return { duration: '1234', videoWidth: '640', videoHeight: '360' }; },
    async fetchFrameByTime() { clock += 29; return frame; }, async release() { clock += 7; } };
  const probe = new probeModule.exports.NetworkMediaProbe(async () => { clock += 2; return extractor; });
  const timed = await probe.inspect('http://example.com/v');
  assert.deepEqual(timed.timings, { prepareMs: 5, metadataMs: 17, thumbnailMs: 29, totalMs: 58 });
  await timed.thumbnail.release(); await probe.close();
  const modes = probeModule.exports.ProbeMode;
  let metadataCalls = 0, frameCalls = 0, delivered = false, finishFrame;
  const splitExtractor = { ...extractor,
    async fetchMetadata() { metadataCalls++; return { duration: '200', videoWidth: '640', videoHeight: '360' }; },
    async fetchFrameByTime(time) { frameCalls++; assert.equal(time, 199000); return frame; } };
  const split = new probeModule.exports.NetworkMediaProbe(async () => splitExtractor);
  const metadata = await split.inspect('http://example.com/v', {}, { mode: modes.METADATA });
  assert.equal(metadata.metadataComplete, true); assert.equal(frameCalls, 0);
  assert.equal(metadata.timings.thumbnailMs, null);
  const thumbnail = await split.inspect('http://example.com/v', {}, { mode: modes.THUMBNAIL, durationHintMs: 200 });
  assert.equal(metadataCalls, 1); assert.equal(thumbnail.timings.metadataMs, null);
  await thumbnail.thumbnail.release();
  splitExtractor.fetchFrameByTime = () => new Promise(resolve => { finishFrame = resolve; });
  const both = split.inspect('http://example.com/v', {}, { onMetadata: value => {
    assert.equal(value.durationMs, 200); assert.equal(value.timings.thumbnailMs, null); delivered = true;
  } });
  for (let i = 0; i < 20 && !finishFrame; i++) await Promise.resolve();
  assert.equal(delivered, true, 'metadata delivered while frame is still pending');
  clock += 31; split.cancel();
  const cancelled = await both;
  assert.equal(cancelled.timings.thumbnailMs, 31);
  const snapshot = JSON.stringify(cancelled.timings);
  clock += 100; finishFrame(frame); await split.close();
  assert.equal(JSON.stringify(cancelled.timings), snapshot, 'cancelled timing is an immutable snapshot');
  console.log('PASS metadata-only, thumbnail-only, early metadata and interrupted timing snapshot');
  console.log('PASS separate native preparation, metadata, thumbnail and total timings');
  const smokeFile = path.resolve(__dirname, '../entry/src/main/ets/services/NetworkMediaProbeSmokeTest.ets');
  const smokeCode = ts.transpileModule(fs.readFileSync(smokeFile, 'utf8'), {
    compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022 }
  }).outputText;
  const smokeModule = { exports: {} };
  let deadline;
  const features = { createNetworkMediaProbe: () => ({ cancel() {}, close: () => new Promise(() => {}),
    inspect: async () => ({ status: 'unavailable', durationMs: 0, width: 0, height: 0, thumbnail: null }) }),
    createNetworkFileProxy: () => ({ close: async () => {} }) };
  const imports = { 'linkora_core': {}, 'linkora_media_probe': { ProbeStatus: { UNAVAILABLE: 'unavailable', METADATA_ONLY: 'metadata_only' } },
    '../foundation/LinkoraFeatures': { LinkoraFeatures: features } };
  vm.runInNewContext(`(function(require,module,exports){${smokeCode}\n})`, {
    setTimeout: callback => { deadline = callback; return 1; }, clearTimeout() {}
  })(name => imports[name] || {}, smokeModule, smokeModule.exports);
  const pending = smokeModule.exports.NetworkMediaProbeSmokeTest.inspect({}, {
    label: 'cleanup-watchdog', protocol: 'http', sourceUrl: 'http://example.com/v', mode: 'unavailable', controlUrl: ''
  }, 0);
  for (let i = 0; i < 20 && !deadline; i++) await Promise.resolve();
  assert.equal(typeof deadline, 'function'); deadline();
  const result = await Promise.race([pending, delay(100).then(() => null)]);
  assert.ok(result && !result.passed && result.cleanupComplete === false, 'stalled cleanup must emit controlled failure');
  console.log('PASS stalled cleanup watchdog returns failure evidence');
}
function run(...args) {
  return execFileSync(hdc, ['-t', target, ...args], { encoding: 'utf8', timeout: 20000, stdio: ['ignore', 'pipe', 'pipe'] });
}
function reference(file) {
  const result = JSON.parse(execFileSync('D:/ffmpeg/bin/ffprobe.exe', ['-v', 'error', '-select_streams', 'v:0',
    '-show_entries', 'stream=width,height:format=duration', '-of', 'json', file], { encoding: 'utf8' }));
  return { expectedDurationMs: Number(result.format.duration) * 1000,
    expectedWidth: result.streams[0].width, expectedHeight: result.streams[0].height };
}
async function main() {
  await unitChecks();
  if (process.argv.includes('--unit')) return;
  fs.mkdirSync(out, { recursive: true });
  const mediaFile = process.env.LINKORA_PROBE_VIDEO || 'D:/Linkora/test-lab/protocols/data/media/sample-h264.mp4';
  const normal = fs.readFileSync(mediaFile);
  const expected = reference(mediaFile);
  const tail = path.join(out, 'tail.mp4'), short = path.join(out, 'short.mp4');
  const ffmpeg = 'D:/ffmpeg/bin/ffmpeg.exe';
  execFileSync(ffmpeg, ['-v', 'error', '-y', '-i', mediaFile, '-c', 'copy', tail]);
  execFileSync(ffmpeg, ['-v', 'error', '-y', '-i', mediaFile, '-t', '0.2', '-an', '-c:v', 'libx264',
    '-pix_fmt', 'yuv420p', '-movflags', '+faststart', short]);
  const username = randomBytes(8).toString('hex'), password = randomBytes(16).toString('hex');
  const authorization = 'Basic ' + Buffer.from(`${username}:${password}`).toString('base64');
  const token = randomUUID();
  const routes = new Map();
  const controls = new Map();
  const sockets = new Set();
  let payload;
  const server = http.createServer((request, response) => {
    if (request.url === `/${token}`) { response.writeHead(200, { 'Content-Type': 'application/json' }); response.end(payload); return; }
    const parts = request.url.split('?')[0].split('/');
    const control = controls.get(parts[1]);
    if (control) {
      if (parts[2] === 'entered') {
        const poll = () => {
          if (response.destroyed) return;
          if (control.entered) response.end('ok'); else setTimeout(poll, 20);
        }; poll(); return;
      }
      if (parts[2] === 'resume') { for (const item of control.held) item.destroy(); control.held.clear(); response.end('ok'); return; }
    }
    const route = routes.get(parts[1]);
    if (!route) { response.writeHead(404).end(); return; }
    route.requests++; route.customAgent = request.headers['user-agent'] === 'LinkoraProbeCheck';
    if (route.auth && request.headers.authorization !== authorization) {
      route.denied++; route.authPresent = typeof request.headers.authorization === 'string'; route.authLength = request.headers.authorization?.length || 0; response.writeHead(401, { 'WWW-Authenticate': 'Basic realm="test"' }).end(); return;
    }
    if (route.control && request.method !== 'HEAD') {
      route.control.entered = true; route.control.held.add(response);
      response.once('close', () => route.control.held.delete(response));
      // No data until explicitly resumed: the system parser has actually requested this source.
      return;
    }
    let first = 0, last = route.data.length - 1;
    const range = request.headers.range?.match(/^bytes=(\d+)-(\d*)$/);
    if (range) { first = Number(range[1]); if (range[2]) last = Math.min(last, Number(range[2])); }
    if (first > last) { response.writeHead(416, { 'Content-Range': `bytes */${route.data.length}` }).end(); return; }
    const headers = { 'Content-Type': 'video/mp4', 'Accept-Ranges': 'bytes', 'Content-Length': last - first + 1 };
    if (range) headers['Content-Range'] = `bytes ${first}-${last}/${route.data.length}`;
    response.writeHead(range ? 206 : 200, headers);
    if (request.method === 'HEAD') { response.end(); return; }
    const data = route.data.subarray(first, last + 1); route.bodyBytesWritten += data.length; response.end(data);
  });
  server.on('connection', socket => { sockets.add(socket); socket.once('close', () => sockets.delete(socket)); });
  const config = { cases: [] };
  const resultPath = `${cache}/media-probe-smoke-result.json`;
  let deviceTouched = false;
  try {
  await new Promise((resolve, reject) => { server.once('error', reject); server.listen(0, '127.0.0.1', resolve); });
  const port = server.address().port;
  const base = `http://10.0.2.2:${port}`;
  const defaults = { host: '', port: 0, rootPath: '/', remotePath: '', username: '', password: '', fingerprint: '',
    sourceUrl: '', mode: '', controlUrl: '' };
  const fixturePath = process.argv.slice(2).find(arg => !arg.startsWith('--'));
  if (fixturePath && !process.argv.includes('--timings')) {
    const fixture = JSON.parse(fs.readFileSync(fixturePath, 'utf8'));
    const host = execFileSync('wsl.exe', ['-e', 'hostname', '-I'], { encoding: 'utf8', timeout: 20000 }).trim().split(/\s+/)[0];
    assert.match(host, /^\d+\.\d+\.\d+\.\d+$/);
    for (const item of fixture.cases) config.cases.push({ ...defaults, ...item, host, ...expected, label: item.protocol });
    assert.deepEqual(config.cases.map(item => item.protocol).sort(), ['ftp', 'nfs', 'sftp', 'smb']);
  }
  function add(label, data = normal, extra = {}) {
    const id = randomUUID();
    const route = { data, auth: extra.auth || false, requests: 0, denied: 0, bodyBytesWritten: 0, label };
    const item = { ...defaults, protocol: 'http', ...expected, ...extra, label, sourceUrl: `${base}/${id}?keep=query` };
    if (extra.auth) Object.assign(item, { protocol: 'webdav', host: '10.0.2.2', port, remotePath: `/${id}`,
      username: extra.username ?? username, password: extra.password ?? password });
    if (extra.mode === 'cancel' || extra.mode === 'timeout') {
      const controlId = randomUUID(); route.control = { entered: false, held: new Set() };
      controls.set(controlId, route.control); item.controlUrl = `${base}/${controlId}`;
    }
    routes.set(id, route); config.cases.push(item);
  }
  if (process.argv.includes('--timings')) {
    for (const mode of ['both', 'metadata', 'thumbnail']) {
      for (let i = 1; i <= 5; i++) add(`timing-${mode}-${i}`, normal, { auth: true, probeMode: mode });
    }
    add('timing-short-thumbnail', fs.readFileSync(short), { ...reference(short), auth: true, probeMode: 'thumbnail' });
  } else {
  add('http'); add('webdav', normal, { auth: true });
  add('webdav-missing-auth', normal, { auth: true, username: '', password: '', mode: 'unavailable' });
  add('webdav-wrong-auth', normal, { auth: true, password: 'wrong', mode: 'unavailable' });
  add('tail-index', fs.readFileSync(tail), reference(tail));
  add('short-video', fs.readFileSync(short), reference(short));
  add('unsupported', Buffer.from('unsupported media fixture'), { mode: 'unavailable' });
  add('cancel', normal, { mode: 'cancel' }); add('after-cancel');
  add('timeout', normal, { mode: 'timeout' }); add('after-timeout');
  add('webdav-cancel', normal, { auth: true, mode: 'cancel' });
  }
  payload = JSON.stringify(config); assert.ok(Buffer.byteLength(payload) <= 65536);
  const configUrl = `${base}/${token}`;
    assert.match(run('install', '-r', 'entry/build/default/outputs/default/entry-default-signed.hap'), /successfully/);
    deviceTouched = true;
    run('shell', 'aa', 'force-stop', 'com.linkora.player'); run('shell', 'rm', '-f', resultPath);
    if (process.argv.includes('--inert')) {
      run('shell', 'aa', 'start', '-a', 'EntryAbility', '-b', 'com.linkora.player', '--ps', 'linkoraMediaProbeSmokeConfig', configUrl);
      await delay(4000);
      assert.ok(!run('shell', 'cat', resultPath).startsWith('{'), 'Release entry must be inert');
      assert.equal([...routes.values()].reduce((sum, item) => sum + item.requests, 0), 0);
      console.log('PASS Release smoke parameter inert'); return;
    }
    run('shell', 'aa', 'start', '-a', 'EntryAbility', '-b', 'com.linkora.player'); await delay(2000);
    assert.ok(!run('shell', 'cat', resultPath).startsWith('{'), 'ordinary startup must be inert');
    run('shell', 'aa', 'force-stop', 'com.linkora.player');
    run('shell', 'aa', 'start', '-a', 'EntryAbility', '-b', 'com.linkora.player', '--ps', 'linkoraMediaProbeSmokeConfig', configUrl);
    let result;
    const deadline = Date.now() + 180000;
    while (Date.now() < deadline) {
      await delay(1000);
      const text = run('shell', 'cat', resultPath);
      if (!text.startsWith('{')) continue;
      result = JSON.parse(text); if (result.complete) break;
    }
    assert.ok(result?.complete, 'device smoke timeout');
    for (const evidence of result.results) {
      const route = [...routes.values()].find(item => item.label === evidence.label);
      if (route) Object.assign(evidence, { httpRequests: route.requests, httpBodyBytesWritten: route.bodyBytesWritten, authDenied: route.denied, authPresent: route.authPresent, authLength: route.authLength, customAgent: route.customAgent });
    }
    fs.writeFileSync(path.join(out, 'device-result.json'), JSON.stringify(result, null, 2));
    console.log(JSON.stringify(result));
    assert.equal(result.validation, true, 'real URL validation');
    assert.equal(result.results.length, config.cases.length, 'all configured scenarios ran');
    for (const item of config.cases) {
      const evidence = result.results.find(value => value.label === item.label);
      assert.ok(evidence?.passed, `case ${item.label}`);
      if (evidence.file) {
        assert.match(evidence.file, /^media-probe-\d+\.(jpg|webp)$/);
        const file = path.join(out, `${item.label}${path.extname(evidence.file)}`);
        run('file', 'recv', `${cache}/${evidence.file}`, file);
        const rgb = execFileSync(ffmpeg, ['-v', 'error', '-i', file, '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-'], { maxBuffer: 10000000 });
        assert.ok(rgb.length > 0 && rgb.some(value => value !== rgb[0]), `valid image ${item.label}`);
        run('shell', 'rm', '-f', `${cache}/${evidence.file}`);
      }
      if (item.label.includes('auth')) assert.ok(evidence.authDenied > 0);
      if (item.protocol === 'http' || item.protocol === 'webdav') assert.ok(evidence.httpRequests > 0);
      else assert.ok(evidence.readCount > 0 && evidence.readBytes > 0);
      if (item.probeMode) {
        assert.equal(typeof evidence.timings?.prepareMs, 'number');
        assert.equal(typeof evidence.timings?.totalMs, 'number');
        assert.equal(evidence.timings.metadataMs === null, item.probeMode === 'thumbnail');
        assert.equal(evidence.timings.thumbnailMs === null, item.probeMode === 'metadata');
        assert.equal(evidence.metadataReadyMs === null, item.probeMode === 'thumbnail');
        assert.equal(evidence.imageEncodingMs === null, item.probeMode === 'metadata');
      }
    }
    assert.equal(result.passed, true);
    console.log('PASS metadata, frames, authentication, cancel, timeout, actual close and subsequent tasks');
  } finally {
    for (const socket of sockets) socket.destroy();
    await new Promise(resolve => server.close(resolve));
    if (deviceTouched) {
    for (let i = 0; i < config.cases.length; i++) run('shell', 'rm', '-f', `${cache}/media-probe-${i}.jpg`, `${cache}/media-probe-${i}.webp`);
    run('shell', 'rm', '-f', resultPath);
    run('shell', 'aa', 'force-stop', 'com.linkora.player'); run('shell', 'aa', 'start', '-a', 'EntryAbility', '-b', 'com.linkora.player');
    }
  }
}
main().catch(error => {
  if (process.argv.includes('--unit')) console.error(error);
  console.error('FAIL network media probe: see controlled evidence in artifacts/media-probe'); process.exitCode = 1;
});
