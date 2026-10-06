import { image } from '@kit.ImageKit';
import { RawThumbnail, ThumbnailPixelFormat } from 'linkora_core';

export class SystemWebPEncoder {
  async encodeRaw(frame: RawThumbnail, quality: number = 80): Promise<ArrayBuffer> {
    if (frame.pixelFormat() !== ThumbnailPixelFormat.RGBA_8888) {
      throw new Error('Unsupported raw thumbnail pixel format');
    }
    const width: number = frame.width();
    const height: number = frame.height();
    const expected: number = width * height * 4;
    const pixels: ArrayBuffer = await frame.readPixels();
    if (width <= 0 || height <= 0 || !Number.isSafeInteger(expected) ||
      expected <= 0 || pixels.byteLength !== expected) {
      throw new Error('Invalid raw thumbnail');
    }
    const pixelMap: image.PixelMap = await image.createPixelMap(pixels, {
      editable: false,
      pixelFormat: image.PixelMapFormat.RGBA_8888,
      size: { width, height }
    });
    try {
      return await this.encode(pixelMap, quality);
    } finally {
      await pixelMap.release().catch(() => {});
    }
  }

  async encode(frame: image.PixelMap, quality: number = 80): Promise<ArrayBuffer> {
    const packer: image.ImagePacker = image.createImagePacker();
    try {
      if (!packer.supportedFormats.includes('image/webp')) {
        throw new Error('WebP encoder unavailable');
      }
      return await packer.packing(frame, {
        format: 'image/webp',
        quality: Math.max(1, Math.min(100, Math.floor(quality)))
      });
    } finally {
      await packer.release().catch(() => {});
    }
  }
}
