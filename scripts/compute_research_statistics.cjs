'use strict';
const fs = require('fs');
const path = require('path');

const MASTER_RECORDS_FILE = path.join(__dirname, '..', 'benchmark_master_records.jsonl');
const lines = fs.readFileSync(MASTER_RECORDS_FILE, 'utf8').trim().split('\n');
const allRecords = lines.map(l => JSON.parse(l));

function percentile(arr, p) {
  if (arr.length === 0) return 0;
  const sorted = [...arr].sort((a, b) => a - b);
  const idx = Math.min(sorted.length - 1, Math.max(0, Math.floor(sorted.length * p)));
  return sorted[idx];
}

function mean(arr) {
  if (arr.length === 0) return 0;
  return Math.round(arr.reduce((s, v) => s + v, 0) / arr.length);
}

function stats(arr) {
  if (arr.length === 0) return null;
  const sorted = [...arr].sort((a, b) => a - b);
  return {
    count: arr.length,
    min: sorted[0],
    max: sorted[sorted.length - 1],
    mean: mean(arr),
    p50: percentile(arr, 0.50),
    p95: percentile(arr, 0.95)
  };
}

console.log('========================================================================');
console.log('1. COST BENCHMARK: LOCAL VS WEBDAV CONTROLLED EXPERIMENT (20 REPS EACH)');
console.log('========================================================================\n');

const costCases = ['cost-mp4-h264', 'cost-mp4-longgop', 'cost-mkv-h264'];

costCases.forEach(caseId => {
  console.log(`------------------------------------------------------------------------`);
  console.log(`CASE: ${caseId}`);
  console.log(`------------------------------------------------------------------------`);
  const cRecords = allRecords.filter(r => r.operation === 'analysis.thumbnail' && r.caseId === caseId && r.iteration >= 0 && r.iteration < 20);

  const localSys = cRecords.filter(r => r.sourceType === 'local' && r.engine === 'system');
  const localFf = cRecords.filter(r => r.sourceType === 'local' && r.engine === 'ffmpeg');
  const webdavSys = cRecords.filter(r => r.sourceType === 'webdav' && r.engine === 'system');
  const webdavFf = cRecords.filter(r => r.sourceType === 'webdav' && r.engine === 'ffmpeg');

  const printTable = (name, records) => {
    const elapsed = stats(records.map(r => r.elapsedMs));
    const extract = stats(records.map(r => r.extractMs || 0));
    const encode = stats(records.map(r => r.encodeMs || 0));
    const write = stats(records.map(r => r.writeMs || 0));
    const bytes = stats(records.map(r => r.bytesRead));
    const ranges = stats(records.map(r => r.rangeRequests));
    const reads = stats(records.map(r => r.readRequests));

    console.log(`  [${name}] (N=${records.length})`);
    console.log(`    Total Elapsed: P50=${elapsed.p50}ms | P95=${elapsed.p95}ms | Mean=${elapsed.mean}ms [${elapsed.min}-${elapsed.max}ms]`);
    console.log(`    Extract:       P50=${extract.p50}ms | P95=${extract.p95}ms | Mean=${extract.mean}ms`);
    console.log(`    Encode:        P50=${encode.p50}ms | P95=${encode.p95}ms | Mean=${encode.mean}ms`);
    console.log(`    Disk Write:    P50=${write.p50}ms | P95=${write.p95}ms | Mean=${write.mean}ms`);
    if (bytes.mean > 0) {
      console.log(`    Upstream Bytes: Mean=${bytes.mean} (${(bytes.mean/1024/1024).toFixed(2)} MB) | Ranges=${ranges.mean} | Reads=${reads.mean}`);
    }

    if (records[0]?.engine === 'ffmpeg') {
      const open = stats(records.map(r => r.openInputMs || 0));
      const info = stats(records.map(r => r.findStreamInfoMs || 0));
      const decInit = stats(records.map(r => r.decoderInitMs || 0));
      const seek = stats(records.map(r => r.seekMs || 0));
      const decode = stats(records.map(r => r.decodeMs || 0));
      const scale = stats(records.map(r => r.scaleMs || 0));
      console.log(`    FFmpeg Internal Breakdown (Mean ms):`);
      console.log(`      openInput: ${open.mean}ms | streamInfo: ${info.mean}ms | decInit: ${decInit.mean}ms | seek: ${seek.mean}ms | decode: ${decode.mean}ms | scale: ${scale.mean}ms`);
    } else {
      console.log(`    System Internal Stages: NOT DIRECTLY OBSERVABLE (Platform AVMetadataExtractor)`);
    }
    return { elapsed, extract, bytes };
  };

  const ls = printTable('LOCAL  + System', localSys);
  const lf = printTable('LOCAL  + FFmpeg', localFf);
  const ws = printTable('WEBDAV + System', webdavSys);
  const wf = printTable('WEBDAV + FFmpeg', webdavFf);

  console.log(`\n  >> Remote-path Incremental Cost:`);
  console.log(`     System: ${ws.elapsed.mean - ls.elapsed.mean} ms (WebDAV Mean ${ws.elapsed.mean}ms - Local Mean ${ls.elapsed.mean}ms)`);
  console.log(`     FFmpeg: ${wf.elapsed.mean - lf.elapsed.mean} ms (WebDAV Mean ${wf.elapsed.mean}ms - Local Mean ${lf.elapsed.mean}ms)`);
  console.log(`\n  >> Engine Ratio on Same Storage:`);
  console.log(`     LOCAL:  System / FFmpeg = ${(ls.elapsed.mean / lf.elapsed.mean).toFixed(2)}x (FFmpeg is faster by ${(ls.elapsed.mean - lf.elapsed.mean)}ms)`);
  console.log(`     WEBDAV: FFmpeg / System = ${(wf.elapsed.mean / ws.elapsed.mean).toFixed(2)}x (System is faster by ${(wf.elapsed.mean - ws.elapsed.mean)}ms)`);
  console.log();
});

console.log('========================================================================');
console.log('2. SEEK-DISTANCE EXPERIMENT (LONG-GOP MP4, 5 REPS PER RATIO)');
console.log('========================================================================\n');

const seekRecords = allRecords.filter(r => r.operation === 'analysis.seek');
const ratios = [0.05, 0.20, 0.50, 0.90];

ratios.forEach(ratio => {
  console.log(`--- Seek Ratio: ${Math.round(ratio * 100)}% (Target: ${Math.round(120000 * ratio)} ms) ---`);
  const sys = seekRecords.filter(r => Math.abs(r.seekRatio - ratio) < 0.01 && r.engine === 'system');
  const ff = seekRecords.filter(r => Math.abs(r.seekRatio - ratio) < 0.01 && r.engine === 'ffmpeg');

  const sTotal = stats(sys.map(r => r.elapsedMs));
  const sBytes = stats(sys.map(r => r.bytesRead));
  const fTotal = stats(ff.map(r => r.elapsedMs));
  const fBytes = stats(ff.map(r => r.bytesRead));
  const fOpen = stats(ff.map(r => r.openInputMs || 0));
  const fInfo = stats(ff.map(r => r.findStreamInfoMs || 0));
  const fSeek = stats(ff.map(r => r.seekMs || 0));
  const fDecode = stats(ff.map(r => r.decodeMs || 0));

  console.log(`  System: Elapsed P50=${sTotal.p50}ms (Mean ${sTotal.mean}ms) | Upstream Bytes=${sBytes.mean} (${(sBytes.mean/1024/1024).toFixed(2)} MB)`);
  console.log(`  FFmpeg: Elapsed P50=${fTotal.p50}ms (Mean ${fTotal.mean}ms) | Upstream Bytes=${fBytes.mean} (${(fBytes.mean/1024/1024).toFixed(2)} MB)`);
  console.log(`          FFmpeg decodeMs=${fDecode.mean}ms | openInputMs=${fOpen.mean}ms | seekMs=${fSeek.mean}ms | infoMs=${fInfo.mean}ms`);
  console.log();
});

console.log('========================================================================');
console.log('3. COMPATIBILITY MATRIX SUMMARY');
console.log('========================================================================\n');

const compatRecords = allRecords.filter(r => r.operation === 'analysis.compat');
const casesSet = [...new Set(compatRecords.map(r => r.caseId))];

casesSet.forEach(cId => {
  const cRecords = compatRecords.filter(r => r.caseId === cId);
  const sys = cRecords.find(r => r.engine === 'system');
  const ff = cRecords.find(r => r.engine === 'ffmpeg');
  console.log(`Case: ${cId.padEnd(28)} | System: ${sys?.success ? 'PASS (' + sys.elapsedMs + 'ms, ' + (sys.bytesRead/1024/1024).toFixed(1) + 'MB)' : 'FAIL (' + sys?.errorCode + ')'} | FFmpeg: ${ff?.success ? 'PASS (' + ff.elapsedMs + 'ms, ' + (ff.bytesRead/1024/1024).toFixed(1) + 'MB)' : 'FAIL (' + ff?.errorCode + ')'}`);
});
