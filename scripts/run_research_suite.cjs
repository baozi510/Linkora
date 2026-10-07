'use strict';
const { runBenchmarkConfig, hdc, CACHE_DIR } = require('./research_orchestrator.cjs');
const fs = require('fs');
const path = require('path');

const MASTER_RECORDS_FILE = path.join(__dirname, '..', 'benchmark_master_records.jsonl');

async function runCostFixture(testCase, warmups = 2, reps = 20, timeoutMs = 600000) {
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
  console.log(`[COST BENCHMARK] Case: ${testCase.caseId} (${testCase.fileName})`);
  console.log(`Warmups: ${warmups}, Repetitions: ${reps}`);
  console.log(`======================================================`);

  const startTime = Date.now();
  const state = await runBenchmarkConfig(config, timeoutMs);
  const elapsedTotal = ((Date.now() - startTime) / 1000).toFixed(1);
  console.log(`[Host] Cost finished in ${elapsedTotal}s! State:`, state);

  const rawRecords = hdc(`shell "cat ${CACHE_DIR}/analysis-benchmark-results.ndjson"`).trim();
  const lines = rawRecords.split('\n').filter(Boolean);
  const records = lines.map(l => JSON.parse(l));
  console.log(`[Host] Collected ${records.length} records (${state.failedRecords} failed)`);

  fs.appendFileSync(MASTER_RECORDS_FILE, lines.join('\n') + '\n');
  return records;
}

async function runSeekExperiment(testCase, seekRatios = [0.05, 0.20, 0.50, 0.90], timeoutMs = 600000) {
  const PORT = 19890;
  const config = {
    schemaVersion: 1,
    mode: 'seek',
    serverName: '*',
    seekRatios,
    benchmarkProxy: {
      host: '127.0.0.1',
      port: PORT
    },
    cases: [testCase]
  };

  console.log(`\n======================================================`);
  console.log(`[SEEK BENCHMARK] Case: ${testCase.caseId} (${testCase.fileName})`);
  console.log(`Ratios: ${seekRatios.join(', ')}`);
  console.log(`======================================================`);

  const startTime = Date.now();
  const state = await runBenchmarkConfig(config, timeoutMs);
  const elapsedTotal = ((Date.now() - startTime) / 1000).toFixed(1);
  console.log(`[Host] Seek finished in ${elapsedTotal}s! State:`, state);

  const rawRecords = hdc(`shell "cat ${CACHE_DIR}/analysis-benchmark-results.ndjson"`).trim();
  const lines = rawRecords.split('\n').filter(Boolean);
  const records = lines.map(l => JSON.parse(l));
  console.log(`[Host] Collected ${records.length} seek records (${state.failedRecords} failed)`);

  fs.appendFileSync(MASTER_RECORDS_FILE, lines.join('\n') + '\n');
  return records;
}

async function runCompatSuite(cases, timeoutMs = 600000) {
  const PORT = 19890;
  const config = {
    schemaVersion: 1,
    mode: 'compat',
    serverName: '*',
    benchmarkProxy: {
      host: '127.0.0.1',
      port: PORT
    },
    cases
  };

  console.log(`\n======================================================`);
  console.log(`[COMPAT SUITE] Running ${cases.length} format cases`);
  console.log(`======================================================`);

  const startTime = Date.now();
  const state = await runBenchmarkConfig(config, timeoutMs);
  const elapsedTotal = ((Date.now() - startTime) / 1000).toFixed(1);
  console.log(`[Host] Compat finished in ${elapsedTotal}s! State:`, state);

  const rawRecords = hdc(`shell "cat ${CACHE_DIR}/analysis-benchmark-results.ndjson"`).trim();
  const lines = rawRecords.split('\n').filter(Boolean);
  const records = lines.map(l => JSON.parse(l));
  console.log(`[Host] Collected ${records.length} compat records (${state.failedRecords} failed)`);

  fs.appendFileSync(MASTER_RECORDS_FILE, lines.join('\n') + '\n');
  return records;
}

async function runStabilitySuite(testCase, cycles = 50, timeoutMs = 600000) {
  const PORT = 19890;
  const config = {
    schemaVersion: 1,
    mode: 'stability',
    serverName: '*',
    stabilityCycles: cycles,
    benchmarkProxy: {
      host: '127.0.0.1',
      port: PORT
    },
    cases: [testCase]
  };

  console.log(`\n======================================================`);
  console.log(`[STABILITY SUITE] Running ${cycles} cycles + cancellation tests on ${testCase.fileName}`);
  console.log(`======================================================`);

  const startTime = Date.now();
  const state = await runBenchmarkConfig(config, timeoutMs);
  const elapsedTotal = ((Date.now() - startTime) / 1000).toFixed(1);
  console.log(`[Host] Stability finished in ${elapsedTotal}s! State:`, state);

  const rawRecords = hdc(`shell "cat ${CACHE_DIR}/analysis-benchmark-results.ndjson"`).trim();
  const lines = rawRecords.split('\n').filter(Boolean);
  const records = lines.map(l => JSON.parse(l));
  console.log(`[Host] Collected ${records.length} stability records (${state.failedRecords} failed)`);

  fs.appendFileSync(MASTER_RECORDS_FILE, lines.join('\n') + '\n');
  return records;
}

module.exports = {
  runCostFixture,
  runSeekExperiment,
  runCompatSuite,
  runStabilitySuite
};
