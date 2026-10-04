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
test('default confirms FFmpeg and existing libraries are AArch64', () => {
  assert.equal(checkNativeEntries([{ name: 'libs/arm64-v8a/liblinkora_ffmpeg.so', data: elf(183) },
    { name: 'libs/arm64-v8a/libmpv.so', data: elf(183) },
    { name: 'libs/arm64-v8a/libmpv_wrapper.so', data: elf(183) },
    { name: 'libs/arm64-v8a/libaki_jsbind.so', data: elf(183) }], 'arm64-v8a'), 4);
});
test('rejects missing analyzer and unrecognized ELF', () => {
  assert.throws(() => checkNativeEntries([], 'arm64-v8a'));
  assert.throws(() => checkNativeEntries([{ name: 'libs/arm64-v8a/liblinkora_ffmpeg.so', data: Buffer.alloc(64) }], 'arm64-v8a'));
});
test('rejects default HAP polluted by simulator MPV dependency override', () => {
  assert.throws(() => checkNativeEntries([{ name: 'libs/arm64-v8a/liblinkora_ffmpeg.so', data: elf(183) }], 'arm64-v8a'),
    /Missing production MPV library/);
});
