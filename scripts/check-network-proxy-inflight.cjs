'use strict';
// Controlled peers prove native I/O has started before cancellation; no timing-based sleeps.
const fs = require('node:fs'), net = require('node:net'), http = require('node:http');
const { randomUUID } = require('node:crypto');
const { spawn } = require('node:child_process');
const assert = require('node:assert/strict');
const fixturePath = process.argv[2];
const servers = [], sockets = new Set(), controls = new Map();
async function listen(server) {
  await new Promise((resolve, reject) => { server.once('error', reject); server.listen(0, '127.0.0.1', resolve); });
  servers.push(server); return server.address().port;
}
function state() {
  return { armed: false, entered: false, waiting: [], held: [], resume() {
    this.armed = false;
    for (const [socket, bytes] of this.held.splice(0)) if (!socket.destroyed) socket.write(bytes);
  }, enter() {
    this.entered = true;
    for (const response of this.waiting.splice(0)) response.writeHead(200).end();
  } };
}
function track(socket) { sockets.add(socket); socket.on('error', () => socket.destroy()); socket.on('close', () => sockets.delete(socket)); }
async function relay(host, port, control, ftp = false) {
  return listen(net.createServer(left => {
    const right = net.connect(port, host); track(left); track(right);
    let reply = '';
    left.on('data', bytes => {
      right.write(bytes);
      if (control?.armed && (!ftp || bytes.toString().includes('RETR '))) control.enter();
    });
    right.on('data', async bytes => {
      if (ftp) {
        reply += bytes.toString();
        const split = reply.lastIndexOf('\r\n');
        if (split < 0) return;
        let complete = reply.slice(0, split + 2); reply = reply.slice(split + 2);
        const match = complete.match(/229[^\r\n]*\(\|\|\|(\d+)\|\)/);
        if (match) {
          const passivePort = await relay(host, Number(match[1]));
          complete = complete.replace(`|||${match[1]}|`, `|||${passivePort}|`);
        }
        bytes = Buffer.from(complete);
      }
      if (control?.armed && control.entered) control.held.push([left, bytes]); else left.write(bytes);
    });
    const drop = () => { left.destroy(); right.destroy(); };
    left.on('close', drop); right.on('close', drop);
  }));
}
async function main() {
  const controllerPort = await listen(http.createServer((request, response) => {
    const [token, action] = request.url.slice(1).split('/');
    const control = controls.get(token);
    if (!control) return response.writeHead(404).end();
    if (action === 'arm') { control.armed = true; control.entered = false; }
    else if (action === 'entered' && !control.entered) { control.waiting.push(response); return; }
    else if (action === 'resume') control.resume();
    else if (action !== 'entered') return response.writeHead(404).end();
    response.writeHead(200).end();
  }));
  function register(control) {
    const token = randomUUID(); controls.set(token, control);
    return `http://10.0.2.2:${controllerPort}/${token}`;
  }
  const config = fixturePath ? JSON.parse(fs.readFileSync(fixturePath)) : { cases: [] };
  for (const fixture of config.cases) {
    const control = state(); fixture.cancellationControlUrl = register(control);
    fixture.port = await relay(fixture.host, fixture.port, control, fixture.protocol === 'ftp');
    fixture.host = '10.0.2.2';
  }
  config.ftpControlChecks = [];
  for (const mode of ['cancel', 'deadline', 'size']) {
    const control = state(); const timers = new Set();
    const stop = () => { for (const timer of timers) clearInterval(timer); timers.clear(); };
    control.resume = () => { stop(); for (const socket of control.peers) socket.destroy(); };
    control.peers = new Set();
    const port = await listen(net.createServer(socket => {
      track(socket); control.peers.add(socket); socket.write('220 test\r\n');
      let input = '';
      socket.on('data', bytes => {
        input += bytes.toString();
        for (;;) {
          const end = input.indexOf('\r\n'); if (end < 0) break;
          const command = input.slice(0, end).split(' ')[0]; input = input.slice(end + 2);
          if (command === 'USER') socket.write('230 ok\r\n');
          else if (command === 'TYPE') socket.write('200 ok\r\n');
          else if (command === 'SIZE') socket.write('213 1024\r\n');
          else if (command === 'EPSV') {
            control.enter(); socket.write('229-unfinished\r\n');
            if (mode === 'size') socket.write('x'.repeat(1024).concat('\r\n').repeat(70));
            const timer = setInterval(() => { if (!socket.destroyed) socket.write('x\r\n'); }, 20);
            timers.add(timer);
          }
          else if (command === 'PASV') socket.write('500 unsupported\r\n');
          else if (command === 'QUIT') socket.end();
        }
      });
      socket.on('close', () => { control.peers.delete(socket); stop(); });
    }));
    config.ftpControlChecks.push({ host: '10.0.2.2', port, controlUrl: register(control), cancel: mode === 'cancel',
      maxMs: mode === 'deadline' ? 10000 : 3000 });
  }
  fs.mkdirSync('artifacts', { recursive: true });
  const output = 'artifacts/proxy-inflight-fixture.json'; fs.writeFileSync(output, JSON.stringify(config));
  try {
    const child = spawn(process.execPath, ['scripts/check-network-proxy.cjs', output], { stdio: 'inherit' });
    const code = await new Promise(resolve => child.on('exit', resolve));
    assert.equal(code, 0, 'in-flight / FTP control checks');
  } finally { fs.unlinkSync(output); }
}
main().catch(error => { console.error(error.message); process.exitCode = 1; }).finally(async () => {
  for (const control of controls.values()) { control.resume(); for (const response of control.waiting) response.destroy(); }
  for (const socket of sockets) socket.destroy();
  await Promise.all(servers.map(server => new Promise(resolve => server.close(resolve))));
});
