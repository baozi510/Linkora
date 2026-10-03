import { MediaFormat } from './MediaLink';

export class MediaFormatDetector {
  static detect(locator: string): MediaFormat {
    const path: string = MediaFormatDetector.pathOnly(locator).toLowerCase();
    if (path.endsWith('.m3u8')) {
      return MediaFormat.HLS;
    }
    if (path.endsWith('.mpd')) {
      return MediaFormat.DASH;
    }
    if (path.endsWith('.mp4') || path.endsWith('.m4v') || path.endsWith('.mov')) {
      return MediaFormat.MP4;
    }
    if (path.endsWith('.mkv') || path.endsWith('.webm')) {
      return MediaFormat.MATROSKA;
    }
    if (path.endsWith('.ts') || path.endsWith('.m2ts')) {
      return MediaFormat.MPEG_TS;
    }
    if (path.endsWith('.mp3') || path.endsWith('.aac') || path.endsWith('.m4a') ||
      path.endsWith('.flac') || path.endsWith('.ogg') || path.endsWith('.wav')) {
      return MediaFormat.AUDIO;
    }
    return MediaFormat.UNKNOWN;
  }

  private static pathOnly(locator: string): string {
    const queryStart: number = locator.indexOf('?');
    const fragmentStart: number = locator.indexOf('#');
    let end: number = locator.length;
    if (queryStart >= 0 && queryStart < end) {
      end = queryStart;
    }
    if (fragmentStart >= 0 && fragmentStart < end) {
      end = fragmentStart;
    }
    return locator.substring(0, end);
  }
}
