import { MediaLayout } from '../ui/AppTheme';
import { FileTypeIcon } from './FileTypeIcon';

@ComponentV2
export struct FolderPreview {
  @Param gridView: boolean = false;
  @Param virtualFolder: boolean = false;
  @Param accentColor: string = 'system';

  build() {
    Stack() {
      FileTypeIcon({ directory: true, virtualFolder: this.virtualFolder,
        gridView: this.gridView, accentColor: this.accentColor })
    }
    .width(this.gridView ? '100%' : MediaLayout.LIST_THUMBNAIL_WIDTH)
    .height(this.gridView ? 'auto' : MediaLayout.LIST_THUMBNAIL_HEIGHT)
    .aspectRatio(MediaLayout.ASPECT_RATIO)
  }
}
