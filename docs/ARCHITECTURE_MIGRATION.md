# Linkora 架构迁移计划

> 本文服从 `docs/MASTER_IMPLEMENTATION_PLAN.md` 的总体技术基线，并描述当前代码如何渐进迁移到 `docs/ARCHITECTURE_TARGET.md`。阶段性验证若推翻某个假设，应先记录证据和审核决策，再更新迁移路径；不得静默偏离 Master Plan。

## 1. 迁移原则

采用 Strangler Migration，不重建平行系统。

```text
现有实现
  ↓
Contract / Adapter
  ↓
新 Service / Policy
  ↓
迁移调用方
  ↓
删除 Legacy
```

业务可用代码优先复用；边界冲突时以最新目标架构为准。

## 2. 现有到目标映射

| 目标角色 | 当前实现 | 处理 |
| --- | --- | --- |
| MediaSource | linkora_core MediaSource | 演进；移除 progressiveKey 泄漏，增加 stable identity / source descriptor |
| StorageProvider | 各 BrowserService | 通过 Adapter/Plugin 收口，不重写协议 |
| RandomAccessSource | RemoteReadSession | 演进/别名迁移，增加 capabilities |
| Plugin registry | SourcePluginRegistry | 保留并真正用于生产装配 |
| MediaProxy | linkora_proxy NetworkFileProxy | 保留，升级为共享基础设施 |
| SystemMediaProbe | NetworkMediaProbe metadata mode | 拆出独立实现 |
| SystemThumbnailExtractor | NetworkMediaProbe thumbnail mode | 拆出独立实现 |
| MediaProbeService | 无 | 新增 |
| ThumbnailService | NetworkMediaLoader 部分职责 | 新增并迁出职责 |
| ThumbnailProcessor | NetworkMediaLoader 内隐式 | 新增 |
| WebP Encoder | ImagePacker inline | 抽成 IThumbnailEncoder |
| ThumbnailCache | NetworkMediaCache | 保留并适配 |
| FFmpegMediaProbe | 无 | 新增 Native module |
| FFmpegThumbnailExtractor | 无 | 新增 |
| Playback backend contract | PlaybackPort | 扩展，不重建 |
| System backend | SystemPlaybackPort | 保留并适配 |
| MPV backend | 无 | 新增 |
| Unified selector | 无 | 新增 BackendSelector/CapabilityChecker |
| Media catalog | LocalMediaScanner + RDB | 保留扩展 |
| Benchmark | timings + scripts + test-lab | 复用并系统化 |

## 3. 推荐执行顺序

### Phase A — Core contract alignment

不改 UI。

1. 扩充 source capability 模型；
2. 为 RemoteReadSession 增加/适配 RandomAccessSource 语义；
3. 引入 MediaInfo / TrackInfo；
4. 引入 IMediaProbe / IThumbnailExtractor / IThumbnailEncoder；
5. 扩展 PlaybackPort 能力模型；
6. 为旧 public API 提供兼容 adapter。

验收：现有功能和测试全部不变。

### Phase B — Storage plugin productionization

目标：让生产代码真正通过统一 Storage contract。

- WebDAVBrowserService -> Storage/Source adapter；
- SMB/SFTP/FTP/NFS -> adapter；
- NetworkDirectoryService 从 protocol if/else 迁移到 registry；
- 保留现有 native reader 和 browser，不重写底层协议。

验收：五种协议目录浏览与 openReader 行为不回退。

### Phase C — Split System analysis

将 `NetworkMediaProbe` 拆成：

- SystemMediaProbe；
- SystemThumbnailExtractor。

建立：

- MediaProbeService；
- ThumbnailService；
- ProbeRequirements；
- CompletenessEvaluator。

NetworkMediaLoader 不再直接 new Probe。

### Phase D — WebP thumbnail pipeline

把 NetworkMediaLoader 中：

- frame selection；
- resize；
- ImagePacker；
- WebP/JPEG；
- cache 写入

拆到独立 pipeline。

规范：

- persistent video thumbnail = WebP；
- 480x270 bounding box；
- quality 80；
- ThumbnailTimePolicy；
- algorithmVersion；
- 无 JPEG 长期 fallback。

现有 NetworkMediaCache 保留，改为 ThumbnailCache adapter。

### Phase E — MediaProxy production path

保留 `linkora_proxy`，但升级：

- 由 LinkoraFeatures/专用 service 管理共享实例；
- remote storage playback 与 analysis 都能获得 proxy lease；
- 加 diagnostics；
- 后续增加 configurable read-ahead；
- progressive download 不再是新功能默认路径。

此阶段仍保留 ProgressiveDownloadRegistry 作为兼容 fallback。

### Phase F — FFmpeg analysis

新增 Native `linkora_media_analysis`（最终命名可调整）：

- libavformat；
- libavcodec；
- libavutil；
- libswscale。

实现：

- FFmpegMediaProbe；
- FFmpegThumbnailExtractor。

远程输入先用 MediaProxy。

### Phase G — Analysis benchmark and policy

使用 test-lab 固定样本对比：

- System；
- FFmpeg。

输出 machine-readable JSON + Markdown 报告。

之后才允许针对格式/来源调整 ProbePolicy 和 ThumbnailPolicy。

### Phase H — MPV backend

引入 HarmonyOS libmpv 封装。

新增 MpvPlaybackPort / MpvPlayerBackend，并复用现有 PlaybackEngine。

第一阶段不要删除 SystemPlaybackPort。

网络文件统一优先走 MediaProxy。

### Phase I — Dual backend

增加：

- CapabilityChecker；
- BackendSelector；
- user preference Auto/System/MPV；
- System open/prepare failure -> one-shot MPV fallback。

扩展 PlaybackSnapshot：

- SEEKING；
- tracks；
- selected track；
- HDR/output diagnostics；
- buffered duration；
- seek complete。

### Phase J — Remove progressive download coupling

当 Proxy + MPV/System 已覆盖远程播放后：

1. 停止新建 ProgressiveDownloadTask；
2. `MediaSource.progressiveKey` 标记 deprecated；
3. 迁移全部 caller；
4. 删除 SystemPlaybackPort progressive dataSrc 路径；
5. 删除 Registry。

不能提前删除，避免迁移期回归。

### Phase K — Catalog enrichment

复用现有 schema：

- richer media tracks；
- probe version；
- thumbnail record；
- source fingerprint；
- remote scan checkpoints。

避免把所有 track 信息硬塞回旧 `network_media_metadata(duration,width,height)` 表。

### Phase L — Advanced AV

按固定矩阵验证：

- HDR10/HLG；
- DV profiles；
- DTS/DTS-HD；
- TrueHD；
- Atmos/DTS:X；
- ASS/PGS；
- hardware decode；
- passthrough。

### Phase M — Direct I/O optional optimization

仅在 Benchmark 证明需要时：

- OH_AVDataSource；
- FFmpeg AVIOContext；
- mpv stream callback。

## 4. 必须保留的现有资产

不要重写：

- LinkoraDatabase transaction/write queue；
- LocalMediaScanner；
- PlaybackBookmarkStore；
- RecentMediaStore；
- Credential store；
- native SMB/SFTP/NFS/FTP readers；
- protocol test lab；
- NetworkFileProxy Range parser/lease ownership；
- PlaybackEngine session-id stale event protection；
- FailureCatalog/Error model；
- LinkoraFeatures 作为默认 dependency composition root。

## 5. 必须拆分的现有职责

### NetworkMediaLoader

当前职责过多，应最终只负责兼容 facade 或被更高层 service 替代。

拆出：

- source resolver；
- probe orchestration；
- thumbnail orchestration；
- encoding；
- cache；
- retry policy；
- diagnostics。

### NetworkMediaProbe

拆成 Metadata / Thumbnail 两个 plugin。

### SystemPlaybackPort

保留 System backend 能力；去除 progressive-download 特有逻辑。

## 6. 文档冲突迁移

后续在代码迁移完成时同步更新：

- `docs/ARCHITECTURE.md`
- `docs/MODULE_BOUNDARIES.md`
- `docs/NETWORK_SOURCE_PLAN.md`
- `docs/PLAYBACK_TEST_MATRIX.md`

在迁移完成前，旧文档中 System-first / progressive-download 内容视为 legacy 描述，不再作为新功能设计依据。
