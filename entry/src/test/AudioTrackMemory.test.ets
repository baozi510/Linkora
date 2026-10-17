import { describe, expect, it } from '@ohos/hypium';
import { AudioTrackChoice, PortTrack, PortTrackKind } from 'linkora_core';

export default function audioTrackMemoryTest(): void {
  describe('AudioTrackMemory', () => {
    it('normalizesStoredLanguageMetadataWithoutPreferences', 0, () => {
      expect(AudioTrackChoice.language('ITA')).assertEqual('it');
      expect(AudioTrackChoice.language('dut')).assertEqual('nl');
      expect(AudioTrackChoice.language('ZH_CN')).assertEqual('zh-cn');
    });

    it('preservesAudioDetails', 0, () => {
      const track: PortTrack = new PortTrack('2', PortTrackKind.AUDIO, 'aac', 'eng', '', false, 2, 48000, 128000, true);
      expect(track.channels).assertEqual(2);
      expect(track.sampleRate).assertEqual(48000);
      expect(track.bitrate).assertEqual(128000);
    });

    it('restoresSemanticChoicesWithoutReusingBackendIdsOrGuessingDuplicates', 0, () => {
      const memory: AudioTrackChoice = new AudioTrackChoice('zho', 'Main', 2);
      const track: PortTrack = new PortTrack('21', PortTrackKind.AUDIO, 'aac', 'zh', 'Main', false, 2);
      expect(AudioTrackChoice.decode(memory.encode())?.match([track])?.id).assertEqual('21');
      const duplicate: PortTrack = new PortTrack('22', PortTrackKind.AUDIO, 'aac', 'zh', 'Main', false, 2);
      expect(memory.match([track, duplicate]) === null).assertTrue();
      expect(AudioTrackChoice.decode('invalid') === null).assertTrue();
    });
  });
}
