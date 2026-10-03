'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const http = require('node:http');
const { promisify } = require('node:util');
const { execFile } = require('node:child_process');
const exec = promisify(execFile);
const root = path.resolve(__dirname, '..');
const out = path.join(root, 'artifacts/network-media-persistence');
const hdc = 'C:/Program Files/Huawei/DevEco Studio/sdk/default/openharmony/toolchains/hdc.exe';
const device = process.env.LINKORA_HDC_TARGET || '127.0.0.1:5555';
const disabled = process.argv.includes('--disabled');
const combinedDisplay = process.argv.includes('--combined-display') && !disabled;
let holdMedia = combinedDisplay;
const heldMedia = [];
const serverName = '网络媒体接入验证 ' + Date.now().toString().slice(-6);
const sample = fs.readFileSync(process.env.LINKORA_MEDIA_SAMPLE || 'D:/Linkora/test-lab/protocols/data/media/sample-h264.mp4');
const call = (...args) => exec(hdc, ['-t', device, ...args], { cwd: root, maxBuffer: 8000000 });
const delay = ms => new Promise(resolve => setTimeout(resolve, ms));
let saved = false, initialGrid = false, layoutRead = false, cacheBefore = [], blocked = 0, disconnected = 0;
let rootListings = 0;
const reads = new Map(), sockets = new Set();
function response(p, name, directory = false) {
  return '<D:response><D:href>' + p + '</D:href><D:propstat><D:prop><D:displayname>' + name +
    '</D:displayname><D:resourcetype>' + (directory ? '<D:collection/>' : '') +
    '</D:resourcetype><D:getcontentlength>' + sample.length +
    '</D:getcontentlength><D:getlastmodified>Wed, 30 Sep 2026 00:00:00 GMT</D:getlastmodified>' +
    '</D:prop><D:status>HTTP/1.1 200 OK</D:status></D:propstat></D:response>';
}
const host = http.createServer((req, res) => {
  const p = new URL(req.url, 'http://localhost').pathname;
  if (req.method === 'PROPFIND') {
    if (p === '/') rootListings++;
    let items = response(p, 'self', true);
    if (p === '/') {
      items += response('/sub/', '子目录', true) + response('/slow/', '取消测试', true);
      for (let i = 0; i < 50; i++) { const name = 'video-' + i.toString().padStart(2, '0') + '.mp4'; items += response('/' + name, name); }
      items += response('/notes.srt', 'notes.srt') + response('/z-broken.mp4', 'z-broken.mp4');
    } else if (p === '/sub/') items += response('/sub/nested.mp4', 'nested.mp4');
    else if (p === '/slow/') items += response('/slow/slow.mp4', 'slow.mp4');
    res.writeHead(207, { 'Content-Type': 'application/xml' }); res.end('<D:multistatus xmlns:D="DAV:">' + items + '</D:multistatus>'); return;
  }
  reads.set(p, (reads.get(p) || 0) + 1);
  if (p === '/z-broken.mp4') { res.writeHead(403); res.end(); return; }
  if (req.method === 'HEAD') { res.writeHead(200, { 'Content-Length': sample.length }); res.end(); return; }
  if (p === '/slow/slow.mp4') {
    blocked++; req.socket.once('close', () => { disconnected++; }); return;
  }
  const match = /^bytes=(\d+)-(\d+)$/.exec(req.headers.range || '');
  if (!match) { res.writeHead(400); res.end(); return; }
  const start = Number(match[1]), end = Math.min(Number(match[2]), sample.length - 1);
  res.writeHead(206, { 'Content-Length': end - start + 1, 'Content-Range': 'bytes ' + start + '-' + end + '/' + sample.length, 'Content-Type': 'video/mp4' });
  const send = () => { if (!res.destroyed) res.end(sample.subarray(start, end + 1)); };
  if (holdMedia) heldMedia.push(send); else send();
});
host.on('connection', socket => { sockets.add(socket); socket.on('close', () => sockets.delete(socket)); });
async function nodes() {
  const remote = '/data/local/tmp/linkora-network-media-ui.json';
  await call('shell', 'uitest', 'dumpLayout', '-p', remote);
  const local = path.join(out, 'ui-current.json'); await call('file', 'recv', remote, local);
  const result = [];
  function walk(node) { if (node.attributes?.visible === 'true') result.push(node.attributes); for (const child of node.children || []) walk(child); }
  walk(JSON.parse(fs.readFileSync(local, 'utf8'))); return result;
}
const glyphs = { '添加服务器': '\uE145', '切换到列表布局': '\uE8EF', '切换到网格布局': '\uE9B0' };
const text = value => Object.assign(n => n.text === value, { debug: value });
const label = value => Object.assign(n => n.text === value || n.text === glyphs[value] ||
  n.accessibilityText === value || n.description === value, { debug: value });
const id = value => Object.assign(n => n.id === value || n.key === value, { debug: value });
function center(n) { const [a, b, c, d] = n.bounds.match(/\d+/g).map(Number); return [String(Math.round((a + c) / 2)), String(Math.round((b + d) / 2))]; }
async function find(predicate, timeout = 12000) {
  const end = Date.now() + timeout;
  do { const found = (await nodes()).filter(predicate).at(-1); if (found) return found; await delay(200); } while (Date.now() < end);
  throw Error('Expected network media UI element missing: ' + predicate.debug);
}
async function click(predicate) { await call('shell', 'uitest', 'uiInput', 'click', ...center(await find(predicate))); await delay(250); }
async function back() { await call('shell', 'uitest', 'uiInput', 'keyEvent', 'Back'); await delay(300); }
async function input(field, value) {
  await click(id(field));
  await call('shell', 'uitest', 'uiInput', 'keyEvent', '2072', '2017');
  await call('shell', 'uitest', 'uiInput', 'keyEvent', '2055');
  await call('shell', "uitest uiInput text '" + value.replaceAll("'", "'\\''") + "'");
  await back();
}
async function start() { await call('shell', 'aa', 'force-stop', 'com.linkora.player'); await call('shell', 'aa', 'start', '-a', 'EntryAbility', '-b', 'com.linkora.player'); await find(text('网络')); }
async function network() { await click(text('网络')); await find(label('添加服务器')); }
async function listing() {
  await click(text(serverName)); await find(text('video-00.mp4'));
  const grid = (await nodes()).some(label('切换到列表布局'));
  if (!layoutRead) { initialGrid = grid; layoutRead = true; }
  if (grid) await click(label('切换到列表布局'));
  await find(label('切换到网格布局'));
}
async function screenshot(name) {
  const remote = '/data/local/tmp/linkora-network-media.jpeg';
  await call('shell', 'snapshot_display', '-f', remote); await call('file', 'recv', remote, path.join(out, name + '.jpg'));
}
async function cacheFiles() {
  const r = await call('shell', 'ls', '-1', '/data/app/el2/100/base/com.linkora.player/haps/entry/files/network-media');
  return r.stdout.split(/\r?\n/).filter(n => /^[a-f0-9]{64}\.(webp|jpg)$/.test(n));
}
async function deleteServer() {
  await start(); await network();
  const card = await find(text(serverName));
  await call('shell', 'uitest', 'uiInput', 'longClick', ...center(card));
  await click(text('删除')); await find(text('删除服务器')); await click(text('删除'));
}
async function main() {
  fs.mkdirSync(out, { recursive: true });
  await new Promise(resolve => host.listen(0, '127.0.0.1', resolve));
  try {
    const port = host.address().port;
    const installed = await call('install', '-r', 'entry/build/default/outputs/default/entry-default-signed.hap');
    assert.match(installed.stdout, /successfully|success/i, 'new package actually installed');
    assert.doesNotMatch(installed.stdout, /failed|error:/i, 'hdc may return exit 0 on installation failure');
    await start(); await network();
    cacheBefore = await cacheFiles();
    if (!disabled && cacheBefore.length === 0) {
      await call('shell', 'rmdir', '/data/app/el2/100/base/com.linkora.player/haps/entry/files/network-media').catch(() => {});
    }
    await click(label('添加服务器')); await click(text('WebDAV'));
    await input('network-form-name', serverName);
    await input('network-form-host', 'http://10.0.2.2:' + port);
    await click(text('保存')); await find(text(serverName)); saved = true;
    await listing();
    if (disabled) {
      await delay(2500); assert.equal(reads.size, 0, 'disabled integration makes no file requests');
      assert.ok(!(await nodes()).some(text('0:10'))); await screenshot('disabled-list');
      console.log('PASS disabled media integration: basic network list, no extraction requests');
      return;
    }
    if (combinedDisplay) {
      const pendingNodes = await nodes();
      assert.ok(pendingNodes.some(text('968 KB')), 'file size visible while media is pending');
      assert.ok(pendingNodes.some(text('2026/09/30')), 'modified date visible while media is pending');
      assert.ok(!pendingNodes.some(text('0:10')) && !pendingNodes.some(text('360P')),
        'pending media only shows basic size and date');
      await screenshot('pending-basic-info');
      holdMedia = false; heldMedia.splice(0).forEach(send => send());
    }
    await delay(2500); await screenshot('before-metadata-check');
    await find(text('0:10'), 18000); await find(text('360P'));
    await screenshot('enabled-list');
    const visibleReads = reads.size;
    assert.ok(visibleReads > 0 && visibleReads < 50, 'only visible subset requested');
    assert.ok(!reads.has('/notes.srt'), 'subtitle not extracted');
    assert.ok(!reads.has('/sub/'), 'folder not extracted');
    assert.ok((await cacheFiles()).length > cacheBefore.length, 'persistent thumbnail file written');
    const webp = (await cacheFiles()).find(n => n.endsWith('.webp') && !cacheBefore.includes(n));
    assert.ok(webp, 'real system encoded WebP');
    await call('file', 'recv', '/data/app/el2/100/base/com.linkora.player/haps/entry/files/network-media/' + webp,
      path.join(out, 'thumbnail.webp'));
    const bytes = fs.readFileSync(path.join(out, 'thumbnail.webp'));
    assert.equal(bytes.subarray(0, 4).toString(), 'RIFF'); assert.equal(bytes.subarray(8, 12).toString(), 'WEBP');
    await back(); const beforeReenter = [...reads.values()].reduce((a, b) => a + b, 0);
    await listing(); await find(text('0:10')); await delay(500);
    assert.equal([...reads.values()].reduce((a, b) => a + b, 0), beforeReenter, 'reentry cache hit');
    await start(); await network(); const beforeCold = [...reads.values()].reduce((a, b) => a + b, 0);
    await listing(); await find(text('0:10')); await delay(500);
    assert.equal([...reads.values()].reduce((a, b) => a + b, 0), beforeCold, 'cold cache hit');
    const beforeRefresh = rootListings;
    const beforeRefreshReads = [...reads.values()].reduce((a, b) => a + b, 0);
    await call('shell', 'uitest', 'uiInput', 'swipe', '550', '500', '550', '1300', '600');
    const refreshDeadline = Date.now() + 18000;
    while (rootListings === beforeRefresh && Date.now() < refreshDeadline) await delay(200);
    assert.ok(rootListings > beforeRefresh, 'pull refresh reloads the unchanged directory');
    await find(text('0:10')); await find(text('360P')); await delay(1000);
    assert.equal([...reads.values()].reduce((a, b) => a + b, 0), beforeRefreshReads, 'refresh reuses media cache without video requests');
    await find(text('0:10')); await find(text('360P')); await screenshot('enabled-refreshed-list');
    await click(label('切换到网格布局')); await screenshot('enabled-grid');
    assert.ok(!(await nodes()).some(text('360P')), 'grid has no metadata chips');
    await click(text('子目录')); await find(text('nested.mp4')); await back();
    await click(text('取消测试')); await find(text('slow.mp4'));
    const enteredDeadline = Date.now() + 5000;
    while (!blocked && Date.now() < enteredDeadline) await delay(100);
    assert.ok(blocked > 0, 'inflight request entered');
    await back();
    assert.ok(!(await nodes()).some(text('slow.mp4')), 'old directory no longer displayed');
    const closeStarted = Date.now(), closingDeadline = closeStarted + 11000;
    while (!disconnected && Date.now() < closingDeadline) await delay(100);
    assert.ok(disconnected > 0, 'leave directory eventually closes native read');
    await click(label('切换到列表布局'));
    console.log('PASS actual network list/grid, real thumbnail values, visible subset, persistent cache, directory switch and inflight cancel');
    fs.writeFileSync(path.join(out, 'ui-evidence.json'), JSON.stringify({ passed: true, visibleReads, totalVideos: 50,
      blocked, disconnected, cancelCleanupMs: Date.now() - closeStarted, cacheHit: true, coldCacheHit: true, unchangedRefresh: true,
      refreshCacheHit: true, refreshVideoRequests: 0, webp: true, persistentDirectory: true,
      pendingBasicInfo: combinedDisplay }));
  } catch (error) {
    fs.writeFileSync(path.join(out, 'ui-failure-evidence.json'), JSON.stringify({ message: error.message, reads: [...reads], blocked, disconnected }));
    if (fs.existsSync(path.join(out, 'ui-current.json'))) fs.copyFileSync(path.join(out, 'ui-current.json'), path.join(out, 'ui-failed.json'));
    throw error;
  } finally {
    let cleanupFailed = false;
    if (saved) { try {
      if (layoutRead && initialGrid) { await start(); await network(); await listing(); await click(label('切换到网格布局')); }
      await deleteServer();
      assert.deepEqual((await cacheFiles()).sort(), cacheBefore.sort(), 'server removal cleans its persistent images');
    } catch (_) { console.error('Test server cleanup needs attention'); cleanupFailed = true; } }
    for (const name of (await cacheFiles().catch(() => [])).filter(n => !cacheBefore.includes(n))) {
      await call('shell', 'rm', '-f', '/data/app/el2/100/base/com.linkora.player/haps/entry/files/network-media/' + name);
    }
    for (const socket of sockets) socket.destroy();
    await new Promise(resolve => host.close(resolve));
    await call('shell', 'rm', '-f', '/data/local/tmp/linkora-network-media-ui.json', '/data/local/tmp/linkora-network-media.jpeg');
    await start();
    if (cleanupFailed) throw Error('Temporary test server cleanup failed');
  }
}
main().catch(error => { console.error(error.message); process.exitCode = 1; });
