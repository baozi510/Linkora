import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { picker } from '@kit.CoreFileKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { AppColors, AppRadius, AppSpacing, AppTypography } from '../ui/AppTheme';

const VIDEO_SUFFIX_FILTER: string = '视频文件|.mp4,.m4v,.mov,.mkv,.webm,.ts,.m2ts';

@ComponentV2
export struct SystemComponentDemoPage {
  @Consumer('linkoraAccentColor') private accentColor: string = 'system';
  @Event onBack: () => void = () => {};

  @Local private switchEnabled: boolean = true;
  @Local private checkboxSelected: boolean = true;
  @Local private selectedMode: string = 'balanced';
  @Local private progressValue: number = 62;
  @Local private lightUpDegree: number = 0.72;
  @Local private operationStatus: string = '尚未调用系统选择器';
  @Local private operationDetail: string = '选择结果只会显示数量，不会在页面中暴露完整文件地址。';

  private async openDocumentPicker(): Promise<void> {
    const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const documentPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker(context);
    const options: picker.DocumentSelectOptions = new picker.DocumentSelectOptions();
    options.maxSelectNumber = 3;
    options.fileSuffixFilters = [VIDEO_SUFFIX_FILTER];
    try {
      const uris: string[] = await documentPicker.select(options);
      this.operationStatus = uris.length > 0 ? `已选择 ${uris.length} 个文件` : '未选择文件';
      this.operationDetail = 'DocumentViewPicker 已返回应用可访问的文件 URI。';
    } catch (error) {
      this.applyPickerError('文件选择器', error as BusinessError);
    }
  }

  private async openPhotoPicker(): Promise<void> {
    const photoPicker: photoAccessHelper.PhotoViewPicker = new photoAccessHelper.PhotoViewPicker();
    const options: photoAccessHelper.PhotoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
    options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.VIDEO_TYPE;
    options.maxSelectNumber = 3;
    try {
      const result: photoAccessHelper.PhotoSelectResult = await photoPicker.select(options);
      this.operationStatus = result.photoUris.length > 0 ?
        `已选择 ${result.photoUris.length} 个相册视频` : '未选择相册视频';
      this.operationDetail = 'PhotoViewPicker 只展示系统媒体库中的视频。';
    } catch (error) {
      this.applyPickerError('相册选择器', error as BusinessError);
    }
  }

  private applyPickerError(name: string, error: BusinessError): void {
    this.operationStatus = `${name}已关闭或调用失败`;
    this.operationDetail = error.code === undefined ? '未返回错误码。' : `系统错误码：${error.code}`;
  }

  private showSystemDialog(): void {
    this.getUIContext().showAlertDialog({
      title: '鸿蒙原生对话框',
      message: '这个弹窗由 ArkUI 的系统对话框接口绘制，会自动适配系统主题、字号和交互规范。',
      primaryButton: {
        value: '取消',
        action: () => {
          this.operationStatus = '已关闭原生对话框';
          this.operationDetail = '未执行确认操作。';
        }
      },
      secondaryButton: {
        value: '确认',
        action: () => {
          this.operationStatus = '已确认原生对话框';
          this.operationDetail = 'AlertDialog 回调执行成功。';
        }
      }
    });
  }

  @Builder
  private demoHeader() {
    Row({ space: 8 }) {
      Button() {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(22)
          .fontColor([AppColors.TEXT_PRIMARY])
      }
      .type(ButtonType.Circle)
      .width(42)
      .height(42)
      .backgroundColor(AppColors.SURFACE)
      .onClick(() => {
        this.onBack();
      })

      Column({ space: 3 }) {
        Text('鸿蒙原生组件')
          .fontSize(AppTypography.PAGE_TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
        Text('ArkUI 控件与系统选择器 Demo')
          .fontSize(AppTypography.CAPTION)
          .fontColor(AppColors.TEXT_SECONDARY)
      }
      .layoutWeight(1)
    }
    .width('100%')
  }

  @Builder
  private sectionTitle(title: string, description: string) {
    Column({ space: 3 }) {
      Text(title)
        .fontSize(AppTypography.SECTION_TITLE)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)
      Text(description)
        .fontSize(AppTypography.CAPTION)
        .lineHeight(17)
        .fontColor(AppColors.TEXT_SECONDARY)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private systemAction(title: string, description: string, symbol: Resource, action: () => void) {
    Button() {
      Row({ space: 12 }) {
        Stack() {
          SymbolGlyph(symbol)
            .fontSize(22)
            .fontColor([AppColors.accent(this.accentColor)])
        }
        .width(40)
        .height(40)
        .backgroundColor(AppColors.CONTROL_SURFACE)
        .borderRadius(AppRadius.CONTROL)

        Column({ space: 3 }) {
          Text(title)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT_PRIMARY)
          Text(description)
            .fontSize(AppTypography.META)
            .lineHeight(16)
            .fontColor(AppColors.TEXT_MUTED)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(16)
          .fontColor([AppColors.TEXT_SECONDARY])
      }
      .padding(14)
      .width('100%')
    }
    .width('100%')
    .height(72)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .onClick(action)
  }

  @Builder
  private nativeControls() {
    Column({ space: 16 }) {
      Row({ space: 12 }) {
        Column({ space: 3 }) {
          Text('Switch')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT_PRIMARY)
          Text(this.switchEnabled ? '已开启' : '已关闭')
            .fontSize(AppTypography.META)
            .fontColor(AppColors.TEXT_MUTED)
        }
        .layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.switchEnabled })
          .selectedColor(AppColors.accent(this.accentColor))
          .onChange((value: boolean) => {
            this.switchEnabled = value;
          })
      }

      Row({ space: 12 }) {
        Checkbox({ name: 'native-checkbox', group: 'component-demo' })
          .select(this.checkboxSelected)
          .shape(CheckBoxShape.ROUNDED_SQUARE)
          .selectedColor(AppColors.accent(this.accentColor))
          .onChange((value: boolean) => {
            this.checkboxSelected = value;
          })
        Text('Checkbox 原生复选框')
          .fontSize(15)
          .fontColor(AppColors.TEXT_PRIMARY)
          .layoutWeight(1)
        Text(this.checkboxSelected ? '已选择' : '未选择')
          .fontSize(AppTypography.META)
          .fontColor(AppColors.TEXT_MUTED)
      }

      Column({ space: 9 }) {
        Row() {
          Text('Slider 与 Progress')
            .fontSize(15)
            .fontColor(AppColors.TEXT_PRIMARY)
            .layoutWeight(1)
          Text(`${Math.round(this.progressValue)}%`)
            .fontSize(AppTypography.CAPTION)
            .fontColor(AppColors.accent(this.accentColor))
        }
        Slider({ value: this.progressValue, min: 0, max: 100, step: 1 })
          .selectedColor(AppColors.accent(this.accentColor))
          .trackColor(AppColors.TRACK)
          .onChange((value: number) => {
            this.progressValue = value;
          })
        Progress({ value: this.progressValue, total: 100, type: ProgressType.Linear })
          .color(AppColors.accent(this.accentColor))
          .backgroundColor(AppColors.TRACK)
          .width('100%')
      }

      Column({ space: 10 }) {
        Row() {
          Text('lightUpEffect 光感强度')
            .fontSize(15)
            .fontColor(AppColors.TEXT_PRIMARY)
            .layoutWeight(1)
          Text(this.lightUpDegree.toFixed(2))
            .fontSize(AppTypography.CAPTION)
            .fontColor(AppColors.accent(this.accentColor))
        }

        Row({ space: 10 }) {
          SymbolGlyph($r('sys.symbol.play_fill'))
            .fontSize(22)
            .fontColor([AppColors.accentForeground(this.accentColor)])
          Text('光感效果预览')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.accentForeground(this.accentColor))
        }
        .padding({ left: 16, right: 16 })
        .width('100%')
        .height(54)
        .backgroundColor(AppColors.accent(this.accentColor))
        .borderRadius(AppRadius.CONTROL)
        .lightUpEffect(this.lightUpDegree)

        Slider({ value: this.lightUpDegree, min: 0, max: 1, step: 0.05 })
          .selectedColor(AppColors.accent(this.accentColor))
          .trackColor(AppColors.TRACK)
          .onChange((value: number) => {
            this.lightUpDegree = value;
          })
      }

      Column({ space: 10 }) {
        Text('Radio 单选模式')
          .fontSize(15)
          .fontColor(AppColors.TEXT_PRIMARY)
        Row({ space: 18 }) {
          Row({ space: 6 }) {
            Radio({ value: 'balanced', group: 'quality-mode' })
              .checked(this.selectedMode === 'balanced')
              .onChange((checked: boolean) => {
                if (checked) {
                  this.selectedMode = 'balanced';
                }
              })
            Text('均衡').fontSize(14).fontColor(AppColors.TEXT_SECONDARY)
          }
          Row({ space: 6 }) {
            Radio({ value: 'quality', group: 'quality-mode' })
              .checked(this.selectedMode === 'quality')
              .onChange((checked: boolean) => {
                if (checked) {
                  this.selectedMode = 'quality';
                }
              })
            Text('画质优先').fontSize(14).fontColor(AppColors.TEXT_SECONDARY)
          }
        }
      }
    }
    .padding(16)
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
  }

  build() {
    Scroll() {
      Column({ space: 20 }) {
        this.demoHeader()

        this.sectionTitle('系统界面', '下面的按钮会离开当前页面，拉起 HarmonyOS 自带的选择或对话界面。')

        Column({ space: 10 }) {
          this.systemAction('从文件中选择视频', 'DocumentViewPicker · 最多选择 3 个',
            $r('sys.symbol.folder'), () => {
              this.openDocumentPicker();
            })
          this.systemAction('从相册中选择视频', 'PhotoViewPicker · 仅显示视频',
            $r('sys.symbol.video'), () => {
              this.openPhotoPicker();
            })
          this.systemAction('显示系统对话框', 'AlertDialog · 跟随系统视觉规范',
            $r('sys.symbol.info_circle'), () => {
              this.showSystemDialog();
            })
        }
        .width('100%')

        Column({ space: 4 }) {
          Text(this.operationStatus)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT_PRIMARY)
          Text(this.operationDetail)
            .fontSize(AppTypography.META)
            .lineHeight(16)
            .fontColor(AppColors.TEXT_MUTED)
        }
        .padding(14)
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .backgroundColor(AppColors.SURFACE_INPUT)
        .borderRadius(AppRadius.CONTROL)

        this.sectionTitle('ArkUI 原生控件', '控件使用系统交互逻辑，颜色和容器保持 Linkora 的视觉风格。')
        this.nativeControls()
      }
      .padding({ left: AppSpacing.PAGE_HORIZONTAL, right: AppSpacing.PAGE_HORIZONTAL,
        top: AppSpacing.PAGE_TOP, bottom: AppSpacing.PAGE_BOTTOM })
      .width('100%')
      .constraintSize({ minHeight: '100%' })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .backgroundColor(AppColors.BACKGROUND)
  }
}
