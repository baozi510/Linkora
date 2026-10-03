import { common } from '@kit.AbilityKit';
import { relationalStore } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { LocalMediaAsset, LocalMediaPlaybackProgress, LocalMediaProgressRepository,
  MediaSource, PlaybackBookmark, PlaybackBookmarkRepository } from 'linkora_core';
import { LinkoraDatabase } from './LinkoraDatabase';
import { SourceIdentity } from './SourceIdentity';

class StoredProgress {
  readonly sourceKey: string;
  readonly positionMs: number;
  readonly durationMs: number;
  readonly updatedAt: number;

  constructor(sourceKey: string, positionMs: number, durationMs: number, updatedAt: number) {
    this.sourceKey = sourceKey;
    this.positionMs = positionMs;
    this.durationMs = durationMs;
    this.updatedAt = updatedAt;
  }
}

export class PlaybackBookmarkStore implements PlaybackBookmarkRepository, LocalMediaProgressRepository {
  private database: LinkoraDatabase;

  constructor(context: common.UIAbilityContext) {
    this.database = LinkoraDatabase.shared(context);
  }

  async load(source: MediaSource): Promise<PlaybackBookmark | null> {
    try {
      await this.database.waitForWrites();
      return await this.loadDatabase(source);
    } catch (_error) {
      return null;
    }
  }

  async save(source: MediaSource, bookmark: PlaybackBookmark): Promise<void> {
    try {
      if (bookmark.duration < 30000 || bookmark.position < 5000) {
        return;
      }
      await this.enqueue(async (): Promise<void> => {
        const store: relationalStore.RdbStore = await this.database.store();
        const key: string = await SourceIdentity.key(source);
        if (bookmark.duration - bookmark.position < 30000) {
          await store.execute('DELETE FROM playback_state WHERE source_key = ?', [key]);
          console.info('Playback position cleared near media end.');
          return;
        }
        await store.execute(
          `INSERT INTO playback_state
            (source_key, position_ms, duration_ms, completed, play_count, last_played_at, updated_at)
           VALUES (?, ?, ?, 0, 0, 0, ?)
           ON CONFLICT(source_key) DO UPDATE SET
            position_ms = excluded.position_ms,
            duration_ms = excluded.duration_ms,
            completed = 0,
            updated_at = excluded.updated_at
           WHERE excluded.updated_at >= playback_state.updated_at`,
          [key, Math.round(bookmark.position), Math.round(bookmark.duration), Math.round(bookmark.updatedAt)]);
        console.info('Playback position updated.');
      });
    } catch (error) {
      const failure: BusinessError = error as BusinessError;
      console.error(`Playback position update failed. code=${failure.code}, message=${failure.message}`);
      throw new Error('Unable to persist playback position');
    }
  }

  async clear(source: MediaSource): Promise<void> {
    try {
      await this.enqueue(async (): Promise<void> => {
        const store: relationalStore.RdbStore = await this.database.store();
        await store.execute('DELETE FROM playback_state WHERE source_key = ?',
          [await SourceIdentity.key(source)]);
      });
    } catch (_error) {
    }
  }

  async loadFor(items: LocalMediaAsset[]): Promise<LocalMediaPlaybackProgress[]> {
    if (items.length === 0) {
      return [];
    }
    try {
      await this.database.waitForWrites();
      const stored: StoredProgress[] = await this.loadStoredProgress();
      const progress: LocalMediaPlaybackProgress[] = [];
      const visitedUris: string[] = [];
      for (const item of items) {
        if (!item.isVideo() || visitedUris.includes(item.uri)) {
          continue;
        }
        visitedUris.push(item.uri);
        const key: string = await SourceIdentity.key(item.toMediaSource());
        for (const entry of stored) {
          if (entry.sourceKey === key) {
            progress.push(new LocalMediaPlaybackProgress(item.uri, entry.positionMs,
              entry.durationMs, entry.updatedAt));
            break;
          }
        }
      }
      return progress;
    } catch (_error) {
      return [];
    }
  }

  private async loadDatabase(source: MediaSource): Promise<PlaybackBookmark | null> {
    const store: relationalStore.RdbStore = await this.database.store();
    let result: relationalStore.ResultSet | null = null;
    try {
      result = await store.querySql(
        'SELECT position_ms, duration_ms, updated_at FROM playback_state WHERE source_key = ? LIMIT 1',
        [await SourceIdentity.key(source)]);
      if (!result.goToNextRow()) {
        return null;
      }
      return new PlaybackBookmark(
        result.getLong(result.getColumnIndex('position_ms')),
        result.getLong(result.getColumnIndex('duration_ms')),
        result.getLong(result.getColumnIndex('updated_at')));
    } catch (_error) {
      throw new Error('Unable to load playback position');
    } finally {
      if (result !== null) {
        try {
          result.close();
        } catch (_closeError) {
        }
      }
    }
  }

  private async loadStoredProgress(): Promise<StoredProgress[]> {
    const store: relationalStore.RdbStore = await this.database.store();
    let result: relationalStore.ResultSet | null = null;
    const items: StoredProgress[] = [];
    try {
      result = await store.querySql(
        `SELECT source_key, position_ms, duration_ms, updated_at FROM playback_state
         WHERE position_ms > 0 AND duration_ms > 0`);
      while (result.goToNextRow()) {
        items.push(new StoredProgress(
          result.getString(result.getColumnIndex('source_key')),
          result.getLong(result.getColumnIndex('position_ms')),
          result.getLong(result.getColumnIndex('duration_ms')),
          result.getLong(result.getColumnIndex('updated_at'))));
      }
      return items;
    } finally {
      if (result !== null) {
        try {
          result.close();
        } catch (_closeError) {
        }
      }
    }
  }

  private async enqueue(operation: () => Promise<void>): Promise<void> {
    await this.database.enqueueWrite(operation);
  }

}
