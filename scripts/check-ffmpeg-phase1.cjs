'use strict';
// Run the same deterministic Hypium cases against pure ArkTS code, without loading NAPI.
const fs = require('node:fs'), path = require('node:path'), vm = require('node:vm');
const assert = require('node:assert/strict');
const studio = process.argv[2] || 'C:/Program Files/Huawei/DevEco Studio';
const ts = require(path.join(studio, 'sdk/default/openharmony/ets/build-tools/ets-loader/node_modules/typescript'));
const root = path.resolve(__dirname, '..'), cache = new Map(), tests = [];
function load(relative) {
  const file = path.join(root, relative);
  if (!fs.existsSync(file)) return {};
  if (cache.has(file)) return cache.get(file);
  const module = { exports: {} }; cache.set(file, module.exports);
  const code = ts.transpileModule(fs.readFileSync(file, 'utf8'), {
    compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022 }
  }).outputText;
  vm.runInNewContext(`(function(require,module,exports){${code}\n})`, {
    ArrayBuffer, Uint8Array, Set, Map, Promise, Error, console
  }, { filename: file })(name => {
    if (name === '@ohos/hypium') return { describe(_name, body) { body(); },
      it(name, _flags, body) { tests.push({ name, body }); }, expect(value) { return {
        assertEqual(expected) { assert.equal(value, expected); }, assertTrue() { assert.equal(value, true); }
      }; } };
    if (name === 'linkora_core') return load('linkora_core/Index.ets');
    if (name === 'linkora_ffmpeg') return load('linkora_ffmpeg/Index.ets');
    if (name.startsWith('.')) return load(path.relative(root, path.resolve(path.dirname(file), name + '.ets')));
    throw Error('Unexpected dependency: ' + name);
  }, module, module.exports);
  return module.exports;
}
(async () => {
  assert.ok(fs.existsSync(path.join(root, 'linkora_ffmpeg/Index.ets')), 'Phase1 module public API is missing');
  const phase2 = process.argv.includes('--phase2');
  if (phase2) assert.ok(fs.existsSync(path.join(root, 'entry/src/main/ets/analysis/MediaAnalysisInputResolver.ets')), 'Phase2 resolver implementation is missing');
  load(phase2 ? 'entry/src/test/MediaAnalysisAdapters.test.ets' : 'entry/src/test/FfmpegAnalysis.test.ets').default();
  for (const test of tests) { await test.body(); console.log('PASS ' + test.name); }
  console.log(`${phase2 ? 'Analysis Phase2' : 'FFmpeg Phase1'} pure tests: ${tests.length}/${tests.length} PASS`);
})().catch(error => { console.error(error); process.exitCode = 1; });
