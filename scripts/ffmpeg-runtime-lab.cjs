'use strict';
// Host-only Phase1B fixture/config service and sanitized guest-WebDAV Range ledger.
const fs = require('node:fs'), path = require('node:path'), http = require('node:http');
const net = require('node:net'), crypto = require('node:crypto'), { spawn } = require('node:child_process');
const directory = path.resolve(process.argv[2] || 'artifacts/ffmpeg-phase1b');
const token = crypto.randomUUID(), ledger = [], connections = new Set();
// Keep the existing lab distro warm: cold WSL startup exceeds the provider's
// eight-second HEAD deadline. No app timeout or provider is changed.
const keeper = spawn('wsl.exe', ['-d', 'Ubuntu', '--', 'sleep', 'infinity'], { windowsHide: true, stdio: 'ignore' });
const save = () => fs.writeFileSync(path.join(directory, 'upstream-range-ledger.json'), JSON.stringify(ledger, null, 2));
const endpoint = `http://10.0.2.2:19333/${token}`;
fs.writeFileSync(path.join(directory, 'launch-endpoint.txt'), endpoint);
const python = 'import socket,sys,threading\ns=socket.create_connection(("127.0.0.1",19081),timeout=10)\ns.settimeout(None)\ndef send():\n try:\n  while data:=sys.stdin.buffer.read1(65536): s.sendall(data)\n  s.shutdown(socket.SHUT_WR)\n except OSError: pass\nthreading.Thread(target=send,daemon=True).start()\ntry:\n while data:=s.recv(65536):\n  sys.stdout.buffer.write(data);sys.stdout.buffer.flush()\nfinally: s.close()';
const bridge = net.createServer(client => {
  const upstream = spawn('wsl.exe', ['-d', 'Ubuntu', '--', 'python3', '-u', '-c', python], { windowsHide: true });
  connections.add(upstream);
  let header = '', entry;
  client.on('data', data => {
    header += data.toString('latin1');
    if (header.length > 16384) return client.destroy();
    while (header.includes('\r\n\r\n')) {
      const end = header.indexOf('\r\n\r\n'), request = header.slice(0, end);
      const body = Number(request.match(/\r\nContent-Length:\s*(\d+)/i)?.[1] || 0);
      if (header.length < end + 4 + body) return;
      const method = request.match(/^(GET|HEAD|PROPFIND) /)?.[1];
      if (method) {
        entry = { time: Date.now(), method, ownFixture: request.split('\r\n')[0].includes('/LinkoraFfmpegPhase1B/remote.mkv'),
          range: request.match(/\r\nRange:\s*([^\r\n]+)/i)?.[1] || null, wireBytes: 0 };
        ledger.push(entry); save();
      }
      header = header.slice(end + 4 + body); // No headers/config written to evidence.
    }
  });
  client.pipe(upstream.stdin); upstream.stdout.pipe(client);
  upstream.stdout.on('data', data => { if (entry) { entry.wireBytes += data.length; save(); } });
  upstream.stdin.on('error', () => client.destroy());
  upstream.stderr.on('data', () => {});
  upstream.on('error', () => client.destroy());
  upstream.on('close', () => { connections.delete(upstream); client.destroy(); });
  client.on('error', () => upstream.kill()); client.on('close', () => upstream.kill());
});
const server = http.createServer((request, response) => {
  if (request.url === `/${token}`) {
    response.setHeader('Content-Type', 'application/json');
    return response.end(JSON.stringify({ mp4: endpoint + '/mp4', mkv: endpoint + '/mkv', host: '10.0.2.2', port: 19334,
      remotePath: '/LinkoraFfmpegPhase1B/remote.mkv', username: '', password: '' }));
  }
  const suffix = request.url === `/${token}/mp4` ? 'mp4' : request.url === `/${token}/mkv` ? 'mkv' : '';
  if (!suffix) { response.statusCode = 404; return response.end(); }
  const fixture = path.join(directory, 'fixtures', 'local.' + suffix);
  response.setHeader('Content-Length', fs.statSync(fixture).size);
  fs.createReadStream(fixture).pipe(response);
});
bridge.listen(19334, '0.0.0.0');
server.listen(19333, '0.0.0.0', () => console.log('Phase1B fixture services ready; endpoint stored in ignored artifact'));
function close() { for (const child of connections) child.kill(); keeper.kill(); server.close(); bridge.close(); save(); }
process.on('SIGINT', () => { close(); process.exit(0); });
process.on('SIGTERM', () => { close(); process.exit(0); });
