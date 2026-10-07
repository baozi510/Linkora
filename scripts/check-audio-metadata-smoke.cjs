'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const root = path.resolve(__dirname, '..');
const diagnosticPath = path.join(root, 'entry/src/simulator/ets/diagnostics/AudioMetadataSmoke.ets');
const runtimePath = path.join(root, 'entry/src/simulator/RuntimeDiagnostics.ets');
const source = fs.readFileSync(diagnosticPath, 'utf8');
const runtime = fs.readFileSync(runtimePath, 'utf8');

assert.match(source, /AnalysisComposition\.ffmpeg\(resolver,\s*10000\)/,
  'audio metadata smoke must use the production FFmpeg probe adapter');
assert.match(source, /ProbeRequirement\.DETAIL/,
  'audio metadata smoke must request metadata detail');
assert.match(source, /info\.videoTracks\.length\s*===\s*0/,
  'audio metadata smoke must assert audio-only media has no video tracks');
assert.match(source, /info\.audioTracks\.length\s*>\s*0/,
  'audio metadata smoke must require an audio track');
assert.doesNotMatch(source, /AnalysisComposition\.thumbnail|ThumbnailExtractRequest|extractFrame\s*\(/,
  'audio metadata smoke must never request a thumbnail/frame');
assert.match(runtime, /linkoraAudioMetadataSmoke/,
  'simulator RuntimeDiagnostics must expose the audio-only metadata diagnostic');
assert.match(runtime, /AudioMetadataSmoke\.run\(context, endpoint\)/,
  'simulator RuntimeDiagnostics must execute the audio-only metadata diagnostic');

console.log('Audio-only metadata diagnostic guard passed.');
