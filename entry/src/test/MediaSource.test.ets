import { describe, expect, it } from '@ohos/hypium';
import { MediaFormat, MediaFormatDetector, MediaLink, MediaProtocol, MediaSource,
  MediaSourceKind } from 'linkora_core';

export default function mediaSourceTest(): void {
  describe('MediaSource', () => {
    it('createsNetworkSourceWithoutExposingQueryInDisplayName', 0, () => {
      const link = new MediaLink(
        'https://media.example.com/library/movie.mp4?token=secret',
        'media.example.com',
        MediaProtocol.HTTPS,
        MediaFormat.MP4
      );
      const source: MediaSource = MediaSource.fromNetworkLink(link);
      expect(source.kind).assertEqual(MediaSourceKind.NETWORK_LINK);
      expect(source.displayName).assertEqual('movie.mp4');
      expect(source.originLabel).assertEqual('media.example.com');
    });

    it('createsLocalDocumentSource', 0, () => {
      const source: MediaSource = MediaSource.fromLocalDocument('file://media/videos/sample.mkv');
      expect(source.kind).assertEqual(MediaSourceKind.LOCAL_DOCUMENT);
      expect(source.displayName).assertEqual('sample.mkv');
      expect(source.originLabel).assertEqual('本地文件');
      expect(source.format).assertEqual(MediaFormat.MATROSKA);
    });

    it('createsLocalLibrarySourceWithMetadataName', 0, () => {
      const source: MediaSource = MediaSource.fromLocalLibrary('file://media/asset/42', 'episode.mkv');
      expect(source.kind).assertEqual(MediaSourceKind.LOCAL_DOCUMENT);
      expect(source.displayName).assertEqual('episode.mkv');
      expect(source.originLabel).assertEqual('本机媒体库');
      expect(source.format).assertEqual(MediaFormat.MATROSKA);
    });

    it('detectsFormatBeforeQueryAndFragment', 0, () => {
      expect(MediaFormatDetector.detect('/video/main.m3u8?token=a#live')).assertEqual(MediaFormat.HLS);
      expect(MediaFormatDetector.detect('/audio/theme.flac?download=1')).assertEqual(MediaFormat.AUDIO);
    });

    it('returnsUnknownForExtensionlessSource', 0, () => {
      expect(MediaFormatDetector.detect('/stream/channel')).assertEqual(MediaFormat.UNKNOWN);
    });
  });
}
