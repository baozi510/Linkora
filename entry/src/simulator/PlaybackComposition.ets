import { common } from '@kit.AbilityKit';
import { PlaybackPort, PlaybackPortObserver, PlayerBackendPreference } from 'linkora_core';
import { NetworkFileProxy } from 'linkora_proxy';
import { SystemPlaybackPort } from 'entry/ets/playback/SystemPlaybackPort';

/**
 * Simulator validation intentionally excludes MPV and all native file-protocol runtimes.
 * Unused parameters keep the target composition contract identical to production.
 */
export async function createPlaybackPort(_context: common.UIAbilityContext, _proxy: NetworkFileProxy,
  observer: PlaybackPortObserver, _preference: PlayerBackendPreference): Promise<PlaybackPort> {
  return SystemPlaybackPort.create(observer);
}
