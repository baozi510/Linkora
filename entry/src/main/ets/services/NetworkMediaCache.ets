import { common } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import { NetworkDirectoryEntry } from '../models/NetworkDirectoryState';
import { NetworkServerEntry } from './NetworkServerStore';
import { SourceIdentity } from './SourceIdentity';
import { LinkoraDatabase } from './LinkoraDatabase';
import { BusinessError } from '@kit.BasicServicesKit';

const MAX_IMAGE_BYTES: number = 256 * 1024;
export class CachedNetworkMedia {
  readonly durationMs: number;
  readonly width: number;
  readonly height: number;
  readonly imageData: ArrayBuffer | null;
  readonly savedAt: number;
  readonly imageFormat: string;
  constructor(durationMs: number, width: number, height: number, imageData: ArrayBuffer | null,
    savedAt: number = Date.now(), imageFormat: string = 'webp') {
    this.durationMs = durationMs; this.width = width; this.height = height;
    this.imageData = imageData; this.savedAt = savedAt; this.imageFormat = imageFormat;
  }
}
interface LegacyMediaRecord { durationMs: number; width: number; height: number; savedAt: number; }

/** Persistent RDB metadata and images; each consumer owns its decoded PixelMap. */
export class NetworkMediaCache {
  private readonly directory: string;
  private readonly legacyDirectory: string;
  private readonly database: LinkoraDatabase;
  private readonly serverId: number;
  private readonly memory: Map<string, CachedNetworkMedia> = new Map();
  constructor(context: common.UIAbilityContext, serverId: number) {
    this.directory = `${context.filesDir}/network-media`;
    this.legacyDirectory = `${context.cacheDir}/network-media`;
    this.database = LinkoraDatabase.shared(context); this.serverId = serverId;
  }
  key(server: NetworkServerEntry, entry: NetworkDirectoryEntry): Promise<string> {
    return SourceIdentity.value(JSON.stringify([server.id, server.updatedAt, server.protocol,
      entry.path, entry.size, entry.modifiedAt]));
  }
  async get(key: string): Promise<CachedNetworkMedia | null> {
    if (!this.safeKey(key)) return null;
    const cached = this.memory.get(key);
    if (cached !== undefined) { this.remember(key, cached); return cached; }
    try {
      await this.database.waitForWrites();
      const store = await this.database.store();
      const rows = await store.querySql(
        'SELECT duration_ms, width, height, updated_at FROM network_media_metadata WHERE cache_key = ?', [key]);
      let value: CachedNetworkMedia | null = null;
      try {
        if (rows.goToNextRow()) {
          const duration: number = rows.getLong(rows.getColumnIndex('duration_ms'));
          const width: number = rows.getLong(rows.getColumnIndex('width'));
          const height: number = rows.getLong(rows.getColumnIndex('height'));
          if (![duration, width, height].every((n: number): boolean => Number.isSafeInteger(n) && n >= 0)) return null;
          let format: string = 'webp';
          let data: ArrayBuffer | null = this.readImage(this.directory, `${key}.webp`);
          if (data === null) { format = 'jpg'; data = this.readImage(this.directory, `${key}.jpg`); }
          value = new CachedNetworkMedia(duration, width, height, data,
            rows.getLong(rows.getColumnIndex('updated_at')), format);
        }
      } finally { rows.close(); }
      if (value !== null) {
        if (value.imageData === null) value = await this.migrateLegacy(key, value) ?? value;
        this.remember(key, value); return value;
      }
      return await this.migrateLegacy(key);
    } catch (_error) { return null; }
  }
  async put(key: string, value: CachedNetworkMedia): Promise<boolean> {
    if (!this.safeKey(key)) return false;
    const data: ArrayBuffer | null = value.imageData !== null && value.imageData.byteLength > 0 &&
      value.imageData.byteLength <= MAX_IMAGE_BYTES ? value.imageData : null;
    const format: string = value.imageFormat === 'jpg' ? 'jpg' : 'webp';
    this.remember(key, new CachedNetworkMedia(value.durationMs, value.width, value.height, data, value.savedAt, format));
    try {
      await this.database.enqueueWrite(async (): Promise<void> => {
        const store = await this.database.store();
        await store.execute(`INSERT OR REPLACE INTO network_media_metadata
          (cache_key, server_id, duration_ms, width, height, updated_at) VALUES (?, ?, ?, ?, ?, ?)`,
          [key, this.serverId, value.durationMs, value.width, value.height, value.savedAt]);
        // Keep file writes in the existing queue so server deletion cannot race a late rename.
        if (data === null) { this.removeImage(key); return; }
        if (!fileIo.accessSync(this.directory)) fileIo.mkdirSync(this.directory, true);
        this.write(`${key}.${format}`, data);
        this.removeFile(this.directory, `${key}.${format === 'webp' ? 'jpg' : 'webp'}`);
      });
      return true;
    } catch (error) {
      console.warn(`Network media persistence failed. code=${(error as BusinessError).code ?? 0}`);
      return false;
    } // Image write failure retains committed metadata.
  }
  async decode(value: CachedNetworkMedia): Promise<image.PixelMap | null> {
    if (value.imageData === null) return null;
    let source: image.ImageSource | null = null;
    try { source = image.createImageSource(value.imageData); return await source.createPixelMap(); }
    catch (_error) { return null; }
    finally { try { await source?.release(); } catch (_error) {} }
  }
  static removeFiles(context: common.UIAbilityContext, keys: string[]): void {
    for (const key of keys) {
      if (!/^[a-f0-9]{64}$/.test(key)) continue;
      for (const extension of ['webp', 'jpg', 'webp.tmp', 'jpg.tmp']) {
        const path: string = `${context.filesDir}/network-media/${key}.${extension}`;
        if (fileIo.accessSync(path)) fileIo.unlinkSync(path);
      }
      for (const extension of ['json', 'jpg']) {
        const path: string = `${context.cacheDir}/network-media/${key}.${extension}`;
        if (fileIo.accessSync(path)) fileIo.unlinkSync(path);
      }
    }
  }
  private async migrateLegacy(key: string, current: CachedNetworkMedia | null = null): Promise<CachedNetworkMedia | null> {
    try {
      const path: string = `${this.legacyDirectory}/${key}.json`;
      if (fileIo.statSync(path).size > 4096) return null;
      const record: LegacyMediaRecord = JSON.parse(fileIo.readTextSync(path)) as LegacyMediaRecord;
      if (![record.durationMs, record.width, record.height, record.savedAt].every(
        (n: number): boolean => Number.isSafeInteger(n) && n >= 0)) return null;
      const value = new CachedNetworkMedia(current?.durationMs || record.durationMs,
        current?.width || record.width, current?.height || record.height,
        this.readImage(this.legacyDirectory, `${key}.jpg`), current?.savedAt ?? record.savedAt, 'jpg');
      if (await this.put(key, value)) {
        this.removeFile(this.legacyDirectory, `${key}.json`); this.removeFile(this.legacyDirectory, `${key}.jpg`);
      }
      return value;
    } catch (_error) { return null; }
  }
  private remember(key: string, value: CachedNetworkMedia): void {
    this.memory.delete(key); this.memory.set(key, value);
    // RAM only: persistent records and images have no time or count eviction.
    while (this.memory.size > 24) this.memory.delete(this.memory.keys().next().value);
  }
  private safeKey(key: string): boolean { return /^[a-f0-9]{64}$/.test(key); }
  private removeFile(directory: string, name: string): void {
    try { fileIo.unlinkSync(`${directory}/${name}`); } catch (_error) {}
  }
  private removeImage(key: string): void {
    for (const extension of ['webp', 'jpg', 'webp.tmp', 'jpg.tmp']) this.removeFile(this.directory, `${key}.${extension}`);
  }
  private readImage(directory: string, name: string): ArrayBuffer | null {
    try {
      const path: string = `${directory}/${name}`;
      const size: number = fileIo.statSync(path).size;
      if (size <= 0 || size > MAX_IMAGE_BYTES) return null;
      const data: ArrayBuffer = new ArrayBuffer(size);
      const file = fileIo.openSync(path, fileIo.OpenMode.READ_ONLY);
      try { return fileIo.readSync(file.fd, data) === size ? data : null; }
      finally { fileIo.closeSync(file.fd); }
    } catch (_error) { return null; }
  }
  private write(name: string, data: ArrayBuffer): void {
    const temporary: string = `${this.directory}/${name}.tmp`;
    try {
      const file = fileIo.openSync(temporary, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
      try { if (fileIo.writeSync(file.fd, data) !== data.byteLength) throw new Error('Incomplete image write'); }
      finally { fileIo.closeSync(file.fd); }
      fileIo.renameSync(temporary, `${this.directory}/${name}`);
    } finally { this.removeFile(this.directory, `${name}.tmp`); }
  }
}
