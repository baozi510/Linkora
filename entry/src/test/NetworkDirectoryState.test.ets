import { describe, expect, it } from '@ohos/hypium';
import { networkDirectoryDetail, networkDirectoryPathDetail } from '../main/ets/components/NetworkDirectoryLabels';
import { NetworkDirectoryLoadGuard } from '../main/ets/models/NetworkDirectoryState';
import { NetworkDirectorySummary } from '../main/ets/services/NetworkDirectorySummaryCache';
import { fileBrowserGridColumnsTemplate } from '../main/ets/components/FileBrowserGridLayout';

export default function networkDirectoryStateTest(): void {
  describe('NetworkDirectoryState', () => {
    it('uses equal cells for folders and files at every window breakpoint', 0, () => {
      expect(fileBrowserGridColumnsTemplate(0)).assertEqual('1fr 1fr');
      expect(fileBrowserGridColumnsTemplate(599)).assertEqual('1fr 1fr');
      expect(fileBrowserGridColumnsTemplate(600)).assertEqual('1fr 1fr 1fr');
      expect(fileBrowserGridColumnsTemplate(839)).assertEqual('1fr 1fr 1fr');
      expect(fileBrowserGridColumnsTemplate(840)).assertEqual('1fr 1fr 1fr 1fr');
    });

    it('only accepts the newest directory request', 0, () => {
      const guard: NetworkDirectoryLoadGuard = new NetworkDirectoryLoadGuard();
      const first: number = guard.next();
      const second: number = guard.next();

      expect(guard.isCurrent(first)).assertFalse();
      expect(guard.isCurrent(second)).assertTrue();

      guard.cancel();
      expect(guard.isCurrent(second)).assertFalse();
    });

    it('describes folders by their direct contents', 0, () => {
      expect(networkDirectoryDetail(null)).assertEqual('文件夹');
      expect(networkDirectoryDetail(new NetworkDirectorySummary('empty', 0, 0, 0)))
        .assertEqual('空文件夹');
      expect(networkDirectoryDetail(new NetworkDirectorySummary('media', 0, 0, 10)))
        .assertEqual('10 个文件夹');
      expect(networkDirectoryDetail(new NetworkDirectorySummary('mixed', 2, 14 * 1024 * 1024 * 1024, 10)))
        .assertEqual('10 个文件夹 · 2 个文件');
      expect(networkDirectoryPathDetail(
        new NetworkDirectorySummary('mixed', 2, 14 * 1024 * 1024 * 1024, 10)))
        .assertEqual('10 个文件夹 · 2 个文件 · 14 GB');
    });
  });
}
