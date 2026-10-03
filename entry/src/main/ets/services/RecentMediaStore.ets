import { common } from '@kit.AbilityKit';
import { relationalStore } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { MediaFormat, MediaSource, MediaSourceKind, RecentMediaItem,
  RecentMediaRepository } from 'linkora_core';
import { LinkoraDatabase } from './LinkoraDatabase';
import { SensitiveLocatorStore } from './SensitiveLocatorStore';
import { SourceIdentity } from './SourceIdentity';

const SECURE_LOCATOR_PREFIX: string = '@asset:';
const RECENT_LIMIT: number = 12;

class StoredRecentEntry {
  readonly sourceKey: string;
  readonly sourceKind: string;
  readonly locatorRef: string;
  readonly displayName: string;
  readonly originLabel: string;
  readonly format: string;
  readonly openedAt: number;

  constructor(sourceKey: string, sourceKind: string, locatorRef: string, displayName: string,
    originLabel: string, format: string, openedAt: number) {
    this.sourceKey = sourceKey;
    this.sourceKind = sourceKind;
    this.locatorRef = locatorRef;
    this.displayName = displayName;
    this.originLabel = originLabel;
    this.format = format;
    this.openedAt = openedAt;
  }
}

export class RecentMediaStore implements RecentMediaRepository {
  private database: LinkoraDatabase;
  private sensitiveLocators: SensitiveLocatorStore = new SensitiveLocatorStore();

  constructor(context: common.UIAbilityContext) {
    this.database = LinkoraDatabase.shared(context);
  }

  async load(): Promise<RecentMediaItem[]> {
    try {
      await this.database.waitForWrites();
      return await this.loadDatabase();
    } catch (_error) {
      return [];
    }
  }

  async record(source: MediaSource): Promise<RecentMediaItem[]> {
    const current: RecentMediaItem[] = await this.load();
    const item: RecentMediaItem = new RecentMediaItem(source, Date.now());
    const record: StoredRecentEntry | null = await this.toStoredEntry(item);
    if (record === null) {
      return current;
    }
    try {
      await this.database.enqueueWrite(async (): Promise<void> => {
        const store: relationalStore.RdbStore = await this.database.store();
        await store.execute(
          `INSERT INTO recent_entry
            (source_key, source_kind, locator_ref, display_name, origin_label, format, opened_at)
           VALUES (?, ?, ?, ?, ?, ?, ?)
           ON CONFLICT(source_key) DO UPDATE SET
            source_kind = excluded.source_kind,
            locator_ref = excluded.locator_ref,
            display_name = excluded.display_name,
            origin_label = excluded.origin_label,
            format = excluded.format,
            opened_at = excluded.opened_at`,
          [record.sourceKey, record.sourceKind, record.locatorRef, record.displayName,
            record.originLabel, record.format, record.openedAt]);
        await store.execute(
          'DELETE FROM recent_entry WHERE source_key NOT IN ' +
          '(SELECT source_key FROM recent_entry ORDER BY opened_at DESC LIMIT ?)', [RECENT_LIMIT]);
      });
      const next: RecentMediaItem[] = await this.loadDatabase();
      await this.removeDiscardedLocators(current, next);
      console.info(`Recent media index updated. count=${next.length}`);
      return next;
    } catch (error) {
      const failure: BusinessError = error as BusinessError;
      console.error(`Recent media index update failed. code=${failure.code}, message=${failure.message}`);
      return current;
    }
  }

  private async loadDatabase(): Promise<RecentMediaItem[]> {
    const store: relationalStore.RdbStore = await this.database.store();
    let result: relationalStore.ResultSet | null = null;
    const items: RecentMediaItem[] = [];
    try {
      result = await store.querySql(
        'SELECT source_kind, locator_ref, display_name, origin_label, format, opened_at ' +
        'FROM recent_entry ORDER BY opened_at DESC LIMIT ?', [RECENT_LIMIT]);
      while (result.goToNextRow()) {
        const kind: MediaSourceKind | null = this.sourceKind(
          result.getString(result.getColumnIndex('source_kind')));
        if (kind === null) {
          continue;
        }
        const locatorRef: string = result.getString(result.getColumnIndex('locator_ref'));
        const locator: string | null = await this.resolveLocator(kind, locatorRef);
        if (locator === null) {
          continue;
        }
        const source: MediaSource = new MediaSource(kind, locator,
          result.getString(result.getColumnIndex('display_name')),
          result.getString(result.getColumnIndex('origin_label')),
          this.formatOf(result.getString(result.getColumnIndex('format'))));
        items.push(new RecentMediaItem(source, result.getLong(result.getColumnIndex('opened_at'))));
      }
    } catch (_error) {
      throw new Error('Unable to load recent media');
    } finally {
      if (result !== null) {
        try {
          result.close();
        } catch (_closeError) {
        }
      }
    }
    return items;
  }

  private async toStoredEntry(item: RecentMediaItem): Promise<StoredRecentEntry | null> {
    const source: MediaSource = item.source;
    let locatorRef: string = source.locator;
    if (source.kind === MediaSourceKind.NETWORK_LINK) {
      const alias: string | null = await this.sensitiveLocators.save(source.locator);
      if (alias === null) {
        return null;
      }
      locatorRef = `${SECURE_LOCATOR_PREFIX}${alias}`;
    }
    return new StoredRecentEntry(await SourceIdentity.key(source), source.kind, locatorRef,
      source.displayName, source.originLabel, source.format, item.openedAt);
  }

  private async resolveLocator(kind: MediaSourceKind, locatorRef: string): Promise<string | null> {
    if (locatorRef.startsWith(SECURE_LOCATOR_PREFIX)) {
      return this.sensitiveLocators.load(locatorRef.substring(SECURE_LOCATOR_PREFIX.length));
    }
    return kind === MediaSourceKind.NETWORK_LINK ? null : locatorRef;
  }

  private sourceKind(value: string): MediaSourceKind | null {
    if (value === MediaSourceKind.LOCAL_DOCUMENT) {
      return MediaSourceKind.LOCAL_DOCUMENT;
    }
    if (value === MediaSourceKind.NETWORK_LINK) {
      return MediaSourceKind.NETWORK_LINK;
    }
    return null;
  }

  private formatOf(value: string): MediaFormat {
    if (value === MediaFormat.HLS) return MediaFormat.HLS;
    if (value === MediaFormat.DASH) return MediaFormat.DASH;
    if (value === MediaFormat.MP4) return MediaFormat.MP4;
    if (value === MediaFormat.MATROSKA) return MediaFormat.MATROSKA;
    if (value === MediaFormat.MPEG_TS) return MediaFormat.MPEG_TS;
    if (value === MediaFormat.AUDIO) return MediaFormat.AUDIO;
    return MediaFormat.UNKNOWN;
  }

  private async removeDiscardedLocators(previous: RecentMediaItem[],
    current: RecentMediaItem[]): Promise<void> {
    for (let index: number = 0; index < previous.length; index++) {
      const source: MediaSource = previous[index].source;
      if (source.kind !== MediaSourceKind.NETWORK_LINK) {
        continue;
      }
      let retained: boolean = false;
      for (let currentIndex: number = 0; currentIndex < current.length; currentIndex++) {
        if (current[currentIndex].source.kind === source.kind &&
          current[currentIndex].source.locator === source.locator) {
          retained = true;
          break;
        }
      }
      if (!retained) {
        await this.sensitiveLocators.remove(source.locator);
      }
    }
  }
}
