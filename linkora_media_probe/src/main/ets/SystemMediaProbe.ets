import { media } from '@kit.MediaKit';

export class SystemMediaMetadataResult {
  readonly durationMs: number;
  readonly width: number;
  readonly height: number;
  readonly complete: boolean;

  constructor(durationMs: number = 0, width: number = 0, height: number = 0,
    complete: boolean = false) {
    this.durationMs = Math.max(0, durationMs);
    this.width = Math.max(0, width);
    this.height = Math.max(0, height);
    this.complete = complete;
  }
}

/**
 * System metadata stage.
 *
 * Extractor creation, URL/header setup, timeout, cancellation and release remain
 * owned by the caller so this stage can share one extractor with thumbnail work.
 */
export class SystemMediaProbe {
  async probe(extractor: media.AVMetadataExtractor): Promise<SystemMediaMetadataResult> {
    const metadata: media.AVMetadata = await extractor.fetchMetadata();
    return new SystemMediaMetadataResult(
      this.positive(metadata.duration),
      this.positive(metadata.videoWidth),
      this.positive(metadata.videoHeight),
      true
    );
  }

  private positive(value: string | undefined): number {
    const parsed: number = Number(value);
    return Number.isFinite(parsed) && parsed > 0 ? parsed : 0;
  }
}
