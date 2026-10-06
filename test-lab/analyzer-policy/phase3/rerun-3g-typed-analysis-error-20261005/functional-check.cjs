'use strict';
// Read-only supplemental validation; reuse the repository's unchanged pure ArkTS loader.
const fs = require('node:fs'), path = require('node:path'), vm = require('node:vm');
const assert = require('node:assert/strict');
const root = process.cwd(), loaderPath = path.join(root, 'scripts/check-ffmpeg-phase1.cjs');
const original = fs.readFileSync(loaderPath, 'utf8');
const prefix = original.slice(0, original.indexOf('(async () => {'));
assert.ok(prefix.includes('function load(relative)'));
const scope = { require, __dirname: path.dirname(loaderPath), process, console, module: { exports: {} } };
vm.runInNewContext(prefix + '\nmodule.exports = load;', scope, { filename: loaderPath });
const load = scope.module.exports;
const core = load('linkora_core/Index.ets');
const { AnalysisOperation, AnalysisError, AnalysisErrorCode } = load('entry/src/main/ets/analysis/AnalysisOperation.ets');
const { PolicyMediaProbe } = load('entry/src/main/ets/analysis/PolicyMediaProbe.ets');
const { ProductionMediaAnalysisPolicy } = load('entry/src/main/ets/analysis/ProductionMediaAnalysisPolicy.ets');
const source = core.MediaSource.fromRemoteFile('/fixture.mkv', 'fixture.mkv', 'synthetic', 1024, 'network-server:1');
const result = (engine, completeness, width = 640) => new core.ProbeResult(
  completeness === core.ProbeCompleteness.UNAVAILABLE ? null : new core.MediaInfo('matroska', 1000, 0, 0,
    [new core.VideoTrackInfo('v', 'hevc', 'Main', '', width, 360)]), completeness, [], new core.MediaProbeDiagnostics(engine));
const adapter = value => ({ calls: 0, async canProbe() { return true; }, async probe() { this.calls++; return value; }, cancel() {}, async close() {} });
let count = 0;
const pass = name => { count++; console.log('PASS ' + name); };
(async () => {
  for (const completeness of [core.ProbeCompleteness.COMPLETE, core.ProbeCompleteness.PARTIAL, core.ProbeCompleteness.UNAVAILABLE]) {
    const ffResult = result('ffmpeg', completeness), sysResult = result('system', core.ProbeCompleteness.COMPLETE, 1920);
    const ff = adapter(ffResult), system = adapter(sysResult), policy = new PolicyMediaProbe(system, ff);
    const actual = await policy.probe(source, core.ProbeRequirement.ADVANCED);
    assert.equal(actual, completeness === core.ProbeCompleteness.UNAVAILABLE ? sysResult : ffResult);
    assert.equal(ff.calls, 1); assert.equal(system.calls, completeness === core.ProbeCompleteness.UNAVAILABLE ? 1 : 0);
    await policy.close(); pass('ADVANCED ' + completeness + ' exact result identity / fallback / no merge');
  }
  const ff = adapter(result('ffmpeg', core.ProbeCompleteness.UNAVAILABLE)), system = adapter(result('system', core.ProbeCompleteness.COMPLETE));
  let finish; ff.probe = async function () { this.calls++; return new Promise(resolve => { finish = resolve; }); };
  const policy = new PolicyMediaProbe(system, ff), pending = policy.probe(source, core.ProbeRequirement.ADVANCED);
  while (!finish) await Promise.resolve(); policy.cancel(); finish(result('ffmpeg', core.ProbeCompleteness.UNAVAILABLE));
  assert.equal((await pending).errorCode, AnalysisErrorCode.CANCELLED); assert.equal(system.calls, 0);
  await policy.close(); pass('ADVANCED cancellation starts no fallback');
  const operation = new AnalysisOperation(), existing = new AnalysisError(AnalysisErrorCode.TIMEOUT);
  assert.equal(operation.failure(existing, AnalysisErrorCode.RESOLVE_FAILED), existing); pass('typed boundary preserves AnalysisError identity');
  assert.equal(operation.failure(new Error('synthetic'), AnalysisErrorCode.RESOLVE_FAILED).code, AnalysisErrorCode.RESOLVE_FAILED);
  pass('typed boundary maps generic provider failure to RESOLVE_FAILED');
  operation.cancel(); assert.equal(operation.failure(existing, AnalysisErrorCode.RESOLVE_FAILED).code, AnalysisErrorCode.CANCELLED);
  operation.complete(); pass('typed boundary prioritizes CANCELLED');
  const routing = new ProductionMediaAnalysisPolicy();
  for (const input of [core.MediaSource.fromLocalDocument('content://document/fixture.mp4'),
    core.MediaSource.fromRemoteFile('/fixture.m3u8', 'fixture.m3u8', 'synthetic'),
    core.MediaSource.fromRemoteFile('/fixture.mpd', 'fixture.mpd', 'synthetic')]) {
    assert.equal(routing.probeOrder(input, core.ProbeRequirement.ADVANCED).join(','), 'system');
    assert.equal(routing.thumbnailOrder(input).join(','), 'system'); pass(input.format + ' / ' + input.kind + ' System-only');
  }
  console.log('Supplemental desktop functional checks: ' + count + '/' + count + ' PASS; no native/UI runtime');
})().catch(error => { console.error(error); process.exitCode = 1; });
