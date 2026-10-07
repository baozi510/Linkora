'use strict';
const { runStabilitySuite } = require('./run_research_suite.cjs');

(async () => {
  try {
    const fixture = {
      caseId: 'stability-mp4-h264',
      directoryPath: '/x',
      fileName: 'output (1).mp4',
      container: 'mp4',
      expectedDurationMs: 30000,
      expectedWidth: 1920,
      expectedHeight: 1080
    };
    const records = await runStabilitySuite(fixture, 50, 300000);
    console.log(`Stability suite completed! Total records: ${records.length}`);
    process.exit(0);
  } catch (e) {
    console.error('Stability suite failed:', e);
    process.exit(1);
  }
})();
