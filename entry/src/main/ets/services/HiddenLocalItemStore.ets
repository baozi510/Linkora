import { common } from '@kit.AbilityKit';
import { relationalStore } from '@kit.ArkData';
import { LocalMediaAsset, LocalMediaFolder } from 'linkora_core';
import { LinkoraDatabase } from './LinkoraDatabase';

export enum HiddenLocalItemType {
  FOLDER = 'folder',
  FILE = 'file'
}

export class HiddenLocalItem {
  readonly itemType: HiddenLocalItemType;
  readonly locator: string;
  readonly displayName: string;
  readonly parentLocator: string;
  readonly hiddenAt: number;

  constructor(itemType: HiddenLocalItemType, locator: string, displayName: string,
    parentLocator: string = '', hiddenAt: number = 0) {
    this.itemType = itemType;
    this.locator = locator;
    this.displayName = displayName;
    this.parentLocator = parentLocator;
    this.hiddenAt = hiddenAt;
  }

  static fromFolder(folder: LocalMediaFolder): HiddenLocalItem {
    return new HiddenLocalItem(HiddenLocalItemType.FOLDER, folder.uri, folder.displayName);
  }

  static fromFile(item: LocalMediaAsset): HiddenLocalItem {
    return new HiddenLocalItem(HiddenLocalItemType.FILE, item.uri, item.displayName, item.parentUri);
  }

  typeLabel(): string {
    return this.itemType === HiddenLocalItemType.FOLDER ? '文件夹' : '文件';
  }
}

export class HiddenLocalItemStore {
  private database: LinkoraDatabase;

  constructor(context: common.UIAbilityContext) {
    this.database = LinkoraDatabase.shared(context);
  }

  async load(): Promise<HiddenLocalItem[]> {
    await this.database.waitForWrites();
    const store: relationalStore.RdbStore = await this.database.store();
    return this.loadItems(store);
  }

  async hide(item: HiddenLocalItem): Promise<HiddenLocalItem[]> {
    return this.hideMany([item]);
  }

  async hideMany(items: HiddenLocalItem[]): Promise<HiddenLocalItem[]> {
    if (items.length === 0) {
      return this.load();
    }
    await this.database.enqueueWrite(async (): Promise<void> => {
      const store: relationalStore.RdbStore = await this.database.store();
      store.beginTransaction();
      try {
        const hiddenAt: number = Date.now();
        for (const item of items) {
          await store.execute(
            `INSERT OR REPLACE INTO hidden_local_item
              (item_type, locator, display_name, parent_locator, hidden_at)
             VALUES (?, ?, ?, ?, ?)`,
            [item.itemType, item.locator, item.displayName, item.parentLocator, hiddenAt]);
        }
        store.commit();
      } catch (error) {
        try {
          store.rollBack();
        } catch (_rollbackError) {
        }
        throw error as Error;
      }
    });
    return this.load();
  }

  async restore(itemType: HiddenLocalItemType, locator: string): Promise<HiddenLocalItem[]> {
    return this.restoreMany([new HiddenLocalItem(itemType, locator, '')]);
  }

  async restoreMany(items: HiddenLocalItem[]): Promise<HiddenLocalItem[]> {
    if (items.length === 0) {
      return this.load();
    }
    await this.database.enqueueWrite(async (): Promise<void> => {
      const store: relationalStore.RdbStore = await this.database.store();
      store.beginTransaction();
      try {
        for (const item of items) {
          await store.execute('DELETE FROM hidden_local_item WHERE item_type = ? AND locator = ?',
            [item.itemType, item.locator]);
        }
        store.commit();
      } catch (error) {
        try {
          store.rollBack();
        } catch (_rollbackError) {
        }
        throw error as Error;
      }
    });
    return this.load();
  }

  async restoreAll(): Promise<HiddenLocalItem[]> {
    await this.database.enqueueWrite(async (): Promise<void> => {
      const store: relationalStore.RdbStore = await this.database.store();
      await store.execute('DELETE FROM hidden_local_item');
    });
    return [];
  }

  private async loadItems(store: relationalStore.RdbStore): Promise<HiddenLocalItem[]> {
    let result: relationalStore.ResultSet | null = null;
    const items: HiddenLocalItem[] = [];
    try {
      result = await store.querySql(
        `SELECT item_type, locator, display_name, parent_locator, hidden_at
         FROM hidden_local_item ORDER BY hidden_at DESC`);
      while (result.goToNextRow()) {
        const typeValue: string = result.getString(result.getColumnIndex('item_type'));
        items.push(new HiddenLocalItem(
          typeValue === HiddenLocalItemType.FOLDER ? HiddenLocalItemType.FOLDER : HiddenLocalItemType.FILE,
          result.getString(result.getColumnIndex('locator')),
          result.getString(result.getColumnIndex('display_name')),
          result.getString(result.getColumnIndex('parent_locator')),
          result.getLong(result.getColumnIndex('hidden_at'))));
      }
    } finally {
      if (result !== null) {
        result.close();
      }
    }
    return items;
  }
}
