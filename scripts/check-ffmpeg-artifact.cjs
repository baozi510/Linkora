'use strict';
const fs = require('node:fs'), zlib = require('node:zlib');
function checkNativeEntries(entries, abi) {
  if (!['x86_64', 'arm64-v8a'].includes(abi)) throw Error('Unsupported ABI');
  const expected = abi === 'x86_64' ? 62 : 183;
  let analyzer = 0;
  for (const entry of entries) {
    if (!entry.name.endsWith('.so')) continue;
    if (entry.data.length < 64 || !entry.data.subarray(0, 4).equals(Buffer.from([0x7f, 0x45, 0x4c, 0x46])) ||
      entry.data[4] !== 2 || entry.data[5] !== 1 || entry.data.readUInt16LE(18) !== expected ||
      !entry.name.startsWith(`libs/${abi}/`)) throw Error('Native ELF/ABI mismatch: ' + entry.name);
    if (entry.name.endsWith('/liblinkora_ffmpeg.so')) analyzer++;
    else if (abi === 'x86_64') throw Error('Unapproved simulator native library: ' + entry.name);
  }
  if (analyzer !== 1) throw Error('Expected exactly one liblinkora_ffmpeg.so; got ' + analyzer);
  if (abi === 'arm64-v8a') {
    for (const name of ['libmpv.so', 'libmpv_wrapper.so', 'libaki_jsbind.so']) {
      if (!entries.some(entry => entry.name === `libs/arm64-v8a/${name}`)) throw Error('Missing production MPV library: ' + name);
    }
  }
  return entries.filter(entry => entry.name.endsWith('.so')).length;
}
function nativeEntries(file) {
  const zip = fs.readFileSync(file);
  let end = zip.length - 22;
  while (end >= Math.max(0, zip.length - 65557) && zip.readUInt32LE(end) !== 0x06054b50) end--;
  if (end < Math.max(0, zip.length - 65557)) throw Error('ZIP end record not found');
  let offset = zip.readUInt32LE(end + 16); const count = zip.readUInt16LE(end + 10), entries = [];
  for (let i = 0; i < count; i++) {
    if (zip.readUInt32LE(offset) !== 0x02014b50) throw Error('Invalid ZIP central directory');
    const method = zip.readUInt16LE(offset + 10), size = zip.readUInt32LE(offset + 20);
    const length = zip.readUInt16LE(offset + 28), extra = zip.readUInt16LE(offset + 30), comment = zip.readUInt16LE(offset + 32);
    const name = zip.subarray(offset + 46, offset + 46 + length).toString('utf8');
    if (name.endsWith('.so')) {
      const local = zip.readUInt32LE(offset + 42);
      if (zip.readUInt32LE(local) !== 0x04034b50) throw Error('Invalid ZIP local header');
      const start = local + 30 + zip.readUInt16LE(local + 26) + zip.readUInt16LE(local + 28);
      const compressed = zip.subarray(start, start + size);
      const data = method === 0 ? compressed : method === 8 ? zlib.inflateRawSync(compressed, { maxOutputLength: 512 * 1024 * 1024 }) : null;
      if (!data || data.length !== zip.readUInt32LE(offset + 24)) throw Error('Unsupported/truncated native ZIP entry');
      entries.push({ name, data });
    }
    offset += 46 + length + extra + comment;
  }
  return entries;
}
module.exports = { checkNativeEntries, nativeEntries };
if (require.main === module) {
  const [file, abi] = process.argv.slice(2);
  console.log(`FFmpeg/native artifact ABI audit PASS: ${checkNativeEntries(nativeEntries(file), abi)} libraries (${abi})`);
}
