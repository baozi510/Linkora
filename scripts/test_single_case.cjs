'use strict';
const { runBenchmarkConfig, hdc, CACHE_DIR } = require('./research_orchestrator.cjs');

(async () => {
  const PORT = 19890;
  const config = {
    schemaVersion: 1,
    mode: 'cost',
    serverName: '*',
    warmups: 1,
    repetitions: 2,
    benchmarkProxy: {
      host: '127.0.0.1',
      port: PORT
    },
    cases: [
      {
        caseId: 'test-mp4-h264',
        directoryPath: '/x',
        fileName: 'output (1).mp4',
        container: 'mp4',
        expectedDurationMs: 30000,
        expectedWidth: 1920,
        expectedHeight: 1080
      }
    ]
  };

  console.log('Running test cost benchmark (1 warmup, 2 reps)...');
  try {
    const state = await runBenchmarkConfig(config, 180000);
    console.log('Finished! State:', state);

    // Fetch records
    const rawRecords = hdc(`shell "cat ${CACHE_DIR}/analysis-benchmark-results.ndjson"`).trim();
    const lines = rawRecords.split('\n').filter(Boolean);
    console.log(`Received ${lines.length} records:`);
    lines.forEach((l, idx) => {
      const r = JSON.parse(l);
      console.log(`[${idx + 1}] op=${r.operation} engine=${r.engine} src=${r.sourceType} iter=${r.iteration} ok=${r.success} elapsed=${r.elapsedMs}ms extract=${r.extractMs}ms bytes=${r.bytesRead}`);
      if (r.engine === 'ffmpeg') {
        console.log(`    ffmpeg breakdown: open=${r.openInputMs}ms info=${r.findStreamInfoMs}ms decInit=${r.decoderInitMs}ms seek=${r.seekMs}ms decode=${r.decodeMs}ms scale=${r.scaleMs}ms`);
      }
      if (r.sourceType === 'webdav') {
        console.log(`    io breakdown: ranges=${r.rangeRequests} reads=${r.readRequests} span=${r.uniqueByteSpan} overlap=${r.overlappingBytes} rereads=${r.headRereads}`);
      }
    });
  } catch (e) {
    console.error('Error during test benchmark:', e);
    process.exit(1);
  }
})();
