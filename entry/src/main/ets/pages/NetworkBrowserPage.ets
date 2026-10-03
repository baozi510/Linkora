import { common } from '@kit.AbilityKit';
import { MediaSource, RemoteProtocol } from 'linkora_core';
import { NetworkDirectoryBrowser } from '../components/NetworkDirectoryBrowser';
import { AppToolbar } from '../components/AppToolbar';
import { NetworkServerEntry, NetworkServerStore } from '../services/NetworkServerStore';
import { NetworkViewSettingsStore } from '../services/NetworkViewSettingsStore';
import { AppColors, AppTypography } from '../ui/AppTheme';

@ComponentV2
export struct NetworkBrowserPage {
  @Require @Param serverId: number;
  @Param path: string = '';
  @Event onOpenDirectory: (path: string) => void = () => {};
  @Event onBack: () => void = () => {};
  @Event onOpenSource: (source: MediaSource) => void = () => {};

  @Local private server: NetworkServerEntry | null = null;
  @Local private loading: boolean = true;
  @Local private failure: string = '';
  @Local private gridView: boolean = NetworkViewSettingsStore.peek() ?? false;
  private viewSettingsStore: NetworkViewSettingsStore | null = null;
  private active: boolean = false;

  aboutToAppear(): void {
    this.active = true;
    const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
    this.viewSettingsStore = new NetworkViewSettingsStore(context);
    if (this.server !== null) {
      return;
    }
    this.viewSettingsStore.load().then((gridView: boolean) => {
      if (this.active) {
        this.gridView = gridView;
      }
    }).catch(() => {});
    this.loadServer(new NetworkServerStore(context));
  }

  aboutToDisappear(): void {
    this.active = false;
    this.viewSettingsStore = null;
  }

  private async loadServer(store: NetworkServerStore): Promise<void> {
    this.loading = true;
    this.failure = '';
    try {
      const servers: NetworkServerEntry[] = await store.load();
      if (!this.active) {
        return;
      }
      for (const server of servers) {
        if (server.id === this.serverId) {
          this.server = server;
          return;
        }
      }
      this.failure = '服务器已不存在';
    } catch (_error) {
      if (this.active) {
        this.failure = '服务器加载失败';
      }
    } finally {
      if (this.active) {
        this.loading = false;
      }
    }
  }

  private updateGridView(gridView: boolean): void {
    this.gridView = gridView;
    this.viewSettingsStore?.save(gridView).catch(() => {});
  }

  @Builder
  private message(text: string) {
    Column({ space: 12 }) {
      AppToolbar({ title: '网络', showBack: true, onBack: this.onBack })
      Text(text)
        .fontSize(AppTypography.BODY)
        .fontColor(AppColors.TEXT_SECONDARY)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height('100%')
  }

  build() {
    if (this.loading) {
      Column() {
        AppToolbar({ title: '网络', showBack: true, onBack: this.onBack })
        LoadingProgress()
          .width(28)
          .height(28)
          .color(AppColors.accent('system'))
          .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Center)
    } else if (this.failure.length > 0 || this.server === null) {
      this.message(this.failure.length > 0 ? this.failure : '服务器已不存在')
    } else if ((this.server as NetworkServerEntry).protocol !== RemoteProtocol.HTTP) {
      NetworkDirectoryBrowser({ server: this.server as NetworkServerEntry, path: this.path, gridView: this.gridView,
        onOpenDirectory: this.onOpenDirectory, onBack: this.onBack, onOpenSource: this.onOpenSource,
        onGridViewChange: (gridView: boolean) => this.updateGridView(gridView) })
    } else {
      this.message('该服务器不支持目录浏览')
    }
  }
}
