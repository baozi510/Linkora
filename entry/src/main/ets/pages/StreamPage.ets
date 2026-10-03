import { common } from '@kit.AbilityKit';
import { media } from '@kit.MediaKit';
import { AppSettings, FailureCatalog, LinkParseResult, MediaFormat, MediaSource, NetworkLinkController,
  NetworkLinkParser, NetworkLinkState, RemoteProtocol } from 'linkora_core';
import { AppActionListItem } from '../components/AppActionListItem';
import { AppIcon, AppIconName } from '../components/AppIcon';
import { AppIconButton } from '../components/AppIconButton';
import { AppSheetHeader } from '../components/AppSheetHeader';
import { AppSheetSurface } from '../components/AppSheetSurface';
import { AppToolbar } from '../components/AppToolbar';
import { LinkoraFeatures } from '../foundation/LinkoraFeatures';
import { NetworkAddressParser, ParsedWebUrl } from '../models/NetworkAddressParser';
import { NetworkServerDraft, NetworkServerEntry, NetworkServerStore } from '../services/NetworkServerStore';
import { NetworkMediaMetadataReader } from '../services/NetworkMediaMetadataReader';
import { AppColors, AppRadius, AppSpacing, AppTypography } from '../ui/AppTheme';

@ComponentV2
export struct StreamPage {
  @Param settings: AppSettings = new AppSettings();
  @Event onOpenSource: (source: MediaSource) => void = () => {};
  @Event onOpenHistory: () => void = () => {};
  @Consumer('linkoraAccentColor') private accentColor: string = 'system';
  @Local private links: NetworkServerEntry[] = [];
  @Local private loading: boolean = true;
  @Local private loadFailure: string = '';
  @Local private sheetVisible: boolean = false;
  @Local private editingId: number = -1;
  @Local private name: string = '';
  @Local private address: string = '';
  @Local private message: string = '';
  @Local private checking: boolean = false;
  @Local private saving: boolean = false;
  private store: NetworkServerStore | null = null;
  private controller: NetworkLinkController | null = null;
  private metadataReader: NetworkMediaMetadataReader = new NetworkMediaMetadataReader();
  private revision: number = 0;
  private active: boolean = true;

  aboutToAppear(): void {
    this.active = true;
    this.store = new NetworkServerStore(this.getUIContext().getHostContext() as common.UIAbilityContext);
    this.loadLinks();
  }

  aboutToDisappear(): void {
    this.active = false;
    this.cancelCheck();
  }

  private async loadLinks(): Promise<void> {
    this.loading = true;
    this.loadFailure = '';
    try {
      const entries: NetworkServerEntry[] = await this.store!.load();
      if (this.active) {
        this.links = entries.filter((entry: NetworkServerEntry) => entry.protocol === RemoteProtocol.HTTP);
      }
    } catch (_error) {
      this.loadFailure = '串流列表加载失败';
    } finally {
      this.loading = false;
    }
  }

  private cancelCheck(): void {
    ++this.revision;
    this.controller?.dispose();
    this.controller = null;
    this.metadataReader.cancel();
    this.checking = false;
  }

  private editLink(entry: NetworkServerEntry | null = null): void {
    if (this.saving) {
      return;
    }
    this.cancelCheck();
    this.editingId = entry?.id ?? -1;
    this.name = entry?.displayName ?? '';
    this.address = entry?.locationLabel() ?? '';
    this.message = '';
    this.sheetVisible = true;
  }

  private parsedLink(): LinkParseResult {
    const value: string = this.address.trim();
    return NetworkLinkParser.parse(value.length > 0 && !value.includes('://') ? `http://${value}` : value);
  }

  private validatedSource(): MediaSource | null {
    const parsed: LinkParseResult = this.parsedLink();
    if (parsed.value === null) {
      this.message = FailureCatalog.fromLinkIssue(parsed.issue).message;
      return null;
    }
    const source: MediaSource = MediaSource.fromNetworkLink(parsed.value);
    return new MediaSource(source.kind, source.locator, this.name.trim() || source.displayName,
      source.originLabel, source.format);
  }

  private async testLink(): Promise<void> {
    const source: MediaSource | null = this.validatedSource();
    if (source === null || this.checking) {
      return;
    }
    this.cancelCheck();
    const revision: number = this.revision;
    this.checking = true;
    this.message = '正在测试连接…';
    const controller: NetworkLinkController = LinkoraFeatures.createNetwork(this.settings,
      (state: NetworkLinkState) => {
        if (revision === this.revision && state.failure !== null) {
          this.message = `${state.failure.title}：${state.failure.message}`;
        }
      });
    this.controller = controller;
    controller.setInput(source.locator);
    await controller.check();
    if (!this.active || revision !== this.revision) {
      return;
    }
    if (controller.currentSource() !== null) {
      if (source.format === MediaFormat.HLS || source.format === MediaFormat.DASH) {
        this.message = '连接成功，时长和分辨率将在播放时读取';
      } else {
        this.message = '连接成功，正在读取媒体信息…';
        const metadata: media.AVMetadata | null = await this.metadataReader.read(source.locator);
        if (!this.active || revision !== this.revision) {
          return;
        }
        const duration: number = Number(metadata?.duration ?? 0);
        const width: number = Number(metadata?.videoWidth ?? 0);
        const height: number = Number(metadata?.videoHeight ?? 0);
        const details: string[] = [];
        if (Number.isFinite(duration) && duration > 0) {
          const seconds: number = Math.floor(duration / 1000);
          details.push(`${Math.floor(seconds / 60)}:${(seconds % 60).toString().padStart(2, '0')}`);
        }
        if (width > 0 && height > 0) {
          details.push(`${width} × ${height}`);
        }
        this.message = details.length > 0 ? `连接成功 · ${details.join(' · ')}` :
          '连接成功，暂未读取到媒体信息，可尝试播放';
      }
    }
    this.checking = false;
  }

  private async saveLink(): Promise<void> {
    const source: MediaSource | null = this.validatedSource();
    if (source === null || this.store === null || this.saving) {
      return;
    }
    const parsed: ParsedWebUrl | null = NetworkAddressParser.parseWeb(source.locator);
    if (parsed === null) {
      this.message = '地址格式不正确';
      return;
    }
    this.cancelCheck();
    this.saving = true;
    const draft: NetworkServerDraft = new NetworkServerDraft(this.name.trim(), RemoteProtocol.HTTP,
      parsed.host, parsed.port, parsed.rootPath, '', '', parsed.secureTransport);
    try {
      const entries: NetworkServerEntry[] = this.editingId > 0 ?
        await this.store.update(this.editingId, draft) : await this.store.add(draft);
      if (this.active) {
        this.links = entries.filter((entry: NetworkServerEntry) => entry.protocol === RemoteProtocol.HTTP);
        this.sheetVisible = false;
      }
    } catch (_error) {
      this.message = '保存失败，请稍后重试';
    } finally {
      this.saving = false;
    }
  }

  private playLink(entry: NetworkServerEntry): void {
    const parsed: LinkParseResult = NetworkLinkParser.parse(entry.locationLabel());
    if (parsed.value === null) {
      this.editLink(entry);
      this.message = FailureCatalog.fromLinkIssue(parsed.issue).message;
      return;
    }
    const source: MediaSource = MediaSource.fromNetworkLink(parsed.value);
    this.onOpenSource(new MediaSource(source.kind, source.locator, entry.displayName.trim() || source.displayName,
      source.originLabel, source.format));
  }

  private confirmDelete(entry: NetworkServerEntry): void {
    this.getUIContext().showAlertDialog({
      title: '删除串流链接',
      message: `确定删除“${entry.titleLabel()}”吗？`,
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: { value: '删除', action: () => {
        this.removeLink(entry.id);
      } }
    });
  }

  private async removeLink(id: number): Promise<void> {
    try {
      const entries: NetworkServerEntry[] = await this.store!.remove(id);
      if (this.active) {
        this.links = entries.filter((entry: NetworkServerEntry) => entry.protocol === RemoteProtocol.HTTP);
      }
    } catch (_error) {
      this.getUIContext().getPromptAction().showToast({ message: '删除失败，请稍后重试' });
    }
  }

  private linkMenu(entry: NetworkServerEntry): MenuElement[] {
    return [
      { value: '编辑', action: () => this.editLink(entry) },
      { value: '删除', action: () => this.confirmDelete(entry) }
    ];
  }

  @Builder
  private linkRow(entry: NetworkServerEntry) {
    AppActionListItem({
      itemHeight: 64,
      accessibilityLabel: `播放 ${entry.titleLabel()}`,
      showTrailingAction: false,
      onOpen: () => this.playLink(entry),
      onOpenMenu: () => this.editLink(entry)
    }) {
      Row({ space: 12 }) {
        AppIcon({ name: AppIconName.LINK, iconSize: 28, color: AppColors.ICON_SECONDARY })
        Column({ space: 4 }) {
          Text(entry.titleLabel())
            .fontSize(AppTypography.BODY)
            .fontColor(AppColors.TEXT_PRIMARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(entry.host)
            .fontSize(AppTypography.CAPTION)
            .fontColor(AppColors.TEXT_SECONDARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        Button() {
          AppIcon({ name: AppIconName.MORE_VERT, iconSize: 19, color: AppColors.ICON_SECONDARY })
        }
          .type(ButtonType.Normal)
          .width(34)
          .height(34)
          .padding(0)
          .backgroundColor(Color.Transparent)
          .accessibilityText('串流链接菜单')
          .bindMenu(this.linkMenu(entry))
      }
      .width('100%')
    }
  }

  @Builder
  private linkSheet() {
    AppSheetSurface() {
      Scroll() {
        Column({ space: 16 }) {
          AppSheetHeader({ title: this.editingId > 0 ? '编辑串流链接' : '添加串流链接' })
          TextInput({ text: this.name, placeholder: '名称（可选）' })
            .id('stream-name')
            .enterKeyType(EnterKeyType.Next)
            .enabled(!this.saving)
            .height(44)
            .fontSize(AppTypography.BODY)
            .fontColor(AppColors.TEXT_PRIMARY)
            .backgroundColor(Color.Transparent)
            .border({ width: { bottom: 1 }, color: AppColors.OUTLINE })
            .borderRadius(AppRadius.NONE)
            .onChange((value: string) => { this.name = value; })
            .onSubmit(() => { this.getUIContext().getFocusController().requestFocus('stream-address'); })
          TextInput({ text: this.address, placeholder: 'HTTP / HTTPS 媒体地址' })
            .id('stream-address')
            .enabled(!this.saving)
            .height(44)
            .fontSize(AppTypography.BODY)
            .fontColor(AppColors.TEXT_PRIMARY)
            .backgroundColor(Color.Transparent)
            .border({ width: { bottom: 1 }, color: AppColors.OUTLINE })
            .borderRadius(AppRadius.NONE)
            .enterKeyType(EnterKeyType.Done)
            .onChange((value: string) => {
              this.cancelCheck();
              this.address = value;
              this.message = '';
            })
            .onSubmit(() => { this.saveLink(); })
          if (this.message.length > 0) {
            Text(this.message)
              .id('stream-check-result')
              .fontSize(AppTypography.BODY)
              .fontColor(AppColors.TEXT_SECONDARY)
              .width('100%')
          }
          Row({ space: 12 }) {
            Button(this.checking ? '测试中' : '测试连接')
              .type(ButtonType.Normal)
              .height(40)
              .fontSize(AppTypography.BODY)
              .fontColor(AppColors.accent(this.accentColor))
              .backgroundColor(Color.Transparent)
              .borderRadius(AppRadius.CONTROL)
              .layoutWeight(1)
              .enabled(!this.checking && !this.saving)
              .onClick(() => { this.testLink(); })
            Button(this.saving ? '正在保存' : '保存')
              .type(ButtonType.Normal)
              .height(40)
              .fontSize(AppTypography.BODY)
              .fontColor(AppColors.accent(this.accentColor))
              .backgroundColor(Color.Transparent)
              .borderRadius(AppRadius.CONTROL)
              .layoutWeight(1)
              .enabled(!this.saving)
              .onClick(() => { this.saveLink(); })
          }
          .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding({ left: AppSpacing.PAGE_HORIZONTAL, right: AppSpacing.PAGE_HORIZONTAL, top: 20, bottom: 32 })
      }
      .width('100%')
    }
  }

  build() {
    Column() {
      AppToolbar({ title: '串流' }) {
        AppIconButton({ icon: AppIconName.SCHEDULE, label: '播放记录',
          onPressed: () => this.onOpenHistory() })
        AppIconButton({ icon: AppIconName.ADD, label: '添加串流链接',
          onPressed: () => this.editLink() })
      }
      if (this.loading) {
        LoadingProgress().width(28).height(28)
      } else if (this.loadFailure.length > 0) {
        Text(this.loadFailure).fontColor(AppColors.TEXT_SECONDARY)
        Button('重试').onClick(() => { this.loadLinks(); })
      } else if (this.links.length === 0) {
        Column({ space: 12 }) {
          AppIcon({ name: AppIconName.LINK, iconSize: 42, color: AppColors.ICON_TERTIARY })
          Text('还没有串流链接').fontColor(AppColors.TEXT_PRIMARY)
          Text('添加 HTTP / HTTPS 媒体地址后播放')
            .fontSize(AppTypography.BODY)
            .fontColor(AppColors.TEXT_SECONDARY)
          Button('添加串流链接')
            .type(ButtonType.Normal)
            .height(38)
            .fontSize(AppTypography.BODY)
            .backgroundColor(AppColors.accent(this.accentColor))
            .fontColor(AppColors.accentForeground(this.accentColor))
            .borderRadius(AppRadius.CONTROL)
            .onClick(() => this.editLink())
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.links, (entry: NetworkServerEntry) => {
            ListItem() { this.linkRow(entry) }
          }, (entry: NetworkServerEntry) => `${entry.id}:${entry.updatedAt}`)
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
    .bindSheet(this.sheetVisible!!, this.linkSheet(), {
      height: SheetSize.FIT_CONTENT,
      radius: { topLeft: AppRadius.SHEET, topRight: AppRadius.SHEET },
      showClose: false,
      onDisappear: () => this.cancelCheck()
    })
  }
}
