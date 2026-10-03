import { image } from '@kit.ImageKit';

export class SystemWebPEncoder {
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
