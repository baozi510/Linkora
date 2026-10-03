import { util } from '@kit.ArkTS';
import { image } from '@kit.ImageKit';
import { LocalFileCategory } from 'linkora_core';
import { AppColors, AppRadius, MediaLayout } from '../ui/AppTheme';
import { FileTypeIcon } from './FileTypeIcon';

@ComponentV2
export struct FileMediaPreview {
  @Param uri: string = '';
  @Param previewWidth: Length = MediaLayout.LIST_THUMBNAIL_WIDTH;
  @Param previewHeight: Length = MediaLayout.LIST_THUMBNAIL_HEIGHT;
  @Param durationLabel: string = '';
  @Param progressRatio: number = 0;
  @Param category: LocalFileCategory = LocalFileCategory.VIDEO;
  @Param fileName: string = '';
  @Param gridView: boolean = false;
  @Param thumbnailEnabled: boolean = false;
  @Param visibleOnly: boolean = false;
  @Param accentColor: string = 'system';
  @Event load: (uri: string, consumerId: string) => Promise<image.PixelMap | null> = async () => null;
  @Event cancelLoad: (uri: string, consumerId: string) => void = () => {};
  @Event onReadyChanged: (ready: boolean) => void = () => {};

  @Local private thumbnail: image.PixelMap | null = null;
  private active: boolean = false;
  private loading: boolean = false;
  private requestId: number = 0;
  private visible: boolean = false;
  private requestedUri: string = '';
  private readonly consumerId: string = util.generateRandomUUID(true);

  aboutToAppear(): void {
    this.active = true;
    this.loadThumbnail();
  }

  @Monitor('uri', 'thumbnailEnabled')
  private onPreviewSourceChanged(): void {
    this.releaseThumbnail();
    this.loadThumbnail();
  }

  private loadThumbnail(): void {
    if (!this.active || (this.visibleOnly && !this.visible) || !this.thumbnailEnabled ||
      this.uri.length === 0 || this.loading || this.thumbnail !== null) {
      return;
    }
    this.loading = true;
    this.onReadyChanged(false);
    const requestId: number = ++this.requestId;
    this.requestedUri = this.uri;
    this.load(this.uri, this.consumerId).then((thumbnail: image.PixelMap | null) => {
      if (!this.active || requestId !== this.requestId) {
        thumbnail?.release().catch(() => {});
        return;
      }
      this.loading = false;
      this.thumbnail = thumbnail;
      this.onReadyChanged(true);
    }).catch(() => {
      if (requestId === this.requestId) {
        this.loading = false;
        this.onReadyChanged(true);
      }
    });
  }

  private releaseThumbnail(): void {
    if (this.requestedUri.length > 0) this.cancelLoad(this.requestedUri, this.consumerId);
    this.requestedUri = '';
    ++this.requestId;
    this.loading = false;
    const thumbnail: image.PixelMap | null = this.thumbnail;
    this.thumbnail = null;
    this.onReadyChanged(false);
    thumbnail?.release().catch(() => {});
  }

  aboutToDisappear(): void {
    this.active = false;
    this.releaseThumbnail();
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Stack({ alignContent: Alignment.Center }) {
        if (this.thumbnail !== null) {
          Image(this.thumbnail!)
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Cover)
        } else {
          FileTypeIcon({ category: this.category, fileName: this.fileName,
            gridView: this.gridView, accentColor: this.accentColor })
        }
      }
      .width('100%')
      .height('100%')

      if (this.durationLabel.length > 0) {
        Text(this.durationLabel)
          .fontSize(9)
          .fontColor('#FFFFFF')
          .height(17)
          .padding({ left: 5, right: 5 })
          .margin(4)
          .backgroundColor('#99000000')
          .borderRadius(AppRadius.FULL)
      }

      if (this.progressRatio > 0) {
        Row() {
          Row() {
            Row()
              .width(`${Math.max(0, Math.min(100, this.progressRatio * 100))}%`)
              .height(3)
              .backgroundColor(AppColors.accent(this.accentColor))
          }
          .width('100%')
          .height(3)
          .backgroundColor(AppColors.TRACK)
        }
        .width('100%')
        .height('100%')
        .alignItems(VerticalAlign.Bottom)
      }
    }
    .width(this.gridView ? '100%' : this.previewWidth)
    .height(this.gridView ? 'auto' : this.previewHeight)
    .aspectRatio(MediaLayout.ASPECT_RATIO)
    .clip(true)
    .backgroundColor(this.thumbnail === null ? Color.Transparent : AppColors.SURFACE_RAISED)
    .borderRadius(AppRadius.SMALL)
    .onVisibleAreaChange([0], (visible: boolean, ratio: number) => {
      if (!this.visibleOnly) return;
      this.visible = visible && ratio > 0;
      if (this.visible) this.loadThumbnail();
      else this.releaseThumbnail();
    })
  }
}
