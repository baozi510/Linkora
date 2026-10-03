const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const violations = [];

function walk(dir) {
  if (!fs.existsSync(dir)) return [];
  const result = [];
  for (const name of fs.readdirSync(dir)) {
    if (['.test', 'build', 'oh_modules'].includes(name)) continue;
    const full = path.join(dir, name);
    const stat = fs.statSync(full);
    if (stat.isDirectory()) result.push(...walk(full));
    else if (name.endsWith('.ets')) result.push(full);
  }
  return result;
}

function rel(file) {
  return path.relative(root, file).replace(/\\/g, '/');
}

function fail(file, rule, detail) {
  violations.push({ file: rel(file), rule, detail });
}

for (const file of walk(path.join(root, 'linkora_core'))) {
  const text = fs.readFileSync(file, 'utf8');
  if (/from\s+['"]@kit\./.test(text) || /from\s+['"]@ohos\./.test(text)) {
    fail(file, 'core-platform-free', 'linkora_core must not depend on HarmonyOS platform kits');
  }
  if (/from\s+['"].*(entry|linkora_proxy|linkora_media_probe)/.test(text)) {
    fail(file, 'core-no-implementation-dependency', 'linkora_core must not import implementation modules');
  }
}

for (const file of walk(path.join(root, 'entry', 'src', 'main', 'ets', 'playback'))) {
  const text = fs.readFileSync(file, 'utf8');
  if (/(WebDavBrowserService|SmbBrowserService|SftpBrowserService|FtpBrowserService|NfsBrowserService|liblinkora_)/.test(text)) {
    fail(file, 'player-no-storage-protocol', 'player code must not depend on protocol implementations');
  }
}

for (const file of walk(path.join(root, 'linkora_media_probe'))) {
  const text = fs.readFileSync(file, 'utf8');
  if (/(WebDavBrowserService|SmbBrowserService|SftpBrowserService|NetworkMediaCache|NetworkThumbnailCache)/.test(text)) {
    fail(file, 'probe-no-storage-cache', 'media probe must not depend on storage protocol/cache implementations');
  }
  if (/ImagePacker|image\/webp|\.webp/.test(text)) {
    fail(file, 'extractor-no-encoding', 'media probe/extractor must not own persistent thumbnail encoding');
  }
}

const directoryService = path.join(root, 'entry', 'src', 'main', 'ets', 'services', 'NetworkDirectoryService.ets');
if (fs.existsSync(directoryService)) {
  const text = fs.readFileSync(directoryService, 'utf8');
  if (/(WebDavBrowserService|SmbBrowserService|SftpBrowserService|FtpBrowserService|NfsBrowserService)/.test(text)) {
    fail(directoryService, 'directory-service-provider-only',
      'NetworkDirectoryService must resolve through NetworkStorageProvider');
  }
}

for (const base of [
  path.join(root, 'entry', 'src', 'main', 'ets', 'pages'),
  path.join(root, 'entry', 'src', 'main', 'ets', 'components')
]) {
  for (const file of walk(base)) {
    const text = fs.readFileSync(file, 'utf8');
    if (/from\s+['"].*(MpvPlaybackPort|SystemPlaybackPort|NetworkFileProxy)/.test(text)) {
      fail(file, 'ui-no-backend-implementation', 'UI must use feature/controller abstractions');
    }
  }
}

if (violations.length > 0) {
  console.error('Architecture boundary violations:');
  for (const item of violations) {
    console.error(`- ${item.file} [${item.rule}] ${item.detail}`);
  }
  process.exit(1);
}

console.log('Architecture boundary checks passed.');
