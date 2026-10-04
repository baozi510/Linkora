'use strict';
// Compare real adapter records with independent host fixture truth. No performance acceptance.
const fs = require('node:fs'), path = require('node:path'), assert = require('node:assert/strict');
const directory = path.resolve(process.argv[2] || 'artifacts/analyzer-phase2');
const truth = JSON.parse(fs.readFileSync(path.join(directory, 'fixture-truth.json')));
const records = fs.readFileSync(path.join(directory, 'functional-results.ndjson'), 'utf8').trim().split(/\r?\n/).map(JSON.parse);
const checks = [], rows = [];
function check(name, actual, expected, tolerance = 0) {
  const passed = tolerance ? Math.abs(actual - expected) <= tolerance : actual === expected;
  checks.push({ check: name, actual, expected, passed });
}
const fraction = text => { const [a, b] = text.split('/').map(Number); return b ? a / b : 0; };
for (const fixture of [...truth.fixtures, { ...truth.fixtures.find(item => item.name === 'long-gop.mkv'), name: 'webdav' }]) {
  const t = fixture.truth, videos = t.streams.filter(s => s.codec_type === 'video'), audio = t.streams.filter(s => s.codec_type === 'audio'), subtitles = t.streams.filter(s => s.codec_type === 'subtitle');
  for (const engine of ['system', 'ffmpeg']) {
    const result = records.find(item => item.case === fixture.name && item.engine === engine && ['SUCCESS', 'UNAVAILABLE'].includes(item.status));
    check(`${fixture.name}/${engine}/record`, Boolean(result), true); if (!result) continue;
    check(`${fixture.name}/${engine}/activeSources`, result.activeSources, 0);
    rows.push({ fixture: fixture.name, engine, status: result.status, completeness: result.completeness, errorCode: result.errorCode, access: result.notes?.find(note => note.startsWith('access='))?.slice(7) });
    if (engine === 'system') {
      // Judge only fields the current System adapter claims. A missing codec/stream count is not zero truth.
      if (result.status === 'SUCCESS') {
        if (result.info.durationMs) check(`${fixture.name}/system/duration`, result.info.durationMs, Math.round(Number(t.format.duration) * 1000), 100);
        if (result.info.videoTracks[0]?.width) check(`${fixture.name}/system/width`, result.info.videoTracks[0].width, videos[0].width);
        if (result.info.videoTracks[0]?.height) check(`${fixture.name}/system/height`, result.info.videoTracks[0].height, videos[0].height);
        check(`${fixture.name}/system/unclaimedAudio`, result.info.audioTracks.length, 0);
        check(`${fixture.name}/system/unclaimedCodec`, result.info.videoTracks[0]?.codec || '', '');
      } else check(`${fixture.name}/system/unavailableIsError`, result.errorCode > 0, true);
      continue;
    }
    check(`${fixture.name}/ffmpeg/success`, result.status, 'SUCCESS'); if (!result.info) continue;
    const info = result.info;
    check(`${fixture.name}/ffmpeg/container`, info.container, t.format.format_name);
    check(`${fixture.name}/ffmpeg/duration`, info.durationMs, Math.round(Number(t.format.duration) * 1000), 100);
    for (const [kind, actual, expected] of [['video', info.videoTracks, videos], ['audio', info.audioTracks, audio], ['subtitle', info.subtitleTracks, subtitles]]) {
      check(`${fixture.name}/${kind}/count`, actual.length, expected.length);
      expected.forEach((stream, i) => {
        const track = actual[i]; if (!track) return;
        check(`${fixture.name}/${kind}${i}/codec`, track.codec, stream.codec_name);
        for (const field of ['language', 'title']) if (stream.tags?.[field]) check(`${fixture.name}/${kind}${i}/${field}`, track[field], stream.tags[field]);
        if (kind === 'video') {
          check(`${fixture.name}/video${i}/profile`, track.profile, stream.profile);
          check(`${fixture.name}/video${i}/width`, track.width, stream.width); check(`${fixture.name}/video${i}/height`, track.height, stream.height);
          check(`${fixture.name}/video${i}/frameRate`, track.frameRate, fraction(stream.avg_frame_rate), 0.001);
          check(`${fixture.name}/video${i}/bitDepth`, track.bitDepth, stream.pix_fmt.includes('10') ? 10 : 8);
          check(`${fixture.name}/video${i}/pixelFormat`, track.pixelFormat, stream.pix_fmt);
          for (const [a, b] of [['transfer', 'color_transfer'], ['colorPrimaries', 'color_primaries'], ['colorSpace', 'color_space']]) if (stream[b]) check(`${fixture.name}/video${i}/${a}`, track[a], stream[b]);
          const hdr = stream.color_transfer === 'smpte2084' ? 'hdr10' : stream.color_transfer === 'arib-std-b67' ? 'hlg' : 'sdr';
          check(`${fixture.name}/video${i}/hdrType`, track.hdrType, hdr);
        } else if (kind === 'audio') {
          check(`${fixture.name}/audio${i}/channels`, track.channels, stream.channels);
          check(`${fixture.name}/audio${i}/sampleRate`, track.sampleRate, Number(stream.sample_rate));
          check(`${fixture.name}/audio${i}/profile`, track.profile, stream.profile);
        } else check(`${fixture.name}/subtitle${i}/kind`, track.kind, 'text');
      });
    }
  }
}
const thumbnails = records.filter(item => item.case.endsWith('-thumbnail') && item.status === 'SUCCESS');
for (const thumbnail of thumbnails) {
  check(`${thumbnail.case}/${thumbnail.engine}/bounds`, thumbnail.width > 0 && thumbnail.width <= 480 && thumbnail.height > 0 && thumbnail.height <= 270, true);
  check(`${thumbnail.case}/${thumbnail.engine}/webp`, thumbnail.webp, true);
  if (thumbnail.engine === 'ffmpeg') { check(`${thumbnail.case}/rgba`, thumbnail.pixelFormat, 'rgba_8888'); check(`${thumbnail.case}/bytes`, thumbnail.bytesValid, true); }
}
check('ffmpegThumbnailCount', thumbnails.filter(item => item.engine === 'ffmpeg').length, 9);
const summary = records.findLast(item => item.case === 'summary');
check('runtimeSummary', summary?.status, 'PASS'); check('runtimeFailures', summary?.failed, 0); check('finalActiveSources', summary?.activeSources, 0); check('ownedServerRemoved', summary?.removedOwnedServer, true);
const ledger = JSON.parse(fs.readFileSync(path.join(directory, 'upstream-range-ledger.json')));
const ranges = ledger.filter(item => item.method === 'GET' && item.ownFixture).map(item => ({ case: item.case, start: Number(/^bytes=(\d+)-/.exec(item.range || '')?.[1] || -1), end: Number(/-(\d+)$/.exec(item.range || '')?.[1] || -1) }));
check('webdavAllGETsUseRange', ranges.length > 0 && ranges.every(range => range.start >= 0 && range.end >= range.start), true);
const frameRanges = ranges.filter(item => item.case === 'webdav-ffmpeg-thumbnail');
const remoteSize = Number(truth.fixtures.find(item => item.name === 'long-gop.mkv').truth.format.size);
const rangeBytes = frameRanges.reduce((sum, item) => sum + item.end - item.start + 1, 0);
check('webdav70PercentFrameNonzeroOffset', frameRanges.some(item => item.start > remoteSize * 0.5), true);
check('webdav70PercentFrameAvoidsFullSequentialDownload', rangeBytes > 0 && rangeBytes < remoteSize * 0.5, true);
const output = { checks: checks.length, passed: checks.filter(item => item.passed).length, failed: checks.filter(item => !item.passed).length, rows,
  thumbnails: thumbnails.map(item => ({ fixture: item.case, engine: item.engine, width: item.width, height: item.height, requestedTimeMs: item.requestedTimeMs, webp: item.webp })),
  randomAccess: { remoteSize, rangeReads: frameRanges.length, rangeBytes, maxOffset: Math.max(...frameRanges.map(item => item.start)), fullSequentialDownload: false }, details: checks };
fs.writeFileSync(path.join(directory, 'functional-checks.json'), JSON.stringify(output, null, 2) + '\n');
console.log(`Functional truth/cleanup checks: ${output.passed}/${output.checks} PASS`);
for (const failure of checks.filter(item => !item.passed)) console.error(JSON.stringify(failure));
assert.equal(output.failed, 0, 'Functional acceptance failed; see functional-checks.json');
