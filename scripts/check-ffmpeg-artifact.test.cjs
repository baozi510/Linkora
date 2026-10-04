'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { checkNativeEntries } = require('./check-ffmpeg-artifact.cjs');
function elf(machine) {
  const bytes = Buffer.alloc(64); Buffer.from([0x7f, 0x45, 0x4c, 0x46, 2, 1]).copy(bytes);
  bytes.writeUInt16LE(machine, 18); return bytes;
}
test('accepts only x86 FFmpeg in simulator', () => {
  assert.equal(checkNativeEntries([{ name: 'libs/x86_64/liblinkora_ffmpeg.so', data: elf(62) }], 'x86_64'), 1);
});
test('rejects mislabeled arm64 ELF in simulator', () => {
  assert.throws(() => checkNativeEntries([{ name: 'libs/x86_64/liblinkora_ffmpeg.so', data: elf(183) }], 'x86_64'));
});
test('rejects production native libs even when ELF is x86', () => {
  assert.throws(() => checkNativeEntries([{ name: 'libs/x86_64/liblinkora_smb.so', data: elf(62) },
    { name: 'libs/x86_64/liblinkora_ffmpeg.so', data: elf(62) }], 'x86_64'));
});
test('default confirms the complete production native set is AArch64', () => {
  const names = ['libaki_jsbind.so', 'libc++_shared.so', 'liblinkora_ffmpeg.so',
    'liblinkora_smb.so', 'liblinkora_sftp.so', 'liblinkora_ftp.so', 'liblinkora_nfs.so',
    'libmpv.so', 'libmpv_wrapper.so'];
  const entries = names.map(name => ({ name: 'libs/arm64-v8a/' + name, data: elf(183) }));
  assert.equal(checkNativeEntries(entries, 'arm64-v8a'), 9);
});
test('rejects missing analyzer and unrecognized ELF', () => {
  assert.throws(() => checkNativeEntries([], 'arm64-v8a'));
  assert.throws(() => checkNativeEntries([{ name: 'libs/arm64-v8a/liblinkora_ffmpeg.so', data: Buffer.alloc(64) }], 'arm64-v8a'));
});
test('rejects default HAP polluted by simulator dependency state', () => {
  const incomplete = [
    'libaki_jsbind.so', 'libc++_shared.so', 'liblinkora_ffmpeg.so',
    'liblinkora_smb.so', 'liblinkora_sftp.so', 'liblinkora_ftp.so'
  ].map(name => ({ name: 'libs/arm64-v8a/' + name, data: elf(183) }));
  assert.throws(() => checkNativeEntries(incomplete, 'arm64-v8a'),
    /Missing production native library/);
});
for (const missing of ['libaki_jsbind.so', 'libc++_shared.so', 'liblinkora_ffmpeg.so',
  'liblinkora_smb.so', 'liblinkora_sftp.so', 'liblinkora_ftp.so', 'liblinkora_nfs.so',
  'libmpv.so', 'libmpv_wrapper.so']) {
  test('rejects default with only ' + missing + ' missing', () => {
    const entries = ['libaki_jsbind.so', 'libc++_shared.so', 'liblinkora_ffmpeg.so',
      'liblinkora_smb.so', 'liblinkora_sftp.so', 'liblinkora_ftp.so', 'liblinkora_nfs.so',
      'libmpv.so', 'libmpv_wrapper.so'].filter(name => name !== missing)
      .map(name => ({ name: 'libs/arm64-v8a/' + name, data: elf(183) }));
    assert.throws(() => checkNativeEntries(entries, 'arm64-v8a'), missing === 'liblinkora_ffmpeg.so'
      ? /Expected exactly one liblinkora_ffmpeg/ : error => error.message === 'Missing production native library: ' + missing);
  });
}
test('rejects unknown x86 simulator native library', () => {
  assert.throws(() => checkNativeEntries([
    { name: 'libs/x86_64/liblinkora_ffmpeg.so', data: elf(62) },
    { name: 'libs/x86_64/libunexpected.so', data: elf(62) }
  ], 'x86_64'), /Unapproved simulator native library/);
});

test('rejects unknown arm64 production native library', () => {
  const names = ['libaki_jsbind.so', 'libc++_shared.so', 'liblinkora_ffmpeg.so',
    'liblinkora_smb.so', 'liblinkora_sftp.so', 'liblinkora_ftp.so', 'liblinkora_nfs.so',
    'libmpv.so', 'libmpv_wrapper.so', 'libunexpected.so'];
  const entries = names.map(name => ({ name: 'libs/arm64-v8a/' + name, data: elf(183) }));
  assert.throws(() => checkNativeEntries(entries, 'arm64-v8a'), /Unexpected production native library set/);
});
