import { common } from '@kit.AbilityKit';
import { PlaybackPort, PlaybackPortObserver, PlayerBackendPreference } from 'linkora_core';
import { NetworkFileProxy } from 'linkora_proxy';
import { AdaptivePlaybackPort } from 'entry/ets/playback/AdaptivePlaybackPort';

export async function createPlaybackPort(context: common.UIAbilityContext, proxy: NetworkFileProxy,
  observer: PlaybackPortObserver, preference: PlayerBackendPreference): Promise<PlaybackPort> {
  return new AdaptivePlaybackPort(context, proxy, observer, preference);
}
