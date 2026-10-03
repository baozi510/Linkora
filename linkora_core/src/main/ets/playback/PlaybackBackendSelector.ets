import { MediaFormat } from '../models/MediaLink';
import { MediaSource } from '../models/MediaSource';
import { PlayerBackendKind, PlayerBackendPreference } from './PlaybackBackend';

/**
 * Baseline selector used until playback benchmark data is available.
 *
 * This deliberately uses only coarse container information. Later policy may
 * consume probed codecs/HDR/audio/subtitle/device capabilities without changing
 * PlaybackEngine or the concrete backends.
 */
export class PlaybackBackendSelector {
  select(source: MediaSource, preference: PlayerBackendPreference): PlayerBackendKind {
    if (preference === PlayerBackendPreference.SYSTEM) {
      return PlayerBackendKind.SYSTEM;
    }
    if (preference === PlayerBackendPreference.MPV) {
      return PlayerBackendKind.MPV;
    }
    return this.systemBaselineCandidate(source) ?
      PlayerBackendKind.SYSTEM : PlayerBackendKind.MPV;
  }

  fallback(selected: PlayerBackendKind): PlayerBackendKind {
    return selected === PlayerBackendKind.SYSTEM ?
      PlayerBackendKind.MPV : PlayerBackendKind.SYSTEM;
  }

  private systemBaselineCandidate(source: MediaSource): boolean {
    return source.format === MediaFormat.MP4 ||
      source.format === MediaFormat.HLS ||
      source.format === MediaFormat.DASH;
  }
}
