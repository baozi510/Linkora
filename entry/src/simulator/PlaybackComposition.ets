import { common } from '@kit.AbilityKit';
import { PlaybackPort, PlaybackPortObserver, PlayerBackendPreference } from 'linkora_core';
import { NetworkFileProxy } from 'linkora_proxy';
import { AdaptivePlaybackPort } from 'entry/ets/playback/AdaptivePlaybackPort';

/**
 * Simulator keeps the production adaptive playback stack intact.
 *
 * The only platform substitution is the target-specific @mpv-ohos/mpv-arkts package,
 * whose simulator stub fails closed when MPV is instantiated. This preserves:
 * - Auto/System/MPV preference handling
 * - BackendSelector
 * - one-shot fallback
 * - REMOTE_FILE -> RandomAccessSource -> MediaProxy resolution
 */
export async function createPlaybackPort(context: common.UIAbilityContext, proxy: NetworkFileProxy,
  observer: PlaybackPortObserver, preference: PlayerBackendPreference): Promise<PlaybackPort> {
  return new AdaptivePlaybackPort(context, proxy, observer, preference);
}
