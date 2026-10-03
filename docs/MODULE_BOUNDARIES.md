# 功能模块边界

## 已完成结构

```text
linkora_core/                       可独立构建和迁移的 HAR
  contracts/                       平台能力接口与结果契约
  features/                        页面无关的业务控制器
  models/                          纯数据模型
  playback/                        播放状态机与 PlaybackPort
  services/                        纯解析逻辑
  sources/                         网络来源与发现插件接口

entry/src/main/ets/
  adapters/                        HarmonyOS 接口实现
  foundation/LinkoraFeatures.ets   唯一依赖装配入口
  playback/SystemPlaybackPort.ets  AVPlayer 适配器
  services/                        权限、媒体库、选择器与 Preferences 实现
  pages/                           状态绑定、Surface 和窗口交互
  components/                      纯视觉组件与回调
  ui/                              设计令牌
```

## 允许的依赖方向

```text
pages/components → linkora_core public API
pages            → LinkoraFeatures
LinkoraFeatures  → adapters/services/SystemPlaybackPort
adapters         → linkora_core contracts
linkora_core     → 不依赖 entry 和 HarmonyOS 平台 Kit
```

禁止从 `linkora_core` 导入 `@kit.*`、ArkUI 组件或 `entry` 文件。禁止页面直接创建 AVPlayer、Preferences、PhotoAccessHelper、HTTP 请求或具体协议客户端。

## UI 重做规则

UI 可以删除并重建 `pages`、`components` 和 `ui`，只要保留以下连接点：

- 使用 `LibraryFeatureController` 获取最近播放、本地扫描状态并触发选择/扫描。
- 使用 `NetworkLinkController` 修改输入、预检地址和获取可播放来源。
- 使用 `PlayerFeatureController` 绑定 Surface、播放、seek、倍速、音量、后台暂停与书签策略。
- 使用 `PlayerGestureController` 识别手势意图；ArkUI 只转发坐标和位移，手势规则不得写回页面。
- 使用 `MediaSource`、`PlaybackSnapshot`、`AppFailure` 等公共状态，不解析平台数字错误。
- 通过 `LinkoraFeatures` 装配功能，不在页面构造平台适配器。

横屏、系统栏、Surface 创建和亮屏调用属于 HarmonyOS UI 宿主职责。窗口亮度通过 `PlayerBrightnessPort` 注入，页面不得直接依赖窗口实现；播放策略和持久化不得回流页面。

## 协议插件规则

WebDAV、SMB、SFTP、FTP、NFS 都实现同一 `SourcePlugin` 契约。协议模块只负责连接、浏览和随机读取，不持有页面，不直接操作播放器。局域网扫描实现 `DiscoveryPlugin`，必须支持取消和硬超时。

播放器接入远程文件时只面向 `RemoteReadSession`，不得根据协议写 `if/else`。凭据仅以 `credentialRef` 传递，实际明文由 HarmonyOS 安全适配器按需读取。

## 本地来源规则

`MediaLibrarySource`、单文件 `PickerFileSource` 和未来的 `DirectorySource` 是并列适配器。Media Library 使用系统 Video Album/Album，不模拟物理目录；DirectorySource 只在系统真正授予目录能力后实现递归树。控制器缓存来源返回的索引，视频/相册模式、搜索、筛选以及列表/网格切换不得触发全量扫描。

本地大数据列表使用状态管理 V2 的 `Repeat.virtualScroll()`。每个相册与媒体条目必须提供来源命名空间内稳定的 key；缩略图组件在复用导致 URI 改变时必须取消旧请求并释放旧 `PixelMap`。

手动文件的持久化、URI 可用性校验和失效清理由 `ManualMediaRepository` 负责；页面只通过控制器触发操作。播放列表进度由 `LocalMediaProgressRepository` 作为独立投影提供，不能把数据库查询或播放书签字段写入 UI 组件。
