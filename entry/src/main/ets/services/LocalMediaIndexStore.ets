import { common } from '@kit.AbilityKit';
import { relationalStore } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { LocalFileCategory, LocalMediaAsset, LocalMediaFolder, LocalMediaScanResult } from 'linkora_core';
import { LinkoraDatabase } from './LinkoraDatabase';

const SOURCE_KIND: string = 'photo_library';
const CHECKPOINT_KEY: string = 'photo_library';
const ROOT_COLLECTION_KEY: string = '@root';
const UNRESOLVED_COLLECTION_KEY: string = 'linkora://unresolved-album';

class ScanCheckpoint {
  readonly generation: number;
  readonly completedAt: number;
  readonly fingerprint: string;

  constructor(generation: number = 0, completedAt: number = 0, fingerprint: string = '') {
    this.generation = Math.max(0, generation);
    this.completedAt = Math.max(0, completedAt);
    this.fingerprint = fingerprint;
  }
}

export class LocalMediaIndexStore {
  private database: LinkoraDatabase;

  constructor(context: common.UIAbilityContext) {
    this.database = LinkoraDatabase.shared(context);
  }

  async replaceLibrary(result: LocalMediaScanResult): Promise<LocalMediaScanResult> {
    if (!result.succeeded()) {
      return result;
    }
    try {
      await this.enqueue(async (): Promise<void> => {
        await this.persistLibrary(result);
      });
      return await this.loadLibrary();
    } catch (error) {
      this.logFailure('Local media index refresh', error);
      return new LocalMediaScanResult(result.items, result.folders, result.selectedFolderUri,
        result.errorCode, result.snapshotComplete, result.generation, result.completedAt,
        result.fingerprint, false);
    }
  }

  async replaceDirectory(result: LocalMediaScanResult): Promise<LocalMediaScanResult> {
    if (!result.succeeded() || result.selectedFolderUri.length === 0) {
      return result;
    }
    try {
      await this.enqueue(async (): Promise<void> => {
        await this.persistDirectory(result);
      });
      return await this.loadDirectory(result.selectedFolderUri);
    } catch (error) {
      this.logFailure('Local album index refresh', error);
      return new LocalMediaScanResult(result.items, result.folders, result.selectedFolderUri,
        result.errorCode, result.snapshotComplete, result.generation, result.completedAt,
        result.fingerprint, false);
    }
  }

  async loadCachedLibrary(): Promise<LocalMediaScanResult | null> {
    await this.database.waitForWrites();
    const store: relationalStore.RdbStore = await this.database.store();
    const checkpoint: ScanCheckpoint | null = await this.completedCheckpoint(store);
    if (checkpoint === null) {
      return null;
    }
    const items: LocalMediaAsset[] = await this.loadItems(store, '', false);
    const folders: LocalMediaFolder[] = await this.loadFolders(store);
    console.info(`Local media cache loaded. items=${items.length}, folders=${folders.length}`);
    return new LocalMediaScanResult(items, folders, '', 0, true,
      checkpoint.generation, checkpoint.completedAt, checkpoint.fingerprint);
  }

  async loadCachedDirectory(directoryUri: string): Promise<LocalMediaScanResult | null> {
    if (directoryUri.length === 0) {
      return null;
    }
    await this.database.waitForWrites();
    const store: relationalStore.RdbStore = await this.database.store();
    const checkpoint: ScanCheckpoint | null = await this.completedCheckpoint(store);
    if (checkpoint === null || !await this.hasCollection(store, directoryUri)) {
      return null;
    }
    const items: LocalMediaAsset[] = await this.loadItems(store, directoryUri, true);
    console.info(`Local directory cache loaded. items=${items.length}`);
    return new LocalMediaScanResult(items, [], directoryUri, 0, true,
      checkpoint.generation, checkpoint.completedAt, checkpoint.fingerprint);
  }

  async loadLibrary(): Promise<LocalMediaScanResult> {
    await this.database.waitForWrites();
    const store: relationalStore.RdbStore = await this.database.store();
    const items: LocalMediaAsset[] = await this.loadItems(store, '', false);
    const folders: LocalMediaFolder[] = await this.loadFolders(store);
    const checkpoint: ScanCheckpoint | null = await this.completedCheckpoint(store);
    return new LocalMediaScanResult(items, folders, '', 0, true,
      checkpoint?.generation ?? 0, checkpoint?.completedAt ?? 0,
      checkpoint?.fingerprint ?? '');
  }

  async loadDirectory(directoryUri: string): Promise<LocalMediaScanResult> {
    await this.database.waitForWrites();
    const store: relationalStore.RdbStore = await this.database.store();
    const items: LocalMediaAsset[] = await this.loadItems(store, directoryUri, true);
    const checkpoint: ScanCheckpoint | null = await this.completedCheckpoint(store);
    return new LocalMediaScanResult(items, [], directoryUri, 0, true,
      checkpoint?.generation ?? 0, checkpoint?.completedAt ?? 0,
      checkpoint?.fingerprint ?? '');
  }

  private async persistLibrary(result: LocalMediaScanResult): Promise<void> {
    const store: relationalStore.RdbStore = await this.database.store();
    const generation: number = await this.nextGeneration(store);
    const now: number = Date.now();
    store.beginTransaction();
    try {
      await store.execute(
        `INSERT INTO scan_checkpoint
          (source_key, cursor, generation, status, started_at, completed_at)
         VALUES (?, ?, ?, 'scanning', ?, 0)
         ON CONFLICT(source_key) DO UPDATE SET
          cursor = excluded.cursor, generation = excluded.generation, status = 'scanning',
          started_at = excluded.started_at, completed_at = 0`,
        [CHECKPOINT_KEY, result.snapshotComplete ? result.fingerprint : '', generation, now]);
      await this.upsertCollection(store, ROOT_COLLECTION_KEY, '', '本地根目录', true,
        0, 0, 0, '', generation, now);
      await this.upsertCollection(store, UNRESOLVED_COLLECTION_KEY,
        UNRESOLVED_COLLECTION_KEY, '未归属相册', true, 0, 0, 0, '', generation, now);
      for (const folder of result.folders) {
        await this.upsertCollection(store, folder.uri, folder.uri,
          folder.displayName, false, folder.totalCount, folder.videoCount, folder.imageCount,
          folder.coverUri, generation, now, folder.subtitleCount, folder.parentUri,
          folder.totalSizeBytes);
      }
      for (let index: number = 0; index < result.items.length; index++) {
        await this.upsertItem(store, result.items[index], generation, now, true);
      }
      if (result.snapshotComplete) {
        await store.execute(
          `DELETE FROM media_collection
           WHERE source_kind = ? AND scan_generation <> ?
             AND source_key <> '@root' AND source_key NOT LIKE 'mock://%'`,
          [SOURCE_KIND, generation]);
        await store.execute(
          `DELETE FROM media_locator
           WHERE source_kind = ? AND scan_generation <> ?
             AND locator NOT LIKE 'mock://%'`,
          [SOURCE_KIND, generation]);
        await store.execute(
          'DELETE FROM media_entity WHERE NOT EXISTS ' +
          '(SELECT 1 FROM media_locator WHERE media_locator.media_id = media_entity.id)',
          []);
      }
      await store.execute(
        `UPDATE scan_checkpoint SET status = 'idle', completed_at = ? WHERE source_key = ?`,
        [Date.now(), CHECKPOINT_KEY]);
      store.commit();
      console.info(`Local media index refreshed. items=${result.items.length}, ` +
        `folders=${result.folders.length}, complete=${result.snapshotComplete}`);
    } catch (error) {
      this.rollback(store);
      this.logFailure('Local media index transaction', error as Object);
      throw new Error('Unable to refresh the local media index');
    }
  }

  private async persistDirectory(result: LocalMediaScanResult): Promise<void> {
    const store: relationalStore.RdbStore = await this.database.store();
    const generation: number = await this.currentGeneration(store);
    const now: number = Date.now();
    store.beginTransaction();
    try {
      await store.execute(
        `INSERT INTO media_collection
          (source_kind, source_key, parent_key, display_name, locator, is_virtual,
           total_count, video_count, image_count, subtitle_count, cover_locator,
           scan_generation, updated_at)
         VALUES (?, ?, NULL, ?, ?, 0, 0, 0, 0, 0, '', ?, ?)
         ON CONFLICT(source_kind, source_key) DO UPDATE SET
          locator = excluded.locator, is_virtual = 0, updated_at = excluded.updated_at`,
        [SOURCE_KIND, result.selectedFolderUri, result.selectedFolderUri,
          result.selectedFolderUri, generation, now]);
      if (result.snapshotComplete) {
        await store.execute(
          'DELETE FROM collection_membership WHERE collection_id = ' +
          '(SELECT id FROM media_collection WHERE source_kind = ? AND source_key = ?)',
          [SOURCE_KIND, result.selectedFolderUri]);
      }
      for (let index: number = 0; index < result.items.length; index++) {
        const item: LocalMediaAsset = result.items[index];
        const indexedItem: LocalMediaAsset = new LocalMediaAsset(item.uri, item.displayName,
          item.durationMs, item.width, item.height, item.sizeBytes, item.modifiedAt,
          item.category, result.selectedFolderUri);
        await this.upsertItem(store, indexedItem, generation, now);
      }
      await store.execute(
        `UPDATE media_collection SET video_count =
          (SELECT COUNT(*) FROM collection_membership membership
           JOIN media_entity entity ON entity.id = membership.media_id
           WHERE membership.collection_id = media_collection.id AND entity.media_type = 'video'),
          image_count =
          (SELECT COUNT(*) FROM collection_membership membership
           JOIN media_entity entity ON entity.id = membership.media_id
           WHERE membership.collection_id = media_collection.id AND entity.media_type = 'image'),
          total_count =
          (SELECT COUNT(*) FROM collection_membership WHERE collection_id = media_collection.id),
          total_size_bytes = COALESCE((SELECT SUM(entity.size_bytes)
            FROM collection_membership membership
            JOIN media_entity entity ON entity.id = membership.media_id
            WHERE membership.collection_id = media_collection.id), 0),
          updated_at = ?
         WHERE source_kind = ? AND source_key = ?`,
        [now, SOURCE_KIND, result.selectedFolderUri]);
      store.commit();
      console.info(`Local directory index refreshed. items=${result.items.length}, ` +
        `complete=${result.snapshotComplete}`);
    } catch (error) {
      this.rollback(store);
      this.logFailure('Local directory index transaction', error as Object);
      throw new Error('Unable to refresh the local directory index');
    }
  }

  private async upsertCollection(store: relationalStore.RdbStore, sourceKey: string,
    locator: string, displayName: string, virtualCollection: boolean,
    totalCount: number, videoCount: number, imageCount: number, coverLocator: string,
    generation: number, now: number, subtitleCount: number = 0,
    parentKey: string = '', totalSizeBytes: number = 0): Promise<void> {
    await store.execute(
      `INSERT INTO media_collection
        (source_kind, source_key, parent_key, display_name, locator, is_virtual,
         total_count, video_count, image_count, subtitle_count, cover_locator,
         total_size_bytes, scan_generation, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
       ON CONFLICT(source_kind, source_key) DO UPDATE SET
        display_name = excluded.display_name,
        parent_key = excluded.parent_key,
        locator = excluded.locator,
        is_virtual = excluded.is_virtual,
        total_count = excluded.total_count,
        video_count = excluded.video_count,
        image_count = excluded.image_count,
        subtitle_count = excluded.subtitle_count,
        cover_locator = excluded.cover_locator,
        total_size_bytes = excluded.total_size_bytes,
        scan_generation = excluded.scan_generation,
        updated_at = excluded.updated_at`,
      [SOURCE_KIND, sourceKey, parentKey, displayName, locator, virtualCollection ? 1 : 0,
        totalCount, videoCount, imageCount, subtitleCount, coverLocator, totalSizeBytes,
        generation, now]);
  }

  private async upsertItem(store: relationalStore.RdbStore, item: LocalMediaAsset,
    generation: number, now: number, replaceMemberships: boolean = false): Promise<void> {
    const identityKey: string = `${SOURCE_KIND}:${item.uri}`;
    const collectionKey: string = item.parentUri.length === 0 ? ROOT_COLLECTION_KEY : item.parentUri;
    await store.execute(
      `INSERT INTO media_entity
        (identity_key, display_name, size_bytes, media_type, duration_ms, width, height,
         modified_at, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
       ON CONFLICT(identity_key) DO UPDATE SET
        display_name = excluded.display_name,
        size_bytes = excluded.size_bytes,
        media_type = excluded.media_type,
        duration_ms = excluded.duration_ms,
        width = excluded.width,
        height = excluded.height,
        modified_at = excluded.modified_at,
        updated_at = excluded.updated_at`,
      [identityKey, item.displayName, item.sizeBytes, item.category, item.durationMs,
        item.width, item.height, item.modifiedAt, now, now]);
    await store.execute(
      `INSERT INTO media_locator
        (media_id, source_kind, locator, permission_state, added_at,
         last_verified_at, scan_generation)
       SELECT id, ?, ?, 'available', ?, ?, ? FROM media_entity WHERE identity_key = ?
       ON CONFLICT(source_kind, locator) DO UPDATE SET
        media_id = excluded.media_id,
        permission_state = 'available',
        last_verified_at = excluded.last_verified_at,
        scan_generation = excluded.scan_generation`,
      [SOURCE_KIND, item.uri, now, now, generation, identityKey]);
    if (replaceMemberships) {
      await store.execute(
        'DELETE FROM collection_membership WHERE locator_id = ' +
        '(SELECT id FROM media_locator WHERE source_kind = ? AND locator = ?)',
        [SOURCE_KIND, item.uri]);
    }
    await this.ensureCollection(store, collectionKey, generation, now);
    await store.execute(
      `INSERT INTO collection_membership
        (collection_id, media_id, locator_id, display_order, added_at)
       SELECT collection.id, entity.id, locator.id, ?, ?
       FROM media_collection collection, media_entity entity, media_locator locator
       WHERE collection.source_kind = ? AND collection.source_key = ?
         AND entity.identity_key = ?
         AND locator.source_kind = ? AND locator.locator = ?
       ON CONFLICT(collection_id, locator_id) DO UPDATE SET
        media_id = excluded.media_id, display_order = excluded.display_order`,
      [item.modifiedAt, now, SOURCE_KIND, collectionKey, identityKey,
        SOURCE_KIND, item.uri]);
  }

  private async ensureCollection(store: relationalStore.RdbStore, collectionKey: string,
    generation: number, now: number): Promise<void> {
    await store.execute(
      `INSERT INTO media_collection
        (source_kind, source_key, parent_key, display_name, locator, is_virtual,
         total_count, video_count, image_count, subtitle_count, cover_locator,
         scan_generation, updated_at)
       VALUES (?, ?, NULL, ?, ?, 1, 0, 0, 0, 0, '', ?, ?)
       ON CONFLICT(source_kind, source_key) DO UPDATE SET
        scan_generation = excluded.scan_generation, updated_at = excluded.updated_at`,
      [SOURCE_KIND, collectionKey, collectionKey, collectionKey, generation, now]);
  }

  private async loadItems(store: relationalStore.RdbStore, directoryUri: string,
    selectDirectory: boolean): Promise<LocalMediaAsset[]> {
    let result: relationalStore.ResultSet | null = null;
    const items: LocalMediaAsset[] = [];
    try {
      if (selectDirectory) {
        result = await store.querySql(
          `SELECT entity.display_name, entity.size_bytes, entity.duration_ms,
            entity.width, entity.height, entity.modified_at, entity.media_type, locator.locator,
            collection.locator AS album_uri
           FROM media_locator locator
           JOIN media_entity entity ON entity.id = locator.media_id
           JOIN collection_membership membership ON membership.locator_id = locator.id
           JOIN media_collection collection ON collection.id = membership.collection_id
           WHERE locator.source_kind = ? AND locator.permission_state = 'available'
            AND collection.source_kind = ? AND collection.locator = ?
           ORDER BY entity.modified_at DESC, entity.id DESC`,
          [SOURCE_KIND, SOURCE_KIND, directoryUri]);
      } else {
        result = await store.querySql(
          `SELECT entity.display_name, entity.size_bytes, entity.duration_ms,
            entity.width, entity.height, entity.modified_at, entity.media_type, locator.locator,
            COALESCE((SELECT candidate.locator
              FROM collection_membership candidate_membership
              JOIN media_collection candidate
                ON candidate.id = candidate_membership.collection_id
              WHERE candidate_membership.locator_id = locator.id
                AND candidate.source_kind = ? AND candidate.is_virtual = 0
              ORDER BY candidate.id LIMIT 1), '') AS album_uri
           FROM media_locator locator
           JOIN media_entity entity ON entity.id = locator.media_id
           WHERE locator.source_kind = ? AND locator.permission_state = 'available'
           ORDER BY entity.modified_at DESC, entity.id DESC`,
          [SOURCE_KIND, SOURCE_KIND]);
      }
      while (result.goToNextRow()) {
        items.push(new LocalMediaAsset(
          result.getString(result.getColumnIndex('locator')),
          result.getString(result.getColumnIndex('display_name')),
          result.getLong(result.getColumnIndex('duration_ms')),
          result.getLong(result.getColumnIndex('width')),
          result.getLong(result.getColumnIndex('height')),
          result.getLong(result.getColumnIndex('size_bytes')),
          result.getLong(result.getColumnIndex('modified_at')),
          this.categoryOf(result.getString(result.getColumnIndex('media_type'))),
          result.getString(result.getColumnIndex('album_uri'))));
      }
    } finally {
      this.close(result);
    }
    return items;
  }

  private categoryOf(value: string): LocalFileCategory {
    if (value === LocalFileCategory.IMAGE) {
      return LocalFileCategory.IMAGE;
    }
    if (value === LocalFileCategory.AUDIO) {
      return LocalFileCategory.AUDIO;
    }
    if (value === LocalFileCategory.SUBTITLE) {
      return LocalFileCategory.SUBTITLE;
    }
    return LocalFileCategory.VIDEO;
  }

  private async loadFolders(store: relationalStore.RdbStore): Promise<LocalMediaFolder[]> {
    let result: relationalStore.ResultSet | null = null;
    const folders: LocalMediaFolder[] = [];
    try {
      result = await store.querySql(
        `SELECT locator, display_name, total_count, video_count, image_count,
          subtitle_count, cover_locator, COALESCE(parent_key, '') AS parent_key,
          total_size_bytes
         FROM media_collection
         WHERE source_kind = ? AND is_virtual = 0
         ORDER BY display_name COLLATE NOCASE, id`, [SOURCE_KIND]);
      while (result.goToNextRow()) {
        folders.push(new LocalMediaFolder(
          result.getString(result.getColumnIndex('locator')),
          result.getString(result.getColumnIndex('display_name')),
          result.getLong(result.getColumnIndex('total_count')),
          result.getLong(result.getColumnIndex('video_count')),
          result.getLong(result.getColumnIndex('image_count')),
          result.getString(result.getColumnIndex('cover_locator')),
          result.getLong(result.getColumnIndex('subtitle_count')),
          result.getString(result.getColumnIndex('parent_key')),
          result.getLong(result.getColumnIndex('total_size_bytes'))));
      }
    } finally {
      this.close(result);
    }
    return folders;
  }

  private async nextGeneration(store: relationalStore.RdbStore): Promise<number> {
    return (await this.currentGeneration(store)) + 1;
  }

  private async currentGeneration(store: relationalStore.RdbStore): Promise<number> {
    let result: relationalStore.ResultSet | null = null;
    try {
      result = await store.querySql(
        'SELECT generation FROM scan_checkpoint WHERE source_key = ? LIMIT 1', [CHECKPOINT_KEY]);
      return result.goToNextRow() ? result.getLong(result.getColumnIndex('generation')) : 0;
    } finally {
      this.close(result);
    }
  }

  private async completedCheckpoint(store: relationalStore.RdbStore): Promise<ScanCheckpoint | null> {
    let result: relationalStore.ResultSet | null = null;
    try {
      result = await store.querySql(
        `SELECT generation, completed_at, cursor FROM scan_checkpoint
         WHERE source_key = ? AND status = 'idle' AND completed_at > 0 LIMIT 1`,
        [CHECKPOINT_KEY]);
      if (!result.goToNextRow()) {
        return null;
      }
      return new ScanCheckpoint(
        result.getLong(result.getColumnIndex('generation')),
        result.getLong(result.getColumnIndex('completed_at')),
        result.getString(result.getColumnIndex('cursor')));
    } finally {
      this.close(result);
    }
  }

  private async hasCollection(store: relationalStore.RdbStore, albumUri: string): Promise<boolean> {
    let result: relationalStore.ResultSet | null = null;
    try {
      result = await store.querySql(
        `SELECT id FROM media_collection
         WHERE source_kind = ? AND locator = ? AND is_virtual = 0 LIMIT 1`,
        [SOURCE_KIND, albumUri]);
      return result.goToNextRow();
    } finally {
      this.close(result);
    }
  }

  private rollback(store: relationalStore.RdbStore): void {
    try {
      store.rollBack();
    } catch (_error) {
    }
  }

  private close(result: relationalStore.ResultSet | null): void {
    if (result === null) {
      return;
    }
    try {
      result.close();
    } catch (_error) {
    }
  }

  private async enqueue(operation: () => Promise<void>): Promise<void> {
    await this.database.enqueueWrite(operation);
  }

  private logFailure(action: string, error: Object): void {
    const failure: BusinessError = error as BusinessError;
    console.error(`${action} failed. code=${failure.code}, message=${failure.message}`);
  }
}
