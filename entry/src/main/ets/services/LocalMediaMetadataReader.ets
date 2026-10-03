import { fileIo } from '@kit.CoreFileKit';
import { media } from '@kit.MediaKit';
import { BusinessError } from '@kit.BasicServicesKit';

export class LocalMediaMetadata {
  readonly available: boolean;
  readonly sizeBytes: number;
  readonly modifiedAt: number;
  readonly durationMs: number;
  readonly width: number;
  readonly height: number;
  /** True only when the media extractor completed; file stat alone is partial metadata. */
  readonly metadataComplete: boolean;
  readonly errorCode: number;

  constructor(available: boolean, sizeBytes: number = 0, modifiedAt: number = 0,
    durationMs: number = 0, width: number = 0, height: number = 0,
    metadataComplete: boolean = false, errorCode: number = 0) {
    this.available = available;
    this.sizeBytes = Math.max(0, sizeBytes);
    const safeModifiedAt: number = Math.max(0, modifiedAt);
    this.modifiedAt = safeModifiedAt > 0 && safeModifiedAt < 1000000000000 ?
      safeModifiedAt * 1000 : safeModifiedAt;
    this.durationMs = Math.max(0, durationMs);
    this.width = Math.max(0, width);
    this.height = Math.max(0, height);
    this.metadataComplete = metadataComplete;
    this.errorCode = Math.max(0, errorCode);
  }
}

/**
 * Reads metadata from a DocumentViewPicker URI.
 *
 * PhotoAsset.get() is only applicable to PhotoAccessHelper assets. A document
 * picker URI is read through a file descriptor and AVMetadataExtractor instead.
 */
export class LocalMediaMetadataReader {
  static async read(uri: string): Promise<LocalMediaMetadata> {
    let sourceFile: fileIo.File | null = null;
    let extractor: media.AVMetadataExtractor | null = null;
    try {
      sourceFile = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
      const stat: fileIo.Stat = fileIo.statSync(sourceFile.fd);
      const base: LocalMediaMetadata = new LocalMediaMetadata(true, stat.size, stat.mtime);
      if (stat.size <= 0) {
        return base;
      }

      try {
        extractor = await media.createAVMetadataExtractor();
        extractor.fdSrc = {
          fd: sourceFile.fd,
          offset: 0,
          length: stat.size
        };
        const metadata: media.AVMetadata = await extractor.fetchMetadata();
        return new LocalMediaMetadata(
          true,
          stat.size,
          stat.mtime,
          LocalMediaMetadataReader.number(metadata.duration),
          LocalMediaMetadataReader.number(metadata.videoWidth),
          LocalMediaMetadataReader.number(metadata.videoHeight),
          true
        );
      } catch (metadataError) {
        // Unknown or unsupported formats still retain the file-level metadata.
        return new LocalMediaMetadata(true, stat.size, stat.mtime, 0, 0, 0,
          false, LocalMediaMetadataReader.errorCode(metadataError));
      }
    } catch (error) {
      return new LocalMediaMetadata(false, 0, 0, 0, 0, 0,
        false, LocalMediaMetadataReader.errorCode(error));
    } finally {
      if (extractor !== null) {
        try {
          await extractor.release();
        } catch (_releaseError) {
        }
      }
      if (sourceFile !== null) {
        try {
          fileIo.closeSync(sourceFile.fd);
        } catch (_closeError) {
        }
      }
    }
  }

  private static number(value: string | undefined): number {
    if (value === undefined) {
      return 0;
    }
    const parsed: number = Number(value);
    return Number.isFinite(parsed) && parsed > 0 ? parsed : 0;
  }

  private static errorCode(error: Object): number {
    const failure: BusinessError = error as BusinessError;
    return typeof failure.code === 'number' ? failure.code : 0;
  }
}
