'use strict';
// Host characterization only; native media acceptance comes from the simulator.
const assert = require('node:assert/strict'), fs = require('node:fs'), vm = require('node:vm');
const ts = require(process.argv[2]);
const calls = [];
const diagnostics = { configure: want => calls.push(['configure', want]), run: async context => calls.push(['run', context]) };
class UIAbility { constructor() { this.context = { marker: 'context' }; } }
const moduleObject = { exports: {} };
const source = ts.transpileModule(fs.readFileSync('entry/src/main/ets/entryability/EntryAbility.ets', 'utf8'),
  { compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2020 } }).outputText;
vm.runInNewContext(source, { exports: moduleObject.exports, module: moduleObject,
  require: name => name === '@kit.AbilityKit' ? { UIAbility } : name === 'entry/RuntimeDiagnostics' ? { RuntimeDiagnostics: diagnostics } : {}, console });
const ability = new moduleObject.exports.default();
assert.equal(typeof ability.onNewWant, 'function', 'warm Ability must dispatch diagnostic Want without a process restart');
const want = { parameters: { unrelated: 'safe' } };
ability.onNewWant(want);
assert.equal(calls.length, 2);
assert.equal(calls[0][0], 'configure'); assert.equal(calls[0][1], want);
assert.equal(calls[1][0], 'run'); assert.equal(calls[1][1], ability.context);
console.log('Warm diagnostic Want dispatch behavior PASS (not native media proof).');
