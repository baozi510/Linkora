import { NetworkServerEntry } from './NetworkServerStore';

const MAX_SESSION_DIRECTORY_SUMMARIES: number = 512;

export class NetworkDirectorySummary {
  readonly path: string;
  readonly fileCount: number;
  readonly totalSize: number;
  readonly directoryCount: number;

  constructor(path: string = '', fileCount: number = 0, totalSize: number = 0, directoryCount: number = 0) {
    this.path = path;
    this.fileCount = Math.max(0, fileCount);
    this.totalSize = Math.max(0, totalSize);
    this.directoryCount = Math.max(0, directoryCount);
  }
}

/** In-memory only. Entries disappear when the app process ends. */
export class NetworkDirectorySummaryCache {
  private static summaries: Map<string, NetworkDirectorySummary> =
    new Map<string, NetworkDirectorySummary>();
  private static insertionOrder: string[] = [];

  static get(server: NetworkServerEntry, path: string): NetworkDirectorySummary | null {
    return NetworkDirectorySummaryCache.summaries.get(
      NetworkDirectorySummaryCache.key(server, path)) ?? null;
  }

  static put(server: NetworkServerEntry, summary: NetworkDirectorySummary): void {
    const key: string = NetworkDirectorySummaryCache.key(server, summary.path);
    if (!NetworkDirectorySummaryCache.summaries.has(key)) {
      NetworkDirectorySummaryCache.insertionOrder.push(key);
    }
    NetworkDirectorySummaryCache.summaries.set(key, summary);
    while (NetworkDirectorySummaryCache.insertionOrder.length > MAX_SESSION_DIRECTORY_SUMMARIES) {
      const oldestKey: string | undefined = NetworkDirectorySummaryCache.insertionOrder.shift();
      if (oldestKey !== undefined) {
        NetworkDirectorySummaryCache.summaries.delete(oldestKey);
      }
    }
  }

  static keyForServer(server: NetworkServerEntry, path: string): string {
    // updatedAt changes whenever a saved server is edited, so stale entries
    // from the previous server configuration cannot be reused accidentally.
    return `${server.id}:${server.updatedAt}:${server.protocol}:${path}`;
  }

  private static key(server: NetworkServerEntry, path: string): string {
    return NetworkDirectorySummaryCache.keyForServer(server, path);
  }
}
