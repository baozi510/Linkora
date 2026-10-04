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
const hvigor = json5('hvigor/hvigor-config.json5');

const simulatorProduct = project.app.products.find(item => item.name === 'simulator');
check(!!simulatorProduct, 'simulator product is missing');
check(simulatorProduct && simulatorProduct.bundleName === 'com.linkora.player.simulator',
  'simulator product must use isolated bundleName');

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
check(defaultTarget && defaultTarget.buildOption.externalNativeOptions.abiFilters.includes('arm64-v8a'),
  'default target must retain arm64-v8a native build');
check(simulatorTarget && simulatorTarget.source.sourceRoots.includes('./src/simulator'),
  'simulator target must use src/simulator');
check(simulatorTarget && !(simulatorTarget.buildOption && simulatorTarget.buildOption.externalNativeOptions),
  'simulator target must not configure CMake/native build');

check(hvigor.dependencies['@ohos/hvigor-multi-target-package-plugin'] === '7.0.0',
  'multi-target package plugin 7.0.0 is required');
check(entryPackage.simulatorTargetDependencies &&
  entryPackage.simulatorTargetDependencies['@mpv-ohos/mpv-arkts'] === 'file:./simulator-stubs/mpv-arkts',
  'simulator target must replace MPV with compile-only stub');

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
  'LinkoraFeatures must delegate playback composition to target source root');
check(!features.includes("from '../playback/AdaptivePlaybackPort'"),
  'LinkoraFeatures must not pin AdaptivePlaybackPort directly');

const directory = read('entry/src/main/ets/services/NetworkDirectoryService.ets');
check(directory.includes("from 'entry/ets/services/DefaultNetworkStorageProviders'"),
  'NetworkDirectoryService must resolve target-specific storage registry');

const networkPage = read('entry/src/main/ets/pages/NetworkPage.ets');
check(networkPage.includes("from 'entry/ets/adapters/NetworkProtocolTestRegistry'"),
  'NetworkPage must resolve target-specific protocol test registry');
check(networkPage.includes('RuntimeProfile.supportsNetworkProtocol'),
  'NetworkPage must filter protocols through RuntimeProfile');

const simulatorPlayback = read('entry/src/simulator/PlaybackComposition.ets');
check(simulatorPlayback.includes('SystemPlaybackPort'),
  'simulator playback composition must use SystemPlaybackPort');
check(!simulatorPlayback.includes('AdaptivePlaybackPort') && !simulatorPlayback.includes('MpvPlaybackPort'),
  'simulator playback composition must not reference MPV/adaptive playback');

const defaultPlayback = read('entry/src/default/PlaybackComposition.ets');
check(defaultPlayback.includes('AdaptivePlaybackPort'),
  'default target must retain AdaptivePlaybackPort');

const simulatorProfile = read('entry/src/simulator/RuntimeProfile.ets');
check(simulatorProfile.includes('PlayerBackendPreference.SYSTEM'),
  'simulator runtime profile must force System backend availability');
check(simulatorProfile.includes('RemoteProtocol.WEBDAV'),
  'simulator runtime profile must retain WebDAV');
check(!simulatorProfile.includes('RemoteProtocol.SMB') &&
  !simulatorProfile.includes('RemoteProtocol.SFTP') &&
  !simulatorProfile.includes('RemoteProtocol.FTP') &&
  !simulatorProfile.includes('RemoteProtocol.NFS'),
  'simulator runtime profile must not advertise native file protocols');

const simulatorProviders = read('entry/src/simulator/ets/services/DefaultNetworkStorageProviders.ets');
check(!/(SmbBrowserService|SftpBrowserService|FtpBrowserService|NfsBrowserService|liblinkora_)/.test(simulatorProviders),
  'simulator storage registry must not import native file protocols');

const simulatorTests = read('entry/src/simulator/ets/adapters/NetworkProtocolTestRegistry.ets');
check(!/(SmbProtocolTestAdapter|SftpProtocolTestAdapter|FtpProtocolTestAdapter|NfsProtocolTestAdapter|liblinkora_)/.test(simulatorTests),
  'simulator protocol-test registry must not import native protocol adapters');

const stub = read('entry/simulator-stubs/mpv-arkts/Index.ets');
check(stub.includes('intentionally unavailable in the x86_64 simulator validation target'),
  'MPV simulator stub must fail closed if accidentally instantiated');

if (failures.length > 0) {
  console.error('Simulator product validation failed:');
  for (const failure of failures) console.error('- ' + failure);
  process.exit(1);
}

console.log('Simulator product static checks passed.');
