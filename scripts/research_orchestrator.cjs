'use strict';
const http = require('node:http');
const { execSync, spawn } = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');

const HDC = 'C:\\Program Files\\Huawei\\DevEco Studio\\sdk\\default\\openharmony\\toolchains\\hdc.exe';
const TARGET = '192.168.123.5:36929';
const PORT = 19890;
const CACHE_DIR = '/data/app/el2/100/base/com.linkora.player/haps/entry/cache';

function hdc(cmd) {
  return execSync(`"${HDC}" -t ${TARGET} ${cmd}`, { encoding: 'utf8', timeout: 30000 });
}

async function runBenchmarkConfig(configJson, timeoutMs = 600000) {
  // Reset reverse port mapping
  try {
    hdc(`fport rm tcp:${PORT} tcp:${PORT}`);
  } catch (_) {}
  try {
    const rportOut = hdc(`rport tcp:${PORT} tcp:${PORT}`);
    console.log('[Host] rport output:', rportOut.trim());
  } catch (e) {
    console.warn('rport warning:', e.message);
  }

  // Force stop any existing instance
  try {
    hdc('shell "aa force-stop com.linkora.player"');
  } catch (_) {}

  // Clear previous state file on device
  try {
    hdc(`shell "rm -f ${CACHE_DIR}/analysis-benchmark-state.json ${CACHE_DIR}/benchmark-discovery.json"`);
  } catch (_) {}

  const token = require('node:crypto').randomUUID();
  let served = false;
  const server = http.createServer((req, res) => {
    console.log(`[HTTP] ${req.method} ${req.url}`);
    if (req.url === '/' + token && req.method === 'GET') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(configJson));
      served = true;
      console.log('[HTTP] Served benchmark config');
    } else {
      res.writeHead(404);
      res.end('Not found');
    }
  });

  const net = require('node:net');
  server.on('connect', (req, clientSocket, head) => {
    console.log('[Tunnel] CONNECT request for:', req.url);
    const serverSocket = net.connect(8088, '192.168.123.123', () => {
      clientSocket.write('HTTP/1.1 200 Connection Established\r\n\r\n');
      if (head && head.length > 0) serverSocket.write(head);
      serverSocket.pipe(clientSocket);
      clientSocket.pipe(serverSocket);
      console.log('[Tunnel] Established for:', req.url);
    });
    serverSocket.on('error', (e) => {
      console.warn('[Tunnel] Server error:', e.message);
      clientSocket.end();
    });
    clientSocket.on('error', () => serverSocket.destroy());
  });

  await new Promise((resolve) => server.listen(PORT, '0.0.0.0', resolve));
  console.log(`[Host] Listening on 0.0.0.0:${PORT}/${token}`);

  try {
    // Launch app with config
    const launchCmd = `shell "aa start -b com.linkora.player -a EntryAbility --ps linkoraAnalysisBenchmarkConfig http://127.0.0.1:${PORT}/${token}"`;
    console.log('[Host] Launching app...');
    const launchOut = hdc(launchCmd);
    console.log('[Host] aa start output:', launchOut.trim());

    // Poll for completion
    const startTime = Date.now();
    let completed = false;
    let state = null;

    while (Date.now() - startTime < timeoutMs) {
      await new Promise(r => setTimeout(r, 2000));
      try {
        const raw = hdc(`shell "cat ${CACHE_DIR}/analysis-benchmark-state.json"`).trim();
        if (raw && raw.startsWith('{') && raw.endsWith('}')) {
          state = JSON.parse(raw);
          if (state.complete) {
            completed = true;
            console.log('[Host] Benchmark run complete! State:', JSON.stringify(state));
            break;
          }
        }
      } catch (_) {
        // State file might not exist yet or be mid-write
      }
    }

    if (!completed) {
      throw new Error(`Benchmark timed out after ${timeoutMs}ms`);
    }

    return state;
  } finally {
    if (server.closeAllConnections) server.closeAllConnections();
    server.close();
  }
}

module.exports = { runBenchmarkConfig, hdc, CACHE_DIR };

if (require.main === module) {
  const mode = process.argv[2] || 'discovery';
  if (mode === 'discovery') {
    (async () => {
      try {
        const state = await runBenchmarkConfig({
          schemaVersion: 1,
          mode: 'discovery',
          serverName: '*',
          benchmarkProxy: {
            host: '127.0.0.1',
            port: PORT
          }
        }, 60000);
        console.log('Final State:', state);

        // Fetch discovery results
        const rawDisc = hdc(`shell "cat ${CACHE_DIR}/benchmark-discovery.json"`).trim();
        const disc = JSON.parse(rawDisc);
        console.log('Discovery Results:');
        console.log('Protocol:', disc.serverProtocol);
        console.log('Server Display Name:', disc.serverDisplayName);
        console.log(`Found ${disc.items.length} files:`);
        disc.items.forEach(it => {
          console.log(`  - [${it.directoryPath}] ${it.displayName} (${(it.sizeBytes / 1024 / 1024).toFixed(2)} MB)`);
        });
      } catch (e) {
        console.error('Error running discovery:', e);
        process.exit(1);
      }
    })();
  }
}
