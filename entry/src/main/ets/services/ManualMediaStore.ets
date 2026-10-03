import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { fileShare } from '@kit.CoreFileKit';
import { relationalStore } from '@kit.ArkData';
import { LocalFileCategory, LocalFileFilter, LocalMediaAsset, LocalMediaAvailability, LocalMediaFolder,
  LocalMediaCatalog, LocalMediaOrigin, ManualMediaRepository, MediaSource } from 'linkora_core';
import { LinkoraDatabase } from './LinkoraDatabase';
import { LocalMediaMetadata, LocalMediaMetadataReader } from './LocalMediaMetadataReader';

const DOCUMENT_SOURCE_KIND: string = 'document_picker';
const ENTRY_SOURCE_KIND: string = 'virtual_entry';
const FOLDER_SOURCE_KIND: string = 'virtual_folder';
const ROOT_COLLECTION_KEY: string = '@virtual-root';
const ENTRY_URI_PREFIX: string = 'linkora://item/';
const FOLDER_URI_PREFIX: string = 'linkora://folder/';
const VERIFICATION_TTL_MS: number = 6 * 60 * 60 * 1000;
const METADATA_CONCURRENCY: number = 3;

class ManualMediaCandidate {
  readonly source: MediaSource;
  readonly snapshot: LocalMediaMetadata;

  constructor(source: MediaSource, snapshot: LocalMediaMetadata) {
    this.source = source;
    this.snapshot = snapshot;
  }
}

class ManualVerification {
  readonly item: LocalMediaAsset;
  readonly snapshot: LocalMediaMetadata;

  constructor(item: LocalMediaAsset, snapshot: LocalMediaMetadata) {
    this.item = item;
    this.snapshot = snapshot;
  }
}

class AliasTarget {
  readonly aliasId: number;
  readonly mediaId: number;
  readonly sourceUri: string;

  constructor(aliasId: number, mediaId: number, sourceUri: string) {
    this.aliasId = aliasId;
    this.mediaId = mediaId;
    this.sourceUri = sourceUri;
  }
}

class VirtualFolderRecord {
  readonly uri: string;
  readonly parentUri: string;
  readonly displayName: string;
  readonly totalCount: number;
  readonly videoCount: number;
  readonly imageCount: number;
  readonly subtitleCount: number;
  readonly totalSizeBytes: number;
  readonly folderCount: number;

  constructor(uri: string, parentUri: string, displayName: string, totalCount: number,
    videoCount: number, imageCount: number, subtitleCount: number, totalSizeBytes: number,
    folderCount: number) {
    this.uri = uri;
    this.parentUri = parentUri;
    this.displayName = displayName;
    this.totalCount = totalCount;
    this.videoCount = videoCount;
    this.imageCount = imageCount;
    this.subtitleCount = subtitleCount;
    this.totalSizeBytes = totalSizeBytes;
    this.folderCount = folderCount;
  }

  toFolder(): LocalMediaFolder {
    return new LocalMediaFolder(this.uri, this.displayName, this.totalCount, this.videoCount,
      this.imageCount, '', this.subtitleCount, this.parentUri, this.totalSizeBytes, true,
      this.folderCount);
  }
}

export class ManualMediaStore implements ManualMediaRepository {
  private database: LinkoraDatabase;
  private fileFilter: LocalFileFilter = new LocalFileFilter();

  constructor(context: common.UIAbilityContext) {
    this.database = LinkoraDatabase.shared(context);
  }

  async load(): Promise<LocalMediaAsset[]> {
    await this.database.waitForWrites();
    return this.loadItems(await this.database.store());
  }

  async loadFolders(): Promise<LocalMediaFolder[]> {
    await this.database.waitForWrites();
    const records: VirtualFolderRecord[] = await this.loadFolderRecords(await this.database.store());
    return records.map((record: VirtualFolderRecord): LocalMediaFolder => record.toFolder());
  }

  async add(sources: MediaSource[], parentUri: string = ''): Promise<LocalMediaAsset[]> {
    const validSources: MediaSource[] = this.sourcesWithLocator(sources);
    if (validSources.length === 0) {
      return this.load();
    }
    const candidates: ManualMediaCandidate[] = await this.readSourceMetadata(validSources);
    await this.enqueue(async (): Promise<void> => {
      const store: relationalStore.RdbStore = await this.database.store();
      store.beginTransaction();
      try {
        const now: number = Date.now();
        await this.ensureRoot(store, now);
        await this.assertFolderTarget(store, parentUri);
        const newSources: MediaSource[] = LocalMediaCatalog.newManualSources(validSources,
          await this.loadItems(store), parentUri);
        const newLocators: Set<string> = new Set<string>(
          newSources.map((source: MediaSource): string => source.locator));
        for (let index: number = 0; index < candidates.length; index++) {
          const candidate: ManualMediaCandidate = candidates[index];
          await this.upsertRealItem(store, candidate.source, candidate.snapshot);
          if (newLocators.delete(candidate.source.locator)) {
            await this.insertAlias(store, candidate.source.locator,
              `${ENTRY_URI_PREFIX}${util.generateRandomUUID(true)}`, parentUri, now + index);
          }
        }
        await this.updateCollectionCounts(store, now);
        store.commit();
      } catch (_error) {
        this.rollback(store);
        throw new Error('Unable to save manually selected media');
      }
    });
    return this.load();
  }

  async reauthorize(uri: string, source: MediaSource): Promise<LocalMediaAsset[]> {
    if (source.locator.length === 0) {
      throw new Error('Missing replacement file');
    }
    const snapshot: LocalMediaMetadata = await LocalMediaMetadataReader.read(source.locator);
    if (!snapshot.available) {
      throw new Error('Replacement file is unavailable');
    }
    let revokedUri: string = '';
    await this.enqueue(async (): Promise<void> => {
      const store: relationalStore.RdbStore = await this.database.store();
      store.beginTransaction();
      try {
        const items: LocalMediaAsset[] = await this.loadItems(store);
        const item: LocalMediaAsset | undefined = items.find((entry: LocalMediaAsset): boolean =>
          entry.uri === uri);
        const target: AliasTarget | null = await this.findAliasTarget(store, uri);
        if (item === undefined || target === null) {
          throw new Error('Original entry no longer exists');
        }
        const others: LocalMediaAsset[] = items.filter((entry: LocalMediaAsset): boolean => entry.uri !== uri);
        if (LocalMediaCatalog.newManualSources([source], others, item.parentUri).length === 0) {
          throw new Error('Replacement already exists in this folder');
        }
        await this.upsertRealItem(store, source, snapshot);
        await store.execute(
          `UPDATE media_locator SET media_id =
             (SELECT media_id FROM media_locator WHERE source_kind = ? AND locator = ?)
           WHERE source_kind = ? AND id = ?`,
          [DOCUMENT_SOURCE_KIND, source.locator, ENTRY_SOURCE_KIND, target.aliasId]);
        await store.execute(
          `UPDATE collection_membership SET media_id =
             (SELECT media_id FROM media_locator WHERE id = ?)
           WHERE locator_id = ?`, [target.aliasId, target.aliasId]);
        if (target.sourceUri !== source.locator && await this.cleanupOrphan(store, target.mediaId)) {
          revokedUri = target.sourceUri;
        }
        await this.updateCollectionCounts(store, Date.now());
        store.commit();
      } catch (_error) {
        this.rollback(store);
        throw new Error('Unable to restore manually selected media');
      }
    });
    await this.revokeReadAccess(revokedUri.length > 0 ? [revokedUri] : []);
    return this.load();
  }

  async createFolder(parentUri: string, name: string): Promise<LocalMediaFolder[]> {
    const safeName: string = this.safeFolderName(name);
    const folderUri: string = `${FOLDER_URI_PREFIX}${util.generateRandomUUID(true)}`;
    await this.enqueue(async (): Promise<void> => {
      const store: relationalStore.RdbStore = await this.database.store();
      store.beginTransaction();
      try {
        const now: number = Date.now();
        await this.ensureRoot(store, now);
        await this.assertFolderTarget(store, parentUri);
        await this.assertNameAvailable(store, parentUri, safeName, '');
        await store.execute(
          `INSERT INTO media_collection
            (source_kind, source_key, parent_key, display_name, locator, is_virtual,
             total_count, video_count, image_count, subtitle_count, cover_locator,
             scan_generation, updated_at, total_size_bytes)
           VALUES (?, ?, ?, ?, ?, 1, 0, 0, 0, 0, '', 0, ?, 0)`,
          [FOLDER_SOURCE_KIND, folderUri, this.collectionKey(parentUri), safeName, folderUri, now]);
        store.commit();
      } catch (_error) {
        this.rollback(store);
        throw new Error('Unable to create virtual folder');
      }
    });
    return this.loadFolders();
  }

  async renameFolder(uri: string, name: string): Promise<LocalMediaFolder[]> {
    const safeName: string = this.safeFolderName(name);
    await this.enqueue(async (): Promise<void> => {
      const store: relationalStore.RdbStore = await this.database.store();
      store.beginTransaction();
      try {
        const folder: VirtualFolderRecord | null = await this.findFolder(store, uri);
        if (folder === null) {
          throw new Error('Virtual folder not found');
        }
        await this.assertNameAvailable(store, folder.parentUri, safeName, uri);
        await store.execute(
          `UPDATE media_collection SET display_name = ?, updated_at = ?
           WHERE source_kind = ? AND source_key = ? AND source_key <> ?`,
          [safeName, Date.now(), FOLDER_SOURCE_KIND, uri, ROOT_COLLECTION_KEY]);
        store.commit();
      } catch (_error) {
        this.rollback(store);
        throw new Error('Unable to rename virtual folder');
      }
    });
    return this.loadFolders();
  }

  async removeFolder(uri: string): Promise<void> {
    if (!uri.startsWith(FOLDER_URI_PREFIX)) {
      return;
    }
    const revokedUris: string[] = [];
    await this.enqueue(async (): Promise<void> => {
      const store: relationalStore.RdbStore = await this.database.store();
      store.beginTransaction();
      try {
        const folders: VirtualFolderRecord[] = await this.loadFolderRecords(store);
        const removed: string[] = this.descendantUris(folders, uri);
        const targets: AliasTarget[] = [];
        for (const folderUri of removed) {
          targets.push(...await this.loadCollectionTargets(store, folderUri));
        }
        for (const target of targets) {
          await store.execute('DELETE FROM media_locator WHERE source_kind = ? AND id = ?',
            [ENTRY_SOURCE_KIND, target.aliasId]);
        }
        for (const folderUri of removed) {
          await store.execute(
            `DELETE FROM media_collection WHERE source_kind = ? AND source_key = ?
             AND source_key <> ?`, [FOLDER_SOURCE_KIND, folderUri, ROOT_COLLECTION_KEY]);
        }
        for (const target of this.uniqueTargets(targets)) {
          if (await this.cleanupOrphan(store, target.mediaId)) {
            revokedUris.push(target.sourceUri);
          }
        }
        await this.updateCollectionCounts(store, Date.now());
        store.commit();
      } catch (_error) {
        this.rollback(store);
        throw new Error('Unable to remove virtual folder');
      }
    });
    await this.revokeReadAccess(this.uniqueStrings(revokedUris));
  }

  async verify(): Promise<LocalMediaAsset[]> {
    const candidates: LocalMediaAsset[] = await this.loadVerificationCandidates(
      Date.now() - VERIFICATION_TTL_MS);
    if (candidates.length === 0) {
      return this.load();
    }
    const verifications: ManualVerification[] = await this.readVerificationMetadata(candidates);
    await this.enqueue(async (): Promise<void> => {
      const store: relationalStore.RdbStore = await this.database.store();
      store.beginTransaction();
      try {
        const now: number = Date.now();
        for (const verification of verifications) {
          const item: LocalMediaAsset = verification.item;
          const snapshot: LocalMediaMetadata = verification.snapshot;
          await store.execute(
            `UPDATE media_locator SET permission_state = ?, last_verified_at = ?
             WHERE source_kind = ? AND locator = ?`,
            [snapshot.available ? 'available' : 'unavailable', now,
              DOCUMENT_SOURCE_KIND, item.sourceUri]);
          if (snapshot.available && snapshot.metadataComplete) {
            await store.execute(
              `UPDATE media_entity SET size_bytes = ?, duration_ms = ?, width = ?, height = ?,
               modified_at = ?, updated_at = ? WHERE identity_key = ?`,
              [snapshot.sizeBytes, snapshot.durationMs, snapshot.width, snapshot.height,
                snapshot.modifiedAt, now, this.identityKey(item.sourceUri)]);
          } else if (snapshot.available) {
            await store.execute(
              `UPDATE media_entity SET size_bytes = ?, modified_at = ?, updated_at = ?
               WHERE identity_key = ?`,
              [snapshot.sizeBytes, snapshot.modifiedAt, now, this.identityKey(item.sourceUri)]);
          }
        }
        await this.updateCollectionCounts(store, now);
        store.commit();
      } catch (_error) {
        this.rollback(store);
        throw new Error('Unable to verify manually selected media');
      }
    });
    return this.load();
  }

  async remove(uri: string): Promise<LocalMediaAsset[]> {
    if (uri.length === 0) {
      return this.load();
    }
    let revokedUri: string = '';
    await this.enqueue(async (): Promise<void> => {
      const store: relationalStore.RdbStore = await this.database.store();
      store.beginTransaction();
      try {
        const target: AliasTarget | null = await this.findAliasTarget(store, uri);
        if (target !== null) {
          await store.execute('DELETE FROM media_locator WHERE source_kind = ? AND id = ?',
            [ENTRY_SOURCE_KIND, target.aliasId]);
          if (await this.cleanupOrphan(store, target.mediaId)) {
            revokedUri = target.sourceUri;
          }
          await this.updateCollectionCounts(store, Date.now());
        }
        store.commit();
      } catch (_error) {
        this.rollback(store);
        throw new Error('Unable to remove manually selected media');
      }
    });
    await this.revokeReadAccess(revokedUri.length > 0 ? [revokedUri] : []);
    return this.load();
  }

  async removeUnavailable(): Promise<LocalMediaAsset[]> {
    const revokedUris: string[] = [];
    await this.enqueue(async (): Promise<void> => {
      const store: relationalStore.RdbStore = await this.database.store();
      store.beginTransaction();
      try {
        const targets: AliasTarget[] = await this.loadUnavailableTargets(store);
        for (const target of this.uniqueTargets(targets)) {
          await store.execute('DELETE FROM media_locator WHERE source_kind = ? AND media_id = ?',
            [ENTRY_SOURCE_KIND, target.mediaId]);
          await store.execute('DELETE FROM media_locator WHERE source_kind = ? AND media_id = ?',
            [DOCUMENT_SOURCE_KIND, target.mediaId]);
          await store.execute(
            `DELETE FROM media_entity WHERE id = ? AND NOT EXISTS
             (SELECT 1 FROM media_locator WHERE media_locator.media_id = media_entity.id)`,
            [target.mediaId]);
          revokedUris.push(target.sourceUri);
        }
        await this.updateCollectionCounts(store, Date.now());
        store.commit();
      } catch (_error) {
        this.rollback(store);
        throw new Error('Unable to remove unavailable manually selected media');
      }
    });
    await this.revokeReadAccess(this.uniqueStrings(revokedUris));
    return this.load();
  }

  private async ensureRoot(store: relationalStore.RdbStore, now: number): Promise<void> {
    await store.execute(
      `INSERT INTO media_collection
        (source_kind, source_key, parent_key, display_name, locator, is_virtual,
         total_count, video_count, image_count, subtitle_count, cover_locator,
         scan_generation, updated_at, total_size_bytes)
       VALUES (?, ?, NULL, '本地', '', 1, 0, 0, 0, 0, '', 0, ?, 0)
       ON CONFLICT(source_kind, source_key) DO UPDATE SET updated_at = excluded.updated_at`,
      [FOLDER_SOURCE_KIND, ROOT_COLLECTION_KEY, now]);
  }

  private async upsertRealItem(store: relationalStore.RdbStore, source: MediaSource,
    snapshot: LocalMediaMetadata): Promise<void> {
    const now: number = Date.now();
    const identityKey: string = this.identityKey(source.locator);
    const category: LocalFileCategory = source.localCategory === LocalFileCategory.UNSUPPORTED ?
      this.fileFilter.categoryOf(source.displayName) : source.localCategory;
    if (snapshot.metadataComplete) {
      await store.execute(
        `INSERT INTO media_entity
         (identity_key, display_name, size_bytes, media_type, duration_ms, width, height,
           modified_at, created_at, updated_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
         ON CONFLICT(identity_key) DO UPDATE SET
          display_name = excluded.display_name, size_bytes = excluded.size_bytes,
          media_type = excluded.media_type, duration_ms = excluded.duration_ms,
          width = excluded.width, height = excluded.height,
          modified_at = excluded.modified_at, updated_at = excluded.updated_at`,
        [identityKey, source.displayName, snapshot.sizeBytes, category, snapshot.durationMs,
          snapshot.width, snapshot.height, snapshot.modifiedAt, now, now]);
    } else if (snapshot.available) {
      await store.execute(
        `INSERT INTO media_entity
         (identity_key, display_name, size_bytes, media_type, duration_ms, width, height,
           modified_at, created_at, updated_at)
         VALUES (?, ?, ?, ?, 0, 0, 0, ?, ?, ?)
         ON CONFLICT(identity_key) DO UPDATE SET
          display_name = excluded.display_name, size_bytes = excluded.size_bytes,
          media_type = excluded.media_type, modified_at = excluded.modified_at,
          updated_at = excluded.updated_at`,
        [identityKey, source.displayName, snapshot.sizeBytes, category,
          snapshot.modifiedAt, now, now]);
    } else {
      await store.execute(
        `INSERT INTO media_entity
         (identity_key, display_name, size_bytes, media_type, duration_ms, width, height,
           modified_at, created_at, updated_at)
         VALUES (?, ?, 0, ?, 0, 0, 0, 0, ?, ?)
         ON CONFLICT(identity_key) DO UPDATE SET
          display_name = excluded.display_name, media_type = excluded.media_type,
          updated_at = excluded.updated_at`,
        [identityKey, source.displayName, category, now, now]);
    }
    await store.execute(
      `INSERT INTO media_locator
        (media_id, source_kind, locator, permission_state, added_at,
         last_verified_at, scan_generation)
       SELECT id, ?, ?, ?, ?, ?, 0 FROM media_entity WHERE identity_key = ?
       ON CONFLICT(source_kind, locator) DO UPDATE SET
        media_id = excluded.media_id, permission_state = excluded.permission_state,
        last_verified_at = excluded.last_verified_at`,
      [DOCUMENT_SOURCE_KIND, source.locator, snapshot.available ? 'available' : 'unavailable',
        now, now, identityKey]);
  }

  private async insertAlias(store: relationalStore.RdbStore, sourceUri: string,
    aliasUri: string, parentUri: string, order: number): Promise<void> {
    const now: number = Date.now();
    await store.execute(
      `INSERT INTO media_locator
        (media_id, source_kind, locator, permission_state, added_at,
         last_verified_at, scan_generation)
       SELECT media_id, ?, ?, 'available', ?, 0, 0
       FROM media_locator WHERE source_kind = ? AND locator = ?`,
      [ENTRY_SOURCE_KIND, aliasUri, now, DOCUMENT_SOURCE_KIND, sourceUri]);
    await store.execute(
      `INSERT INTO collection_membership
        (collection_id, media_id, locator_id, display_order, added_at)
       SELECT collection.id, alias.media_id, alias.id, ?, ?
       FROM media_collection collection, media_locator alias
       WHERE collection.source_kind = ? AND collection.source_key = ?
         AND alias.source_kind = ? AND alias.locator = ?`,
      [order, now, FOLDER_SOURCE_KIND, this.collectionKey(parentUri),
        ENTRY_SOURCE_KIND, aliasUri]);
  }

  private async updateCollectionCounts(store: relationalStore.RdbStore, now: number): Promise<void> {
    await store.execute(
      `UPDATE media_collection SET
        total_count = (SELECT COUNT(*) FROM collection_membership
          WHERE collection_id = media_collection.id),
        video_count = (SELECT COUNT(*) FROM collection_membership membership
          JOIN media_entity entity ON entity.id = membership.media_id
          WHERE membership.collection_id = media_collection.id AND entity.media_type = 'video'),
        image_count = (SELECT COUNT(*) FROM collection_membership membership
          JOIN media_entity entity ON entity.id = membership.media_id
          WHERE membership.collection_id = media_collection.id AND entity.media_type = 'image'),
        subtitle_count = (SELECT COUNT(*) FROM collection_membership membership
          JOIN media_entity entity ON entity.id = membership.media_id
          WHERE membership.collection_id = media_collection.id AND entity.media_type = 'subtitle'),
        total_size_bytes = (SELECT COALESCE(SUM(entity.size_bytes), 0)
          FROM collection_membership membership
          JOIN media_entity entity ON entity.id = membership.media_id
          WHERE membership.collection_id = media_collection.id),
        updated_at = ?
       WHERE source_kind = ?`,
      [now, FOLDER_SOURCE_KIND]);
  }

  private async loadItems(store: relationalStore.RdbStore): Promise<LocalMediaAsset[]> {
    let result: relationalStore.ResultSet | null = null;
    const items: LocalMediaAsset[] = [];
    try {
      result = await store.querySql(
        `SELECT entity.display_name, entity.size_bytes, entity.duration_ms,
          entity.width, entity.height, entity.modified_at, entity.media_type,
          alias.locator AS alias_locator, real.locator AS real_locator,
          real.permission_state, collection.source_key AS collection_key
         FROM media_locator alias
         JOIN media_entity entity ON entity.id = alias.media_id
         JOIN media_locator real ON real.media_id = alias.media_id AND real.source_kind = ?
         JOIN collection_membership membership ON membership.locator_id = alias.id
         JOIN media_collection collection ON collection.id = membership.collection_id
         WHERE alias.source_kind = ? AND collection.source_kind = ?
         ORDER BY membership.display_order DESC, alias.id DESC`,
        [DOCUMENT_SOURCE_KIND, ENTRY_SOURCE_KIND, FOLDER_SOURCE_KIND]);
      while (result.goToNextRow()) {
        const collectionKey: string = result.getString(result.getColumnIndex('collection_key'));
        items.push(new LocalMediaAsset(
          result.getString(result.getColumnIndex('alias_locator')),
          result.getString(result.getColumnIndex('display_name')),
          result.getLong(result.getColumnIndex('duration_ms')),
          result.getLong(result.getColumnIndex('width')),
          result.getLong(result.getColumnIndex('height')),
          result.getLong(result.getColumnIndex('size_bytes')),
          result.getLong(result.getColumnIndex('modified_at')),
          this.categoryOf(result.getString(result.getColumnIndex('media_type'))),
          collectionKey === ROOT_COLLECTION_KEY ? '' : collectionKey,
          LocalMediaOrigin.DOCUMENT_PICKER,
          result.getString(result.getColumnIndex('permission_state')) === 'available' ?
            LocalMediaAvailability.AVAILABLE : LocalMediaAvailability.UNAVAILABLE,
          result.getString(result.getColumnIndex('real_locator'))));
      }
    } finally {
      this.close(result);
    }
    return items;
  }

  private async loadFolderRecords(store: relationalStore.RdbStore): Promise<VirtualFolderRecord[]> {
    let result: relationalStore.ResultSet | null = null;
    const folders: VirtualFolderRecord[] = [];
    try {
      result = await store.querySql(
        `SELECT collection.source_key, collection.parent_key, collection.display_name,
          collection.total_count, collection.video_count, collection.image_count,
          collection.subtitle_count, collection.total_size_bytes,
          (SELECT COUNT(*) FROM media_collection child
           WHERE child.source_kind = ? AND child.parent_key = collection.source_key) AS folder_count
         FROM media_collection collection
         WHERE collection.source_kind = ? AND collection.source_key <> ?
         ORDER BY collection.updated_at, collection.id`,
        [FOLDER_SOURCE_KIND, FOLDER_SOURCE_KIND, ROOT_COLLECTION_KEY]);
      while (result.goToNextRow()) {
        const parentKey: string = result.getString(result.getColumnIndex('parent_key'));
        folders.push(new VirtualFolderRecord(
          result.getString(result.getColumnIndex('source_key')),
          parentKey === ROOT_COLLECTION_KEY ? '' : parentKey,
          result.getString(result.getColumnIndex('display_name')),
          result.getLong(result.getColumnIndex('total_count')),
          result.getLong(result.getColumnIndex('video_count')),
          result.getLong(result.getColumnIndex('image_count')),
          result.getLong(result.getColumnIndex('subtitle_count')),
          result.getLong(result.getColumnIndex('total_size_bytes')),
          result.getLong(result.getColumnIndex('folder_count'))));
      }
    } finally {
      this.close(result);
    }
    return folders;
  }

  private async loadVerificationCandidates(cutoff: number): Promise<LocalMediaAsset[]> {
    await this.database.waitForWrites();
    const store: relationalStore.RdbStore = await this.database.store();
    let result: relationalStore.ResultSet | null = null;
    const items: LocalMediaAsset[] = [];
    try {
      result = await store.querySql(
        `SELECT entity.display_name, entity.size_bytes, entity.duration_ms,
          entity.width, entity.height, entity.modified_at, entity.media_type,
          locator.locator, locator.permission_state
         FROM media_locator locator
         JOIN media_entity entity ON entity.id = locator.media_id
         WHERE locator.source_kind = ? AND locator.last_verified_at <= ?
         ORDER BY locator.last_verified_at, locator.id`, [DOCUMENT_SOURCE_KIND, cutoff]);
      while (result.goToNextRow()) {
        const sourceUri: string = result.getString(result.getColumnIndex('locator'));
        items.push(new LocalMediaAsset(sourceUri,
          result.getString(result.getColumnIndex('display_name')),
          result.getLong(result.getColumnIndex('duration_ms')),
          result.getLong(result.getColumnIndex('width')),
          result.getLong(result.getColumnIndex('height')),
          result.getLong(result.getColumnIndex('size_bytes')),
          result.getLong(result.getColumnIndex('modified_at')),
          this.categoryOf(result.getString(result.getColumnIndex('media_type'))),
          '', LocalMediaOrigin.DOCUMENT_PICKER,
          result.getString(result.getColumnIndex('permission_state')) === 'available' ?
            LocalMediaAvailability.AVAILABLE : LocalMediaAvailability.UNAVAILABLE, sourceUri));
      }
    } finally {
      this.close(result);
    }
    return items;
  }

  private async findFolder(store: relationalStore.RdbStore,
    uri: string): Promise<VirtualFolderRecord | null> {
    const folders: VirtualFolderRecord[] = await this.loadFolderRecords(store);
    for (const folder of folders) {
      if (folder.uri === uri) {
        return folder;
      }
    }
    return null;
  }

  private async assertFolderTarget(store: relationalStore.RdbStore, uri: string): Promise<void> {
    if (uri.length === 0) {
      return;
    }
    if (!uri.startsWith(FOLDER_URI_PREFIX) || await this.findFolder(store, uri) === null) {
      throw new Error('Invalid virtual folder');
    }
  }

  private async assertNameAvailable(store: relationalStore.RdbStore, parentUri: string,
    name: string, excludedUri: string): Promise<void> {
    let result: relationalStore.ResultSet | null = null;
    try {
      result = await store.querySql(
        `SELECT COUNT(*) AS item_count FROM media_collection
         WHERE source_kind = ? AND parent_key = ? AND display_name = ? COLLATE NOCASE
           AND source_key <> ?`,
        [FOLDER_SOURCE_KIND, this.collectionKey(parentUri), name, excludedUri]);
      if (result.goToNextRow() && result.getLong(result.getColumnIndex('item_count')) > 0) {
        throw new Error('Duplicate virtual folder');
      }
    } finally {
      this.close(result);
    }
  }

  private async findAliasTarget(store: relationalStore.RdbStore,
    aliasUri: string): Promise<AliasTarget | null> {
    let result: relationalStore.ResultSet | null = null;
    try {
      result = await store.querySql(
        `SELECT alias.id AS alias_id, alias.media_id, real.locator AS real_locator
         FROM media_locator alias
         JOIN media_locator real ON real.media_id = alias.media_id AND real.source_kind = ?
         WHERE alias.source_kind = ? AND alias.locator = ?`,
        [DOCUMENT_SOURCE_KIND, ENTRY_SOURCE_KIND, aliasUri]);
      if (result.goToNextRow()) {
        return new AliasTarget(result.getLong(result.getColumnIndex('alias_id')),
          result.getLong(result.getColumnIndex('media_id')),
          result.getString(result.getColumnIndex('real_locator')));
      }
    } finally {
      this.close(result);
    }
    return null;
  }

  private async loadCollectionTargets(store: relationalStore.RdbStore,
    folderUri: string): Promise<AliasTarget[]> {
    let result: relationalStore.ResultSet | null = null;
    const targets: AliasTarget[] = [];
    try {
      result = await store.querySql(
        `SELECT alias.id AS alias_id, alias.media_id, real.locator AS real_locator
         FROM media_collection collection
         JOIN collection_membership membership ON membership.collection_id = collection.id
         JOIN media_locator alias ON alias.id = membership.locator_id AND alias.source_kind = ?
         JOIN media_locator real ON real.media_id = alias.media_id AND real.source_kind = ?
         WHERE collection.source_kind = ? AND collection.source_key = ?`,
        [ENTRY_SOURCE_KIND, DOCUMENT_SOURCE_KIND, FOLDER_SOURCE_KIND, folderUri]);
      while (result.goToNextRow()) {
        targets.push(new AliasTarget(result.getLong(result.getColumnIndex('alias_id')),
          result.getLong(result.getColumnIndex('media_id')),
          result.getString(result.getColumnIndex('real_locator'))));
      }
    } finally {
      this.close(result);
    }
    return targets;
  }

  private async loadUnavailableTargets(store: relationalStore.RdbStore): Promise<AliasTarget[]> {
    let result: relationalStore.ResultSet | null = null;
    const targets: AliasTarget[] = [];
    try {
      result = await store.querySql(
        `SELECT 0 AS alias_id, media_id, locator AS real_locator
         FROM media_locator WHERE source_kind = ? AND permission_state = 'unavailable'`,
        [DOCUMENT_SOURCE_KIND]);
      while (result.goToNextRow()) {
        targets.push(new AliasTarget(0, result.getLong(result.getColumnIndex('media_id')),
          result.getString(result.getColumnIndex('real_locator'))));
      }
    } finally {
      this.close(result);
    }
    return targets;
  }

  private async cleanupOrphan(store: relationalStore.RdbStore, mediaId: number): Promise<boolean> {
    let result: relationalStore.ResultSet | null = null;
    try {
      result = await store.querySql(
        `SELECT COUNT(*) AS alias_count FROM media_locator
         WHERE source_kind = ? AND media_id = ?`, [ENTRY_SOURCE_KIND, mediaId]);
      if (result.goToNextRow() && result.getLong(result.getColumnIndex('alias_count')) > 0) {
        return false;
      }
    } finally {
      this.close(result);
    }
    await store.execute('DELETE FROM media_locator WHERE source_kind = ? AND media_id = ?',
      [DOCUMENT_SOURCE_KIND, mediaId]);
    await store.execute(
      `DELETE FROM media_entity WHERE id = ? AND NOT EXISTS
       (SELECT 1 FROM media_locator WHERE media_locator.media_id = media_entity.id)`, [mediaId]);
    return true;
  }

  private descendantUris(folders: VirtualFolderRecord[], rootUri: string): string[] {
    const removed: string[] = [];
    if (!folders.some((folder: VirtualFolderRecord): boolean => folder.uri === rootUri)) {
      return removed;
    }
    removed.push(rootUri);
    let changed: boolean = true;
    while (changed) {
      changed = false;
      for (const folder of folders) {
        if (removed.includes(folder.parentUri) && !removed.includes(folder.uri)) {
          removed.push(folder.uri);
          changed = true;
        }
      }
    }
    return removed;
  }

  private uniqueTargets(targets: AliasTarget[]): AliasTarget[] {
    const result: AliasTarget[] = [];
    const mediaIds: number[] = [];
    for (const target of targets) {
      if (!mediaIds.includes(target.mediaId)) {
        mediaIds.push(target.mediaId);
        result.push(target);
      }
    }
    return result;
  }

  private uniqueStrings(values: string[]): string[] {
    const result: string[] = [];
    for (const value of values) {
      if (!result.includes(value)) {
        result.push(value);
      }
    }
    return result;
  }

  private async readSourceMetadata(sources: MediaSource[]): Promise<ManualMediaCandidate[]> {
    const result: ManualMediaCandidate[] = [];
    for (let offset: number = 0; offset < sources.length; offset += METADATA_CONCURRENCY) {
      const chunk: MediaSource[] = sources.slice(offset, offset + METADATA_CONCURRENCY);
      const snapshots: LocalMediaMetadata[] = await Promise.all(chunk.map(
        (source: MediaSource): Promise<LocalMediaMetadata> =>
          LocalMediaMetadataReader.read(source.locator)));
      for (let index: number = 0; index < chunk.length; index++) {
        result.push(new ManualMediaCandidate(chunk[index], snapshots[index]));
      }
    }
    return result;
  }

  private async readVerificationMetadata(items: LocalMediaAsset[]): Promise<ManualVerification[]> {
    const result: ManualVerification[] = [];
    for (let offset: number = 0; offset < items.length; offset += METADATA_CONCURRENCY) {
      const chunk: LocalMediaAsset[] = items.slice(offset, offset + METADATA_CONCURRENCY);
      const snapshots: LocalMediaMetadata[] = await Promise.all(chunk.map(
        (item: LocalMediaAsset): Promise<LocalMediaMetadata> =>
          LocalMediaMetadataReader.read(item.contentUri())));
      for (let index: number = 0; index < chunk.length; index++) {
        result.push(new ManualVerification(chunk[index], snapshots[index]));
      }
    }
    return result;
  }

  private sourcesWithLocator(sources: MediaSource[]): MediaSource[] {
    const result: MediaSource[] = [];
    for (const source of sources) {
      if (source.locator.length > 0) {
        result.push(source);
      }
    }
    return result;
  }

  private safeFolderName(name: string): string {
    const safeName: string = name.trim();
    if (safeName.length === 0 || safeName.length > 120) {
      throw new Error('Invalid virtual folder name');
    }
    return safeName;
  }

  private collectionKey(parentUri: string): string {
    return parentUri.length > 0 ? parentUri : ROOT_COLLECTION_KEY;
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

  private async revokeReadAccess(uris: string[]): Promise<void> {
    if (uris.length === 0) {
      return;
    }
    const policies: fileShare.PolicyInfo[] = uris.map((uri: string): fileShare.PolicyInfo => ({
      uri: uri,
      operationMode: fileShare.OperationMode.READ_MODE
    }));
    try {
      await fileShare.revokePermission(policies);
    } catch (_batchError) {
      for (let index: number = 0; index < policies.length; index++) {
        try {
          await fileShare.revokePermission([policies[index]]);
        } catch (_itemError) {
          console.warn(`Document permission revoke failed. item=${index}`);
        }
      }
    }
  }

  private identityKey(uri: string): string {
    return `${DOCUMENT_SOURCE_KIND}:${uri}`;
  }

  private async enqueue(operation: () => Promise<void>): Promise<void> {
    await this.database.enqueueWrite(operation);
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
}
