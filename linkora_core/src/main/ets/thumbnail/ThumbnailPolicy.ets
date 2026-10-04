export class ThumbnailPlan {
  readonly timeMs: number;
  readonly width: number;
  readonly height: number;
  readonly quality: number;
  readonly algorithmVersion: number;

  constructor(timeMs: number, width: number, height: number,
    quality: number = 80, algorithmVersion: number = 1) {
    this.timeMs = Math.max(0, Math.floor(timeMs));
    this.width = Math.max(1, Math.floor(width));
    this.height = Math.max(1, Math.floor(height));
    this.quality = Math.max(1, Math.min(100, Math.floor(quality)));
    this.algorithmVersion = Math.max(1, Math.floor(algorithmVersion));
  }

  cacheIdentity(): string {
    return [this.timeMs, this.width, this.height, this.quality, this.algorithmVersion].join(':');
  }
}

export interface ThumbnailTimePolicy {
  plan(durationMs: number, sourceWidth: number, sourceHeight: number): ThumbnailPlan;
}

interface ThumbnailSize {
  width: number;
  height: number;
}

export class DefaultThumbnailTimePolicy implements ThumbnailTimePolicy {
  private readonly maxWidth: number;
  private readonly maxHeight: number;
  private readonly quality: number;
  private readonly algorithmVersion: number;

  constructor(maxWidth: number = 480, maxHeight: number = 270,
    quality: number = 80, algorithmVersion: number = 1) {
    this.maxWidth = Math.max(1, Math.floor(maxWidth));
    this.maxHeight = Math.max(1, Math.floor(maxHeight));
    this.quality = Math.max(1, Math.min(100, Math.floor(quality)));
    this.algorithmVersion = Math.max(1, Math.floor(algorithmVersion));
  }

  plan(durationMs: number, sourceWidth: number, sourceHeight: number): ThumbnailPlan {
    const duration: number = Number.isFinite(durationMs) && durationMs > 0 ? durationMs : 0;
    let timeMs: number = 0;
    if (duration > 0 && duration < 30000) {
      timeMs = duration * 0.2;
    } else if (duration >= 30000) {
      timeMs = Math.min(duration * 0.1, 60000);
    }

    const size = this.fit(sourceWidth, sourceHeight);
    return new ThumbnailPlan(timeMs, size.width, size.height, this.quality, this.algorithmVersion);
  }

  private fit(sourceWidth: number, sourceHeight: number): ThumbnailSize {
    const width: number = Number.isFinite(sourceWidth) && sourceWidth > 0 ? sourceWidth : 0;
    const height: number = Number.isFinite(sourceHeight) && sourceHeight > 0 ? sourceHeight : 0;
    if (width <= 0 || height <= 0) {
      return { width: this.maxWidth, height: this.maxHeight };
    }
    const scale: number = Math.min(this.maxWidth / width, this.maxHeight / height, 1);
    return {
      width: Math.max(1, Math.round(width * scale)),
      height: Math.max(1, Math.round(height * scale))
    };
  }
}
