'use strict';

const fs = require('node:fs');

const rawPath = process.argv[2];
const casesPath = process.argv[3] || 'test-lab/media-compatibility/cases.json';
if (!rawPath) {
  console.error('Usage: node scripts/summarize-playback-capability.cjs <raw.ndjson> [cases.json]');
  process.exit(2);
}

const manifest = JSON.parse(fs.readFileSync(casesPath, 'utf8'));
const rows = fs.readFileSync(rawPath, 'utf8').split(/\r?\n/).filter(Boolean).map((line, index) => {
  try { return JSON.parse(line); } catch (error) {
    throw new Error(`Invalid NDJSON line ${index + 1}: ${error.message}`);
  }
});

const allowed = new Set(manifest.verdicts);
const expected = new Map();
for (const c of manifest.cases) {
  for (const backend of c.requiredBackends) expected.set(`${c.id}|${backend}`, c);
}
const seen = new Map();
for (const r of rows) {
  const key = `${r.caseId}|${r.backend}`;
  if (!expected.has(key)) throw new Error(`Unexpected record: ${key}`);
  if (seen.has(key)) throw new Error(`Duplicate record: ${key}`);
  if (!allowed.has(r.verdict)) throw new Error(`Invalid verdict ${r.verdict} for ${key}`);
  seen.set(key, r);
}
const missing = [...expected.keys()].filter(k => !seen.has(k));

const backendSummary = {};
for (const backend of ['system','mpv']) {
  backendSummary[backend] = {};
  for (const verdict of manifest.verdicts) backendSummary[backend][verdict] = 0;
}
const tierSummary = {};
for (const c of manifest.cases) {
  if (!tierSummary[c.tier]) tierSummary[c.tier] = { cases:0, productPass:0, productUnsupported:0 };
  tierSummary[c.tier].cases++;
  const sr = seen.get(`${c.id}|system`);
  const mr = seen.get(`${c.id}|mpv`);
  if (sr) backendSummary.system[sr.verdict]++;
  if (mr) backendSummary.mpv[mr.verdict]++;
  if (sr && mr) {
    if (sr.verdict === 'PASS' || mr.verdict === 'PASS') tierSummary[c.tier].productPass++;
    else tierSummary[c.tier].productUnsupported++;
  }
}

const tierAFailures = manifest.cases.filter(c => c.productGate).filter(c => {
  const s = seen.get(`${c.id}|system`), m = seen.get(`${c.id}|mpv`);
  return s && m && s.verdict !== 'PASS' && m.verdict !== 'PASS';
}).map(c => c.id);

const infrastructureFailures = rows.filter(r =>
  r.crash === true || r.anr === true || r.unbounded === true || r.releaseClean === false
).map(r => ({caseId:r.caseId,backend:r.backend}));

const result = {
  manifestCases: manifest.cases.length,
  expectedRecords: expected.size,
  actualRecords: rows.length,
  missing,
  backendSummary,
  tierSummary,
  tierAFailures,
  infrastructureFailures,
  complete: missing.length === 0,
  productGatePass: missing.length === 0 && tierAFailures.length === 0 && infrastructureFailures.length === 0
};
console.log(JSON.stringify(result,null,2));
process.exit(result.complete ? 0 : 1);
