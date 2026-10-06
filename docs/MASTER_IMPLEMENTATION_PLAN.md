# HarmonyOS 网络播放器完整实施计划

## 0. 文档定位

本计划用于指导 Codex 在**现有 HarmonyOS 项目骨架**上渐进实现完整网络播放器。

核心产品方向：

```text
Local / WebDAV / SMB
        ↓
统一媒体数据源
        ↓
媒体分析 / 媒体库 / 播放
        ↓
MPV + System 双播放后端
```

不允许为了执行本计划推倒现有项目重建。

迁移原则：

```text
现有实现
   ↓
Audit
   ↓
识别可复用代码
   ↓
Contract / Adapter
   ↓
逐步切换调用方
   ↓
删除重复 Legacy
```

发生冲突时优先级：

```text
1. 本文档最新规范
2. 当前产品需求
3. 可复用的现有实现
4. 旧架构约定
```

---

# 1. 最终总体架构

```text
                         Application / UI
                               │
                        Application Services
                               │
        ┌──────────────────────┼──────────────────────┐
        ▼                      ▼                      ▼
   MediaCatalog          MediaAnalysis          PlaybackManager
        │                      │                      │
        │              ┌───────┴────────┐             │
        │              ▼                ▼             │
        │       MediaProbeService  ThumbnailService   │
        │              │                │             │
        │          ProbePolicy     ThumbnailPolicy    │
        │          /       \        /          \      │
        │      System     FFmpeg System       FFmpeg  │
        │                                            │
        ▼                                            ▼
                    MediaSource / MediaResource
                               │
                  StorageProvider Registry
                  /          |           \
               Local       WebDAV        SMB
                  \          |           /
                   RandomAccessSource
                           │
                      MediaProxy
                           │
               localhost HTTP / Range
                           │
              ┌────────────┼─────────────┐
              ▼            ▼             ▼
           System        FFmpeg          MPV
```

后期优化路径：

```text
RandomAccessSource
       │
 ┌─────┼───────────────┐
 ▼     ▼               ▼
OH_AVDataSource     AVIOContext     MPV stream callback
```

**第二代 Direct I/O 只有在 Benchmark 证明 MediaProxy 是瓶颈后才做。**

---

# 2. 强制架构原则

以下规则不得因现有骨架而妥协。

### Storage 与播放器彻底分离

禁止：

```text
MpvPlayer → WebDavClient
SystemPlayer → SmbClient
```

必须：

```text
StorageProvider
      ↓
MediaSource
      ↓
Player
```

### Metadata 与 Thumbnail 分离

必须分别存在：

```text
IMediaProbe
```

和：

```text
IThumbnailExtractor
```

允许：

```text
Metadata = FFmpeg
Thumbnail = System
```

或者反过来。

### Thumbnail Extractor 不负责 WebP

Extractor 只负责：

```text
取一帧
```

后续统一：

```text
Raw frame
↓
ThumbnailProcessor
↓
WebP Encoder
↓
ThumbnailCache
```

### System 与 FFmpeg 都是插件

业务代码不能直接：

```text
new SystemMediaProbe()
new FFmpegMediaProbe()
```

必须调用：

```text
MediaProbeService
ThumbnailService
```

### MPV 与 System Player 都是 Backend

UI 不允许知道具体播放器。

### Benchmark 决定优化策略

禁止提前写死：

```text
MKV 一定 FFmpeg
MP4 一定 System
```

必须依据实测。

---

# 3. 推荐逻辑模块

不要求现有工程严格照目录重建。

重点是依赖关系。

```text
core/
  contracts
  errors
  diagnostics
  logging
  cancellation

storage/
  core
  local
  webdav
  smb

proxy/
  core
  cache

analysis/
  core
  system
  ffmpeg

thumbnail/
  core
  system
  ffmpeg
  processor
  encoder
  cache

catalog/

player/
  core
  mpv
  system

benchmark/
```

如果现有项目已有：

```text
common/
feature/
network/
repository/
```

优先保留。

---

# 4. Core Contracts

## MediaSource

统一描述一个媒体资源。

建议：

```ts
interface MediaSource {
  id: string

  uri: string

  type:
    | 'local'
    | 'http'
    | 'webdav'
    | 'smb'
    | 'proxy'

  size?: number
  mimeType?: string

  fingerprint?: string

  credentialRef?: string

  requestHeaders?: Record<string, string>
}
```

注意：

长期持久化时不要保存明文：

```text
Authorization
Cookie
SMB Password
```

credentialRef 与运行期 session 分离。

---

# 5. Storage Contracts

## StorageProvider

```ts
interface StorageProvider {
  canHandle(uri: string): boolean

  stat(uri: string): Promise<MediaFileStat>

  list(uri: string): Promise<MediaFileEntry[]>

  open(uri: string): Promise<RandomAccessSource>
}
```

## RandomAccessSource

```ts
interface RandomAccessSource {
  readonly id: string
  readonly size?: number
  readonly seekable: boolean

  open(): Promise<void>

  readAt(
    offset: number,
    length: number
  ): Promise<ArrayBuffer>

  close(): Promise<void>
}
```

所有：

```text
Local
WebDAV
SMB
未来云盘
```

最终都映射成这个模型。

---

# 6. Storage 能力声明

除了 `readAt()`，Source 建议声明：

```ts
interface SourceCapabilities {
  seekable: boolean
  sizeKnown: boolean
  supportsRanges: boolean
  reopenable: boolean
  directUriAvailable: boolean
  fileDescriptorAvailable: boolean
}
```

不要让播放器通过协议名字猜能力。

---

# 7. Media Input Fast Path

不要强迫所有数据经过 ArkTS callback。

统一考虑：

```text
MediaResource
├─ Direct URL
├─ FD
├─ MediaProxy URL
└─ RandomAccessSource
```

选择最便宜的数据路径。

Local 优先：

```text
FD / URI
```

HTTP/WebDAV：

```text
direct URL
或
MediaProxy
```

SMB 第一代：

```text
SMB readAt
↓
MediaProxy
```

---

# 8. MediaProxy

MediaProxy 是整个网络播放器的重要基础设施，而不是 MPV 专属模块。

结构：

```text
WebDAV / SMB
      ↓
RandomAccessSource
      ↓
MediaProxy
      ↓
127.0.0.1:<port>
      ↓
System / FFmpeg / MPV
```

必须绑定：

```text
localhost only
```

避免暴露到局域网。

---

# 9. MediaProxy HTTP 能力

最低支持：

```text
GET
HEAD
Range
206 Partial Content
416 Range Not Satisfiable

Content-Length
Content-Range
Accept-Ranges
```

必须支持：

```text
取消
超时
认证失败
upstream 重连
seek 后取消旧请求
```

---

# 10. MediaProxy 缓冲

第一版：

```text
Memory Read-Ahead
```

播放器请求：

```text
64 KB
```

upstream 可以：

```text
2~4 MB
```

但必须配置化。

后续：

```text
L1 memory cache
+
L2 disk segment cache
```

不要第一版过度实现。

---

# 11. Media Metadata Architecture

Metadata 统一入口：

```text
MediaProbeService
```

插件：

```text
SystemMediaProbe
FFmpegMediaProbe
```

接口：

```ts
interface IMediaProbe {
  readonly name: string

  canProbe(source: MediaSource): Promise<boolean>

  probe(
    source: MediaSource,
    requirements: ProbeRequirements
  ): Promise<ProbeResult>
}
```

---

# 12. MediaInfo

必须覆盖媒体中心实际需要的信息。

```text
MediaInfo
├─ container
├─ duration
├─ bitrate
├─ size
├─ videoTracks[]
├─ audioTracks[]
├─ subtitleTracks[]
├─ chapters[]
└─ tags
```

Video：

```text
codec
profile
level
resolution
fps
bitrate
bit depth
pixel format
color primaries
transfer
colorspace
HDR type
Dolby Vision profile
```

Audio：

```text
codec
profile
channels
channel layout
sample rate
bitrate
language
title
default
```

Subtitle：

```text
codec
language
title
forced
default
text / bitmap
```

PGS：

```text
bitmap
```

ASS/SRT/VTT：

```text
text
```

---

# 13. ProbeRequirements

不能因为 API 没报错就认为成功。

建立场景需求：

```text
LIST
DETAIL
ADVANCED
```

LIST：

```text
duration
resolution
```

DETAIL：

```text
codec
tracks
audio
subtitle
```

ADVANCED：

```text
profile
bitDepth
HDR
DV profile
color metadata
chapters
```

如果 System 返回的信息不足：

```text
incomplete
```

而不是：

```text
failed
```

然后决定是否调用 FFmpeg。

---

# 14. ProbeResult Merge

System 和 FFmpeg 结果允许合并。

例如：

```text
System:
duration ✅
width ✅
height ✅

FFmpeg:
Dolby Vision ✅
chapters ✅
```

最终：

```text
Merged MediaInfo
```

Diagnostics 保留：

```text
duration → system
dolbyVisionProfile → ffmpeg
chapters → ffmpeg
```

方便排错。

---

# 15. System Media Probe

System Probe 第一阶段负责：

```text
基础容器
duration
resolution
普通 codec
bitrate
fps
普通 tracks
```

系统拿不到的信息：

```text
undefined
```

禁止伪造。

---

# 16. FFmpeg Media Probe

FFmpeg 不以 CLI 形式集成。

禁止：

```text
ffmpeg executable
ffprobe executable
```

建立：

```text
libmediaprobe.so
```

主要使用：

```text
libavformat
libavcodec
libavutil
libswscale
```

Metadata：

```text
avformat_open_input
↓
avformat_find_stream_info
↓
AVStream / AVCodecParameters
↓
metadata / side data / chapters
```

---

# 17. FFmpeg Remote I/O

第一代：

```text
FFmpeg
↓
MediaProxy URL
```

不要第一版实现：

```text
ArkTS readAt
↕
Native AVIOContext
```

第二代优化再考虑。

---

# 18. Thumbnail 架构

独立入口：

```text
ThumbnailService
```

结构：

```text
ThumbnailService
      ↓
ThumbnailTimePolicy
      ↓
ThumbnailPolicy
      ↓
IThumbnailExtractor
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

---

# 19. Thumbnail Extractor

接口：

```ts
interface IThumbnailExtractor {
  readonly name: string

  extract(
    source: MediaSource,
    request: ThumbnailExtractRequest
  ): Promise<RawThumbnail>
}
```

实现：

```text
SystemThumbnailExtractor
FFmpegThumbnailExtractor
```

System 可返回：

```text
PixelMap
```

FFmpeg 可返回：

```text
RGBA buffer
```

---

# 20. Thumbnail Time Policy

默认不要取：

```text
0 秒
```

基础算法：

```text
duration < 30 秒
→ 20%

duration >= 30 秒
→ min(10%, 60 秒)
```

后期可增加：

```text
SmartThumbnailPolicy
```

多个候选帧：

```text
黑屏检测
低亮度检测
视觉信息量
```

第一版不要实现智能选帧。

---

# 21. Thumbnail Processor

负责：

```text
rotation
resize
aspect ratio
pixel conversion
```

默认：

```text
maxWidth = 480
maxHeight = 270
mode = fit
```

禁止拉伸。

---

# 22. WebP

所有新生成持久化视频缩略图统一：

```text
.webp
```

默认：

```text
quality = 80
```

配置化。

WebP 编码与 FFmpeg 解码分离。

FFmpeg Thumbnail 不直接输出 `.webp`。

---

# 23. Thumbnail Cache Key

必须包含：

```text
mediaFingerprint
frameTime
maxWidth
maxHeight
resizeMode
quality
algorithmVersion
```

例如：

```text
algorithmVersion = 1
```

以后改算法只升级版本即可自动失效。

---

# 24. Media Fingerprint

Remote：

```text
canonical URI
size
ETag
Last-Modified
```

Local：

```text
path
size
mtime
```

不要仅使用文件名。

---

# 25. MPV 播放器

MPV 是第一套正式播放 Backend。

推荐先使用现有成熟 HarmonyOS libmpv 封装，而不是从零实现播放器。

接口：

```ts
interface IPlayerBackend {
  open(source: MediaSource, options?: PlaybackOptions): Promise<void>

  play(): void
  pause(): void
  seek(positionMs: number): void
  stop(): void
  release(): void
}
```

---
# 26. Unified Player State

统一状态：

```text
IDLE
PREPARING
READY
PLAYING
PAUSED
SEEKING
BUFFERING
ENDED
ERROR
```

注意：

> 不只是统一枚举名称，还要统一事件语义。

---

# 27. Player Events

至少统一：

```text
state
position
duration
buffering
buffer position

video tracks
audio tracks
subtitle tracks

speed
volume

video size
HDR info

first frame
seek completed
ended
error
```

---

# 28. Player 生命周期

统一：

```text
create
↓
attachSurface
↓
open / prepare
↓
play / pause / seek
↓
stop
↓
detachSurface
↓
release
```

禁止不同 Backend 自己决定 UI 生命周期。

---

# 29. Playback MediaSource

播放层不得知道：

```text
WebDAV password
SMB implementation
HTTP cache
```

只接收：

```text
MediaSource / ResolvedMediaInput
```

---

# 30. System Player

System Player 后加入。

最终：

```text
UnifiedPlayer
      ↓
BackendSelector
   /        \
System     MPV
```

用户模式：

```text
Auto
System
MPV
```

---

# 31. BackendSelector

不能只看扩展名。

System 可播放条件：

```text
source ingestion
∩
container
∩
video codec
∩
profile
∩
bit depth
∩
HDR capability
∩
audio codec
∩
subtitle
∩
output capability
```

全部满足：

```text
System
```

否则：

```text
MPV
```

---

# 32. Backend Fallback

允许：

```text
System prepare/open 失败
↓
MPV fallback
```

原则：

```text
每次 Session 最多一次 fallback
```

不要：

```text
播放过程中 System ↔ MPV 来回切换
```

Fallback 需要尽量保留：

```text
position
audio track
subtitle
speed
play intent
headers/source
```

---

# 33. MPV Codec 路线

MPV：

```text
container
↓
FFmpeg demux
↓
codec
```

支持：

```text
能硬解 → HarmonyOS hardware decode
不能硬解 → FFmpeg software decode
```

不等于：

```text
实时转码
```

---

# 34. Decode / Passthrough / Transcode

必须在代码和文档里严格区分。

Decode：

```text
DTS
↓
PCM
```

Passthrough：

```text
DTS
↓
原始 bitstream
↓
AVR
```

Transcode：

```text
DTS
↓
PCM
↓
AAC/AC3
```

三者不同。

---

# 35. HDR / Dolby Vision

HDR10/HLG：

```text
10-bit decode
↓
HDR render path
↓
HDR output surface
```

如果 HDR 输出不可用：

```text
tone mapping
↓
SDR
```

Dolby Vision：

```text
video base layer
+
DV metadata
```

MPV/FFmpeg/libplacebo 可以做 DV-aware 处理。

但：

```text
DV-aware playback
≠
native Dolby Vision output/certification
```

必须在 Capability 中区别。

---

# 36. Audio

需要区分：

```text
AC3
EAC3
DTS
DTS-HD
TrueHD
Atmos
DTS:X
```

MPV/FFmpeg 可以技术上直接解码很多格式。

但：

```text
TrueHD → PCM
```

不一定保留 Atmos object rendering。

DTS-HD → PCM 同理。

对象音频保持需要另外验证：

```text
bitstream passthrough
```

---

# 37. Subtitle

至少支持模型：

```text
Text subtitle
├─ SRT
├─ ASS
└─ VTT

Bitmap subtitle
└─ PGS
```

ASS：

```text
文本/样式渲染
```

PGS：

```text
位图字幕
```

绝对不能混用同一处理逻辑。

---

# 38. Media Catalog

完成 Storage + Analysis + Thumbnail 后建立媒体库。

结构：

```text
StorageProvider.list()
      ↓
MediaScanner
      ↓
MediaSource
      ↓
MediaProbeService
      ↓
ThumbnailService
      ↓
MediaRepository
      ↓
Database
```

---

# 39. Media Scanner

必须支持：

```text
增量扫描
取消
重试
并发限制
目录变化检测
fingerprint
```

不能每次重新分析整个 NAS。

---

# 40. Probe 并发

初始建议：

```text
Metadata:
2~4

Thumbnail:
1~2
```

这不是永久值。

Benchmark 后调整。

---

# 41. Media Database

至少存：

```text
media id
source id
path
fingerprint

size
mtime / etag

duration
container

tracks
HDR

thumbnail key

last played
resume position

scan status
probe version
```

Metadata schema 需要：

```text
schemaVersion
```

方便以后升级。

---

# 42. Jellyfin / Emby / Plex

以后作为：

```text
Remote Media Repository / Resolver
```

而不是播放器 Backend。

职责：

```text
获取 MediaSource
选择版本
外部字幕
resume position
DirectPlay / Transcode URL
```

播放器仍然只接收最终 MediaSource。

---

# 43. Direct Play

播放器本地 decode 不等于 server transcode。

典型：

```text
NAS/Jellyfin 原始 MKV
↓
HTTP Range
↓
MPV
↓
local decode
```

这是 Direct Play。

---

# 44. Seek

Seek 不是：

```text
时间 → 固定 byte offset
```

正确流程：

```text
container index / keyframe
↓
定位附近 byte range
↓
random read
↓
decode forward
↓
target frame
```

不要在 Storage 层实现“时间换 byte”。

---

# 45. SMB

SMB 作为 StorageProvider。

实现：

```text
SmbStorageProvider
SmbRandomAccessSource
```

需要：

```text
long-lived handle
positioned reads
connection reuse
reconnect
timeout
cancellation
```

新增 SMB 后：

```text
Probe
Thumbnail
Player
```

应该基本不用修改。

否则说明抽象泄漏。

---

# 46. Logging

统一 Logger。

每次请求建议包含：

```text
traceId
sourceId
engine
backend
operation
elapsed
bytesRead
rangeRequests
fallback
error
```

禁止记录：

```text
Authorization
Cookie
password
SMB credential
```

---

# 47. Cancellation

Cancellation 必须是一等公民。

以下操作都必须可取消：

```text
directory scan
WebDAV request
SMB request
thumbnail
metadata probe
MediaProxy upstream
player open
seek-related fetch
```

用户离开页面后不允许继续偷偷 decode。

---

# 48. Error Model

统一错误类型。

至少：

```text
UNSUPPORTED_FORMAT

OPEN_FAILED

NETWORK_FAILED

AUTH_FAILED

RANGE_NOT_SUPPORTED

SEEK_FAILED

DEMUX_FAILED

DECODE_FAILED

THUMBNAIL_FAILED

PLAYER_PREPARE_FAILED

TIMEOUT

CANCELLED

UNKNOWN
```

Native error 原始信息放：

```text
diagnostics
```

不要直接暴露给 UI。

---

# 49. Benchmark：Media Analysis

比较：

```text
System
vs
FFmpeg
```

Metadata：

```text
success rate
completeness
open time
probe time
total
bytes read
range count
memory
```

Thumbnail：

```text
open
seek
decode
resize
WebP encode
disk write
total
bytes read
range requests
WebP size
```

---

# 50. Benchmark：Playback

比较：

```text
MPV
vs
System
```

至少：

```text
first frame

seek p50
seek p95

buffering count
buffering duration

CPU
memory
temperature
power

HDR output
audio behavior
subtitle correctness
```

---

# 51. 固定测试媒体矩阵

建立永久测试集：

```text
MP4 H264 AAC
MP4 HEVC AAC

MKV H264
MKV HEVC
HEVC Main10

HDR10
HLG
Dolby Vision

AC3
EAC3

DTS
DTS-HD MA

TrueHD

ASS
PGS

multiple audio tracks
multiple subtitles

long GOP

4K remux

broken / unusual container
```

来源：

```text
Local
WebDAV
SMB
```

---

# 52. Security

网络凭据：

```text
CredentialStore / secure storage
```

不要：

```text
保存进 URL
打印日志
保存进 thumbnail cache key
```

MediaProxy URL 建议：

```text
随机 session/token
```

不要把 upstream credential 放 query string。

---

# 53. 第三方 Native 依赖

建立：

```text
THIRD_PARTY.md
```

记录：

```text
mpv
FFmpeg
libplacebo
libass
libwebp（如果使用）
SMB library
```

包括：

```text
版本
编译参数
来源
patch
ABI
```

方便后期升级。

---

# 54. 构建与 ABI

第一版重点：

```text
arm64
```

Native module 必须统一：

```text
toolchain
API level
C++ runtime
build flags
```

不要让：

```text
mpv native
FFmpeg probe
SMB native
```

各用完全不同构建体系。

---

# 55. FFmpeg 与 MPV FFmpeg 重复问题

第一版允许：

```text
MPV 内部 FFmpeg
+
MediaProbe 自己 FFmpeg
```

因为开发简单。

不要第一阶段为了减少体积重构成共享 FFmpeg。

后期 Benchmark：

```text
HAP size
memory
maintenance cost
```

再决定是否共享。

---

# 56. Codex 迁移策略

项目已有骨架，因此整个实施使用：

```text
Strangler Pattern
```

原则：

```text
新接口建立
↓
旧代码 Adapter
↓
新调用使用新接口
↓
旧调用逐步 delegate
↓
确认无调用
↓
删除 legacy
```

---

# 57. Phase 0 — 全仓库 Audit

**不改业务代码。**

Codex 输出：

```text
ARCHITECTURE_CURRENT.md

ARCHITECTURE_TARGET.md

ARCHITECTURE_MIGRATION.md

MIGRATION_CALLSITES.md
```

检查整个项目：

```text
models

network

HTTP

WebDAV

SMB

storage

metadata

thumbnail

image cache

proxy

database

scanner

MPV

AVPlayer

native

DI

repository

viewmodel

UI

tests
```

不得只检查缩略图。

完成后停止。

---

# 58. Phase 1 — Contracts + Adapter 层

建立或映射：

```text
MediaSource

StorageProvider
RandomAccessSource

MediaInfo

IMediaProbe

IThumbnailExtractorIThumbnailEncoder

IPlayerBackend

Errors
Cancellation
Diagnostics
```

如果已有类似模型：

```text
优先 Adapter
```

不要全项目强制换类型。

验收：

```text
现有功能不变化
项目正常编译
无循环依赖
```

---

# 59. Phase 2 — Local + WebDAV Storage

先完成：

```text
LocalStorageProvider
WebDavStorageProvider
```

以及：

```text
readAt
```

WebDAV 至少验证：

```text
PROPFIND
stat
list
Range
auth
redirect
cancel
ETag
Last-Modified
```

远程大文件不能整文件下载。

---

# 60. Phase 3 — System Media Analysis

实现：

```text
SystemMediaProbe
SystemThumbnailExtractor
```

但两者独立。

同时建立：

```text
MediaProbeService
ThumbnailService
```

先只注册 System。

---

# 61. Phase 4 — WebP Thumbnail Pipeline

完成：

```text
ThumbnailTimePolicy

ThumbnailProcessor

WebPEncoder

ThumbnailCache
```

从此：

```text
新生成视频缩略图统一 WebP
```

默认：

```text
480×270 bounding box
quality 80
```

旧缓存可 Lazy Migration。

---

# 62. Phase 5 — MediaProxy v1

实现统一：

```text
localhost Range HTTP
```

支持：

```text
HEAD
GET
206
416
cancel
read ahead
```

让：

```text
System Probe
System Thumbnail
```

可以通过同样路径测试 WebDAV。

---

# 63. Phase 6 — FFmpeg Analysis

接入：

```text
libmediaprobe.so
```

实现：

```text
FFmpegMediaProbe

FFmpegThumbnailExtractor
```

远程第一版：

```text
MediaProxy URL
```

Extractor 仍然不输出 WebP。

---

# 64. Phase 7 — Analysis Benchmark + Policy

现在比较：

```text
System vs FFmpeg
```

产生：

```text
benchmark-analysis.json
benchmark-analysis.md
```

然后才建立最终：

```text
ProbePolicy
ThumbnailPolicy
CompletenessEvaluator
ProbeResultMerger
```

Baseline 可以：

```text
System → FFmpeg
```

但优化策略必须有数据。

---

# 65. Phase 8 — MPV Player MVP

接入 MPV Backend。

完成：

```text
open
play
pause
stop
seek

position
duration
buffering

video/audio/subtitle tracks

external subtitle

speed
volume

first frame
ended
error
```

网络：

```text
WebDAV
↓
MediaProxy
↓
MPV
```

Local 走 direct fast path。

---

# 66. Phase 9 — SMB

现在加入：

```text
SmbStorageProvider
SmbRandomAccessSource
```

然后验证：

```text
Probe
Thumbnail
MPV
```

不需要修改核心。

---

# 67. Phase 10 — Media Catalog

建立：

```text
MediaScanner

MediaRepository

MediaDatabase
```

接入：

```text
Local
WebDAV
SMB
```

实现：

```text
incremental scan
fingerprint
metadata
thumbnail
history
resume
```

---

# 68. Phase 11 — System Player Backend

完成：

```text
SystemPlayerBackend
```

以及：

```text
UnifiedPlayer
BackendSelector
CapabilityChecker
```

用户：

```text
Auto
System
MPV
```

---

# 69. Phase 12 — Playback Benchmark

System vs MPV。

结果决定 Auto 策略。

不要只按：

```text
extension
codec
```

做选择。

---

# 70. Phase 13 — 高级影音

逐项验证：

```text
HDR10

HLG

Dolby Vision profiles

DTS

DTS-HD MA

TrueHD

Atmos behavior

DTS:X behavior

Audio Vivid

ASS

PGS

hardware decode

audio passthrough
```

每项明确：

```text
supported
degraded
fallback
unsupported
```

---

# 71. Phase 14 — 第二代 Direct I/O

仅当 Benchmark 证明必要。

替代：

```text
localhost HTTP
```

部分场景改为：

```text
OH_AVDataSource

FFmpeg AVIOContext

MPV stream callback
```

不能因为“架构更漂亮”就实现。

---

# 72. Phase 15 — 稳定性与 Release Hardening

完成：

```text
network switch

sleep / wake

background / foreground

NAS disconnect

credential expiration

disk full

cache corruption

large library

low memory

player crash recovery
```

并建立长期回归测试。

---

# 73. Codex 每阶段执行规范

每次只允许执行：

```text
一个 Phase
```

除非任务明确批准跨 Phase。

开始前必须：

```text
阅读 ARCHITECTURE_TARGET.md

检查现有代码

输出计划修改文件

说明为什么改
```

再编码。

---

# 74. 每阶段结束要求

必须运行：

```text
build
lint
unit tests
integration tests
```

能够真机验证的注明：

```text
DEVICE TESTED
```

没有验证的明确：

```text
NOT DEVICE TESTED
```

不得虚构。

---

# 75. 每阶段报告模板

Codex 输出：

```text
Phase:

Goal:

Files changed:

Existing code reused:

Adapters introduced:

Public APIs changed:

Tests executed:

Results:

Known limitations:

Architecture deviations:

Performance observations:

Next blockers:
```

---

# 76. 禁止 Codex 的行为

禁止：

```text
看到新规范就重新建第二套架构
```

禁止：

```text
未经要求大规模移动目录
```

禁止：

```text
顺手改无关 UI
```

禁止：

```text
同一功能保留两套长期实现
```

禁止：

```text
FFmpeg 自己访问 WebDAV
```

禁止：

```text
Player 自己实现 SMB
```

禁止：

```text
ThumbnailExtractor 直接生成 WebP 文件
```

禁止：

```text
Metadata 与 Thumbnail 重新绑在一起
```

禁止：

```text
未 Benchmark 就写死性能路由
```

禁止：

```text
一次实现所有 Phase
```

---

# 77. 第一轮 Codex 任务

现在不要让 Codex直接写 FFmpeg、WebP 或 Player。

第一轮只执行：

```text
Phase 0
```

任务要求：

```text
完整 Audit 当前仓库。
```

必须覆盖：

```text
整个播放器
```

而不是：

```text
只看 metadata / thumbnail
```

输出：

```text
ARCHITECTURE_CURRENT.md
ARCHITECTURE_TARGET.md
ARCHITECTURE_MIGRATION.md
MIGRATION_CALLSITES.md
```

完成后立即停止。

---

# 78. Phase 0 审核通过标准

我们人工检查：

```text
现有哪个模块负责什么

哪些可以直接复用

哪些需要 Adapter

哪些存在边界冲突

哪些实现重复

现有 WebDAV 成熟度

现有播放器成熟度

现有 Metadata / Thumbnail 耦合情况

现有 Proxy 是否存在

现有 Cache 是否可复用

现有 Database 是否可扩展

现有 Native 构建系统能否承载 FFmpeg
```

确认后才进入 Phase 1。

---

# 79. 最终架构成功判据

新增：

```text
SFTP
```

应该只主要新增：

```text
SftpStorageProvider
```

新增新的 Metadata engine：

```text
implements IMediaProbe
```

新增新的 Thumbnail engine：

```text
implements IThumbnailExtractor
```

改 WebP → AVIF：

```text
implements IThumbnailEncoder
```

增加新播放器：

```text
implements IPlayerBackend
```

如果每次加新能力都要修改大量无关模块：

```text
架构失败
```

---

# 80. 最终研发顺序总览

```text
Phase 0
Existing Project Audit
        ↓
Phase 1
Contracts + Adapters
        ↓
Phase 2
Local + WebDAV Storage
        ↓
Phase 3
System Metadata + System Thumbnail
        ↓
Phase 4
WebP Thumbnail Pipeline
        ↓
Phase 5
MediaProxy
        ↓
Phase 6
FFmpeg Metadata + Thumbnail
        ↓
Phase 7
Analysis Benchmark + Policies
        ↓
Phase 8
MPV Player MVP
        ↓
Phase 9
SMB
        ↓
Phase 10
Media Catalog / Scanner / Database
        ↓
Phase 11
System Player + UnifiedPlayer
        ↓
Phase 12
Playback Benchmark + BackendSelector
        ↓
Phase 13
HDR / DV / Advanced Audio / Subtitle
        ↓
Phase 14
Direct I/O Optimization
        ↓
Phase 15
Stability / Release Hardening
```

这就是当前项目完整的技术实施基线。

除非后续 Benchmark、HarmonyOS API 限制或者真实代码结构证明某个假设不成立，否则后续所有 Codex 任务都应以这份架构作为约束。
