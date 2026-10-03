# Linkora 当前架构审计（Phase 0）

> 审计基线：main @ cdedbea6022e2931172fcff441e2f862d8a89ed7  
> 本文只描述当前代码，不代表最终目标架构。

## 1. 总体判断

Linkora 已经不是空骨架。当前仓库已经具备：

- 独立的纯 ArkTS `linkora_core` HAR；
- `PlaybackEngine / PlaybackPort` 播放抽象与系统 `AVPlayer` 适配；
- `SourcePlugin / RemoteReadSession` 网络来源契约；
- WebDAV、SMB、SFTP、FTP、NFS 浏览与随机读取基础设施；
- 独立 `linkora_proxy` loopback Range HTTP 代理；
- 独立 `linkora_media_probe` 系统媒体探测 HAR；
- 本地媒体扫描、RDB、播放历史/书签；
- 网络媒体元数据与缩略图持久化；
- 协议实验室、媒体兼容性样本与自动检查脚本。

因此后续应采用渐进迁移，而不是重建第二套架构。

## 2. 当前模块

### linkora_core

职责基本正确：纯模型、错误、Feature Controller、播放状态机、协议契约。

关键文件：

- `models/MediaSource.ets`
- `sources/SourcePlugin.ets`
- `playback/PlaybackPort.ets`
- `playback/PlaybackEngine.ets`
- `playback/PlaybackModels.ets`

优点：

- 不依赖 HarmonyOS `@kit.*`；
- UI 不直接创建系统播放器；
- 播放会话使用 session id 防止旧事件污染新会话；
- 已存在 `RemoteReadSession.read(offset,length)`。

当前限制：

- `MediaSourceKind` 只有 `NETWORK_LINK / LOCAL_DOCUMENT`，不足以表达远程文件来源与 resolved input；
- `MediaSource` 包含 `progressiveKey`，把旧渐进下载方案泄漏进核心模型；
- `RemoteReadSession` 缺 source capabilities、稳定 source id、size unknown、reopenable 等能力描述；
- `PlaybackPort` 缺轨道、HDR、seek-complete、buffered duration、后端能力等事件。

### entry

当前承担 HarmonyOS 平台适配、数据库、协议实现、UI 和依赖装配。

重要实现：

- `playback/SystemPlaybackPort.ets`
- `foundation/LinkoraFeatures.ets`
- `services/NetworkDirectoryService.ets`
- `services/HttpRemoteReadSession.ets`
- `services/NativeRemoteReadSession.ets`
- `services/NetworkMediaLoader.ets`
- `services/NetworkMediaCache.ets`
- `services/LocalMediaMetadataReader.ets`
- `services/LocalMediaThumbnailLoader.ets`
- `services/LinkoraDatabase.ets`

### linkora_proxy

已经实现可工作的第一代 MediaProxy 原型：

- 只监听 `127.0.0.1`；
- 随机 token，不暴露远程路径/凭据；
- GET / HEAD；
- HTTP Range；
- 200 / 206 / 416；
- Content-Length / Content-Range / Accept-Ranges；
- Proxy lease 拥有 RemoteReadSession 生命周期；
- 256 KiB 分块读取；
- source/client 数量限制；
- 超时和关闭处理。

当前仍属于实验实现：

- 没有共享 L1 read-ahead cache；
- 没有 L2 disk segment cache；
- 每个 source 的 read 被串行化；
- 当前 NetworkMediaLoader 每个 job 自己创建/关闭 Proxy，而不是 app/session 级共享；
- 尚未成为播放器统一远程入口。

### linkora_media_probe

目前只有 System Probe：

`AVMetadataExtractor -> metadata + fetchFrameByTime`

当前 `NetworkMediaProbe` 同一个类同时负责：

- metadata；
- thumbnail frame；
- cancellation；
- timeout；
- timings。

它已经支持 BOTH / METADATA / THUMBNAIL 三种模式，但接口职责仍耦合。

当前未存在：

- `IMediaProbe` plugin contract；
- 独立 `IThumbnailExtractor`；
- FFmpeg probe；
- FFmpeg thumbnail extractor；
- ProbePolicy / ThumbnailPolicy；
- completeness requirements；
- result merger。

## 3. 网络来源

当前支持协议：

- WebDAV：ArkTS HTTP；
- SMB：native libsmb2；
- SFTP：native libssh2；
- FTP：native；
- NFS：native libnfs；
- HTTP：直链。

`NetworkDirectoryService` 当前通过 protocol if/else 直接创建具体 browser service。虽然 core 已存在 `SourcePluginRegistry`，生产目录浏览链路尚未真正使用它。

### Random access

已有两种实现：

- `HttpRemoteReadSession`：HEAD + 精确 HTTP Range；
- `NativeRemoteReadSession`：native handle + positioned read。

因此新的 `RandomAccessSource` 不需要从零开发，可由现有 `RemoteReadSession` 演进/适配得到。

## 4. 当前媒体分析链路

网络文件当前链路：

```text
NetworkDirectoryService.openReader()
        ↓
RemoteReadSession
        ↓
NetworkFileProxy
        ↓
localhost URL
        ↓
NetworkMediaProbe
        ↓
AVMetadataExtractor
        ↓
metadata + PixelMap
        ↓
NetworkMediaLoader
        ↓
ImagePacker(WebP/JPEG)
        ↓
NetworkMediaCache
```

关键问题：`NetworkMediaLoader` 当前同时承担 orchestration、engine selection、metadata merge、thumbnail extraction、WebP/JPEG encoding、cache、retry suppression 和 timing log，职责过重。

当前缩略图：

- 网络：系统抽帧 224x126，ImagePacker 优先 WebP，失败回退 JPEG，quality 85；
- 本地 PhotoAccessHelper：224x132，内存 raw-pixel LRU；
- 持久网络图片位于 `filesDir/network-media`；
- network cache schema 9 仅持久化 duration/width/height。

## 5. 当前播放链路

```text
PlayerPage
  ↓
PlayerFeatureController
  ↓
PlaybackEngine
  ↓
PlaybackPort
  ↓
SystemPlaybackPort
  ↓
HarmonyOS AVPlayer
```

抽象层已经适合扩展双后端，但当前 `LinkoraFeatures.createPlayer()` 固定创建 `SystemPlaybackPort`。

当前远程播放有两条旧路径：

1. HTTP/HTTPS：`player.url`；
2. 非 HTTP 文件协议：ProgressiveDownloadRegistry + 增长中的本地缓存 + `AVPlayer.dataSrc`。

第二条与最新目标架构冲突：后续应迁移为 `RemoteReadSession -> MediaProxy -> backend`，progressive download 只保留迁移期 fallback，最终从 core MediaSource 中删除 `progressiveKey`。

## 6. 数据库与媒体库

当前 RDB 已到 schema 9，并已有：

- media_entity；
- media_locator；
- media_collection；
- collection_membership；
- playback_state；
- recent_entry；
- scan_checkpoint；
- network_server；
- network_media_metadata。

本地媒体：

- PhotoAccessHelper 是权威索引；
- 有完整扫描、fingerprint、stale-while-revalidate；
- 有播放进度、最近播放、手动文件来源；
- 已有取消、防抖和写队列设计。

后续无需重新设计媒体库基础表，应在现有 schema 上扩充 richer MediaInfo / probe version / thumbnail metadata。

## 7. 测试资产

仓库已有：

- `test-lab/protocols`：WebDAV / SMB / FTP / NFS 等服务；
- media compatibility sample generator；
- `PLAYBACK_TEST_MATRIX.md`；
- Network proxy/probe unit tests；
- 多个 `scripts/check-*.cjs`。

后续 Benchmark 应复用这些资产，而不是建立第二套测试目录。

## 8. 与最新规范直接冲突的旧假设

以下旧文档/实现需要后续迁移：

1. “System AVPlayer first，明确缺口才考虑 C/C++”  
   → 改为 MPV + System 双 backend；MPV 作为完整兼容路径，System 作为可选优化路径。

2. “网络文件使用 progressive download + AVDataSrcDescriptor”  
   → 改为 RandomAccessSource + MediaProxy 为第一代统一路径。

3. `NetworkMediaProbe` 同时返回 metadata + thumbnail  
   → 拆为 IMediaProbe 与 IThumbnailExtractor。

4. NetworkMediaLoader 内直接 WebP/JPEG 编码与缓存  
   → 拆为 ThumbnailProcessor / IThumbnailEncoder / ThumbnailCache。

5. JPEG fallback  
   → 最新要求为持久视频缩略图统一 WebP；若系统 WebP 编码不可用，应使用独立 WebP encoder fallback，而不是持久化 JPEG。

6. 缩略图默认接近 1 秒位置  
   → 改为 ThumbnailTimePolicy（短片 20%，普通片 min(10%,60s)）。

## 9. 当前完成度粗略映射

| 目标能力 | 当前状态 |
| --- | --- |
| Core clean architecture | 已有，需扩展 |
| MediaSource | 已有，需泛化 |
| Random access | 已有 RemoteReadSession，可演进 |
| WebDAV | 已有 |
| SMB/SFTP/FTP/NFS | 已有基础实现 |
| MediaProxy v1 | 已有 |
| System metadata | 已有 |
| System thumbnail | 已有但耦合 |
| WebP persistence | 已有但策略需重构 |
| FFmpeg analyzer | 未有 |
| MPV backend | 未有 |
| System backend | 已有 |
| Unified backend selector | 未有 |
| Local catalog/database | 已有较成熟基础 |
| Network catalog persistence | 部分已有 |
| Analysis benchmark | 有 timings/脚本基础，未形成双引擎 benchmark |
| Playback benchmark | 有矩阵基础，未形成双后端 benchmark |
