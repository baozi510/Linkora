import { describe, expect, it } from '@ohos/hypium';
import { LocalBrowseMode, LocalFileCategory, LocalMediaAsset, LocalMediaAvailability,
  LocalMediaFolder, LocalMediaOrigin } from 'linkora_core';
import { LocalMediaOrdering } from '../main/ets/models/LocalMediaOrdering';
import { LocalBrowserEntry } from '../main/ets/components/LocalMediaBrowser';
import { LocalMediaAvailabilityFilter, LocalMediaSortField, LocalMediaSortOptions, LocalMediaSourceFilter,
  LocalMediaTypeFilter } from '../main/ets/models/LocalMediaViewOptions';

export default function localMediaOrderingTest(): void {
  describe('LocalMediaOrdering', () => {
    it('sortsEpisodeNamesNaturally', 0, () => {
      expect(LocalMediaOrdering.naturalText('Episode 2.mp4', 'Episode 10.mp4')).assertLess(0);
      expect(LocalMediaOrdering.naturalText('Episode 02.mp4', 'Episode 2.mp4')).assertLarger(0);
    });

    it('filtersByTypeSourceAndAvailability', 0, () => {
      const availableVideo: LocalMediaAsset = new LocalMediaAsset(
        'file://video', 'video.mp4', 0, 0, 0, 10, 1, LocalFileCategory.VIDEO,
        '', LocalMediaOrigin.MEDIA_LIBRARY, LocalMediaAvailability.AVAILABLE);
      const unavailableSubtitle: LocalMediaAsset = new LocalMediaAsset(
        'file://subtitle', 'movie.srt', 0, 0, 0, 10, 1, LocalFileCategory.SUBTITLE,
        '', LocalMediaOrigin.DOCUMENT_PICKER, LocalMediaAvailability.UNAVAILABLE);
      const result: LocalMediaAsset[] = LocalMediaOrdering.items(
        [availableVideo, unavailableSubtitle], [], '', LocalMediaSortField.NAME, true,
        LocalMediaTypeFilter.SUBTITLE, LocalMediaSourceFilter.MANUAL,
        LocalMediaAvailabilityFilter.UNAVAILABLE);
      expect(result.length).assertEqual(1);
      expect(result[0].uri).assertEqual('file://subtitle');
    });

    it('sortsNamesWithStableUriFallback', 0, () => {
      const second: LocalMediaAsset = new LocalMediaAsset('file://b', 'same.mp4', 0, 0, 0, 0, 0);
      const first: LocalMediaAsset = new LocalMediaAsset('file://a', 'same.mp4', 0, 0, 0, 0, 0);
      const result: LocalMediaAsset[] = LocalMediaOrdering.items(
        [second, first], [], '', LocalMediaSortField.NAME, true,
        LocalMediaTypeFilter.ALL, LocalMediaSourceFilter.ALL, LocalMediaAvailabilityFilter.ALL);
      expect(result[0].uri).assertEqual('file://a');
    });

    it('rebuildsVirtualFolderRowWhenItsDisplayNameChanges', 0, () => {
      const original = new LocalMediaFolder('linkora://folder/1', 'V1', 1, 1, 0,
        '', 0, '', 10, true, 1);
      const renamed = new LocalMediaFolder('linkora://folder/1', 'Renamed', 1, 1, 0,
        '', 0, '', 10, true, 1);

      expect(LocalBrowserEntry.fromDirectory(original).key ===
        LocalBrowserEntry.fromDirectory(renamed).key).assertFalse();
    });

    it('rebuildsVirtualMediaRowWhenItsAvailabilityChanges', 0, () => {
      const available = new LocalMediaAsset('linkora://item/1', 'video.mp4', 10, 1, 1, 10, 1,
        LocalFileCategory.VIDEO, '', LocalMediaOrigin.DOCUMENT_PICKER,
        LocalMediaAvailability.AVAILABLE, 'file://video');
      const unavailable = new LocalMediaAsset('linkora://item/1', 'video.mp4', 10, 1, 1, 10, 1,
        LocalFileCategory.VIDEO, '', LocalMediaOrigin.DOCUMENT_PICKER,
        LocalMediaAvailability.UNAVAILABLE, 'file://video');

      expect(LocalBrowserEntry.fromMedia(available).key ===
        LocalBrowserEntry.fromMedia(unavailable).key).assertFalse();
    });

    it('limitsSortFieldsToTheActiveBrowseMode', 0, () => {
      expect(LocalMediaSortOptions.supports(LocalBrowseMode.DIRECTORY,
        LocalMediaSortField.ITEM_COUNT)).assertTrue();
      expect(LocalMediaSortOptions.supports(LocalBrowseMode.DIRECTORY,
        LocalMediaSortField.MODIFIED)).assertFalse();
      expect(LocalMediaSortOptions.supports(LocalBrowseMode.VIDEO,
        LocalMediaSortField.TYPE)).assertTrue();
      expect(LocalMediaSortOptions.supports(LocalBrowseMode.VIDEO,
        LocalMediaSortField.ITEM_COUNT)).assertFalse();
    });

    it('fallsBackToNameWhenBrowseModeChanges', 0, () => {
      expect(LocalMediaSortOptions.normalize(LocalBrowseMode.DIRECTORY,
        LocalMediaSortField.MODIFIED)).assertEqual(LocalMediaSortField.NAME);
      expect(LocalMediaSortOptions.normalize(LocalBrowseMode.VIDEO,
        LocalMediaSortField.ITEM_COUNT)).assertEqual(LocalMediaSortField.NAME);
    });
  });
}
