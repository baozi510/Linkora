# Linkora 迁移调用点清单

> Phase 0 静态审计结果。后续每个 Phase 完成时更新状态。

## 1. Dependency composition

### entry/src/main/ets/foundation/LinkoraFeatures.ets

当前：

- createPlayer 固定 `SystemPlaybackPort`；
- createNetworkMediaProbe 直接返回具体 NetworkMediaProbe；
- createNetworkFileProxy 直接返回具体 Proxy；
- createNetworkMediaLoader 直接创建旧 orchestration。

目标：

- 注册 Storage plugins；
- 注册 Media Probe plugins；
- 注册 Thumbnail plugins；
- 提供共享 MediaProxy service；
- createPlayer 注入 backend selector，而不是固定 System。

优先级：P0。

## 2. Playback

### linkora_core/playback/PlaybackPort.ets

当前缺：

- tracks；
- HDR info；
- seek complete；
- buffered duration；
- backend diagnostics；
- capability model。

目标：演进为统一 backend contract，同时保留兼容接口。

优先级：P0/P1。

### linkora_core/playback/PlaybackEngine.ets

可保留：

- session id；
- stale event filtering；
- state ownership；
- error normalization。

目标：

- SEEKING；
- backend fallback orchestration（或独立 selector/service）；
- richer snapshot。

优先级：P1。

### entry/playback/SystemPlaybackPort.ets

当前：

- URL；
- local fdSrc；
- progressive dataSrc。

目标：

- 保留 URL/local；
- remote file 改 MediaProxy input；
- progressive path 迁移后删除；
- 对齐统一 track/HDR/seek events。

优先级：P1。

### entry/pages/PlayerPage.ets

原则上无需知道 backend。

只应在 PlaybackSnapshot 扩展后适配 UI 字段，不得 import MPV/System。

优先级：P2。

## 3. Media source

### linkora_core/models/MediaSource.ets

当前问题：

- 只有 NETWORK_LINK / LOCAL_DOCUMENT；
- `progressiveKey` 进入 domain；
- 无 credentialRef / source fingerprint / capabilities。

目标：

- stable MediaSource；
- resolved input 与 identity 分离；
- progressiveKey deprecated。

优先级：P0。

## 4. Storage / protocol

### linkora_core/sources/SourcePlugin.ets

已有：

- SourcePlugin；
- SourceConnection；
- RemoteReadSession；
- registry。

目标：

- RemoteReadSession -> RandomAccessSource semantic alignment；
- source capabilities；
- registry 真正进入生产路径。

优先级：P0。

### entry/services/NetworkDirectoryService.ets

当前通过 protocol if/else 调具体 browser。

目标：

- registry/provider resolver；
- 页面与分析/播放不再知道 protocol branch。

优先级：P1。

### entry/services/HttpRemoteReadSession.ets

保留。

需要后续改善：

- HEAD 不可靠时的 size fallback policy；
- Range capability diagnostics；
- source capability 输出；
- request metrics。

优先级：P1。

### entry/services/NativeRemoteReadSession.ets

保留。

增加：

- capabilities；
- metrics；
- cancellation 与 reopen semantics 文档化。

优先级：P1。

### WebDavBrowserService / SmbBrowserService / SftpBrowserService / FileProtocolBrowserService

底层协议代码保留，通过 provider adapter 接入。

优先级：P1。

## 5. MediaProxy

### linkora_proxy/NetworkFileProxy.ets

保留核心。

需要：

- shared lifecycle；
- configurable block/read-ahead；
- diagnostics；
- 后续 segment cache；
- production playback path。

优先级：P1。

### linkora_proxy/HttpByteRange.ets

基本可保留。

继续复用现有单元测试。

优先级：保留。

## 6. Media analysis

### linkora_media_probe/NetworkMediaProbe.ets

当前 metadata + thumbnail 耦合。

目标拆分：

- SystemMediaProbe；
- SystemThumbnailExtractor。

原类在迁移期作为 facade delegate 新实现。

优先级：P0。

### entry/services/NetworkMediaLoader.ets

当前直接 new：

- NetworkFileProxy；
- NetworkMediaProbe；
- ImagePacker；
- NetworkMediaCache。

并实现：

- mode selection；
- metadata merge；
- thumbnail encode；
- WebP/JPEG fallback；
- retry suppression；
- queue；
- timeout。

目标：

- 调 MediaProbeService；
- 调 ThumbnailService；
- 不直接依赖具体 engine；
- 最终缩减为 UI/catalog compatibility facade 或删除。

优先级：最高。

### entry/services/NetworkMediaMetadataReader.ets

这是串流页旧的 System metadata helper。

目标：

- 迁移到 MediaProbeService 的 HTTP/direct-url adapter；
- 保持串流产品行为，不强制自动缩略图。

优先级：P2。

### entry/services/LocalMediaMetadataReader.ets

当前独立 System metadata reader。

目标：

- 作为 Local SystemMediaProbe adapter 或 facade；
- 不重复维护 metadata rules。

优先级：P2。

## 7. Thumbnail

### entry/services/NetworkMediaCache.ets

保留持久层思路。

目标：

- 实现统一 ThumbnailCache adapter；
- cache key 加 algorithmVersion / size / quality / frame time；
- 最终 persistent image 仅 WebP。

优先级：P1。

### entry/services/LocalMediaThumbnailLoader.ets

PhotoAccessHelper 快速路径有价值，保留。

目标：

- 作为 local-library specialized SystemThumbnailExtractor；
- 与通用 ThumbnailService 对齐 cancellation/cache ownership；
- 是否落盘由统一 ThumbnailCache 决定。

优先级：P2。

### entry/components/FileMediaPreview.ets
### entry/components/RecentMediaThumbnail.ets
### entry/pages/NetworkBrowserPage.ets

这些属于消费方。

目标：

- 最终只调用 ThumbnailService / controller；
- 不感知 System/FFmpeg/WebP。

优先级：P2。

## 8. Database / catalog

### entry/services/LinkoraDatabase.ets

保留。

当前 schema 9 的 `network_media_metadata` 只有：

- duration；
- width；
- height。

目标：

- 新 schema 保存 richer analysis record；
- thumbnail metadata 独立；
- probe version；
- fingerprint；
- track info。

优先级：P2/P3。

### entry/services/LocalMediaScanner.ets

成熟资产，避免重写。

未来只需把手动/远程媒体分析切到统一 MediaProbeService。

优先级：保留。

## 9. Legacy progressive playback

### entry/playback/ProgressiveDownloadRegistry.ets
### SystemPlaybackPort progressive branch
### MediaSource.progressiveKey

迁移策略：

1. Proxy playback ready 前保留；
2. 新 remote playback 优先 Proxy；
3. 完成兼容矩阵后停止写入 progressiveKey；
4. 最后删除。

优先级：后置清理，不能现在删除。

## 10. Tests / scripts

继续复用：

- NetworkFileProxy.test；
- NetworkMediaProbe.test；
- PlaybackEngine.test；
- MediaSource.test；
- test-lab/protocols；
- test-lab/media-compatibility；
- scripts/check-network-proxy*；
- scripts/check-network-media-probe*。

新增：

- System vs FFmpeg analysis benchmark；
- MPV vs System playback benchmark；
- WebP encoder test；
- backend fallback tests；
- field-source merge tests；
- proxy large-seek/read-byte metrics。

## 11. 第一批实际代码任务（Phase 1）

Phase 0 文档审核通过后，第一批只建议做：

1. 新增/扩充 contracts；
2. 不改 UI；
3. 不引入 FFmpeg；
4. 不引入 MPV；
5. 给现有 RemoteReadSession、NetworkMediaProbe、PlaybackPort 建兼容 adapter；
6. 保证现有测试和 app 行为不变。

完成后再进入 Storage productionization 与 Media Analysis split。
