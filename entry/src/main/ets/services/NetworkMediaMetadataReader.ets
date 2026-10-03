import { media } from '@kit.MediaKit';

/** A single user-requested inspection, bounded across creation and network reads. */
export class NetworkMediaMetadataReader {
  private extractor: media.AVMetadataExtractor | null = null;
  private cancelRead: (() => void) | null = null;

  async read(url: string): Promise<media.AVMetadata | null> {
    this.cancel();
    let cancel: () => void = () => {};
    const cancelled: Promise<media.AVMetadata | null> = new Promise((resolve) => {
      cancel = () => resolve(null);
    });
    this.cancelRead = cancel;
    const timer: number = setTimeout(() => {
      if (this.cancelRead === cancel) {
        this.cancel();
      }
    }, 8000);
    const inspect: Promise<media.AVMetadata | null> = this.inspect(url, cancel).catch(() => null);
    try {
      return await Promise.race([inspect, cancelled]);
    } finally {
      clearTimeout(timer);
      if (this.cancelRead === cancel) {
        this.cancel();
      }
    }
  }

  cancel(): void {
    const cancel: (() => void) | null = this.cancelRead;
    this.cancelRead = null;
    cancel?.();
    const extractor: media.AVMetadataExtractor | null = this.extractor;
    this.extractor = null;
    this.release(extractor);
  }

  private async inspect(url: string, cancel: () => void): Promise<media.AVMetadata | null> {
    const extractor: media.AVMetadataExtractor = await media.createAVMetadataExtractor();
    if (this.cancelRead !== cancel) {
      this.release(extractor);
      return null;
    }
    this.extractor = extractor;
    extractor.setUrlSource(url);
    return extractor.fetchMetadata();
  }

  private release(extractor: media.AVMetadataExtractor | null): void {
    try {
      extractor?.release().catch(() => {});
    } catch (_error) {
    }
  }
}
