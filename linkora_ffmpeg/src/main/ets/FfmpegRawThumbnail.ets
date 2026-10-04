import { RawThumbnail, ThumbnailPixelFormat } from 'linkora_core';
import { NativeFrameResult, FfmpegError, FfmpegErrorCode } from './NativeModels';

export class FfmpegRawThumbnail implements RawThumbnail {
  private readonly frameWidth: number;
  private readonly frameHeight: number;
  private pixels: ArrayBuffer | null;
  constructor(frame: NativeFrameResult) {
    const bytes = frame.width * frame.height * 4;
    if (!Number.isInteger(frame.width) || !Number.isInteger(frame.height) || frame.width < 1 ||
      frame.height < 1 || frame.width > 4096 || frame.height > 4096 || bytes > 32 * 1024 * 1024 ||
      frame.pixelFormat !== 'rgba_8888' || frame.pixels.byteLength !== bytes) {
      throw new FfmpegError(FfmpegErrorCode.SIZE_REJECTED);
    }
    this.frameWidth = frame.width; this.frameHeight = frame.height; this.pixels = frame.pixels;
  }
  width(): number { return this.frameWidth; }
  height(): number { return this.frameHeight; }
  pixelFormat(): ThumbnailPixelFormat { return ThumbnailPixelFormat.RGBA_8888; }
  async readPixels(): Promise<ArrayBuffer> {
    if (this.pixels === null) throw new FfmpegError(FfmpegErrorCode.RELEASED);
    return this.pixels.slice(0);
  }
  async release(): Promise<void> { this.pixels = null; }
}
