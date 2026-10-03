import { describe, expect, it } from '@ohos/hypium';
import { DefaultThumbnailTimePolicy } from 'linkora_core';

export default function thumbnailPolicyTest(): void {
  describe('ThumbnailPolicy', () => {
    it('usesTwentyPercentForShortVideos', 0, () => {
      const policy = new DefaultThumbnailTimePolicy();
      const plan = policy.plan(20000, 1920, 1080);
      expect(plan.timeMs).assertEqual(4000);
      expect(plan.width).assertEqual(480);
      expect(plan.height).assertEqual(270);
      expect(plan.quality).assertEqual(80);
      expect(plan.algorithmVersion).assertEqual(1);
    });

    it('capsNormalVideosAtSixtySeconds', 0, () => {
      const policy = new DefaultThumbnailTimePolicy();
      expect(policy.plan(20 * 60 * 1000, 1920, 1080).timeMs).assertEqual(60000);
      expect(policy.plan(2 * 60 * 60 * 1000, 1920, 1080).timeMs).assertEqual(60000);
    });

    it('preservesAspectRatioInsideBoundingBox', 0, () => {
      const policy = new DefaultThumbnailTimePolicy();
      const cinema = policy.plan(600000, 3840, 1600);
      const portrait = policy.plan(600000, 1080, 1920);
      expect(cinema.width).assertEqual(480);
      expect(cinema.height).assertEqual(200);
      expect(portrait.width).assertEqual(152);
      expect(portrait.height).assertEqual(270);
    });
  });
}
