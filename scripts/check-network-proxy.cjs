'use strict';
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const { execFileSync } = require('node:child_process');
const http = require('node:http');
const { randomUUID } = require('node:crypto');
const hdc = 'C:/Program Files/Huawei/DevEco Studio/sdk/default/openharmony/toolchains/hdc.exe';
const cache = '/data/app/el2/100/base/com.linkora.player/haps/entry/cache';
const fixture = process.argv[2];
const target = process.env.LINKORA_HDC_TARGET || '127.0.0.1:5555';
function run(...args) {
  return execFileSync(hdc, ['-t', target, ...args], { encoding: 'utf8', timeout: 20000, stdio: ['ignore', 'pipe', 'pipe'] });
}
async function main() {
  const output = path.resolve('artifacts/proxy-smoke-result.json');
  fs.mkdirSync(path.dirname(output), { recursive: true });
  let config = 'builtin';
  let fixtureServer;
  try {
    assert.match(run('install', '-r', 'entry/build/default/outputs/default/entry-default-signed.hap'), /successfully/);
    run('shell', 'aa', 'force-stop', 'com.linkora.player');
    run('shell', 'rm', '-f', `${cache}/proxy-smoke-result.json`);
    if (fixture) {
      assert.ok(Array.isArray(JSON.parse(fs.readFileSync(fixture, 'utf8')).cases), 'fixture needs cases');
      const payload = fs.readFileSync(fixture);
      const token = randomUUID();
      fixtureServer = http.createServer((request, response) => {
        if (request.method !== 'GET' || request.url !== `/${token}`) { response.writeHead(404).end(); return; }
        response.writeHead(200, { 'Content-Type': 'application/json', 'Content-Length': payload.length });
        response.end(payload);
      });
      await new Promise((resolve, reject) => {
        fixtureServer.once('error', reject); fixtureServer.listen(0, '127.0.0.1', resolve);
      });
      config = `http://10.0.2.2:${fixtureServer.address().port}/${token}`;
    }
    assert.match(run('shell', 'aa', 'start', '-a', 'EntryAbility', '-b', 'com.linkora.player',
      '--ps', 'linkoraProxySmokeConfig', config), /successfully/);
    const deadline = Date.now() + 60000;
    let result;
    while (Date.now() < deadline) {
      await new Promise(resolve => setTimeout(resolve, 1000));
      let text = '';
      try { text = run('shell', 'cat', `${cache}/proxy-smoke-result.json`); } catch { continue; }
      if (!text.startsWith('{')) continue;
      result = JSON.parse(text);
      if (result.complete) break;
    }
    assert.ok(result?.complete, 'device smoke timed out');
    fs.writeFileSync(output, JSON.stringify(result, null, 2) + '\n');
    console.log(JSON.stringify(result));
    assert.equal(result.passed, true, 'device checks failed');
    if (fixture) {
      const cases = JSON.parse(fs.readFileSync(fixture, 'utf8')).cases;
      for (const item of cases) {
        assert.ok(result.checks.includes(`${item.protocol} bytes and cancellation`));
        if (item.cancellationControlUrl) assert.ok(result.checks.includes(`${item.protocol} native in-flight cancellation`));
      }
    }
    console.log('PASS: device proxy checks');
  } finally {
    if (fixtureServer) await new Promise(resolve => fixtureServer.close(resolve));
    run('shell', 'aa', 'force-stop', 'com.linkora.player');
    run('shell', 'aa', 'start', '-a', 'EntryAbility', '-b', 'com.linkora.player');
  }
}
main().catch(error => { console.error(error.message); process.exitCode = 1; });
