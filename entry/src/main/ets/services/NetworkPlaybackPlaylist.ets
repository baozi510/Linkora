import { LocalFileCategory, LocalFileFilter, PlaybackPlaylist, PlaybackPlaylistItem } from 'linkora_core';
import { NetworkDirectoryEntry, NetworkDirectoryEntryKind } from '../models/NetworkDirectoryState';
import { NetworkMediaSourceFactory } from './NetworkMediaSourceFactory';
import { NetworkServerEntry } from './NetworkServerStore';

export class NetworkPlaybackPlaylist {
  static build(server: NetworkServerEntry, directoryPath: string, orderedVisibleEntries: NetworkDirectoryEntry[],
    selectedPath: string, complete: boolean): PlaybackPlaylist | null {
    if (!Number.isSafeInteger(server.id) || server.id <= 0) return null;
    const directory: string = directoryPath.replace(/\/+$/, '');
    const filter = new LocalFileFilter();
    const items: PlaybackPlaylistItem[] = [];
    const paths: Set<string> = new Set<string>();
    let startIndex: number = -1;
    for (const entry of orderedVisibleEntries) {
      const slash: number = entry.path.lastIndexOf('/');
      const parent: string = slash < 0 ? '' : entry.path.substring(0, slash);
      if (entry.kind !== NetworkDirectoryEntryKind.FILE || entry.path.trim().length === 0 ||
        parent !== directory || filter.categoryOf(entry.displayName) !== LocalFileCategory.VIDEO ||
        paths.has(entry.path)) {
        continue;
      }
      paths.add(entry.path);
      if (entry.path === selectedPath) startIndex = items.length;
      const source = NetworkMediaSourceFactory.fromEntry(server, entry);
      items.push(new PlaybackPlaylistItem(`${source.sourceId}:${entry.path}`, source));
    }
    return startIndex < 0 ? null : new PlaybackPlaylist(items, startIndex, complete);
  }
}
