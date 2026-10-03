import networkMediaProbeTest from './NetworkMediaProbe.test';
import networkLinkParserTest from './NetworkLinkParser.test';
import mediaSourceTest from './MediaSource.test';
import architectureContractsTest from './ArchitectureContracts.test';
import playbackEngineTest from './PlaybackEngine.test';
import playbackBookmarkTest from './PlaybackBookmark.test';
import failureCatalogTest from './FailureCatalog.test';
import localMediaAssetTest from './LocalMediaAsset.test';
import featureModulesTest from './FeatureModules.test';
import playerGestureControllerTest from './PlayerGestureController.test';
import networkAddressParserTest from './NetworkAddressParser.test';
import localMediaOrderingTest from './LocalMediaOrdering.test';
import appNavigationTest from './AppNavigation.test';
import networkDirectoryStateTest from './NetworkDirectoryState.test';
import networkFileProxyTest from './NetworkFileProxy.test';

export default function testsuite(): void {
  networkLinkParserTest();
  mediaSourceTest();
  architectureContractsTest();
  playbackEngineTest();
  playbackBookmarkTest();
  failureCatalogTest();
  localMediaAssetTest();
  featureModulesTest();
  playerGestureControllerTest();
  networkAddressParserTest();
  localMediaOrderingTest();
  appNavigationTest();
  networkDirectoryStateTest();
  networkFileProxyTest();
  networkMediaProbeTest();
}
