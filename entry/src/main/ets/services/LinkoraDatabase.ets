import { common } from '@kit.AbilityKit';
import { relationalStore } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';

const DATABASE_NAME: string = 'linkora_local.db';
const SCHEMA_VERSION: number = 9;

const VERSION_ONE_STATEMENTS: string[] = [
  `CREATE TABLE IF NOT EXISTS media_entity (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    identity_key TEXT NOT NULL UNIQUE,
    display_name TEXT NOT NULL,
    size_bytes INTEGER NOT NULL DEFAULT 0,
    duration_ms INTEGER NOT NULL DEFAULT 0,
    width INTEGER NOT NULL DEFAULT 0,
    height INTEGER NOT NULL DEFAULT 0,
    modified_at INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )`,
  `CREATE TABLE IF NOT EXISTS media_locator (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    media_id INTEGER NOT NULL,
    source_kind TEXT NOT NULL,
    locator TEXT NOT NULL,
    permission_state TEXT NOT NULL DEFAULT 'available',
    added_at INTEGER NOT NULL,
    last_verified_at INTEGER NOT NULL DEFAULT 0,
    scan_generation INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY(media_id) REFERENCES media_entity(id) ON DELETE CASCADE,
    UNIQUE(source_kind, locator)
  )`,
  'CREATE INDEX IF NOT EXISTS idx_media_locator_media ON media_locator(media_id)',
  `CREATE TABLE IF NOT EXISTS media_collection (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    source_kind TEXT NOT NULL,
    source_key TEXT NOT NULL,
    parent_key TEXT,
    display_name TEXT NOT NULL,
    locator TEXT,
    is_virtual INTEGER NOT NULL DEFAULT 0,
    total_count INTEGER NOT NULL DEFAULT 0,
    video_count INTEGER NOT NULL DEFAULT 0,
    image_count INTEGER NOT NULL DEFAULT 0,
    subtitle_count INTEGER NOT NULL DEFAULT 0,
    cover_locator TEXT NOT NULL DEFAULT '',
    scan_generation INTEGER NOT NULL DEFAULT 0,
    updated_at INTEGER NOT NULL,
    UNIQUE(source_kind, source_key)
  )`,
  'CREATE INDEX IF NOT EXISTS idx_media_collection_parent ' +
    'ON media_collection(source_kind, parent_key)',
  `CREATE TABLE IF NOT EXISTS collection_membership (
    collection_id INTEGER NOT NULL,
    media_id INTEGER NOT NULL,
    locator_id INTEGER NOT NULL,
    display_order INTEGER NOT NULL DEFAULT 0,
    added_at INTEGER NOT NULL,
    PRIMARY KEY(collection_id, locator_id),
    FOREIGN KEY(collection_id) REFERENCES media_collection(id) ON DELETE CASCADE,
    FOREIGN KEY(media_id) REFERENCES media_entity(id) ON DELETE CASCADE,
    FOREIGN KEY(locator_id) REFERENCES media_locator(id) ON DELETE CASCADE
  )`,
  'CREATE INDEX IF NOT EXISTS idx_collection_membership_media ' +
    'ON collection_membership(media_id)',
  `CREATE TABLE IF NOT EXISTS playback_state (
    source_key TEXT PRIMARY KEY,
    position_ms INTEGER NOT NULL DEFAULT 0,
    duration_ms INTEGER NOT NULL DEFAULT 0,
    completed INTEGER NOT NULL DEFAULT 0,
    play_count INTEGER NOT NULL DEFAULT 0,
    last_played_at INTEGER NOT NULL DEFAULT 0,
    updated_at INTEGER NOT NULL
  )`,
  'CREATE INDEX IF NOT EXISTS idx_playback_state_recent ' +
    'ON playback_state(last_played_at DESC)',
  `CREATE TABLE IF NOT EXISTS recent_entry (
    source_key TEXT PRIMARY KEY,
    source_kind TEXT NOT NULL,
    locator_ref TEXT NOT NULL,
    display_name TEXT NOT NULL,
    origin_label TEXT NOT NULL,
    format TEXT NOT NULL,
    opened_at INTEGER NOT NULL
  )`,
  'CREATE INDEX IF NOT EXISTS idx_recent_entry_opened ON recent_entry(opened_at DESC)',
  `CREATE TABLE IF NOT EXISTS scan_checkpoint (
    source_key TEXT PRIMARY KEY,
    cursor TEXT NOT NULL DEFAULT '',
    generation INTEGER NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'idle',
    started_at INTEGER NOT NULL DEFAULT 0,
    completed_at INTEGER NOT NULL DEFAULT 0
  )`
];

const VERSION_TWO_STATEMENTS: string[] = [
  `CREATE TABLE IF NOT EXISTS network_server (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    display_name TEXT NOT NULL,
    protocol TEXT NOT NULL,
    host TEXT NOT NULL,
    port INTEGER NOT NULL,
    root_path TEXT NOT NULL DEFAULT '/',
    username TEXT NOT NULL DEFAULT '',
    password_value TEXT NOT NULL DEFAULT '',
    secure_transport INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )`,
  'CREATE INDEX IF NOT EXISTS idx_network_server_updated ON network_server(updated_at DESC)'
];

const VERSION_THREE_STATEMENTS: string[] = [
  `ALTER TABLE network_server ADD COLUMN advanced_options TEXT NOT NULL DEFAULT ''`
];

const VERSION_FOUR_STATEMENTS: string[] = [
  `CREATE TABLE IF NOT EXISTS hidden_local_item (
    item_type TEXT NOT NULL,
    locator TEXT NOT NULL,
    display_name TEXT NOT NULL,
    parent_locator TEXT NOT NULL DEFAULT '',
    hidden_at INTEGER NOT NULL,
    PRIMARY KEY(item_type, locator)
  )`,
  'CREATE INDEX IF NOT EXISTS idx_hidden_local_item_time ON hidden_local_item(hidden_at DESC)'
];

const VERSION_FIVE_STATEMENTS: string[] = [
  `ALTER TABLE media_collection ADD COLUMN total_size_bytes INTEGER NOT NULL DEFAULT 0`
];

const VERSION_SIX_STATEMENTS: string[] = [
  `ALTER TABLE media_entity ADD COLUMN media_type TEXT NOT NULL DEFAULT 'video'`
];

const VERSION_SEVEN_STATEMENTS: string[] = [
  `ALTER TABLE network_server ADD COLUMN credential_alias TEXT NOT NULL DEFAULT ''`
];

const VERSION_EIGHT_STATEMENTS: string[] = [
  `INSERT OR IGNORE INTO media_collection
    (source_kind, source_key, parent_key, display_name, locator, is_virtual,
     total_count, video_count, image_count, subtitle_count, cover_locator,
     scan_generation, updated_at, total_size_bytes)
   VALUES ('virtual_folder', '@virtual-root', NULL, '本地', '', 1,
     0, 0, 0, 0, '', 0, 0, 0)`,
  `INSERT OR IGNORE INTO media_locator
    (media_id, source_kind, locator, permission_state, added_at,
     last_verified_at, scan_generation)
   SELECT real.media_id, 'virtual_entry', 'linkora://item/migrated-' || real.id,
     real.permission_state, real.added_at, real.last_verified_at, 0
   FROM media_locator real
   JOIN collection_membership old_membership ON old_membership.locator_id = real.id
   JOIN media_collection old_collection ON old_collection.id = old_membership.collection_id
   WHERE real.source_kind = 'document_picker'
     AND old_collection.source_kind = 'document_picker'
     AND old_collection.source_key = '@manual'`,
  `INSERT OR IGNORE INTO collection_membership
    (collection_id, media_id, locator_id, display_order, added_at)
   SELECT root.id, alias.media_id, alias.id,
     old_membership.display_order, old_membership.added_at
   FROM media_locator real
   JOIN collection_membership old_membership ON old_membership.locator_id = real.id
   JOIN media_collection old_collection ON old_collection.id = old_membership.collection_id
   JOIN media_locator alias
     ON alias.source_kind = 'virtual_entry'
    AND alias.locator = 'linkora://item/migrated-' || real.id
   JOIN media_collection root
     ON root.source_kind = 'virtual_folder' AND root.source_key = '@virtual-root'
   WHERE real.source_kind = 'document_picker'
     AND old_collection.source_kind = 'document_picker'
     AND old_collection.source_key = '@manual'`,
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
      WHERE membership.collection_id = media_collection.id AND entity.media_type = 'subtitle')
   WHERE source_kind = 'virtual_folder' AND source_key = '@virtual-root'`,
  `DELETE FROM media_collection
   WHERE source_kind = 'document_picker' AND source_key = '@manual'`
];

const VERSION_NINE_STATEMENTS: string[] = [
  `CREATE TABLE IF NOT EXISTS network_media_metadata (
    cache_key TEXT PRIMARY KEY,
    server_id INTEGER NOT NULL,
    duration_ms INTEGER NOT NULL DEFAULT 0,
    width INTEGER NOT NULL DEFAULT 0,
    height INTEGER NOT NULL DEFAULT 0,
    updated_at INTEGER NOT NULL,
    FOREIGN KEY(server_id) REFERENCES network_server(id) ON DELETE CASCADE
  )`,
  'CREATE INDEX IF NOT EXISTS idx_network_media_server ON network_media_metadata(server_id)'
];

export class LinkoraDatabase {
  private static instance: LinkoraDatabase | null = null;
  private static pendingWrite: Promise<void> = Promise.resolve();

  private context: common.UIAbilityContext;
  private activeStore: relationalStore.RdbStore | null = null;
  private opening: Promise<relationalStore.RdbStore> | null = null;

  private constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  static shared(context: common.UIAbilityContext): LinkoraDatabase {
    if (LinkoraDatabase.instance === null) {
      LinkoraDatabase.instance = new LinkoraDatabase(context);
    }
    return LinkoraDatabase.instance;
  }

  async initialize(): Promise<void> {
    await this.store();
  }

  async waitForWrites(): Promise<void> {
    await LinkoraDatabase.pendingWrite;
  }

  async enqueueWrite(operation: () => Promise<void>): Promise<void> {
    const next: Promise<void> = LinkoraDatabase.pendingWrite.then(operation);
    LinkoraDatabase.pendingWrite = next.catch(() => {});
    await next;
  }

  async store(): Promise<relationalStore.RdbStore> {
    if (this.activeStore !== null) {
      return this.activeStore;
    }
    if (this.opening === null) {
      this.opening = this.open();
    }
    try {
      this.activeStore = await this.opening;
      return this.activeStore;
    } finally {
      this.opening = null;
    }
  }

  private async open(): Promise<relationalStore.RdbStore> {
    try {
      console.info('Database initialization started.');
      const config: relationalStore.StoreConfig = {
        name: DATABASE_NAME,
        securityLevel: relationalStore.SecurityLevel.S2,
        encrypt: true
      };
      const store: relationalStore.RdbStore = await relationalStore.getRdbStore(this.context, config);
      console.info(`Database opened. schemaVersion=${store.version}`);
      await store.execute('PRAGMA foreign_keys = ON');
      console.info('Database foreign-key enforcement enabled.');
      await this.ensureSchema(store);
      console.info(`Database initialization completed. schemaVersion=${store.version}`);
      return store;
    } catch (error) {
      const failure: BusinessError = error as BusinessError;
      console.error(`Database open failed. code=${failure.code}, message=${failure.message}`);
      throw new Error('Unable to open the local database');
    }
  }

  private async ensureSchema(store: relationalStore.RdbStore): Promise<void> {
    if (store.version > SCHEMA_VERSION) {
      throw new Error(`Unsupported database schema version: ${store.version}`);
    }
    if (store.version < 1) {
      console.info('Database schema v1 creation started.');
      await this.applyStatements(store, VERSION_ONE_STATEMENTS, 1);
    }
    if (store.version < 2) {
      console.info('Database schema v2 creation started.');
      await this.applyStatements(store, VERSION_TWO_STATEMENTS, 2);
    }
    if (store.version < 3) {
      console.info('Database schema v3 migration started.');
      await this.applyStatements(store, VERSION_THREE_STATEMENTS, 3);
    }
    if (store.version < 4) {
      console.info('Database schema v4 migration started.');
      await this.applyStatements(store, VERSION_FOUR_STATEMENTS, 4);
    }
    if (store.version < 5) {
      console.info('Database schema v5 migration started.');
      await this.applyStatements(store, VERSION_FIVE_STATEMENTS, 5);
    }
    if (store.version < 6) {
      console.info('Database schema v6 migration started.');
      await this.applyStatements(store, VERSION_SIX_STATEMENTS, 6);
    }
    if (store.version < 7) {
      console.info('Database schema v7 migration started.');
      await this.applyStatements(store, VERSION_SEVEN_STATEMENTS, 7);
    }
    if (store.version < 8) {
      console.info('Database schema v8 migration started.');
      await this.applyStatements(store, VERSION_EIGHT_STATEMENTS, 8);
    }
    if (store.version < 9) {
      console.info('Database schema v9 migration started.');
      await this.applyStatements(store, VERSION_NINE_STATEMENTS, 9);
    }
  }

  private async applyStatements(store: relationalStore.RdbStore,
    statements: string[], version: number): Promise<void> {
    store.beginTransaction();
    try {
      for (const statement of statements) {
        // Older builds may have persisted an ADD COLUMN without its version marker.
        const addition: RegExpMatchArray | null = statement.match(/^ALTER TABLE (\w+) ADD COLUMN (\w+) /);
        if (addition !== null && await this.hasColumn(store, addition[1], addition[2])) {
          continue;
        }
        await store.execute(statement);
      }
      store.version = version;
      store.commit();
    } catch (error) {
      try {
        store.rollBack();
      } catch (_rollbackError) {
      }
      const failure: BusinessError = error as BusinessError;
      console.error(`Database schema v${version} migration failed. ` +
        `code=${failure.code}, message=${failure.message}`);
      throw new Error('Database schema statement failed');
    }
    console.info(`Database schema version advanced to ${version}.`);
  }

  private async hasColumn(store: relationalStore.RdbStore, table: string,
    column: string): Promise<boolean> {
    const result: relationalStore.ResultSet = await store.querySql(`PRAGMA table_info(${table})`);
    try {
      while (result.goToNextRow()) {
        if (result.getString(result.getColumnIndex('name')) === column) {
          return true;
        }
      }
      return false;
    } finally {
      result.close();
    }
  }
}
