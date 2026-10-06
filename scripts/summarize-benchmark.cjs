const fs = require('fs');

const input = process.argv[2];
const output = process.argv[3];
if (!input || !output) {
  console.error('Usage: node scripts/summarize-benchmark.cjs <results.ndjson> <report.md>');
  process.exit(2);
}

const lines = fs.readFileSync(input, 'utf8').split(/\r?\n/).filter(Boolean);
const records = [];
for (let i = 0; i < lines.length; i++) {
  try {
    const value = JSON.parse(lines[i]);
    if (typeof value.operation !== 'string' || typeof value.engine !== 'string' ||
      typeof value.caseId !== 'string') {
      throw new Error('operation/engine/caseId required');
    }
    records.push(value);
  } catch (error) {
    console.error(`Invalid NDJSON line ${i + 1}: ${error.message}`);
    process.exit(1);
  }
}

function percentile(values, p) {
  if (values.length === 0) return null;
  const sorted = values.slice().sort((a, b) => a - b);
  const index = Math.min(sorted.length - 1, Math.max(0, Math.ceil(p * sorted.length) - 1));
  return sorted[index];
}
function avg(values) {
  return values.length === 0 ? null : values.reduce((a, b) => a + b, 0) / values.length;
}
function nums(values, field) {
  return values
    .filter(x => x[field] !== null && x[field] !== undefined)
    .map(x => Number(x[field]))
    .filter(x => Number.isFinite(x) && x >= 0);
}
function groupBy(keys) {
  const groups = new Map();
  for (const record of records) {
    const key = keys.map(k => String(record[k] ?? 'unknown')).join('|');
    if (!groups.has(key)) groups.set(key, []);
    groups.get(key).push(record);
  }
  return groups;
}
function cell(value, digits = 0) {
  if (value === null || value === undefined) return '-';
  return digits > 0 ? value.toFixed(digits) : Math.round(value).toString();
}

let md = '# Linkora Analysis Benchmark Report\n\n';
md += `Records: ${records.length}\n\n`;
md += '> Benchmark data is descriptive evidence. Policy changes require a separate GPT review.\n\n';

md += '## Aggregate\n\n';
md += '| Operation | Requirement | Engine | Source | N | Success | Complete | P50 ms | P95 ms | Avg prepare | Avg probe/extract | Avg encode | Avg write | Avg bytes | Avg ranges | Avg WebP bytes | Avg memory |\n';
md += '| --- | --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |\n';

for (const [key, values] of [...groupBy(['operation', 'requirement', 'engine', 'sourceType']).entries()].sort()) {
  const [operation, requirement, engine, source] = key.split('|');
  const success = values.filter(x => x.success === true).length;
  const complete = values.filter(x => x.completeness === 'complete').length;
  const elapsed = nums(values, 'elapsedMs');
  const prepare = nums(values, 'prepareMs');
  const probe = operation === 'analysis.thumbnail' ? nums(values, 'extractMs') : nums(values, 'probeMs');
  const encode = nums(values, 'encodeMs');
  const write = nums(values, 'writeMs');
  const bytes = nums(values, 'bytesRead');
  const ranges = nums(values, 'rangeRequests');
  const webp = nums(values, 'webpBytes');
  const memory = nums(values, 'memoryBytes');
  md += `| ${operation} | ${requirement} | ${engine} | ${source} | ${values.length} | ${(success * 100 / values.length).toFixed(1)}% | ${(complete * 100 / values.length).toFixed(1)}% | ${cell(percentile(elapsed, .50))} | ${cell(percentile(elapsed, .95))} | ${cell(avg(prepare))} | ${cell(avg(probe))} | ${cell(avg(encode))} | ${cell(avg(write))} | ${cell(avg(bytes))} | ${cell(avg(ranges), 1)} | ${cell(avg(webp))} | ${cell(avg(memory))} |\n`;
}

md += '\n## Per case\n\n';
md += '| Case | Operation | Requirement | Engine | N | Success | Complete | P50 ms | P95 ms | Avg bytes | Avg ranges |\n';
md += '| --- | --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |\n';
for (const [key, values] of [...groupBy(['caseId', 'operation', 'requirement', 'engine']).entries()].sort()) {
  const [caseId, operation, requirement, engine] = key.split('|');
  const success = values.filter(x => x.success === true).length;
  const complete = values.filter(x => x.completeness === 'complete').length;
  const elapsed = nums(values, 'elapsedMs');
  md += `| ${caseId} | ${operation} | ${requirement} | ${engine} | ${values.length} | ${(success * 100 / values.length).toFixed(1)}% | ${(complete * 100 / values.length).toFixed(1)}% | ${cell(percentile(elapsed, .50))} | ${cell(percentile(elapsed, .95))} | ${cell(avg(nums(values, 'bytesRead')))} | ${cell(avg(nums(values, 'rangeRequests')), 1)} |\n`;
}

fs.writeFileSync(output, md, 'utf8');
console.log(`Wrote ${output}`);
