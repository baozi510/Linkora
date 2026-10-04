'use strict';

const fs = require('node:fs');
const path = require('node:path');

const root = path.resolve(__dirname, '..');
const failures = [];

function read(relative) {
  return fs.readFileSync(path.join(root, relative), 'utf8').replace(/^\uFEFF/, '');
}

function json5(relative) {
  return Function('"use strict"; return (' + read(relative) + ');')();
}

function check(condition, message) {
  if (!condition) failures.push(message);
}

const project = json5('build-profile.json5');
const entry = json5('entry/build-profile.json5');
const entryPackage = json5('entry/oh-package.json5');
const ffmpeg = json5('linkora_ffmpeg/build-profile.json5');
const ffmpegModule = project.modules.find(item => item.name === 'linkora_ffmpeg');
check(!!ffmpegModule, 'linkora_ffmpeg module is required');
for (const [target, abi, product] of [['default', 'arm64-v8a', 'default'], ['simulator', 'x86_64', 'simulator']]) {
  const config = ffmpeg.targets.find(item => item.name === target);
  check(config && JSON.stringify(config.config.buildOption.externalNativeOptions.abiFilters) === JSON.stringify([abi]),
    `linkora_ffmpeg@${target} must build only ${abi}`);
  const moduleTarget = ffmpegModule && ffmpegModule.targets.find(item => item.name === target);
  check(moduleTarget && JSON.stringify(moduleTarget.applyToProducts) === JSON.stringify([product]),
    `linkora_ffmpeg@${target} must apply only to ${product}`);
}
check(entryPackage.dependencies.linkora_ffmpeg === 'file:../linkora_ffmpeg', 'entry must package linkora_ffmpeg');
const hvigor = json5('hvigor/hvigor-config.json5');

const simulatorProduct = project.app.products.find(item => item.name === 'simulator');
check(!!simulatorProduct, 'simulator product is missing');
check(simulatorProduct && simulatorProduct.bundleName === undefined,
  'simulator product must not override the production bundleName');
const appScope = json5('AppScope/app.json5');
check(appScope.app.bundleName === 'com.linkora.player',
  'simulator and default must share the production app identity');

const entryModule = project.modules.find(item => item.name === 'entry');
const projectDefaultTarget = entryModule && entryModule.targets.find(item => item.name === 'default');
const projectSimulatorTarget = entryModule && entryModule.targets.find(item => item.name === 'simulator');
check(projectDefaultTarget && projectDefaultTarget.applyToProducts.includes('default'),
  'entry@default must remain on default product');
check(projectDefaultTarget && !projectDefaultTarget.applyToProducts.includes('simulator'),
  'entry@default must not be packaged into simulator product');
check(projectSimulatorTarget && projectSimulatorTarget.applyToProducts.includes('simulator'),
  'entry@simulator must apply to simulator product');

const defaultTarget = entry.targets.find(item => item.name === 'default');
const simulatorTarget = entry.targets.find(item => item.name === 'simulator');
check(defaultTarget && defaultTarget.source.sourceRoots.includes('./src/default'),
  'default target must use src/default');
check(defaultTarget && defaultTarget.config && defaultTarget.config.buildOption &&
  defaultTarget.config.buildOption.externalNativeOptions.abiFilters.includes('arm64-v8a'),
  'default target must retain arm64-v8a native build');
check(simulatorTarget && simulatorTarget.source.sourceRoots.includes('./src/simulator'),
  'simulator target must use src/simulator');
check(simulatorTarget && !(simulatorTarget.buildOption && simulatorTarget.buildOption.externalNativeOptions) &&
  !(simulatorTarget.config && simulatorTarget.config.buildOption &&
    simulatorTarget.config.buildOption.externalNativeOptions),
  'entry@simulator must not build production native libraries');

check(hvigor.dependencies['@ohos/hvigor-multi-target-package-plugin'] === '7.0.0',
  'multi-target package plugin 7.0.0 is required');
check(entryPackage.simulatorTargetDependencies &&
  entryPackage.simulatorTargetDependencies['@mpv-ohos/mpv-arkts'] === 'file:./simulator-stubs/mpv-arkts',
  'simulator target must replace only the MPV native package with the compile-only stub');

const required = [
  'entry/src/default/PlaybackComposition.ets',
  'entry/src/simulator/PlaybackComposition.ets',
  'entry/src/default/RuntimeProfile.ets',
  'entry/src/simulator/RuntimeProfile.ets',
  'entry/src/simulator/ets/services/DefaultNetworkStorageProviders.ets',
  'entry/src/simulator/ets/adapters/NetworkProtocolTestRegistry.ets',
  'entry/simulator-stubs/mpv-arkts/Index.ets'
];
for (const relative of required) {
  check(fs.existsSync(path.join(root, relative)), relative + ' is missing');
}

const features = read('entry/src/main/ets/foundation/LinkoraFeatures.ets');
check(features.includes("from 'entry/PlaybackComposition'"),
  'LinkoraFeatures must delegate only the platform composition boundary');
check(!features.includes("from '../playback/AdaptivePlaybackPort'"),
  'LinkoraFeatures must not pin the production composition directly');

const settings = read('entry/src/main/ets/pages/SettingsPage.ets');
check(settings.includes("PlayerBackendPreference.AUTO") &&
  settings.includes("PlayerBackendPreference.SYSTEM") &&
  settings.includes("PlayerBackendPreference.MPV"),
  'simulator must retain the same Auto/System/MPV settings UI as production');
check(!settings.includes("RuntimeProfile"),
  'production settings UI must not be forked for simulator');

const networkPage = read('entry/src/main/ets/pages/NetworkPage.ets');
check(networkPage.includes("from 'entry/ets/adapters/NetworkProtocolTestRegistry'"),
  'NetworkPage must resolve only the target-specific protocol transport registry');
check(!networkPage.includes("RuntimeProfile.supportsNetworkProtocol"),
  'simulator must not hide production protocol configuration UI');
for (const protocol of ['SMB', 'SFTP', 'FTP', 'NFS', 'WEBDAV']) {
  check(networkPage.includes('RemoteProtocol.' + protocol) ||
    networkPage.includes('NETWORK_PROTOCOL_CAPABILITIES'),
    'network UI must retain protocol surface: ' + protocol);
}

const directory = read('entry/src/main/ets/services/NetworkDirectoryService.ets');
check(directory.includes("from 'entry/ets/services/DefaultNetworkStorageProviders'"),
  'NetworkDirectoryService must resolve only the target-specific transport registry');

const simulatorPlayback = read('entry/src/simulator/PlaybackComposition.ets');
check(simulatorPlayback.includes('AdaptivePlaybackPort'),
  'simulator must retain the production AdaptivePlaybackPort and BackendSelector');
check(!simulatorPlayback.includes('SimulatorSystemPlaybackPort'),
  'simulator must not replace the whole playback stack with a System-only wrapper');

const defaultPlayback = read('entry/src/default/PlaybackComposition.ets');
check(defaultPlayback.includes('AdaptivePlaybackPort'),
  'default target must retain AdaptivePlaybackPort');

const simulatorProfile = read('entry/src/simulator/RuntimeProfile.ets');
check(simulatorProfile.includes('return false;') &&
  simulatorProfile.includes('supportsBackendPreference') &&
  simulatorProfile.includes('supportsNetworkProtocol'),
  'simulator RuntimeProfile must describe full product surface, not hide capabilities');

const simulatorProviders = read('entry/src/simulator/ets/services/DefaultNetworkStorageProviders.ets');
check(simulatorProviders.includes('registerSharedNetworkStorageProviders'),
  'simulator must reuse the exact shared HTTP/WebDAV provider implementation');
const sharedProviders = read('entry/src/main/ets/services/SharedNetworkStorageProviders.ets');
check(sharedProviders.includes('WebDavStorageProvider') &&
  sharedProviders.includes('DirectHttpCompatibilityProvider'),
  'shared provider module must own real WebDAV/HTTP implementations');
for (const protocol of ['SMB', 'SFTP', 'FTP', 'NFS']) {
  check(simulatorProviders.includes('RemoteProtocol.' + protocol),
    'simulator storage registry must register last-layer replacement for ' + protocol);
}
check(simulatorProviders.includes('SimulatorUnavailableNativeStorageProvider'),
  'simulator native storage replacement must fail at the transport boundary');
check(!/(SmbBrowserService|SftpBrowserService|FtpBrowserService|NfsBrowserService|liblinkora_)/.test(simulatorProviders),
  'simulator transport replacement must not import arm64 native protocol implementations');
check(!simulatorProviders.includes('WebDavBrowserService'),
  'simulator must not duplicate the shared WebDAV provider implementation');

const simulatorTests = read('entry/src/simulator/ets/adapters/NetworkProtocolTestRegistry.ets');
for (const protocol of ['SMB', 'SFTP', 'FTP', 'NFS']) {
  check(simulatorTests.includes('RemoteProtocol.' + protocol) ||
    simulatorTests.includes(protocol[0] + protocol.slice(1).toLowerCase() + 'ProtocolTestAdapter'),
    'simulator protocol-test registry must preserve protocol surface: ' + protocol);
}
check(simulatorTests.includes('SIMULATOR_NATIVE_TRANSPORT_UNAVAILABLE'),
  'simulator must explicitly identify unavailable native transport tests');

const stub = read('entry/simulator-stubs/mpv-arkts/Index.ets');
check(stub.includes('intentionally unavailable in the x86_64 simulator validation target'),
  'MPV simulator stub must fail closed only when the native backend is instantiated');

if (failures.length > 0) {
  console.error('Simulator product validation failed:');
  for (const failure of failures) console.error('- ' + failure);
  process.exit(1);
}

console.log('Simulator product parity/isolation checks passed.');
