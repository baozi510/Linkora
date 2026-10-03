import { MediaSource } from '../models/MediaSource';

export enum ThumbnailPixelFormat {
  UNKNOWN = 'unknown',
  RGBA_8888 = 'rgba_8888',
  BGRA_8888 = 'bgra_8888'
}

export enum ThumbnailResizeMode {
  FIT = 'fit',
  FILL = 'fill'
}

export class ThumbnailExtractRequest {
  readonly timeMs: number;
  readonly maxWidth: number;
  readonly maxHeight: number;

  constructor(timeMs: number, maxWidth: number = 480, maxHeight: number = 270) {
    this.timeMs = Math.max(0, timeMs);
    this.maxWidth = Math.max(1, maxWidth);
    this.maxHeight = Math.max(1, maxHeight);
  }
}

export class ThumbnailProcessRequest {
  readonly maxWidth: number;
  readonly maxHeight: number;
  readonly resizeMode: ThumbnailResizeMode;

  constructor(maxWidth: number = 480, maxHeight: number = 270,
    resizeMode: ThumbnailResizeMode = ThumbnailResizeMode.FIT) {
    this.maxWidth = Math.max(1, maxWidth);
    this.maxHeight = Math.max(1, maxHeight);
    this.resizeMode = resizeMode;
  }
}

export interface RawThumbnail {
  width(): number;
  height(): number;
  pixelFormat(): ThumbnailPixelFormat;
  readPixels(): Promise<ArrayBuffer>;
  release(): Promise<void>;
}

export interface IThumbnailExtractor {
  name(): string;
  canExtract(source: MediaSource): Promise<boolean>;
  extract(source: MediaSource, request: ThumbnailExtractRequest): Promise<RawThumbnail | null>;
  cancel(): void;
  close(): Promise<void>;
}

export interface IThumbnailProcessor {
  process(frame: RawThumbnail, request: ThumbnailProcessRequest): Promise<RawThumbnail>;
}

export class ThumbnailEncodeRequest {
  readonly quality: number;

  constructor(quality: number = 80) {
    this.quality = Math.max(1, Math.min(quality, 100));
  }
}

export class EncodedThumbnail {
  readonly data: ArrayBuffer;
  readonly mimeType: string;
  readonly extension: string;
  readonly width: number;
  readonly height: number;

  constructor(data: ArrayBuffer, mimeType: string = 'image/webp', extension: string = 'webp',
    width: number = 0, height: number = 0) {
    this.data = data;
    this.mimeType = mimeType;
    this.extension = extension;
    this.width = Math.max(0, width);
    this.height = Math.max(0, height);
  }
}

export interface IThumbnailEncoder {
  name(): string;
  encode(frame: RawThumbnail, request: ThumbnailEncodeRequest): Promise<EncodedThumbnail>;
}
