'use strict';
const fs = require('node:fs'), path = require('node:path'), { spawn, spawnSync } = require('node:child_process');
const hdc = 'C:/Program Files/Huawei/DevEco Studio/sdk/default/openharmony/toolchains/hdc.exe';
const out = path.resolve(process.argv[2] || 'artifacts/ffmpeg-phase1b');
const round = process.argv[3] || '01', records = [], observations = [], commands = [];
const endpoint = fs.readFileSync(path.join(out, 'launch-endpoint.txt'), 'utf8').trim();
if (!/^http:\/\/10\.0\.2\.2:19333\/[a-f0-9-]{36}$/.test(endpoint)) throw Error('Invalid test endpoint');
const run = (...args) => {
  const result = spawnSync(hdc, args, { encoding: 'utf8', windowsHide: true, timeout: 10000 });
  if (result.error || result.status !== 0) throw Error('HDC command failed: ' + args.slice(0, 3).join(' '));
  return result.stdout || '';
};
const raw = fs.createWriteStream(path.join(out, `runtime-${round}-raw.log`));
const reader = spawn(hdc, ['shell', 'hilog'], { windowsHide: true });
let lineBuffer = '', done = false, foreground = false, observedPid = '', launched = false;
const save = () => {
  fs.writeFileSync(path.join(out, `runtime-${round}-records.json`), JSON.stringify(records, null, 2));
  fs.writeFileSync(path.join(out, `runtime-${round}-observations.json`), JSON.stringify({ observations, commands }, null, 2));
};
function sample(stage) {
  const pid = run('shell', 'pidof', 'com.linkora.player').trim().split(/\s+/)[0];
  if (!/^\d+$/.test(pid)) return observations.push({ stage, unavailable: true });
  observedPid = pid;
  const status = run('shell', 'cat', `/proc/${pid}/status`);
  observations.push({ stage, pid: Number(pid), at: Date.now(),
    threads: Number(status.match(/Threads:\s+(\d+)/)?.[1] || 0), rssKb: Number(status.match(/VmRSS:\s+(\d+)/)?.[1] || 0) });
  save();
}
function abilityState(output, expected) {
  const block = output.split(/(?=Mission ID #)/).find(item => item.includes('com.linkora.player:entry:EntryAbility')) || '';
  return block.includes('state #' + expected);
}
function handle(line) {
  const at = line.indexOf('LINKORA_FFMPEG_SMOKE:');
  if (at < 0 || done || !launched) return;
  const record = JSON.parse(line.slice(at + 'LINKORA_FFMPEG_SMOKE:'.length));
  // Ignore stale native smoke records from a prior process.
  if (observedPid && !line.includes(' ' + observedPid + ' ')) return;
  records.push({ at: Date.now(), record }); save();
  if (record.case === 'native-initialize') sample('native-initialize');
  if (record.case === 'lifecycle-start') sample('lifecycle-start');
  if (record.case === 'lifecycle-5' && (round === '01' || round === '03')) {
    run('shell', 'uitest', 'uiInput', 'keyEvent', 'Home');
    const state = run('shell', 'hidumper', '-s', 'AbilityManagerService', '-a', '-l');
    commands.push({ case: 'background', at: Date.now(), backgroundObserved: abilityState(state, 'BACKGROUND') });
    setTimeout(() => {
      const reply = run('shell', 'aa', 'start', '-a', 'EntryAbility', '-b', 'com.linkora.player');
      const state = run('shell', 'hidumper', '-s', 'AbilityManagerService', '-a', '-l');
      foreground = abilityState(state, 'FOREGROUND');
      commands.push({ case: 'foreground', at: Date.now(), started: reply.includes('successfully'), foregroundObserved: foreground }); save();
    }, 1500);
  }
  if (record.case === 'lifecycle-10') sample('lifecycle-10');
  if (record.case === 'complete') {
    done = true; sample('complete');
    console.log(JSON.stringify({ round, result: record, backgroundForeground: (round === '01' || round === '03') ? foreground : null }));
    reader.kill(); raw.end(); clearTimeout(deadline);
    process.exitCode = record.status === 'PASS' ? 0 : 1;
  }
}
reader.stdout.on('data', data => {
  raw.write(data); lineBuffer += data.toString('utf8');
  while (lineBuffer.includes('\n')) {
    const end = lineBuffer.indexOf('\n'), line = lineBuffer.slice(0, end).trim(); lineBuffer = lineBuffer.slice(end + 1);
    try { handle(line); } catch (error) { console.error('Evidence collection failed: ' + error.message); }
  }
});
reader.stderr.on('data', data => raw.write(data));
const deadline = setTimeout(() => { done = true; reader.kill(); raw.end(); save(); console.error('Runtime evidence timed out'); process.exitCode = 1; }, 180000);
// Give the streaming logger time to attach before cold-launching; no buffer clearing.
setTimeout(() => {
  run('shell', 'aa', 'force-stop', 'com.linkora.player');
  observedPid = '';
  const reply = run('shell', 'aa', 'start', '-a', 'EntryAbility', '-b', 'com.linkora.player', '--ps', 'linkoraFfmpegSmoke', endpoint);
  sample('cold-launch'); launched = true;
  commands.push({ case: 'cold-launch', at: Date.now(), started: reply.includes('successfully') }); save();
}, 500);
