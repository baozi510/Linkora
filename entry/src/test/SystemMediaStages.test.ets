import { describe, expect, it } from '@ohos/hypium';
import { image } from '@kit.ImageKit';
import { media } from '@kit.MediaKit';
import {
  SystemMediaProbe,
  SystemThumbnailExtractor
} from 'linkora_media_probe';

class StageExtractorStub {
  metadata: media.AVMetadata = { duration: '45000', videoWidth: '3840', videoHeight: '2160' };
  timeUs: number = -1;
  width: number = 0;
  height: number = 0;
  frame: image.PixelMap;

  constructor(frame: image.PixelMap) {
    this.frame = frame;
  }

  async fetchMetadata(): Promise<media.AVMetadata> {
    return this.metadata;
  }

  async fetchFrameByTime(time: number, _option: media.AVImageQueryOptions,
    params: media.PixelMapParams): Promise<image.PixelMap> {
    this.timeUs = time;
    this.width = params.width;
    this.height = params.height;
    return this.frame;
  }
}

class FrameStub {
  async release(): Promise<void> {}
}

export default function systemMediaStagesTest(): void {
  describe('SystemMediaStages', () => {
    it('extractsMetadataWithoutOwningExtractorLifecycle', 0, async () => {
      const frame = new FrameStub() as Object as image.PixelMap;
      const stub = new StageExtractorStub(frame);
      const stage = new SystemMediaProbe();

      const result = await stage.probe(stub as Object as media.AVMetadataExtractor);

      expect(result.durationMs).assertEqual(45000);
      expect(result.width).assertEqual(3840);
      expect(result.height).assertEqual(2160);
      expect(result.complete).assertTrue();
    });

    it('extractsFrameWithoutEncodingOrCaching', 0, async () => {
      const frame = new FrameStub() as Object as image.PixelMap;
      const stub = new StageExtractorStub(frame);
      const stage = new SystemThumbnailExtractor();

      const result = await stage.extract(
        stub as Object as media.AVMetadataExtractor,
        200,
        480,
        270
      );

      expect(result.thumbnail).assertEqual(frame);
      expect(result.timeUs).assertEqual(199000);
      expect(stub.width).assertEqual(480);
      expect(stub.height).assertEqual(270);
    });
  });
}
