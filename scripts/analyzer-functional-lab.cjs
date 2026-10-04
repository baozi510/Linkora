'use strict';
// Host-only owned fixtures, guest WebDAV bridge, and functional evidence. No performance samples.
const fs = require('node:fs'), path = require('node:path'), http = require('node:http');
const net = require('node:net'), crypto = require('node:crypto'), { spawn } = require('node:child_process');
const directory = path.resolve(process.argv[2] || 'artifacts/analyzer-phase2');
const labRoot = path.resolve(process.argv[3] || 'D:/Linkora/test-lab/protocols/data/media');
if (!fs.statSync(labRoot).isDirectory()) throw Error('Existing protocol lab media root required');
const token = crypto.randomUUID(), owned = path.resolve(labRoot, 'LinkoraAnalyzer-' + token);
if (path.dirname(owned) !== labRoot || fs.existsSync(owned)) throw Error('Unsafe owned lab directory');
fs.mkdirSync(owned); const remote = path.join(owned, 'remote.mkv');
fs.copyFileSync(path.join(directory, 'fixtures/long-gop.mkv'), remote);
const hash = file => crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
const remoteHash = hash(remote), records = [], ledger = [], children = new Set(); let current = 'setup';
const endpoint = `http://10.0.2.2:19333/${token}`;
fs.writeFileSync(path.join(directory, 'launch-endpoint.txt'), endpoint);
const keeper = spawn('wsl.exe', ['-d', 'Ubuntu', '--', 'sleep', 'infinity'], { windowsHide: true, stdio: 'ignore' });
const python = 'import socket,sys,threading\ns=socket.create_connection(("127.0.0.1",19081),timeout=10)\ns.settimeout(None)\ndef send():\n try:\n  while data:=sys.stdin.buffer.read1(65536): s.sendall(data)\n  s.shutdown(socket.SHUT_WR)\n except OSError: pass\nthreading.Thread(target=send,daemon=True).start()\ntry:\n while data:=s.recv(65536):\n  sys.stdout.buffer.write(data);sys.stdout.buffer.flush()\nfinally: s.close()';
const save = () => fs.writeFileSync(path.join(directory, 'upstream-range-ledger.json'), JSON.stringify(ledger, null, 2) + '\n');
const bridge = net.createServer(client => {
  const upstream = spawn('wsl.exe', ['-d', 'Ubuntu', '--', 'python3', '-u', '-c', python], { windowsHide: true });
  children.add(upstream); let header = '';
  client.on('data', data => {
    header += data.toString('latin1'); if (header.length > 32768) return client.destroy();
    while (header.includes('\r\n\r\n')) {
      const end = header.indexOf('\r\n\r\n'), request = header.slice(0, end);
      const body = Number(request.match(/\r\nContent-Length:\s*(\d+)/i)?.[1] || 0);
      if (header.length < end + 4 + body) return;
      const method = request.match(/^(GET|HEAD|PROPFIND) /)?.[1];
      if (method) ledger.push({ case: current, method, ownFixture: request.split('\r\n')[0].includes('/LinkoraAnalyzer-' + token + '/remote.mkv'),
        range: request.match(/\r\nRange:\s*([^\r\n]+)/i)?.[1] || null });
      header = header.slice(end + 4 + body); save();
    }
  });
  client.pipe(upstream.stdin); upstream.stdout.pipe(client);
  upstream.stdin.on('error', () => client.destroy()); upstream.stderr.on('data', () => {});
  upstream.on('error', () => client.destroy()); upstream.on('close', () => { children.delete(upstream); client.destroy(); });
  client.on('error', () => upstream.kill()); client.on('close', () => upstream.kill());
});
const truth = JSON.parse(fs.readFileSync(path.join(directory, 'fixture-truth.json')));
const config = { fixtures: truth.fixtures.map(item => { const v = item.truth.streams.find(s => s.codec_type === 'video');
  return { name: item.name, url: endpoint + '/' + item.name, durationMs: Math.round(Number(item.truth.format.duration) * 1000), width: v.width, height: v.height }; }),
  host: '10.0.2.2', port: 19334, remotePath: '/' + path.basename(owned) + '/remote.mkv', remoteSize: fs.statSync(remote).size, corrupt: endpoint + '/corrupt.mp4' };
const server = http.createServer((request, response) => {
  if (request.url === '/' + token + '/stop' && request.method === 'POST') {
    response.end('stopping owned helper'); response.on('finish', () => { close(); process.exit(0); }); return;
  }
  if (request.url === '/' + token && request.method === 'GET') { response.setHeader('Content-Type', 'application/json'); return response.end(JSON.stringify(config)); }
  if (request.url === '/' + token + '/evidence' && request.method === 'POST') {
    let body = ''; request.on('data', data => { body += data; if (body.length > 131072) request.destroy(); });
    request.on('end', () => { try {
      const record = JSON.parse(body);
      if (typeof record.case !== 'string' || typeof record.status !== 'string' || /https?:\/\/|elapsedMs|median|p95|cpu|gpu/i.test(body)) throw Error('Non-functional or unsafe evidence');
      if (record.status === 'START') current = record.case + (record.engine ? '-' + record.engine : '');
      records.push(record); fs.writeFileSync(path.join(directory, 'functional-results.ndjson'), records.map(x => JSON.stringify(x)).join('\n') + '\n');
      response.end('ok');
      if (record.case === 'summary') console.log(`Functional matrix finished: ${record.passed} passed, ${record.failed} failed`);
    } catch (_) { response.statusCode = 400; response.end('invalid evidence'); } }); return;
  }
  const name = request.url?.slice(('/' + token + '/').length);
  if (!request.url?.startsWith('/' + token + '/') || !(truth.fixtures.some(f => f.name === name) || name === 'corrupt.mp4')) { response.statusCode = 404; return response.end(); }
  const file = name === 'corrupt.mp4' ? null : path.join(directory, 'fixtures', name);
  const size = file ? fs.statSync(file).size : 4096; let start = 0, end = size - 1;
  if (request.headers.range) {
    const range = /^bytes=(\d+)-(\d*)$/.exec(request.headers.range);
    if (!range || Number(range[1]) >= size) { response.statusCode = 416; response.setHeader('Content-Range', `bytes */${size}`); return response.end(); }
    start = Number(range[1]); end = range[2] ? Math.min(size - 1, Number(range[2])) : size - 1;
    response.statusCode = 206; response.setHeader('Content-Range', `bytes ${start}-${end}/${size}`);
  }
  response.setHeader('Accept-Ranges', 'bytes'); response.setHeader('Content-Length', end - start + 1);
  if (request.method === 'HEAD') return response.end();
  if (file) fs.createReadStream(file, { start, end }).pipe(response); else response.end(Buffer.alloc(end - start + 1, 65));
});
bridge.listen(19334, '0.0.0.0'); server.listen(19333, '0.0.0.0', () => console.log('Functional fixture services ready; endpoint saved in ignored artifact'));
function close() {
  for (const child of children) child.kill(); keeper.kill(); server.close(); bridge.close(); save();
  const removable = fs.existsSync(remote) && hash(remote) === remoteHash && fs.readdirSync(owned).length === 1 && path.dirname(path.resolve(owned)) === labRoot;
  if (removable) { fs.unlinkSync(remote); fs.rmdirSync(owned); }
  fs.writeFileSync(path.join(directory, 'lab-cleanup.json'), JSON.stringify({ ownedFixtureRemoved: removable, sharedLabServicesStopped: false }, null, 2) + '\n');
}
process.on('SIGINT', () => { close(); process.exit(0); }); process.on('SIGTERM', () => { close(); process.exit(0); });
