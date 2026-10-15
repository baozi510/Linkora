import { describe, expect, it } from '@ohos/hypium';
import { AppFailure, FailureCode, FailureDomain, LocalBrowseMode, LocalFileCategory, LocalMediaAsset, LocalMediaAvailability,
  LocalMediaCatalog, LocalMediaFolder, LocalMediaOrigin, LocalMediaScanOptions,
  LocalPlaybackPlaylist, LocalMediaScanState, PlaybackPlaylist, PlaybackPlaylistItem, RecoveryAction } from 'linkora_core';
import { LocalMediaOrdering } from '../main/ets/models/LocalMediaOrdering';
import { LocalMediaAvailabilityFilter, LocalMediaSortField, LocalMediaSourceFilter,
  LocalMediaTypeFilter } from '../main/ets/models/LocalMediaViewOptions';
import { PlayerDestinationParams } from '../main/ets/models/AppNavigation';
import { LocalFolderPageData } from '../main/ets/models/LocalFolderPageData';

function asset(uri: string, name: string, category: LocalFileCategory = LocalFileCategory.VIDEO,
  parent: string = 'folder-a', availability: LocalMediaAvailability = LocalMediaAvailability.AVAILABLE,
  origin: LocalMediaOrigin = LocalMediaOrigin.MEDIA_LIBRARY, sourceUri: string = uri): LocalMediaAsset {
  return new LocalMediaAsset(uri, name, 1000, 640, 360, 10, 1, category, parent,
    origin, availability, sourceUri);
}

export default function localPlaybackPlaylistTest(): void {
  describe('LocalPlaybackPlaylist', () => {
    it('keepsOnlyAvailableVideosAndLocatesClickedVideoAfterFiltering', 0, () => {
      const list = LocalPlaybackPlaylist.build([
        asset('image', 'cover.jpg', LocalFileCategory.IMAGE),
        asset('first', 'first.mp4'),
        asset('missing', 'missing.mkv', LocalFileCategory.VIDEO, 'folder-a', LocalMediaAvailability.UNAVAILABLE),
        asset('subtitle', 'first.srt', LocalFileCategory.SUBTITLE),
        asset('audio', 'song.flac', LocalFileCategory.AUDIO),
        asset('unknown', 'file.bin', LocalFileCategory.UNSUPPORTED),
        asset('second', 'second.mkv')
      ], 'second', true);
      expect(list?.items.length).assertEqual(2);
      expect(list?.items[0].id).assertEqual('first');
      expect(list?.startIndex).assertEqual(1);
      expect(list?.currentItem()?.id).assertEqual('second');
      expect(list?.complete).assertTrue();
    });

    it('doesNotOpenAnEmptyOrNonVideoDirectory', 0, () => {
      expect(LocalPlaybackPlaylist.build([], '', true)).assertNull();
      expect(LocalPlaybackPlaylist.build([asset('sub', 'a.srt', LocalFileCategory.SUBTITLE)], 'sub', true))
        .assertNull();
    });

    it('doesNotFallBackToFirstWhenClickedEntryDisappearsOrBecomesUnavailable', 0, () => {
      expect(LocalPlaybackPlaylist.build([asset('first', 'a.mp4')], 'gone', true)).assertNull();
      expect(LocalPlaybackPlaylist.build([asset('first', 'a.mp4'),
        asset('gone', 'b.mp4', LocalFileCategory.VIDEO, 'folder-a', LocalMediaAvailability.UNAVAILABLE)],
        'gone', true)).assertNull();
    });

    it('rejectsBlankEntryIdentitiesAndPlaybackLocators', 0, () => {
      const list = LocalPlaybackPlaylist.build([
        asset('', 'bad.mp4'),
        asset('virtual', 'bad2.mp4', LocalFileCategory.VIDEO, 'folder-a',
          LocalMediaAvailability.AVAILABLE, LocalMediaOrigin.DOCUMENT_PICKER, ''),
        asset('valid', 'ok.mp4')
      ], 'valid', true);
      expect(list?.items.length).assertEqual(1);
      expect(list?.currentItem()?.id).assertEqual('valid');
    });

    it('deduplicatesRepeatedIdentityWithoutChangingTheSelectedIndex', 0, () => {
      const list = LocalPlaybackPlaylist.build([
        asset('first', 'a.mp4'), asset('first', 'a.mp4'), asset('second', 'b.mp4')
      ], 'second', true);
      expect(list?.items.length).assertEqual(2);
      expect(list?.startIndex).assertEqual(1);
    });

    it('keepsSameNamedVideosDistinct', 0, () => {
      const list = LocalPlaybackPlaylist.build([
        asset('a', 'same.mp4'), asset('b', 'same.mp4')
      ], 'b', true);
      expect(list?.items.length).assertEqual(2);
      expect(list?.currentItem()?.source.locator).assertEqual('b');
    });

    it('preservesVirtualEntryIdentityWhileUsingItsRealPlaybackUri', 0, () => {
      const list = LocalPlaybackPlaylist.build([
        asset('linkora://item/1', 'a.mp4', LocalFileCategory.VIDEO, 'virtual-folder',
          LocalMediaAvailability.AVAILABLE, LocalMediaOrigin.DOCUMENT_PICKER, 'file://shared.mp4'),
        asset('linkora://item/2', 'b.mp4', LocalFileCategory.VIDEO, 'virtual-folder',
          LocalMediaAvailability.AVAILABLE, LocalMediaOrigin.DOCUMENT_PICKER, 'file://shared.mp4')
      ], 'linkora://item/2', true);
      expect(list?.items.length).assertEqual(2);
      expect(list?.currentItem()?.id).assertEqual('linkora://item/2');
      expect(list?.currentItem()?.source.locator).assertEqual('file://shared.mp4');
      expect(list?.currentItem()?.source.displayName).assertEqual('b.mp4');
    });

    it('keepsTheExistingBrowserOrderAndDoesNotMutateItsInput', 0, () => {
      const items = [asset('ten', 'Episode 10.mp4'), asset('two', 'Episode 2.mp4')];
      const list = LocalPlaybackPlaylist.build(items, 'two', true);
      expect(list?.items[0].id).assertEqual('ten');
      expect(list?.startIndex).assertEqual(1);
      expect(items[0].uri).assertEqual('ten');
      items.pop();
      expect(list?.items.length).assertEqual(2);
      const exposed = list?.items ?? [];
      exposed.pop();
      expect(list?.items.length).assertEqual(2);
    });

    it('usesTheExistingSearchAndDescendingSortForTheQueue', 0, () => {
      const visible = LocalMediaOrdering.items([
        asset('a', 'Episode A.mp4'), asset('b', 'Episode B.mkv'), asset('other', 'Trailer.mp4')
      ], [], 'episode', LocalMediaSortField.NAME, false, LocalMediaTypeFilter.ALL,
      LocalMediaSourceFilter.ALL, LocalMediaAvailabilityFilter.ALL);
      const list = LocalPlaybackPlaylist.build(visible, 'a', true);
      expect(list?.items.length).assertEqual(2);
      expect(list?.items[0].id).assertEqual('b');
      expect(list?.startIndex).assertEqual(1);
    });

    it('usesOnlyTheDirectDirectoryProjectionWithoutReadingDescendants', 0, () => {
      const folder = new LocalMediaFolder('folder-a', 'A', 2, 2, 0);
      const child = new LocalMediaFolder('folder-a/child', 'Child', 1, 1, 0, '', 0, 'folder-a');
      const view = LocalMediaCatalog.createView([
        asset('first', 'a.mp4'), asset('nested', 'b.mp4', LocalFileCategory.VIDEO, 'folder-a/child'),
        asset('elsewhere', 'c.mp4', LocalFileCategory.VIDEO, 'folder-b')
      ], new LocalMediaScanOptions(undefined, 'folder-a'), [folder, child]);
      const list = LocalPlaybackPlaylist.build(view.items, 'first', true);
      expect(list?.items.length).assertEqual(1);
      expect(list?.currentItem()?.id).assertEqual('first');
    });

    it('acceptsTheCurrentAllVideosGroupAsItsOwnScope', 0, () => {
      const view = LocalMediaCatalog.createView([
        asset('a', 'a.mp4'), asset('b', 'b.mkv', LocalFileCategory.VIDEO, 'folder-b')
      ], new LocalMediaScanOptions(undefined, '', 500, LocalBrowseMode.VIDEO));
      const list = LocalPlaybackPlaylist.build(view.items, 'b', true);
      expect(list?.items.length).assertEqual(2);
      expect(list?.startIndex).assertEqual(1);
    });

    it('preservesIncompleteStatusForCachedOrStillLoadingItems', 0, () => {
      const list = LocalPlaybackPlaylist.build([asset('a', 'a.mp4')], 'a', false);
      expect(list?.complete).assertFalse();
      expect(list?.currentItem()?.id).assertEqual('a');
    });

    it('marksOnlyFinishedSuccessfulProjectionsComplete', 0, () => {
      expect(new LocalFolderPageData('a', [], LocalMediaScanState.READY, null, false, true).isComplete()).assertTrue();
      expect(new LocalFolderPageData('a', [], LocalMediaScanState.EMPTY, null, false, true).isComplete()).assertTrue();
      expect(new LocalFolderPageData('a', [], LocalMediaScanState.READY, null, false, false).isComplete()).assertFalse();
      expect(new LocalFolderPageData('a', [], LocalMediaScanState.SCANNING, null, false, true).isComplete()).assertFalse();
      expect(new LocalFolderPageData('a', [], LocalMediaScanState.FAILED, null, false, true).isComplete()).assertFalse();
      expect(new LocalFolderPageData('a', [], LocalMediaScanState.PERMISSION_DENIED, null, false, true).isComplete()).assertFalse();
      expect(new LocalFolderPageData('a', [], LocalMediaScanState.READY, null, true, true).isComplete()).assertFalse();
      const failure = new AppFailure(FailureDomain.FILE, FailureCode.LOCAL_SCAN_FAILED,
        'Scan failed', 'Partial cached result', RecoveryAction.RETRY, 'Retry', true, '');
      expect(new LocalFolderPageData('a', [], LocalMediaScanState.READY, failure, false, true).isComplete()).assertFalse();
    });

    it('carriesTheFullSnapshotAndSelectedSourceThroughNavigation', 0, () => {
      const list = LocalPlaybackPlaylist.build([asset('a', 'a.mp4'), asset('b', 'b.mkv')], 'b', true);
      const route = new PlayerDestinationParams(asset('other', 'other.mp4').toMediaSource(), list);
      expect(route.playlist?.items.length).assertEqual(2);
      expect(route.playlist?.startIndex).assertEqual(1);
      expect(route.source.locator).assertEqual('b');
      const single = new PlayerDestinationParams(asset('single', 'single.mp4').toMediaSource());
      expect(single.source.locator).assertEqual('single');
      expect(single.playlist).assertNull();
      const empty = new PlayerDestinationParams(single.source, new PlaybackPlaylist([], -1, true));
      expect(empty.source.locator).assertEqual('single');
      expect(empty.playlist).assertNull();
    });

    it('keepsAnEmptySnapshotUnselectedAndRejectsInvalidIndices', 0, () => {
      expect(new PlaybackPlaylist([], -1, true).currentItem()).assertNull();
      let rejected: boolean = false;
      try {
        new PlaybackPlaylist([new PlaybackPlaylistItem('a', asset('a', 'a.mp4').toMediaSource())], 1, true);
      } catch (_error) {
        rejected = true;
      }
      expect(rejected).assertTrue();
    });

    it('rejectsDuplicateIdsAtTheCommonPlaylistBoundary', 0, () => {
      let rejected: boolean = false;
      try {
        new PlaybackPlaylist([
          new PlaybackPlaylistItem('same', asset('a', 'a.mp4').toMediaSource()),
          new PlaybackPlaylistItem('same', asset('b', 'b.mp4').toMediaSource())
        ], 0, true);
      } catch (_error) {
        rejected = true;
      }
      expect(rejected).assertTrue();
    });
  });
}
