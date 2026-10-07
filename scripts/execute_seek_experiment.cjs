'use strict';
const { runSeekExperiment } = require('./run_research_suite.cjs');

(async () => {
  try {
    const fixture = {
      caseId: 'seek-mp4-longgop',
      directoryPath: '/x',
      fileName: 'output.mp4',
      container: 'mp4',
      expectedDurationMs: 120000,
      expectedWidth: 1920,
      expectedHeight: 1080
    };
    const records = await runSeekExperiment(fixture, [0.05, 0.20, 0.50, 0.90], 300000);
    console.log(`Seek experiment completed! Total records: ${records.length}`);
    process.exit(0);
  } catch (e) {
    console.error('Seek experiment failed:', e);
    process.exit(1);
  }
})();
