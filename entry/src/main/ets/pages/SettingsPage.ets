import { common } from '@kit.AbilityKit';
import { AppAccentColor, AppSettings, AppThemeMode, DEFAULT_SUBTITLE_EXTENSIONS,
  DEFAULT_VIDEO_EXTENSIONS } from 'linkora_core';
import { AppIcon, AppIconName } from '../components/AppIcon';
import { AppToolbar } from '../components/AppToolbar';
import { SettingsDetail } from '../models/AppNavigation';
import { LocalViewSettings } from '../models/LocalMediaViewOptions';
import { LocalViewSettingsStore } from '../services/LocalViewSettingsStore';
import { AppColors, AppRadius, AppSpacing, AppTypography } from '../ui/AppTheme';

@ComponentV2
export struct SettingsPage {
  @Param settings: AppSettings = new AppSettings();
  @Param saving: boolean = false;
  @Param manualThemeSupported: boolean = true;
  @Param hiddenItemCount: number = 0;
  @Event onRememberPositionChange: (enabled: boolean) => void = () => {};
  @Event onKeepScreenOnChange: (enabled: boolean) => void = () => {};
  @Event onCellularPlaybackChange: (enabled: boolean) => void = () => {};
  @Event onExperimentalNetworkStorageChange: (enabled: boolean) => void = () => {};
  @Event onThemeModeChange: (mode: AppThemeMode) => void = () => {};
  @Event onAccentColorChange: (accentColor: AppAccentColor) => void = () => {};
  @Event onLocalFileExtensionsChange: (videoExtensions: string[], subtitleExtensions: string[]) => void = () => {};
  @Event onOpenSystemComponents: () => void = () => {};
  @Event onLocalViewSettingsChange: () => void = () => {};
  @Event onManageHiddenItems: () => void = () => {};
  @Event onOpenDetail: (detail: SettingsDetail) => void = () => {};
  @Event onBack: () => void = () => {};

  @Param detail: SettingsDetail = SettingsDetail.HOME;
  @Local private videoExtensionsText: string = '';
  @Local private subtitleExtensionsText: string = '';
  @Local private localViewSettings: LocalViewSettings = new LocalViewSettings();
  @Local private localViewSettingsReady: boolean = false;
  @Consumer('linkoraAccentColor') private accentColor: string = 'system';
  private localViewSettingsStore: LocalViewSettingsStore | null = null;

  aboutToAppear(): void {
    if (this.detail === SettingsDetail.LOCAL_MEDIA) {
      this.videoExtensionsText = this.settings.localVideoExtensions.join(', ');
      this.subtitleExtensionsText = this.settings.localSubtitleExtensions.join(', ');
      const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
      this.localViewSettingsStore = new LocalViewSettingsStore(context);
      const cachedSettings: LocalViewSettings | null = LocalViewSettingsStore.peek();
      if (cachedSettings !== null) {
        this.localViewSettings = cachedSettings;
        this.localViewSettingsReady = true;
      } else {
        this.localViewSettingsStore.load().then((settings: LocalViewSettings) => {
          if (this.localViewSettingsStore !== null) {
            this.localViewSettings = settings;
            this.localViewSettingsReady = true;
          }
        }).catch(() => {
          this.localViewSettingsReady = true;
        });
      }
    }
  }

  aboutToDisappear(): void {
    this.localViewSettingsStore = null;
  }

  private updateLocalViewSettings(change: (settings: LocalViewSettings) => void): void {
    if (!this.localViewSettingsReady) {
      return;
    }
    const settings: LocalViewSettings = LocalViewSettingsStore.peek() ?? new LocalViewSettings();
    change(settings);
    this.localViewSettings = settings;
    this.localViewSettingsStore?.save(settings).catch(() => {
      console.warn('Unable to persist local view settings');
    });
    this.onLocalViewSettingsChange();
  }

  private pageTitle(): string {
    if (this.detail === SettingsDetail.PLAYER) {
      return '播放器';
    }
    if (this.detail === SettingsDetail.NETWORK) {
      return '网络播放';
    }
    if (this.detail === SettingsDetail.LOCAL_MEDIA) {
      return '本地媒体';
    }
    if (this.detail === SettingsDetail.APPEARANCE) {
      return '外观';
    }
    return '设置';
  }

  private openLocalMediaSettings(): void {
    this.onOpenDetail(SettingsDetail.LOCAL_MEDIA);
  }

  private parseExtensions(value: string): string[] {
    const result: string[] = [];
    const values: string[] = value.split(',');
    for (const item of values) {
      if (item.trim().length > 0) {
        result.push(item.trim());
      }
    }
    return result;
  }

  private themeLabel(): string {
    if (this.settings.themeMode === AppThemeMode.DARK) {
      return '深色';
    }
    if (this.settings.themeMode === AppThemeMode.LIGHT) {
      return '浅色';
    }
    return '跟随系统';
  }

  @Builder
  private themeChoice(mode: AppThemeMode, title: string, description: string, enabled: boolean = true) {
    Button() {
      Row({ space: 12 }) {
        Column({ space: 3 }) {
          Text(title)
            .fontSize(AppTypography.BODY)
            .fontColor(AppColors.TEXT_PRIMARY)
          Text(description)
            .fontSize(AppTypography.META)
            .fontColor(AppColors.TEXT_MUTED)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        if (this.settings.themeMode === mode) {
          AppIcon({ name: AppIconName.CHECK_CIRCLE, iconSize: 20,
            color: AppColors.accent(this.accentColor) })
        }
      }
      .width('100%')
    }
    .type(ButtonType.Normal)
    .width('100%')
    .height(56)
    .padding({ left: 14, right: 14 })
    .backgroundColor(Color.Transparent)
    .enabled(enabled)
    .opacity(enabled ? 1 : 0.4)
    .onClick(() => {
      this.onThemeModeChange(mode);
    })
  }

  @Builder
  private accentChoice(accentColor: AppAccentColor, title: string) {
    Button() {
      Row({ space: 12 }) {
        Row()
          .width(22)
          .height(22)
          .backgroundColor(AppColors.accent(accentColor))
          .borderRadius(AppRadius.SMALL)
        Text(title)
          .fontSize(AppTypography.BODY)
          .fontColor(AppColors.TEXT_PRIMARY)
          .layoutWeight(1)
        if (this.settings.accentColor === accentColor) {
          AppIcon({ name: AppIconName.CHECK_CIRCLE, iconSize: 20,
            color: AppColors.accent(this.accentColor) })
        }
      }
      .width('100%')
    }
    .type(ButtonType.Normal)
    .width('100%')
    .height(48)
    .padding({ left: 14, right: 14 })
    .backgroundColor(Color.Transparent)
    .onClick(() => {
      this.onAccentColorChange(accentColor);
    })
  }

  @Builder
  private navigationRow(title: string, description: string, icon: AppIconName, action: () => void) {
    Button() {
      Row({ space: 10 }) {
        AppIcon({ name: icon, iconSize: 20, color: AppColors.ICON_PRIMARY })
          .width(28)
        Column({ space: 3 }) {
          Text(title)
            .fontSize(AppTypography.BODY)
            .fontColor(AppColors.TEXT_PRIMARY)
          if (description.length > 0) {
            Text(description)
              .fontSize(AppTypography.META)
              .fontColor(AppColors.TEXT_MUTED)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        AppIcon({ name: AppIconName.CHEVRON_RIGHT, iconSize: 16, color: AppColors.ICON_TERTIARY })
      }
      .width('100%')
      .height('100%')
    }
    .type(ButtonType.Normal)
    .width('100%')
    .height(52)
    .padding({ left: 12, right: 12 })
    .backgroundColor(Color.Transparent)
    .onClick(() => {
      action();
    })
  }

  @Builder
  private toggleRow(title: string, description: string, enabled: boolean,
    onChange: (value: boolean) => void) {
    Row({ space: 12 }) {
      Column({ space: 3 }) {
        Text(title)
          .fontSize(AppTypography.BODY)
          .fontColor(AppColors.TEXT_PRIMARY)
        Text(description)
          .fontSize(AppTypography.META)
          .lineHeight(15)
          .fontColor(AppColors.TEXT_MUTED)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Toggle({ type: ToggleType.Switch, isOn: enabled })
        .selectedColor(AppColors.accent(this.accentColor))
        .onClick(() => {
          onChange(!enabled);
        })
    }
    .width('100%')
    .height(56)
    .padding({ left: 14, right: 14 })
  }

  @Builder
  private profile() {
    Row({ space: 12 }) {
      Stack() {
        Text('L')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.accentForeground(this.accentColor))
      }
      .width(44)
      .height(44)
      .backgroundColor(AppColors.accent(this.accentColor))
      .borderRadius(AppRadius.CONTROL)

      Column({ space: 3 }) {
        Text('Linkora')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY)
        Text('本地优先 · 不上传媒体资料')
          .fontSize(AppTypography.META)
          .fontColor(AppColors.TEXT_MUTED)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text(this.themeLabel())
        .fontSize(AppTypography.META)
        .fontColor(AppColors.TEXT_SECONDARY)
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .backgroundColor(AppColors.SURFACE_INPUT)
        .borderRadius(AppRadius.SMALL)
    }
    .width('100%')
    .height(64)
    .padding({ left: 14, right: 14 })
    .backgroundColor(AppColors.SURFACE_RAISED)
    .borderRadius(AppRadius.CONTROL)
  }

  @Builder
  private settingsHome() {
    Column({ space: 12 }) {
      this.profile()

      Column() {
        this.navigationRow('本地媒体', '视频与字幕扫描后缀', AppIconName.HARD_DRIVE, () => {
          this.openLocalMediaSettings();
        })
        this.navigationRow('播放器', '播放位置、亮屏与基础播放行为', AppIconName.MOVIE, () => {
          this.onOpenDetail(SettingsDetail.PLAYER);
        })
        this.navigationRow('网络播放', '移动网络与远程资源策略', AppIconName.LANGUAGE, () => {
          this.onOpenDetail(SettingsDetail.NETWORK);
        })
      }
      .width('100%')
      .backgroundColor(AppColors.SURFACE_RAISED)
      .borderRadius(AppRadius.CONTROL)

      Column() {
        this.navigationRow('外观', `${this.themeLabel()} · 主题色`, AppIconName.PALETTE, () => {
          this.onOpenDetail(SettingsDetail.APPEARANCE);
        })
        this.navigationRow('鸿蒙原生组件', '查看系统组件与交互效果', AppIconName.WIDGETS, () => {
          this.onOpenSystemComponents();
        })
      }
      .width('100%')
      .backgroundColor(AppColors.SURFACE_RAISED)
      .borderRadius(AppRadius.CONTROL)

      Column({ space: 4 }) {
        Row({ space: 10 }) {
          AppIcon({ name: AppIconName.INFO, iconSize: 20, color: AppColors.ICON_SECONDARY })
          Text('关于 Linkora')
            .fontSize(AppTypography.BODY)
            .fontColor(AppColors.TEXT_PRIMARY)
        }
        Text('HarmonyOS 原生媒体播放器 · 0.1.0')
          .fontSize(AppTypography.META)
          .fontColor(AppColors.TEXT_MUTED)
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding(14)
      .backgroundColor(AppColors.SURFACE_RAISED)
      .borderRadius(AppRadius.CONTROL)

      if (!this.manualThemeSupported) {
        Text('当前系统仅支持跟随系统主题；固定浅色或深色需要更高系统版本。')
          .fontSize(AppTypography.META)
          .fontColor(AppColors.TEXT_MUTED)
          .width('100%')
      }
      if (this.saving) {
        Text('正在保存设置…')
          .fontSize(AppTypography.META)
          .fontColor(AppColors.TEXT_MUTED)
      }
    }
    .width('100%')
  }

  @Builder
  private detailContent() {
    if (this.detail === SettingsDetail.LOCAL_MEDIA) {
      Column({ space: 10 }) {
        Column({ space: 14 }) {
        Column({ space: 6 }) {
          Text('视频后缀')
            .fontSize(AppTypography.CAPTION)
            .fontColor(AppColors.TEXT_SECONDARY)
            .width('100%')
          TextInput({ text: this.videoExtensionsText, placeholder: '.mp4, .mkv, .mov' })
            .width('100%')
            .height(42)
            .fontSize(AppTypography.BODY)
            .fontColor(AppColors.TEXT_PRIMARY)
            .placeholderColor(AppColors.TEXT_MUTED)
            .backgroundColor(AppColors.SURFACE_INPUT)
            .borderRadius(AppRadius.CONTROL)
            .onChange((value: string) => {
              this.videoExtensionsText = value;
            })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Column({ space: 6 }) {
          Text('字幕后缀')
            .fontSize(AppTypography.CAPTION)
            .fontColor(AppColors.TEXT_SECONDARY)
            .width('100%')
          TextInput({ text: this.subtitleExtensionsText, placeholder: '.srt, .ass, .vtt' })
            .width('100%')
            .height(42)
            .fontSize(AppTypography.BODY)
            .fontColor(AppColors.TEXT_PRIMARY)
            .placeholderColor(AppColors.TEXT_MUTED)
            .backgroundColor(AppColors.SURFACE_INPUT)
            .borderRadius(AppRadius.CONTROL)
            .onChange((value: string) => {
              this.subtitleExtensionsText = value;
            })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Text('使用英文逗号分隔。后缀会自动转为小写并补全开头的点。字幕只会从已授权目录和网络位置中发现。')
          .fontSize(AppTypography.META)
          .lineHeight(16)
          .fontColor(AppColors.TEXT_MUTED)
          .width('100%')

        Row({ space: 10 }) {
          Button('恢复默认')
            .type(ButtonType.Normal)
            .height(40)
            .fontSize(AppTypography.CAPTION)
            .fontColor(AppColors.TEXT_PRIMARY)
            .backgroundColor(AppColors.SURFACE_INPUT)
            .borderRadius(AppRadius.CONTROL)
            .onClick(() => {
              this.videoExtensionsText = DEFAULT_VIDEO_EXTENSIONS.join(', ');
              this.subtitleExtensionsText = DEFAULT_SUBTITLE_EXTENSIONS.join(', ');
            })
          Button('保存并重新扫描')
            .type(ButtonType.Normal)
            .height(40)
            .fontSize(AppTypography.CAPTION)
            .fontColor(AppColors.accentForeground(this.accentColor))
            .backgroundColor(AppColors.accent(this.accentColor))
            .borderRadius(AppRadius.CONTROL)
            .layoutWeight(1)
            .onClick(() => {
              this.onLocalFileExtensionsChange(this.parseExtensions(this.videoExtensionsText),
                this.parseExtensions(this.subtitleExtensionsText));
            })
        }
        .width('100%')
        }
        .width('100%')
        .padding(14)
        .backgroundColor(AppColors.SURFACE_RAISED)
        .borderRadius(AppRadius.CONTROL)

        Text('列表显示')
          .fontSize(AppTypography.CAPTION)
          .fontColor(AppColors.TEXT_SECONDARY)
          .width('100%')
          .margin({ top: 4 })

        if (this.localViewSettingsReady) {
          Column() {
            this.toggleRow('显示隐藏项目', '在本地列表中显示已隐藏的文件和文件夹',
              this.localViewSettings.showHiddenItems, (value: boolean) => {
                this.updateLocalViewSettings((settings: LocalViewSettings) => {
                  settings.showHiddenItems = value;
                });
              })
            this.toggleRow('显示缩略图', '为支持的媒体文件加载预览图',
              this.localViewSettings.showThumbnails, (value: boolean) => {
                this.updateLocalViewSettings((settings: LocalViewSettings) => {
                  settings.showThumbnails = value;
                });
              })
            this.toggleRow('显示文件后缀', '在文件名称后显示扩展名',
              this.localViewSettings.showFileExtension, (value: boolean) => {
                this.updateLocalViewSettings((settings: LocalViewSettings) => {
                  settings.showFileExtension = value;
                });
              })
          }
          .width('100%')
          .backgroundColor(AppColors.SURFACE_RAISED)
          .borderRadius(AppRadius.CONTROL)

          Text('信息字段')
            .fontSize(AppTypography.CAPTION)
            .fontColor(AppColors.TEXT_SECONDARY)
            .width('100%')
            .margin({ top: 4 })

          Column() {
            this.toggleRow('显示项目数量', '在文件夹信息中显示文件夹和文件数量',
              this.localViewSettings.showItemCount, (value: boolean) => {
                this.updateLocalViewSettings((settings: LocalViewSettings) => {
                  settings.showItemCount = value;
                });
              })
            this.toggleRow('显示文件大小', '在文件信息中显示占用空间',
              this.localViewSettings.showSize, (value: boolean) => {
                this.updateLocalViewSettings((settings: LocalViewSettings) => {
                  settings.showSize = value;
                });
              })
            this.toggleRow('显示清晰度', '显示视频或图片的分辨率',
              this.localViewSettings.showResolution, (value: boolean) => {
                this.updateLocalViewSettings((settings: LocalViewSettings) => {
                  settings.showResolution = value;
                });
              })
            this.toggleRow('显示时长', '显示音视频的播放时长',
              this.localViewSettings.showDuration, (value: boolean) => {
                this.updateLocalViewSettings((settings: LocalViewSettings) => {
                  settings.showDuration = value;
                });
              })
            this.toggleRow('显示日期', '显示文件的修改日期',
              this.localViewSettings.showModifiedDate, (value: boolean) => {
                this.updateLocalViewSettings((settings: LocalViewSettings) => {
                  settings.showModifiedDate = value;
                });
              })
          }
          .width('100%')
          .backgroundColor(AppColors.SURFACE_RAISED)
          .borderRadius(AppRadius.CONTROL)

          if (this.hiddenItemCount > 0) {
            Column() {
              this.navigationRow('管理已隐藏项目', `${this.hiddenItemCount} 项`,
                AppIconName.VISIBILITY, () => {
                  this.onManageHiddenItems();
                })
            }
            .width('100%')
            .backgroundColor(AppColors.SURFACE_RAISED)
            .borderRadius(AppRadius.CONTROL)
          }
        } else {
          Row() {
            LoadingProgress()
              .width(24)
              .height(24)
              .color(AppColors.accent(this.accentColor))
          }
          .width('100%')
          .height(56)
          .justifyContent(FlexAlign.Center)
          .backgroundColor(AppColors.SURFACE_RAISED)
          .borderRadius(AppRadius.CONTROL)
        }
      }
      .width('100%')
    } else if (this.detail === SettingsDetail.PLAYER) {
      Column() {
        this.toggleRow('记住播放位置', '再次打开时从上次位置继续',
          this.settings.rememberPlaybackPosition, (value: boolean) => {
            this.onRememberPositionChange(value);
          })
        this.toggleRow('播放时保持亮屏', '播放视频期间不自动锁屏',
          this.settings.keepScreenOnDuringPlayback, (value: boolean) => {
            this.onKeepScreenOnChange(value);
          })
      }
      .width('100%')
      .backgroundColor(AppColors.SURFACE_RAISED)
      .borderRadius(AppRadius.CONTROL)
    } else if (this.detail === SettingsDetail.NETWORK) {
      Column() {
        this.toggleRow('实验性网络存储', '启用 WebDAV、SMB、SFTP、FTP 与 NFS；首发默认关闭',
          this.settings.experimentalNetworkStorage, (value: boolean) => {
            this.onExperimentalNetworkStorageChange(value);
          })
        this.toggleRow('允许移动网络播放', '使用蜂窝网络打开远程媒体资源',
          this.settings.allowCellularPlayback, (value: boolean) => {
            this.onCellularPlaybackChange(value);
          })
      }
      .width('100%')
      .backgroundColor(AppColors.SURFACE_RAISED)
      .borderRadius(AppRadius.CONTROL)
    } else if (this.detail === SettingsDetail.APPEARANCE) {
      Column({ space: 10 }) {
        Text('显示模式')
          .fontSize(AppTypography.CAPTION)
          .fontColor(AppColors.TEXT_SECONDARY)
          .width('100%')
        Column() {
          this.themeChoice(AppThemeMode.SYSTEM, '跟随系统', '自动匹配系统的浅色或深色模式')
          this.themeChoice(AppThemeMode.LIGHT, '浅色', '始终使用浅色界面', this.manualThemeSupported)
          this.themeChoice(AppThemeMode.DARK, '深色', '始终使用深色界面', this.manualThemeSupported)
        }
        .width('100%')
        .backgroundColor(AppColors.SURFACE_RAISED)
        .borderRadius(AppRadius.CONTROL)

        Text('主题色')
          .fontSize(AppTypography.CAPTION)
          .fontColor(AppColors.TEXT_SECONDARY)
          .width('100%')
          .margin({ top: 6 })
        Column() {
          this.accentChoice(AppAccentColor.SYSTEM, '系统色')
          this.accentChoice(AppAccentColor.BLUE, '蓝色')
          this.accentChoice(AppAccentColor.PURPLE, '紫色')
          this.accentChoice(AppAccentColor.GREEN, '绿色')
          this.accentChoice(AppAccentColor.ORANGE, '橙色')
          this.accentChoice(AppAccentColor.PINK, '粉色')
        }
        .width('100%')
        .backgroundColor(AppColors.SURFACE_RAISED)
        .borderRadius(AppRadius.CONTROL)
      }
      .width('100%')
    }
  }

  build() {
    Column() {
      AppToolbar({
        title: this.pageTitle(),
        showBack: this.detail !== SettingsDetail.HOME,
        onBack: this.onBack
      })

      Scroll() {
        Column() {
          if (this.detail === SettingsDetail.HOME) {
            this.settingsHome()
          } else {
            this.detailContent()
          }
        }
        .width('100%')
        .constraintSize({ minHeight: '100%' })
        .justifyContent(FlexAlign.Start)
        .padding({ left: AppSpacing.PAGE_HORIZONTAL, right: AppSpacing.PAGE_HORIZONTAL,
          top: 12, bottom: AppSpacing.PAGE_BOTTOM })
      }
      .width('100%')
      .height(0)
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
  }
}
