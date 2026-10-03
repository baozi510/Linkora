import { MediaFormat, MediaLink } from './MediaLink';
import { MediaFormatDetector } from './MediaFormatDetector';
import { LocalFileCategory, LocalFileFilter } from './LocalFileFilter';

export enum MediaSourceKind {
  NETWORK_LINK = 'network_link',
  LOCAL_DOCUMENT = 'local_document',
  REMOTE_FILE = 'remote_file'
}

export class MediaSource {
  readonly kind: MediaSourceKind;
  readonly locator: string;
  readonly displayName: string;
  readonly originLabel: string;
  readonly format: MediaFormat;
  readonly localCategory: LocalFileCategory;
  readonly sizeBytes: number;
  /** Legacy migration field. New remote-file flows must use RandomAccessSource/ResolvedMediaInput. */
  readonly progressiveKey: string;
  readonly sourceId: string;
  readonly credentialRef: string;
  readonly fingerprint: string;

  constructor(kind: MediaSourceKind, locator: string, displayName: string,
    originLabel: string, format: MediaFormat,
    localCategory: LocalFileCategory = LocalFileCategory.UNSUPPORTED,
    sizeBytes: number = 0, progressiveKey: string = '', sourceId: string = '',
    credentialRef: string = '', fingerprint: string = '') {
    this.kind = kind;
    this.locator = locator;
    this.displayName = displayName;
    this.originLabel = originLabel;
    this.format = format;
    this.localCategory = localCategory;
    this.sizeBytes = sizeBytes;
    this.progressiveKey = progressiveKey;
    this.sourceId = sourceId;
    this.credentialRef = credentialRef;
    this.fingerprint = fingerprint;
  }

  static empty(): MediaSource {
    return new MediaSource(MediaSourceKind.NETWORK_LINK, '', '未选择媒体', '', MediaFormat.UNKNOWN);
  }

  static fromNetworkLink(link: MediaLink): MediaSource {
    return new MediaSource(
      MediaSourceKind.NETWORK_LINK,
      link.url,
      MediaSource.networkDisplayName(link.url),
      link.host,
      link.format
    );
  }

  static fromLocalDocument(uri: string, displayName: string = '',
    category: LocalFileCategory = LocalFileCategory.UNSUPPORTED): MediaSource {
    const resolvedName: string = displayName.length > 0 ? displayName : MediaSource.fileName(uri);
    const resolvedCategory: LocalFileCategory = category === LocalFileCategory.UNSUPPORTED ?
      new LocalFileFilter().categoryOf(resolvedName) : category;
    return new MediaSource(
      MediaSourceKind.LOCAL_DOCUMENT,
      uri,
      resolvedName,
      '本地文件',
      MediaFormatDetector.detect(resolvedName),
      resolvedCategory
    );
  }

  static fromLocalLibrary(uri: string, displayName: string,
    category: LocalFileCategory = LocalFileCategory.UNSUPPORTED): MediaSource {
    const resolvedName: string = displayName.length > 0 ? displayName : MediaSource.fileName(uri);
    const resolvedCategory: LocalFileCategory = category === LocalFileCategory.UNSUPPORTED ?
      new LocalFileFilter().categoryOf(resolvedName) : category;
    return new MediaSource(
      MediaSourceKind.LOCAL_DOCUMENT,
      uri,
      resolvedName,
      '本机媒体库',
      MediaFormatDetector.detect(resolvedName),
      resolvedCategory
    );
  }

  static fromRemoteFile(locator: string, displayName: string, originLabel: string,
    sizeBytes: number = 0, sourceId: string = '', credentialRef: string = '',
    fingerprint: string = ''): MediaSource {
    const resolvedName: string = displayName.length > 0 ? displayName : MediaSource.fileName(locator);
    return new MediaSource(
      MediaSourceKind.REMOTE_FILE,
      locator,
      resolvedName,
      originLabel,
      MediaFormatDetector.detect(resolvedName),
      new LocalFileFilter().categoryOf(resolvedName),
      Math.max(0, sizeBytes),
      '',
      sourceId,
      credentialRef,
      fingerprint
    );
  }

  private static networkDisplayName(value: string): string {
    const queryStart: number = value.indexOf('?');
    const fragmentStart: number = value.indexOf('#');
    let end: number = value.length;
    if (queryStart >= 0 && queryStart < end) {
      end = queryStart;
    }
    if (fragmentStart >= 0 && fragmentStart < end) {
      end = fragmentStart;
    }
    const path: string = value.substring(0, end);
    const slash: number = path.lastIndexOf('/');
    if (slash >= 0 && slash + 1 < path.length) {
      return path.substring(slash + 1);
    }
    return '网络媒体';
  }

  private static fileName(uri: string): string {
    const queryStart: number = uri.indexOf('?');
    const value: string = queryStart >= 0 ? uri.substring(0, queryStart) : uri;
    const slash: number = value.lastIndexOf('/');
    if (slash >= 0 && slash + 1 < value.length) {
      const encodedName: string = value.substring(slash + 1);
      try {
        return decodeURIComponent(encodedName);
      } catch (_error) {
        return encodedName;
      }
    }
    return '本地视频';
  }
}
