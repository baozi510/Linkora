import { LocalMediaAsset } from './LocalMediaAsset';
import { PlaybackPlaylist, PlaybackPlaylistItem } from './PlaybackPlaylist';

export class LocalPlaybackPlaylist {
  /** Consume the browser's scoped, filtered and ordered view without rescanning. */
  static build(orderedVisibleItems: LocalMediaAsset[], selectedUri: string,
    complete: boolean): PlaybackPlaylist | null {
    const items: PlaybackPlaylistItem[] = [];
    const ids: Set<string> = new Set<string>();
    let startIndex: number = -1;
    for (const asset of orderedVisibleItems) {
      if (!asset.isVideo() || !asset.isAvailable() || asset.uri.trim().length === 0 ||
        asset.contentUri().trim().length === 0 || ids.has(asset.uri)) {
        continue;
      }
      ids.add(asset.uri);
      if (asset.uri === selectedUri) startIndex = items.length;
      items.push(new PlaybackPlaylistItem(asset.uri, asset.toMediaSource()));
    }
    return startIndex < 0 ? null : new PlaybackPlaylist(items, startIndex, complete);
  }
}
