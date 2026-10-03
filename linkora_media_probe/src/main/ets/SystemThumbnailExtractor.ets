import { image } from '@kit.ImageKit';
import { media } from '@kit.MediaKit';

export class SystemThumbnailResult {
  readonly thumbnail: image.PixelMap;
  readonly timeUs: number;
  readonly width: number;
  readonly height: number;

  constructor(thumbnail: image.PixelMap, timeUs: number, width: number, height: number) {
    this.thumbnail = thumbnail;
    this.timeUs = Math.max(0, timeUs);
    this.width = Math.max(1, width);
    this.height = Math.max(1, height);
  }
}

/**
 * System thumbnail extraction stage.
 *
 * This class only chooses/seeks/decodes a frame. It deliberately does not
 * encode WebP, write cache files or decide the long-term thumbnail policy.
 */
export class SystemThumbnailExtractor {
  async extract(extractor: media.AVMetadataExtractor, durationMs: number,
    width: number = 224, height: number = 126): Promise<SystemThumbnailResult> {
    const targetWidth: number = Math.max(1, width);
    const targetHeight: number = Math.max(1, height);
    const timeUs: number = durationMs > 0 ?
      Math.min(1000000, Math.max(0, (durationMs - 1) * 1000)) : 0;
    const thumbnail: image.PixelMap = await extractor.fetchFrameByTime(
      timeUs,
      media.AVImageQueryOptions.AV_IMAGE_QUERY_CLOSEST_SYNC,
      { width: targetWidth, height: targetHeight }
    );
    return new SystemThumbnailResult(thumbnail, timeUs, targetWidth, targetHeight);
  }
}
