# Linkora 目标架构（最新规范）

> 项目最高级技术实施基线是 `docs/MASTER_IMPLEMENTATION_PLAN.md`。本文是其当前工程化目标架构；若本文与更旧架构文档冲突，以本文为准；若与 Master Plan 或后续明确审核通过的架构决策冲突，以 Master Plan / 后续审核决策为准。

## 1. 目标

Linkora 最终是一个网络媒体播放器，而不是单一 AVPlayer 包装器。

主要来源：

```text
Local / HTTP / WebDAV / SMB / SFTP / FTP / NFS
```

核心能力：

```text
Storage
  ↓
MediaSource / ResolvedMediaInput
  ├─ Media Analysis
  ├─ Media Catalog
  └─ Playback
```

播放后端：

```text
UnifiedPlayer
     ↓
BackendSelector
  /             \
MPV             System
```

## 2. 强制模块边界

### Storage

协议层只负责：

- list/stat；
- open random access；
- auth/reconnect；
- cancel/close。

不得依赖播放器、FFmpeg、UI。

目标 contract：

```text
StorageProvider
  ↓
RandomAccessSource
  - size?
  - seekable
  - supportsRanges
  - reopenable
  - readAt(offset,length)
  - cancel
  - close
```

现有 `RemoteReadSession` 应通过兼容迁移升级到该模型。

### MediaSource 与 ResolvedMediaInput

`MediaSource` 表示稳定媒体身份，不承载临时 progressive task。

解析后根据 backend 选择最便宜输入：

```text
ResolvedMediaInput
├─ direct URL + headers
├─ local fd / uri
├─ MediaProxy URL
└─ future direct random-access handle
```

凭据使用 credential reference，不进入日志、URL 或缓存 key。

## 3. MediaProxy

第一代统一远程文件入口：

```text
RandomAccessSource
       ↓
MediaProxy
       ↓
127.0.0.1
       ↓
System / FFmpeg / MPV
```

第一阶段保留现有 `linkora_proxy`，升级为共享基础设施：

- GET/HEAD/Range；
- 206/416；
- source lease；
- cancellation；
- read-ahead；
- 可选 segment cache；
- diagnostics；
- app/session 级生命周期。

Direct URL 仍允许作为 fast path，但不能让业务层根据协议写 if/else。

## 4. Media Analysis

Metadata 和 Thumbnail 必须拆开。

```text
MediaProbeService
  ↓
ProbePolicy
  ├─ SystemMediaProbe
  └─ FFmpegMediaProbe
```

```text
ThumbnailService
  ↓
ThumbnailPolicy
  ├─ SystemThumbnailExtractor
  └─ FFmpegThumbnailExtractor
        ↓
RawThumbnail
        ↓
ThumbnailProcessor
        ↓
IThumbnailEncoder
        ↓
WebP
        ↓
ThumbnailCache
```

允许 Metadata 与 Thumbnail 选择不同 engine。

### Probe requirements

至少分：

- LIST；
- DETAIL；
- ADVANCED。

System 结果不足不是 failure，而是 incomplete。必要时调用 FFmpeg 补充，并由 ProbeResultMerger 合并字段，同时 diagnostics 保存字段来源。

### FFmpeg

App 不集成 ffmpeg / ffprobe CLI。

建立 Native media analysis module，第一版使用：

- libavformat；
- libavcodec；
- libavutil；
- libswscale。

远程文件第一代统一通过 MediaProxy URL。

## 5. Thumbnail

持久视频缩略图统一 WebP。

基础默认值：

- maxWidth 480；
- maxHeight 270；
- fit，保持 aspect ratio；
- quality 80，可配置；
- algorithmVersion 写入 cache key。

Extractor 不负责编码和磁盘。

时间策略：

- duration < 30s：20%；
- 其他：min(duration * 10%, 60s)。

若 HarmonyOS ImagePacker 的 WebP encoder 在目标设备不可用，应接独立 WebP encoder fallback，而不是长期 JPEG fallback。

## 6. Playback

保留并扩展现有：

`PlaybackEngine -> PlaybackPort`

目标语义提升为：

```text
UnifiedPlayer / PlaybackEngine
       ↓
IPlayerBackend
       ├─ MpvPlayerBackend
       └─ SystemPlayerBackend
```

统一状态至少：

- IDLE；
- PREPARING；
- READY；
- PLAYING；
- PAUSED；
- SEEKING；
- BUFFERING；
- ENDED；
- ERROR。

统一事件至少：

- duration/position；
- buffered duration/percent；
- first frame；
- seek completed；
- video size；
- video/audio/subtitle tracks；
- selected tracks；
- speed/volume；
- HDR/output info；
- backend diagnostics；
- ended/error。

### Backend selection

Auto 模式不能只看扩展名：

```text
input capability
∩ container
∩ video codec/profile/bitDepth
∩ HDR
∩ audio
∩ subtitle
∩ output capability
```

全部满足才选择 System，否则 MPV。

System prepare/open 失败允许单次 fallback MPV，尽量保留 position/tracks/subtitle/speed/play intent。

## 7. Media Catalog

复用现有 RDB 与 LocalMediaScanner。

新增远程媒体目录扫描时沿用：

```text
StorageProvider.list
   ↓
MediaScanner
   ↓
MediaProbeService
   ↓
ThumbnailService
   ↓
Repository / RDB
```

支持：

- incremental scan；
- fingerprint；
- cancellation；
- retry；
- concurrency control；
- probe version / thumbnail algorithm version。

## 8. HDR / DV / Audio / Subtitle

高级兼容能力后置验证，但架构需提前容纳。

视频：

- HDR10；
- HLG；
- Dolby Vision profile；
- bit depth；
- color primaries / transfer / colorspace。

音频：

- AC3/EAC3；
- DTS/DTS-HD；
- TrueHD；
- Atmos/DTS:X 的 decode 与 passthrough 区分。

字幕：

- ASS/SRT/VTT = text；
- PGS = bitmap。

必须严格区分：

- decode；
- passthrough；
- transcode；
- remux；
- direct play。

## 9. 第二代 Direct I/O

只有 Benchmark 证明 MediaProxy 是瓶颈才实现：

- System：OH_AVDataSource；
- FFmpeg：AVIOContext；
- MPV：libmpv stream callback。

不能因为“更优雅”提前增加复杂度。

## 10. Benchmark

分析：

- System vs FFmpeg；
- success rate；
- completeness；
- bytes read；
- Range requests；
- open/probe/decode/encode time；
- p50/p95；
- memory。

播放：

- MPV vs System；
- first frame；
- seek p50/p95；
- buffering；
- CPU/GPU/memory/power；
- HDR/audio/subtitle correctness。

性能策略必须基于数据。
