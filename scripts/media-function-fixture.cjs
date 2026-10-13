'use strict';
// Task-owned loopback fixture and bounded sanitized result transport.
const fs = require('node:fs'), path = require('node:path'), http = require('node:http'), crypto = require('node:crypto');
const root = path.resolve(process.argv[2]), token = crypto.randomUUID();
const prefix = '/' + token, endpoint = 'http://10.0.2.2:19333' + prefix;
fs.writeFileSync(path.join(root, 'endpoint.PRIVATE.txt'), endpoint);
const fixture = path.join(root, 'owned-h264.mp4'), size = fs.statSync(fixture).size;
const server = http.createServer((req, res) => {
  if (req.method === 'POST' && req.url === prefix + '/shutdown') {
    res.end('closed'); server.close(); return;
  }
  if (req.method === 'POST' && req.url === prefix + '/evidence') {
    let body = ''; req.on('data', part => { body += part; if (body.length > 32768) req.destroy(); });
    req.on('end', () => {
      try {
        const record = JSON.parse(body);
        const allowed = ['case','status','code','width','height','bytes','timeMs','pixelHash','video','audio','durationMs','frames','position','seekPosition','firstFrame','states'];
        if (Object.keys(record).some(key => !allowed.includes(key))) throw Error('unapproved field');
        fs.appendFileSync(path.join(root, 'evidence.PRIVATE.jsonl'), JSON.stringify(record) + '\n'); res.end('ok');
      } catch (_) { res.statusCode = 400; res.end(); }
    }); return;
  }
  if (!['GET','HEAD'].includes(req.method)) { res.statusCode = 405; res.end(); return; }
  if (req.url === prefix) { res.setHeader('Content-Type', 'application/json'); res.end(JSON.stringify({systemOnly:fs.existsSync(path.join(root,'system-only.PRIVATE.flag'))})); return; }
  if (req.url !== prefix + '/mp4') { res.statusCode = 404; res.end(); return; }
  const match = /^bytes=(\d+)-(\d*)$/.exec(req.headers.range || '');
  const start = match ? Number(match[1]) : 0, end = match && match[2] ? Math.min(Number(match[2]), size - 1) : size - 1;
  if (start >= size || end < start) { res.statusCode = 416; res.setHeader('Content-Range', 'bytes */' + size); res.end(); return; }
  res.statusCode = match ? 206 : 200;
  res.setHeader('Content-Type', 'video/mp4'); res.setHeader('Accept-Ranges','bytes'); res.setHeader('Content-Length',end-start+1);
  if (match) res.setHeader('Content-Range', `bytes ${start}-${end}/${size}`);
  if (req.method === 'HEAD') res.end(); else fs.createReadStream(fixture,{start,end}).pipe(res);
});
server.listen(19333, '127.0.0.1', () => console.log('Owned fixture ready'));
process.on('SIGINT', () => server.close()); process.on('SIGTERM', () => server.close());
