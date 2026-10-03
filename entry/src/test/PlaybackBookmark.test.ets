import { describe, expect, it } from '@ohos/hypium';
import { PlaybackBookmark } from 'linkora_core';

export default function playbackBookmarkTest(): void {
  describe('PlaybackBookmark', () => {
    it('roundTripsStoredBookmark', 0, () => {
      const bookmark = new PlaybackBookmark(95234, 420000, 1000000);
      const decoded: PlaybackBookmark | null = PlaybackBookmark.decode(bookmark.encode());

      expect(decoded === null).assertFalse();
      expect((decoded as PlaybackBookmark).position).assertEqual(95234);
      expect((decoded as PlaybackBookmark).duration).assertEqual(420000);
    });

    it('rejectsMalformedBookmark', 0, () => {
      expect(PlaybackBookmark.decode('broken') === null).assertTrue();
      expect(PlaybackBookmark.decode('-1,100,100') === null).assertTrue();
    });

    it('resumesOnlyMeaningfulProgress', 0, () => {
      expect(new PlaybackBookmark(4000, 120000, 100).resumePosition()).assertEqual(0);
      expect(new PlaybackBookmark(95000, 120000, 100).resumePosition()).assertEqual(0);
      expect(new PlaybackBookmark(45000, 120000, 100).resumePosition()).assertEqual(45000);
    });
  });
}
