// Run after installing a Debug HAP: node scripts/check-stream-ui.cjs
const assert = require('node:assert/strict');
const { execFile } = require('node:child_process');
const { promisify } = require('node:util');
const fs = require('node:fs');
const path = require('node:path');
const http = require('node:http');
const run = promisify(execFile);
const root = path.resolve(__dirname, '..');
const hdc = 'C:/Program Files/Huawei/DevEco Studio/sdk/default/openharmony/toolchains/hdc.exe';
const target = process.env.LINKORA_DEVICE || '127.0.0.1:5555';
const name = 'Stream regression API20';
const fixture = fs.readFileSync(path.join(root, 'test-lab/media/album_a_video_01.mp4'));
const delay = ms => new Promise(resolve => setTimeout(resolve, ms));
const call = (...args) => run(hdc, ['-t', target, ...args]);

async function nodes() {
  const remote = '/data/local/tmp/linkora-stream-check.json';
  const local = path.join(root, 'artifacts/stream-check.json');
  await call('shell', 'uitest', 'dumpLayout', '-p', remote);
  await call('file', 'recv', remote, local);
  const result = [];
  function walk(node) {
    if (node.attributes?.visible === 'true') result.push(node.attributes);
    for (const child of node.children || []) walk(child);
  }
  walk(JSON.parse(fs.readFileSync(local, 'utf8')));
  return result;
}

async function find(predicate, timeout = 12000) {
  const deadline = Date.now() + timeout;
  do {
    const result = (await nodes()).filter(predicate).at(-1);
    if (result) return result;
    await delay(200);
  } while (Date.now() < deadline);
  throw Error('Expected UI element was not found: ' + predicate);
}

function center(node) {
  const [x1, y1, x2, y2] = node.bounds.match(/\d+/g).map(Number);
  return [String(Math.round((x1 + x2) / 2)), String(Math.round((y1 + y2) / 2))];
}
const text = value => node => node.text === value;
const id = value => node => node.id === value || node.key === value;
const glyphs = { '添加串流链接': '\uE145', '添加服务器': '\uE145', '播放记录': '\uEFD6' };
const label = value => node => node.text === value || node.text === glyphs[value] ||
  node.accessibilityText === value || node.description === value;
async function click(predicate) {
  await call('shell', 'uitest', 'uiInput', 'click', ...center(await find(predicate)));
  await delay(200);
}
async function input(field, value) {
  await click(id(field));
  await call('shell', 'uitest', 'uiInput', 'keyEvent', '2072', '2017');
  await call('shell', 'uitest', 'uiInput', 'keyEvent', '2055');
  const quoted = "'" + value.replaceAll("'", "'\\''") + "'";
  await call('shell', 'uitest uiInput text ' + quoted);
  await delay(250);
  await back();
}
async function menuFor(title) {
  const row = await find(text(title));
  const y = Number(center(row)[1]);
  const menus = (await nodes()).filter(text('\uE5D4'));
  menus.sort((a, b) => Math.abs(Number(center(a)[1]) - y) - Math.abs(Number(center(b)[1]) - y));
  assert(menus.length > 0, 'Expected a stream menu');
  await call('shell', 'uitest', 'uiInput', 'click', ...center(menus[0]));
  await delay(250);
}
async function back() {
  await call('shell', 'uitest', 'uiInput', 'keyEvent', 'Back');
  await delay(250);
}
async function coldStart() {
  await call('shell', 'aa', 'force-stop', 'com.linkora.player');
  await call('shell', 'aa', 'start', '-a', 'EntryAbility', '-b', 'com.linkora.player');
  await find(text('串流'));
}

async function main() {
  let requests = 0;
  const server = http.createServer((req, res) => {
    requests++;
    if (!req.url.startsWith('/stream-check.mp4')) {
      res.writeHead(404); res.end(); return;
    }
    const range = /^bytes=(\d+)-(\d*)$/.exec(req.headers.range || '');
    const start = range ? Number(range[1]) : 0;
    const end = range && range[2] ? Math.min(Number(range[2]), fixture.length - 1) : fixture.length - 1;
    const headers = { 'Content-Type': 'video/mp4', 'Accept-Ranges': 'bytes',
      'Content-Length': end - start + 1 };
    if (range) headers['Content-Range'] = `bytes ${start}-${end}/${fixture.length}`;
    res.writeHead(range ? 206 : 200, headers);
    res.end(req.method === 'HEAD' ? undefined : fixture.subarray(start, end + 1));
  });
  await new Promise(resolve => server.listen(0, '0.0.0.0', resolve));
  const url = `http://10.0.2.2:${server.address().port}/stream-check.mp4?token=probe%2Ftest&part=1`;
  try {
    await coldStart();
    await click(text('串流'));
    for (let count = 0; count < 5; count++) {
      const previous = (await nodes()).find(node => node.text === name || node.text === name + ' edited');
      if (!previous) break;
      await menuFor(previous.text);
      await click(text('删除'));
      await click(text('删除'));
    }
    await click(label('添加串流链接'));
    await input('stream-name', name);
    await input('stream-address', 'smb://example.com/video.mp4');
    await click(text('测试连接'));
    const invalid = await find(id('stream-check-result'));
    assert.match(invalid.text, /HTTP|HTTPS/);
    await input('stream-address', url);
    await click(text('测试连接'));
    const inspected = await find(node => node.text?.startsWith('连接成功 ·'), 22000);
    assert.match(inspected.text, /0:02/);
    assert.match(inspected.text, /640 × 360/);
    console.log('PASS: URL validation, connection and API20 metadata inspection');
    await input('stream-address', url.replace('/stream-check.mp4', '/missing.mp4'));
    await click(text('测试连接'));
    await find(node => node.text?.startsWith('媒体不存在：'));
    await input('stream-address', url);
    await click(text('保存'));
    await find(text(name));
    const requestsAfterInspection = requests;
    await click(text('网络'));
    assert.equal((await nodes()).some(text(name)), false);
    await click(label('添加服务器'));
    const protocols = (await nodes()).map(node => node.text);
    assert(protocols.includes('WebDAV'));
    assert.equal(protocols.some(value => /^HTTP/.test(value)), false);
    await back();
    console.log('PASS: streams are excluded from network servers and protocol picker');
    await click(text('串流'));
    await menuFor(name);
    await click(text('编辑'));
    assert.equal((await find(id('stream-address'))).text, url);
    await input('stream-name', name + ' edited');
    await click(text('保存'));
    await coldStart();
    await click(text('串流'));
    assert.equal(requests, requestsAfterInspection, 'List loads must not probe saved streams');
    await click(text(name + ' edited'));
    await find(node => node.text === '0:02' || node.text?.includes('640'), 18000);
    assert.equal((await nodes()).some(text('无法播放')), false);
    await back();
    await click(label('播放记录'));
    await find(text(name + ' edited'));
    console.log('PASS: query retention, edit persistence, playback and history');
    await click(text('串流'));
    await menuFor(name + ' edited');
    await click(text('删除'));
    await click(text('删除'));
    assert.equal((await nodes()).some(text(name + ' edited')), false);
    await coldStart();
    await click(text('串流'));
    assert.equal((await nodes()).some(text(name + ' edited')), false);
    console.log('PASS: delete persists across cold start');
    await call('shell', 'uitest', 'screenCap', '-p', '/data/local/tmp/stream-final.png');
    await call('file', 'recv', '/data/local/tmp/stream-final.png', path.join(root, 'artifacts/stream-final.png'));
  } finally {
    server.closeAllConnections();
    await new Promise(resolve => server.close(resolve));
  }
}
main().catch(error => { console.error(error); process.exitCode = 1; });
