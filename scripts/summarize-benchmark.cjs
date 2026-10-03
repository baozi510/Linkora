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
    if (typeof value.operation !== 'string' || typeof value.engine !== 'string') {
      throw new Error('operation/engine required');
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
  if (values.length === 0) return null;
  return values.reduce((a, b) => a + b, 0) / values.length;
}

function num(values, field) {
  return values.map(x => Number(x[field])).filter(Number.isFinite);
}

const groups = new Map();
for (const record of records) {
  const key = [record.operation, record.engine, record.sourceType || 'unknown'].join('|');
  if (!groups.has(key)) groups.set(key, []);
  groups.get(key).push(record);
}

let md = '# Linkora Benchmark Report\n\n';
md += `Records: ${records.length}\n\n`;
md += '| Operation | Engine | Source | N | Success | P50 ms | P95 ms | Avg bytes | Avg ranges |\n';
md += '| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |\n';

for (const [key, values] of [...groups.entries()].sort()) {
  const [operation, engine, source] = key.split('|');
  const success = values.filter(x => x.success === true).length;
  const elapsed = num(values, 'elapsedMs');
  const bytes = num(values, 'bytesRead');
  const ranges = num(values, 'rangeRequests');
  const rate = values.length === 0 ? 0 : success * 100 / values.length;
  const p50 = percentile(elapsed, 0.50);
  const p95 = percentile(elapsed, 0.95);
  const ab = avg(bytes);
  const ar = avg(ranges);
  md += `| ${operation} | ${engine} | ${source} | ${values.length} | ${rate.toFixed(1)}% | ${p50 ?? '-'} | ${p95 ?? '-'} | ${ab === null ? '-' : Math.round(ab)} | ${ar === null ? '-' : ar.toFixed(1)} |\n`;
}

fs.writeFileSync(output, md, 'utf8');
console.log(`Wrote ${output}`);
