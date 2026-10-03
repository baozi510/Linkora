import { describe, expect, it } from '@ohos/hypium';
import { LocalBrowseMode, LocalFileCategory, LocalFileFilter, LocalMediaAsset,
  LocalMediaAvailability, LocalMediaCatalog, LocalMediaCatalogView, LocalMediaFolder,
  LocalMediaFolderFilter, LocalMediaOrigin, LocalMediaScanOptions, MediaSource, MediaSourceKind } from 'linkora_core';

export default function localMediaAssetTest(): void {
  describe('LocalMediaAsset', () => {
    it('deduplicatesManualSourcesWithinTheirOwnDirectory', 0, () => {
      const source = MediaSource.fromLocalDocument('file://shared.mp4');
      const other = MediaSource.fromLocalDocument('file://elsewhere/shared.mp4');
      const existing = new LocalMediaAsset('linkora://item/old', 'shared.mp4', 0, 0, 0, 0, 0,
        LocalFileCategory.VIDEO, '', LocalMediaOrigin.DOCUMENT_PICKER,
        LocalMediaAvailability.UNAVAILABLE, source.locator);

      const root = LocalMediaCatalog.newManualSources([source, source, other], [existing], '');
      expect(root.length).assertEqual(1);
      expect(root[0].locator).assertEqual(other.locator);
      expect(LocalMediaCatalog.newManualSources([source, source], [existing],
        'linkora://folder/custom').length).assertEqual(1);
    });

    it('formatsShortAndLongDurations', 0, () => {
      const shortVideo = new LocalMediaAsset('file://short.mp4', 'short.mp4', 65000, 1920, 1080, 1024, 0);
      const longVideo = new LocalMediaAsset('file://long.mp4', 'long.mp4', 3723000, 3840, 2160, 1024, 0);

      expect(shortVideo.durationLabel()).assertEqual('1:05');
      expect(longVideo.durationLabel()).assertEqual('1:02:03');
    });

    it('formatsResolutionAndFileSize', 0, () => {
      const item = new LocalMediaAsset('file://movie.mkv', 'movie.mkv', 1000, 1920, 1080,
        1536 * 1024, 0);

      expect(item.resolutionLabel()).assertEqual('1080P');
      expect(item.sizeLabel()).assertEqual('1.5 MB');
    });

    it('formatsLandscapeAndPortraitVideoQuality', 0, () => {
      const hd = new LocalMediaAsset('file://hd.mp4', 'hd.mp4', 0, 1280, 720, 0, 0);
      const portrait = new LocalMediaAsset('file://portrait.mp4', 'portrait.mp4', 0, 1080, 1920, 0, 0);
      const ultraHd = new LocalMediaAsset('file://uhd.mp4', 'uhd.mp4', 0, 3840, 2160, 0, 0);
      const unknown = new LocalMediaAsset('file://unknown.mp4', 'unknown.mp4', 0, 0, 0, 0, 0);

      expect(hd.resolutionLabel()).assertEqual('720P');
      expect(portrait.resolutionLabel()).assertEqual('1080P');
      expect(ultraHd.resolutionLabel()).assertEqual('4K');
      expect(unknown.resolutionLabel()).assertEqual('清晰度未知');
    });

    it('mapsToPlayableLocalSource', 0, () => {
      const item = new LocalMediaAsset('file://media/asset/42', 'episode.mkv', 0, 0, 0, 0, 0);
      const source = item.toMediaSource();

      expect(source.kind).assertEqual(MediaSourceKind.LOCAL_DOCUMENT);
      expect(source.displayName).assertEqual('episode.mkv');
      expect(source.originLabel).assertEqual('本机媒体库');
      expect(source.localCategory).assertEqual(LocalFileCategory.VIDEO);
    });

    it('keepsVirtualIdentitySeparateFromPlayableDocument', 0, () => {
      const item = new LocalMediaAsset('linkora://item/alias', 'episode.mkv', 0, 0, 0, 0, 0,
        LocalFileCategory.VIDEO, 'linkora://folder/season', LocalMediaOrigin.DOCUMENT_PICKER,
        LocalMediaAvailability.AVAILABLE, 'file://real/episode.mkv');

      expect(item.uri).assertEqual('linkora://item/alias');
      expect(item.contentUri()).assertEqual('file://real/episode.mkv');
      expect(item.toMediaSource().locator).assertEqual('file://real/episode.mkv');
    });

    it('filtersLocalFoldersWithoutArkUI', 0, () => {
      const empty = new LocalMediaFolder('album://empty', 'Empty', 0, 0, 0);
      const images = new LocalMediaFolder('album://images', 'Images', 3, 0, 3);
      const videos = new LocalMediaFolder('album://videos', 'Videos', 5, 2, 3);

      expect(empty.matches(LocalMediaFolderFilter.ALL)).assertTrue();
      expect(empty.matches(LocalMediaFolderFilter.NON_EMPTY)).assertFalse();
      expect(images.matches(LocalMediaFolderFilter.NON_EMPTY)).assertTrue();
      expect(images.matches(LocalMediaFolderFilter.VIDEO_ONLY)).assertFalse();
      expect(videos.matches(LocalMediaFolderFilter.VIDEO_ONLY)).assertTrue();
      expect(videos.detailLabel()).assertEqual('2 个视频 · 3 张图片');
    });

    it('keepsEmptyVirtualFoldersVisible', 0, () => {
      const folder = new LocalMediaFolder('linkora://folder/empty', 'Empty', 0, 0, 0,
        '', 0, '', 0, true);

      expect(folder.isVirtual()).assertTrue();
      expect(folder.matches(LocalMediaFolderFilter.VIDEO_ONLY)).assertTrue();
    });

    it('describesVirtualFoldersByFoldersAndFiles', 0, () => {
      const folder = new LocalMediaFolder('linkora://folder/library', 'Library', 3, 2, 1,
        '', 0, '', 0, true, 2);

      expect(folder.detailLabel()).assertEqual('2 个文件夹 · 3 个文件');
    });

    it('boundsLocalScanPageSize', 0, () => {
      expect(new LocalMediaScanOptions(LocalMediaFolderFilter.ALL, '', 0).maxResults).assertEqual(1);
      expect(new LocalMediaScanOptions(LocalMediaFolderFilter.ALL, '', 9999).maxResults).assertEqual(2000);
    });

    it('appliesFileTypesForEachBrowseMode', 0, () => {
      const filter = new LocalFileFilter(['mp4'], ['srt']);
      const video = new LocalMediaScanOptions(LocalMediaFolderFilter.ALL, '', 500,
        LocalBrowseMode.VIDEO, filter);
      const album = new LocalMediaScanOptions(LocalMediaFolderFilter.ALL, '', 500,
        LocalBrowseMode.DIRECTORY, filter);

      expect(video.acceptsFile('movie.mp4')).assertTrue();
      expect(video.acceptsFile('movie.srt')).assertFalse();
      expect(album.acceptsFile('movie.mp4')).assertTrue();
      expect(album.acceptsFile('movie.srt')).assertTrue();
      expect(album.acceptsFile('poster.jpg')).assertTrue();
      expect(album.acceptsFile('notes.pdf')).assertFalse();
    });

    it('classifiesConfiguredVideoAndSubtitleExtensions', 0, () => {
      const filter = new LocalFileFilter(['MP4', '.mkv', '.MP4'], ['srt', '.ASS']);

      expect(filter.videoExtensions.length).assertEqual(2);
      expect(filter.categoryOf('Movie.MKV')).assertEqual(LocalFileCategory.VIDEO);
      expect(filter.categoryOf('Movie.zh-Hans.SRT')).assertEqual(LocalFileCategory.SUBTITLE);
      expect(filter.categoryOf('poster.jpg')).assertEqual(LocalFileCategory.IMAGE);
      expect(filter.accepts('subtitle.ass')).assertTrue();
      expect(LocalBrowseMode.VIDEO).assertEqual('video');
      expect(LocalBrowseMode.DIRECTORY).assertEqual('directory');
    });

    it('buildsPickerExtensionsForRequestedCategories', 0, () => {
      const filter = new LocalFileFilter(['mp4'], ['srt'], ['mp3', 'flac']);

      expect(filter.categoryOf('track.mp3')).assertEqual(LocalFileCategory.AUDIO);
      expect(filter.extensionsFor([LocalFileCategory.VIDEO]).join(','))
        .assertEqual('.mp4');
      expect(filter.extensionsFor([LocalFileCategory.AUDIO, LocalFileCategory.SUBTITLE]).join(','))
        .assertEqual('.mp3,.flac,.srt');
    });

    it('keepsSubtitleEntriesNonVideo', 0, () => {
      const subtitle = new LocalMediaAsset('file://movie.zh.srt', 'movie.zh.srt', 0, 0, 0, 512, 1,
        LocalFileCategory.SUBTITLE);

      expect(subtitle.isSubtitle()).assertTrue();
      expect(subtitle.isVideo()).assertFalse();
    });

    it('derivesVideoAndAlbumViewsFromOneFlatMediaList', 0, () => {
      const assets: LocalMediaAsset[] = [
        new LocalMediaAsset('file://movie-a', 'movie-a.mp4', 0, 0, 0, 10, 1,
          LocalFileCategory.VIDEO, 'album://movies'),
        new LocalMediaAsset('file://movie-b', 'movie-b.mkv', 0, 0, 0, 10, 1,
          LocalFileCategory.VIDEO, 'album://movies'),
        new LocalMediaAsset('file://subtitle-b', 'movie-b.srt', 0, 0, 0, 10, 1,
          LocalFileCategory.SUBTITLE, 'album://movies'),
        new LocalMediaAsset('file://clip', 'clip.mp4', 0, 0, 0, 10, 1,
          LocalFileCategory.VIDEO, 'album://camera'),
        new LocalMediaAsset('file://movie-a', 'movie-a.mp4', 0, 0, 0, 10, 1,
          LocalFileCategory.VIDEO, 'album://movies'),
        new LocalMediaAsset('file://root', 'root.mp4', 0, 0, 0, 10, 1,
          LocalFileCategory.VIDEO),
        new LocalMediaAsset('file://unknown', 'unknown.mp4', 0, 0, 0, 10, 1,
          LocalFileCategory.VIDEO, 'linkora://unresolved-album')
      ];
      const albums: LocalMediaFolder[] = [
        new LocalMediaFolder('album://movies', 'Movies', 3, 2, 0, '', 1),
        new LocalMediaFolder('album://camera', 'Camera', 1, 1, 0)
      ];
      const filter: LocalFileFilter = new LocalFileFilter(['mp4', 'mkv'], ['srt']);
      const root: LocalMediaCatalogView = LocalMediaCatalog.createView(assets,
        new LocalMediaScanOptions(LocalMediaFolderFilter.ALL, '', 500, LocalBrowseMode.DIRECTORY, filter), albums);
      const movies: LocalMediaCatalogView = LocalMediaCatalog.createView(assets,
        new LocalMediaScanOptions(LocalMediaFolderFilter.ALL, 'album://movies', 500,
          LocalBrowseMode.DIRECTORY, filter), albums);
      const video: LocalMediaCatalogView = LocalMediaCatalog.createView(assets,
        new LocalMediaScanOptions(LocalMediaFolderFilter.ALL, '', 500,
          LocalBrowseMode.VIDEO, filter), albums);
      const albumRootWithoutRootFiles: LocalMediaCatalogView = LocalMediaCatalog.createView(
        assets.filter((item: LocalMediaAsset) => item.parentUri.length > 0),
        new LocalMediaScanOptions(LocalMediaFolderFilter.ALL, '', 500,
          LocalBrowseMode.DIRECTORY, filter), albums);

      expect(root.folders.length).assertEqual(2);
      expect(root.items.length).assertEqual(1);
      expect(movies.selectedDirectoryUri).assertEqual('album://movies');
      expect(movies.items.length).assertEqual(4);
      expect(movies.items[2].isSubtitle()).assertTrue();
      expect(video.items.length).assertEqual(5);
      expect(video.folders.length).assertEqual(0);
      expect(albumRootWithoutRootFiles.folders.length).assertEqual(2);
      expect(albumRootWithoutRootFiles.items.length).assertEqual(0);
    });

    it('projectsMixedEntriesAsADirectoryTree', 0, () => {
      const rootUri: string = 'directory://movies';
      const childUri: string = 'directory://movies/season-1';
      const folders: LocalMediaFolder[] = [
        new LocalMediaFolder(rootUri, 'Movies', 3, 3, 0),
        new LocalMediaFolder(childUri, 'Season 1', 1, 1, 0, '', 0, rootUri)
      ];
      const assets: LocalMediaAsset[] = [
        new LocalMediaAsset('file://trailer', 'trailer.mp4', 0, 0, 0, 10, 1,
          LocalFileCategory.VIDEO, rootUri),
        new LocalMediaAsset('file://episode', 'episode.mp4', 0, 0, 0, 10, 1,
          LocalFileCategory.VIDEO, childUri)
      ];
      const view: LocalMediaCatalogView = LocalMediaCatalog.createView(assets,
        new LocalMediaScanOptions(LocalMediaFolderFilter.ALL, rootUri, 500,
          LocalBrowseMode.DIRECTORY), folders);

      expect(view.selectedDirectoryUri).assertEqual(rootUri);
      expect(view.childFolders.length).assertEqual(1);
      expect(view.childFolders[0].uri).assertEqual(childUri);
      expect(view.items.length).assertEqual(1);
      expect(view.items[0].displayName).assertEqual('trailer.mp4');
    });

    it('normalizesUnixSecondTimestamps', 0, () => {
      const item = new LocalMediaAsset('file://dated', 'dated.mp4', 0, 0, 0, 0, 1725580800);
      expect(item.modifiedAt).assertEqual(1725580800000);
    });
  });
}
