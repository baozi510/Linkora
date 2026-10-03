import { LocalFileCategory, LocalFileFilter } from 'linkora_core';
import { AppColors, AppRadius, MediaLayout } from '../ui/AppTheme';
import { AppIcon, AppIconName } from './AppIcon';

@ComponentV2
export struct FileTypeIcon {
  @Param fileName: string = '';
  @Param category: LocalFileCategory = LocalFileCategory.UNSUPPORTED;
  @Param gridView: boolean = false;
  @Param directory: boolean = false;
  @Param virtualFolder: boolean = false;
  @Param accentColor: string = 'system';
  private fileFilter: LocalFileFilter = new LocalFileFilter();

  private resolvedCategory(): LocalFileCategory {
    return this.fileName.length > 0 ? this.fileFilter.categoryOf(this.fileName) : this.category;
  }

  private iconColor(): ResourceColor {
    return this.directory || this.resolvedCategory() === LocalFileCategory.VIDEO ?
      AppColors.accent(this.accentColor) : AppColors.ICON_SECONDARY;
  }

  private iconResource(): Resource {
    if (this.directory) {
      return $r('app.media.ms_folder_filled');
    }
    if (this.resolvedCategory() === LocalFileCategory.VIDEO) {
      return $r('app.media.ms_movie_grid');
    }
    if (this.resolvedCategory() === LocalFileCategory.SUBTITLE) {
      return $r('app.media.ms_subtitles_grid');
    }
    return $r('app.media.ms_file_grid');
  }

  private iconAspectRatio(): number {
    // 文件在列表和网格中共用横版图案；高度仍按展示模式决定。
    return this.directory ? MediaLayout.FOLDER_ASPECT_RATIO : 9 / 7;
  }

  build() {
    Stack() {
      Stack({ alignContent: Alignment.BottomEnd }) {
        Image(this.iconResource())
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Contain)
          .fillColor(this.iconColor())
        if (this.directory && this.virtualFolder) {
          AppIcon({ name: AppIconName.LINK, iconSize: 12, color: '#FFFFFF' })
            .margin(this.gridView ? 12 : 6)
        }
      }
      .height(this.gridView ? MediaLayout.GRID_ICON_HEIGHT : MediaLayout.LIST_FILE_ICON_SIZE)
      .aspectRatio(this.iconAspectRatio())
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.CONTROL_SURFACE)
    .borderRadius(AppRadius.SMALL)
    .clip(true)
  }
}
