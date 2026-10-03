# linkora_core

`linkora_core` 是 Linkora 的可移植功能 HAR，不包含 ArkUI 页面、HarmonyOS Context、AVPlayer、Preferences、媒体库或网络请求实现。

## 公共能力

- 媒体来源、播放状态、错误、书签、本地媒体和远程协议模型
- 可注入 `PlaybackPort` 的播放状态机
- `PlayerFeatureController`、`LibraryFeatureController`、`NetworkLinkController`
- 本地媒体、历史记录、书签和网络预检端口契约
- `SourcePluginRegistry`、随机读取、目录浏览和局域网发现契约

应用只应通过 [Index.ets](Index.ets) 导入公共 API，不得引用 `src/main/ets` 内部路径。

```text
ArkUI page
    ↓ state / intent
FeatureController (linkora_core)
    ↓ interface
Harmony adapter (entry)
    ↓
AVPlayer / MediaLibrary / Preferences / NetworkKit
```

## 接入新的 UI

新 UI 通过 `LinkoraFeatures` 创建控制器，订阅状态对象，然后调用控制器意图方法。UI 不负责保存书签、解释平台错误、请求媒体库、探测 URL 或创建 AVPlayer。

## 接入新的网络协议

每种协议独立实现 `SourcePlugin`。连接对象实现 `list`、`stat`、`openReader` 和 `close`；读取对象实现带 offset 的 `read`、`cancel` 和 `close`。适配器通过 `SourcePluginRegistry.register` 注册，播放器和页面不需要增加协议分支。

SMB、SFTP、FTP 和 NFS 的 native 库必须封装在各自适配器模块中；WebDAV 可由 ArkTS 适配器实现。插件不得把账号、密码或 token 拼进路径或日志。
