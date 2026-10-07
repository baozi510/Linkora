'use strict';
const { runCostFixture } = require('./run_research_suite.cjs');

const fixtures = [
  {
    caseId: 'cost-mp4-h264',
    directoryPath: '/x',
    fileName: 'output (1).mp4',
    container: 'mp4',
    expectedDurationMs: 30000,
    expectedWidth: 1920,
    expectedHeight: 1080
  },
  {
    caseId: 'cost-mp4-longgop',
    directoryPath: '/x',
    fileName: 'output.mp4',
    container: 'mp4',
    expectedDurationMs: 120000,
    expectedWidth: 1920,
    expectedHeight: 1080
  },
  {
    caseId: 'cost-mkv-h264',
    directoryPath: '/movie/Fan 2016 Hindi 1080p BluRay x264 DD 5.1 MSubs - LOKiHD - Telly',
    fileName: 'SaMple.mkv',
    container: 'mkv',
    expectedDurationMs: 60000,
    expectedWidth: 1920,
    expectedHeight: 1080
  }
];

(async () => {
  for (const f of fixtures) {
    try {
      console.log(`\n>>> Running 20-rep Cost Benchmark for ${f.caseId} ...`);
      const records = await runCostFixture(f, 2, 20, 600000);
      console.log(`>>> Case ${f.caseId} completed: ${records.length} records`);
    } catch (e) {
      console.error(`Case ${f.caseId} failed:`, e);
    }
  }
  console.log('\nAll full cost fixtures completed!');
  process.exit(0);
})();
