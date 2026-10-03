import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';

const STORE_NAME: string = 'network_view_settings';
const KEY_GRID_VIEW: string = 'grid_view';

export class NetworkViewSettingsStore {
  private static cachedGridView: boolean | null = null;
  private context: common.UIAbilityContext;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  static peek(): boolean | null {
    return NetworkViewSettingsStore.cachedGridView;
  }

  async load(): Promise<boolean> {
    if (NetworkViewSettingsStore.cachedGridView !== null) {
      return NetworkViewSettingsStore.cachedGridView;
    }
    let gridView: boolean = false;
    try {
      const store: preferences.Preferences = await preferences.getPreferences(this.context, STORE_NAME);
      const value: preferences.ValueType = await store.get(KEY_GRID_VIEW, false);
      gridView = typeof value === 'boolean' ? value : false;
    } catch (_error) {
      gridView = false;
    }
    NetworkViewSettingsStore.cachedGridView = gridView;
    return gridView;
  }

  async save(gridView: boolean): Promise<void> {
    NetworkViewSettingsStore.cachedGridView = gridView;
    const store: preferences.Preferences = await preferences.getPreferences(this.context, STORE_NAME);
    await store.put(KEY_GRID_VIEW, gridView);
    await store.flush();
  }
}
