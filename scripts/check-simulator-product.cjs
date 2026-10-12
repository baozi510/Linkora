'use strict';

const fs = require('node:fs');
const path = require('node:path');

const root = path.resolve(__dirname, '..');
const failures = [];
for (const target of ['default', 'simulator']) {
  const diagnostics = path.join(root, 'entry/src', target, 'RuntimeDiagnostics.ets');
  if (!fs.existsSync(diagnostics)) failures.push(`${target} RuntimeDiagnostics target boundary missing`);
}
const noopPath = path.join(root, 'entry/src/default/RuntimeDiagnostics.ets');
if (fs.existsSync(noopPath)) {
  const noop = fs.readFileSync(noopPath, 'utf8');
  if (/linkora_ffmpeg|FfmpegRuntimeSmoke|AnalyzerIntegrationSmoke|NetworkFileProxy|http\./.test(noop)) failures.push('default diagnostics must remain no-op');
}
const commonFiles = fs.readdirSync(path.join(root, 'entry/src/main/ets'), { recursive: true });
for (const file of commonFiles.filter(name => name.endsWith('.ets'))) {
  const source = fs.readFileSync(path.join(root, 'entry/src/main/ets', file), 'utf8');
  if (/linkora_ffmpeg\/Native|FfmpegRuntimeSmoke|AnalyzerIntegrationSmoke/.test(source)) failures.push('common source must delegate diagnostics through target boundary: ' + file);
}

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
const defaultProduct = project.app.products.find(item => item.name === 'default');
check(!!simulatorProduct, 'simulator product is missing');
check(defaultProduct && defaultProduct.bundleName === undefined,
  'default product must preserve AppScope bundle identity');
check(simulatorProduct && simulatorProduct.bundleName === 'com.linkora.player.simulator',
  'simulator must use a distinct non-destructive bundle identity');
const appScope = json5('AppScope/app.json5');
check(appScope.app.bundleName === 'com.linkora.player',
  'production AppScope bundle identity must remain unchanged');

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
check(defaultTarget && !defaultTarget.source.sourceRoots.includes('./src/simulator'),
  'default target must exclude simulator diagnostics source root');
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
// Only the documented ohpm parameterFile route can select the stub.
const rootPackage = json5('oh-package.json5');
const mpvDefaultParams = json5('oh-package-default-params.json5');
const mpvSimulatorParams = json5('oh-package-simulator-params.json5');
check(rootPackage.parameterFile === './oh-package-default-params.json5',
  'default ohpm parameterFile must preserve the production dependency');
check(entryPackage.dependencies['@mpv-ohos/mpv-arkts'] === '@param:dependencies.mpv',
  'entry MPV dependency must resolve via documented @param reference');
check(!Object.prototype.hasOwnProperty.call(entryPackage, 'simulatorTargetDependencies'),
  'remove unsupported unconsumed simulatorTargetDependencies declaration');
check(mpvDefaultParams.dependencies && mpvDefaultParams.dependencies.mpv === '1.0.0',
  'default MPV param must resolve real production 1.0.0');
check(mpvSimulatorParams.dependencies &&
  mpvSimulatorParams.dependencies.mpv === './entry/simulator-stubs/mpv-arkts',
  'simulator MPV param must resolve the local compile-only stub from project root');
const stubManifest = json5('entry/simulator-stubs/mpv-arkts/oh-package.json5');
check(stubManifest.name === '@mpv-ohos/mpv-arkts' && stubManifest.version === '1.0.0' &&
  stubManifest.modelVersion === '5.0.0' && stubManifest.main === 'Index.ets',
  'simulator MPV stub must provide a parseable named versioned HAR package');
const stubModule = project.modules.find(item => item.name === 'mpv_simulator_stub');
check(stubModule && stubModule.srcPath === './entry/simulator-stubs/mpv-arkts' &&
  stubModule.targets.length === 1 &&
  stubModule.targets[0].name === 'default' &&
  JSON.stringify(stubModule.targets[0].applyToProducts) === JSON.stringify(['simulator']),
  'simulator MPV HAR module must be registered only for simulator product');
const stubProfile = json5('entry/simulator-stubs/mpv-arkts/build-profile.json5');
const stubDescriptor = json5('entry/simulator-stubs/mpv-arkts/src/main/module.json5');
check(stubProfile.apiType === 'stageMode' &&
  stubProfile.targets.some(item => item.name === 'default'),
  'simulator MPV HAR module must have a source target');
check(stubDescriptor.module.name === 'mpv_simulator_stub' &&
  stubDescriptor.module.type === 'har',
  'simulator MPV HAR module descriptor must match registered module name');
check(read('entry/simulator-stubs/mpv-arkts/hvigorfile.ts').includes('harTasks'),
  'simulator MPV HAR module must use harTasks');

// A source declaration is never proof of installed target dependency resolution.
// Caller may supply the REAL generated simulator ohpm lock after an authorized
// ohpm --pf install; failing it blocks subsequent simulator artifact acceptance.
const lockAt = process.argv.indexOf('--simulator-lock');
if (lockAt >= 0) {
  const supplied = process.argv[lockAt + 1];
  if (!supplied || supplied.startsWith('--')) {
    failures.push('--simulator-lock requires a generated lockfile path');
  } else {
    const lockPath = path.resolve(root, supplied);
    if (!lockPath.startsWith(root + path.sep)) {
      failures.push('--simulator-lock must stay inside the isolated project');
    } else {
      try {
        const lock = JSON.parse(fs.readFileSync(lockPath, 'utf8'));
        const records = Object.values(lock.packages || {}).filter(item =>
          item && item.name === '@mpv-ohos/mpv-arkts');
        check(records.length === 1, 'simulator resolved lock must contain exactly one MPV dependency');
        const pkg = records[0];
        if (pkg) {
          const resolved = String(pkg.resolved || '').replace(/\\/g, '/');
          check(pkg.registryType === 'local' &&
            resolved.includes('simulator-stubs/mpv-arkts') &&
            !resolved.includes('https://'),
            'simulator lock must resolve local MPV stub, never remote production native HAR');
        }
      } catch (_error) {
        failures.push('cannot read/parse actual generated simulator dependency lock');
      }
    }
  }
}

const required = [
  'entry/src/default/PlaybackComposition.ets',
  'entry/src/simulator/PlaybackComposition.ets',
  'entry/src/default/RuntimeProfile.ets',
  'entry/src/simulator/RuntimeProfile.ets',
  'entry/src/simulator/ets/services/DefaultNetworkStorageProviders.ets',
  'entry/src/simulator/ets/adapters/NetworkProtocolTestRegistry.ets',
  'entry/simulator-stubs/mpv-arkts/Index.ets',
  'entry/simulator-stubs/mpv-arkts/hvigorfile.ts',
  'entry/simulator-stubs/mpv-arkts/build-profile.json5',
  'entry/simulator-stubs/mpv-arkts/src/main/module.json5'
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

console.log(lockAt >= 0 ?
  'Simulator source and supplied resolved lock checks passed (HAP ABI audit still required).' :
  'Simulator source checks passed; effective MPV dependency NOT VERIFIED (use --simulator-lock after ohpm --pf).');
