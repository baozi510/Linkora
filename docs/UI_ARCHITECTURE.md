# UI 架构规范

## 目标

UI 可以整体换肤或重新排版，但不得迫使播放、网络、文件和持久化模块随之修改。页面负责组合组件和转发用户意图，不负责解释平台错误或直接调用系统播放器。

主导航为本地、串流、网络、设置；手机底栏与宽屏侧栏使用相同入口。`StreamPage` 负责 HTTP/HTTPS 媒体直链，`NetworkPage` 负责 WebDAV/SMB/SFTP/FTP/NFS 服务器。串流连接检查复用 `NetworkLinkController`，播放与历史统一走 `Index.openSource`；已有 HTTP 配置直接在串流页显示。

## 目录职责

```text
ui/AppTheme.ets          颜色、间距、圆角、字号和全局尺寸
models/AppRoute.ets      应用一级导航模型
components/              可复用且不持有业务服务的视觉组件
pages/                   页面组合、短生命周期 UI 状态和意图转发
linkora_core/features/   页面无关的功能控制器
linkora_core/            模型、错误、播放状态机和插件契约 HAR
foundation/              控制器与 HarmonyOS 适配器的装配入口
adapters/services/       网络、文件选择和持久化平台实现
```

## 强制规则

- 新增颜色、字号、间距、圆角和全局尺寸前，先检查 `AppTheme.ets`；跨两个以上组件复用的值必须进入设计令牌。
- 页面背景、层级背景、文字及普通图标使用 HarmonyOS `sys.color` 语义资源；品牌色、播放器覆层及业务状态色由应用资源统一配置。
- 页面不得重复实现已有的标题、卡片、媒体行、播放器顶部栏和错误状态。
- 一级导航只能使用 `AppSection`，不得在页面或底栏中另建字符串路由。
- 固定用户文案写入 `resources/base/element/string.json`；媒体名称、域名、格式和诊断码等运行时文本除外。
- 通用组件不得依赖 `PlaybackEngine`、Preferences、Network Kit 或 Media Kit，只接受属性和回调。
- 页面可以持有输入框、搜索和展开状态；跨页面或需要持久化的状态必须进入模型或服务。
- 页面禁止根据数字平台错误码选择 UI，统一渲染 `AppFailure`。
- 页面不得直接实例化具体服务或播放器；统一通过 `LinkoraFeatures` 获取控制器。
- 组件应支持父容器决定宽高，避免把设备宽度写死；新增平板布局时以 `AppLayout` 为唯一断点来源。
- 非播放器页面使用小圆角：普通区块 6vp、控件 5vp、紧凑元素 4vp；禁止页面自行放大圆角。
- 应用壳、标题栏、导航、列表、卡片和提示不使用描边或分割线，以留白和背景层级区分内容。
- 操作与导航图标统一通过 `AppIcon` 使用 Google Material Symbols 字体；文件预览图标由 `FileTypeIcon` 和 `FolderPreview` 管理同图标体系的矢量资源。页面不得自行选择预览图标资源或写死预览图标尺寸。
- Top Bar 高度、前导热区、操作热区与图标大小分别由 `AppLayout` 和 `AppIconSize` 管理；返回按钮使用 48vp 热区，图形对齐 16vp 页面基准线。
- 手机底部导航内容区使用 52vp，与 API 12 及以上 `BottomTabBarStyle` 默认高度一致；系统手势安全区不计入应用底栏高度。
- 媒体列表缩略图尺寸和 16:9 比例由 `MediaLayout` 统一管理。
- 本地列表、本地网格和网络文件页统一使用 `FileMediaPreview`；该组件负责预览容器、加载与释放缩略图、时长/进度覆盖层，并在关闭加载、无缩略图或加载失败时交给同一个 `FileTypeIcon` 渲染。页面只传文件类型/文件名、加载权限、展示模式和回调，不得分支拼装缩略图与占位图标。近期本地媒体也复用该组件。
- 文件夹列表和网格统一使用 `FolderPreview`，内部与文件共用 `FileTypeIcon` 的图标缩放规则和虚拟目录关联标记。选择按钮及标题由条目层管理。
- 列表与网格共享 `MediaLayout.ITEM_VERTICAL_GAP` 作为条目间的垂直节奏，统一由 `Grid.rowsGap` 控制；条目自身不得承担外部上下间距。
- 本地与网络文件浏览使用唯一的可滚动 `Grid` 承载文件夹和文件。列表模式使用 `columnsTemplate('1fr')`；网格模式共用 `FileBrowserGridLayout`，根据 `AppLayout` 断点采用两、三、四列。所有条目占一个等宽单元格，不设置文件夹专属列跨度或末行补位。切换模式不得替换滚动容器、复制数据或手工计算网格总高度。
- 本地浏览区与 Top Bar 的顶部间距由 `MediaLayout.BROWSER_TOP_INSET` 统一控制，列表和网格不得分别写死数值。
- 文件夹和视频的 `GridItem` 使用稳定 URI key，仅内部视觉结构随模式变化；文件夹仍排在媒体文件之前。
- 本地浏览切换表示视频平铺与目录浏览两种业务模式。视频模式平铺全部去重视频；目录模式根层显示固定“本地媒体”入口、用户文件夹和根层手动添加的文件。“本地媒体”承接系统相册及明确无相册归属的系统媒体；进入相册后只显示该相册的资产。未解析归属不得当作根层。固定入口仅由展示投影生成，不创建数据库目录，也不参与重命名、删除、隐藏或批量选择。
- 本地媒体时长只显示在缩略图右下角，不得在元数据 chip 中重复显示。
- 外观设置使用二级页面的单选列表；显示模式与主题色由 `AppSettings` 持久化，主题色通过统一存储键驱动应用壳和业务页面更新。
- 文件夹、影片、字幕和其他文件共用图标尺寸规则：列表统一 28vp 高度，网格统一为 16:9 预览区域高度的 60%；按各 SVG 裁切后的宽高比确定宽度，保持居中且不拉伸。不为某类图标单独设置较小尺寸。文件夹与文件共用 80×45vp 列表预览区域和 16:9 网格区域，列表名称保持左对齐，网格标题居中、最多两行；虚拟目录继续显示关联标记。Top Bar 和设置页图标使用系统中性图标色，不跟随主题强调色。
- 文件夹和文件类型占位预览在列表、网格中都使用 `AppColors.CONTROL_SURFACE` 底色，由 `FileTypeIcon` 统一管理；真实缩略图继续填满预览区域。占位图时长以右下角普通文字显示，真实图片时长保留对比标签。播放进度沿预览底部显示主题色已播放段和 `AppColors.TRACK` 完整轨道，不为图标单独定位。各类型预览统一使用无留白 SVG 和同一个渲染入口；列表与网格共用横版图案，影片和字幕使用 200 字重的版本，普通文件使用横向折角轮廓。三类文件图标共用 9:7 比例，字幕及其他文件采用中性色。资源选择集中在 `FileTypeIcon`，尺寸由 `MediaLayout` 维护。
- 本地与网络文件网格不显示元数据 chip，包括文件大小、日期、目录统计及缩略图时长标签；条目只保留预览和两行居中标题，以及必要的选择、关联和播放进度标记。列表模式沿用现有信息展示。
- 操作图标通过 `AppIconName` 管理；预览图标只在共用预览组件中替换，尺寸集中在 `MediaLayout` 与 `AppIconSize`。页面不得覆盖这些规则。

## 已建立的公共组件

- `AdaptiveAppShell`：按窗口宽度在手机底部导航与大屏侧边导航之间切换。
- `AppSideBar`、`AppBottomBar`：共享 `AppSection` 的三项一级导航。
- `AppIcon`、`AppIconButton`：语义化字体图标映射与无底板图标操作。
- `FileMediaPreview`、`FileTypeIcon`：共用文件预览容器、缩略图生命周期及文件类型占位；页面不再维护成功、失败和关闭缩略图的不同视觉分支。
- `FolderPreview`：本地与网络共用的列表/网格文件夹预览与关联标记。
- `AppToolbar`：页面紧凑标题栏、当前目录名称和路径。
- `MetadataChip`：媒体与协议元数据标签。
- `AppPageHeader`：一级页面标题与可选操作。
- `AppSectionHeader`：页面分区标题与辅助信息。
- `MediaSourceCard`：媒体来源入口。
- `RecentMediaRow`：媒体库和播放记录共用的最近媒体行。
- `FailureNotice`：普通页面错误卡片。
- `PlayerTopBar`：普通与全屏播放器顶部栏。
- `PlayerFailureOverlay`：播放器错误覆盖层。
- `PlayerControls`、`PlayerStatusPanel`：播放控制与状态展示。
- `PlayerGestureFeedback`：进度、亮度、音量和临时倍速的手势反馈，不持有播放器。

## 修改 UI 的推荐顺序

1. 先调整 `AppTheme` 验证整体视觉方向。
2. 再修改公共组件的结构与交互。
3. 最后调整页面组合和响应式布局。
4. 不得为了视觉改动绕过 `MediaSource`、`PlaybackSnapshot` 或 `AppFailure`。
5. 运行 `scripts/verify.ps1`，并在模拟器验证四个一级页面、播放器和错误状态。
