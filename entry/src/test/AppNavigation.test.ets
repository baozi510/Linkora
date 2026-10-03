import { describe, expect, it } from '@ohos/hypium';
import { MediaSource } from 'linkora_core';
import { AppNavigationParams, NetworkDirectoryDestinationParams, PlayerDestinationParams,
  SettingsDetail, SettingsDetailDestinationParams } from
  '../main/ets/models/AppNavigation';
import { DirectoryHistory } from '../main/ets/models/DirectoryHistory';
import { LocalFolderPageData } from '../main/ets/models/LocalFolderPageData';

export default function appNavigationTest(): void {
  describe('AppNavigationParams', () => {
    it('acceptsOnlyValidSettingsDetailParams', 0, () => {
      expect(AppNavigationParams.settingsDetail(
        new SettingsDetailDestinationParams(SettingsDetail.APPEARANCE))?.detail)
        .assertEqual(SettingsDetail.APPEARANCE);
      expect(AppNavigationParams.settingsDetail(new NetworkDirectoryDestinationParams(7))).assertNull();
    });

    it('acceptsOnlyPositiveServerIds', 0, () => {
      expect(AppNavigationParams.networkDirectory(new NetworkDirectoryDestinationParams(7))?.serverId)
        .assertEqual(7);
      expect(AppNavigationParams.networkDirectory(new NetworkDirectoryDestinationParams(0))).assertNull();
    });

    it('acceptsOnlyPlayerDestinationParams', 0, () => {
      const source: MediaSource = MediaSource.empty();
      expect(AppNavigationParams.player(new PlayerDestinationParams(source))?.source).assertEqual(source);
      expect(AppNavigationParams.player(new NetworkDirectoryDestinationParams(7))).assertNull();
    });

    it('keepsParentDataWhenAChildFolderProjectionArrives', 0, () => {
      const parent: LocalFolderPageData = new LocalFolderPageData('folder-a');
      const child: LocalFolderPageData = new LocalFolderPageData('folder-b');

      expect(LocalFolderPageData.forRoute('folder-a', parent, child).folderUri).assertEqual('folder-a');
      expect(LocalFolderPageData.forRoute('folder-b', parent, child).folderUri).assertEqual('folder-b');
    });

    it('restoresOnlyDirectoryPathsNotPageInstances', 0, () => {
      const history: DirectoryHistory = new DirectoryHistory();
      history.enter('root');
      history.enter('movies');

      expect(history.back()).assertEqual('movies');
      expect(history.back()).assertEqual('root');
      expect(history.back()).assertNull();
    });

    it('resetsDirectoryNavigationToRoot', 0, () => {
      const history: DirectoryHistory = new DirectoryHistory();
      history.enter('');
      history.enter('movies');

      expect(history.reset()).assertEqual('');
      expect(history.back()).assertNull();
    });
  });
}
