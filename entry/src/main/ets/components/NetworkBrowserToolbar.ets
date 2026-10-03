import { AppIconName } from './AppIcon';
import { AppIconButton } from './AppIconButton';
import { AppToolbar } from './AppToolbar';

@ComponentV2
export struct NetworkBrowserToolbar {
  @Param title: string = '';
  @Param path: string = '';
  @Param gridView: boolean = false;
  @Event onBack: () => void = () => {};
  @Event onGridViewChange: (gridView: boolean) => void = () => {};
  build() {
    Column() {
      AppToolbar({ title: this.title, path: this.path, showBack: true, onBack: this.onBack }) {
        AppIconButton({
          icon: this.gridView ? AppIconName.VIEW_LIST : AppIconName.GRID_VIEW,
          selected: false,
          label: this.gridView ? '切换到列表布局' : '切换到网格布局',
          onPressed: () => {
            this.onGridViewChange(!this.gridView);
          }
        })
      }
    }
    .width('100%')
  }
}
