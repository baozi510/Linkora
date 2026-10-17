import { describe, expect, it } from '@ohos/hypium';
import { AudioTrackChoice, AudioTrackPreferences, PortTrack, PortTrackKind } from 'linkora_core';

export default function audioTrackPreferencesTest(): void {
  describe('AudioTrackPreferences', () => {
    it('normalizesContainerLanguagesAndHonorsPreferenceOrder', 0, () => {
      const english: PortTrack = new PortTrack('1', PortTrackKind.AUDIO, 'aac', 'eng');
      const chinese: PortTrack = new PortTrack('2', PortTrackKind.AUDIO, 'aac', 'zho');
      expect(new AudioTrackPreferences(['en', 'zh']).choose([chinese, english], null)?.id).assertEqual('1');
      expect(AudioTrackPreferences.language('ITA')).assertEqual('it');
      expect(AudioTrackPreferences.language('dut')).assertEqual('nl');
      expect(AudioTrackPreferences.language('ZH_CN')).assertEqual('zh-cn');
    });

    it('prefersTheDefaultAmongEquivalentLanguages', 0, () => {
      const first: PortTrack = new PortTrack('1', PortTrackKind.AUDIO, 'aac', 'en');
      const second: PortTrack = new PortTrack('2', PortTrackKind.AUDIO, 'aac', 'eng', '', false, 2, 48000, 128000, true);
      expect(new AudioTrackPreferences(['en']).choose([first, second], null)?.id).assertEqual('2');
      expect(second.channels).assertEqual(2);
      expect(second.sampleRate).assertEqual(48000);
      expect(second.bitrate).assertEqual(128000);
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
