'use strict';
const { runBenchmarkConfig, hdc, CACHE_DIR } = require('./research_orchestrator.cjs');
const fs = require('fs');

async function runCase(testCase, warmups = 2, reps = 20, timeoutMs = 600000) {
  const PORT = 19890;
  const config = {
    schemaVersion: 1,
    mode: 'cost',
    serverName: '*',
    warmups,
    repetitions: reps,
    benchmarkProxy: {
      host: '127.0.0.1',
      port: PORT
    },
    cases: [testCase]
  };

  console.log(`\n======================================================`);
  console.log(`Starting Cost Benchmark for: ${testCase.caseId} (${testCase.fileName})`);
  console.log(`Warmups: ${warmups}, Repetitions: ${reps}`);
  console.log(`======================================================`);

  const startTime = Date.now();
  const state = await runBenchmarkConfig(config, timeoutMs);
  const elapsedTotal = ((Date.now() - startTime) / 1000).toFixed(1);
  console.log(`Finished in ${elapsedTotal}s! State:`, state);

  // Read results
  const rawRecords = hdc(`shell "cat ${CACHE_DIR}/analysis-benchmark-results.ndjson"`).trim();
  const lines = rawRecords.split('\n').filter(Boolean);
  const records = lines.map(l => JSON.parse(l));
  console.log(`Received ${records.length} records (${state.failedRecords} failed)`);

  // Append to master record file on host
  const masterFile = 'benchmark_master_records.jsonl';
  fs.appendFileSync(masterFile, lines.join('\n') + '\n');
  console.log(`Appended ${records.length} records to ${masterFile}`);

  return records;
}

module.exports = { runCase };

if (require.main === module) {
  (async () => {
    try {
      const records = await runCase({
        caseId: 'cost-mp4-longgop',
        directoryPath: '/x',
        fileName: 'output.mp4',
        container: 'mp4',
        expectedDurationMs: 120000,
        expectedWidth: 1920,
        expectedHeight: 1080
      }, 1, 2, 300000);
      console.log('Sample record:', records[0]);
      process.exit(0);
    } catch (e) {
      console.error('Run failed:', e);
      process.exit(1);
    }
  })();
}
