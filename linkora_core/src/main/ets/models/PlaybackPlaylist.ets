import { MediaSource } from './MediaSource';

export class PlaybackPlaylistItem {
  readonly id: string;
  readonly source: MediaSource;

  constructor(id: string, source: MediaSource) {
    this.id = id;
    this.source = source;
  }
}

/** A detached media snapshot; it does not resolve sources or advance playback. */
export class PlaybackPlaylist {
  private readonly entries: PlaybackPlaylistItem[];
  readonly startIndex: number;
  readonly complete: boolean;

  constructor(items: PlaybackPlaylistItem[], startIndex: number, complete: boolean) {
    if (!Number.isInteger(startIndex) || (items.length === 0 ? startIndex !== -1 :
      startIndex < 0 || startIndex >= items.length)) {
      throw new Error('Invalid playlist start index');
    }
    const ids: Set<string> = new Set<string>();
    for (const item of items) {
      if (item.id.trim().length === 0 || item.source.locator.trim().length === 0 || ids.has(item.id)) {
        throw new Error('Invalid or repeated playlist item identity');
      }
      ids.add(item.id);
    }
    this.entries = items.slice();
    this.startIndex = startIndex;
    this.complete = complete;
  }

  get items(): PlaybackPlaylistItem[] {
    return this.entries.slice();
  }

  currentItem(): PlaybackPlaylistItem | null {
    return this.startIndex < 0 ? null : this.entries[this.startIndex];
  }
}
