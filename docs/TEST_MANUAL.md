# Linkora 完整测试手册

> 适用基线：播放器架构 Phase 0–7 代码完成后。  
> 目标：验证 Storage、MediaProxy、System Media Analysis、WebP Thumbnail、System/MPV 双后端、媒体库、网络协议以及稳定性。

## 1. 测试前置条件

### 开发环境

- DevEco Studio，SDK 26.0.0。
- HarmonyOS target API 26。
- arm64 真机。
- Node/PowerShell 环境可执行仓库 scripts。
- 执行 `ohpm install`，确认 `@mpv-ohos/mpv-arkts@1.0.0` 成功解析。
- 不手工伪造 package lock。

### 构建前检查

运行：

```powershell
./scripts/verify.ps1
```

必须完成：

- architecture boundary check
- persistence checks
- proxy checks
- media probe checks
- unit-test compilation
- unit tests
- Debug/Release HAR
- Debug/Release HAP

任何一步失败都不要继续做性能结论。

## 2. 架构边界测试

运行：

```powershell
node scripts/check-architecture-boundaries.cjs
```

必须输出：

```text
Architecture boundary checks passed.
```

重点确认：

- linkora_core 不依赖 @kit。
- Player 不直接依赖 WebDAV/SMB/SFTP/FTP/NFS。
- MediaProbe 不负责 WebP/cache。
- UI 不直接 import MPV/System backend。
- NetworkDirectoryService 不重新出现协议 if/else。

## 3. 单元测试

运行 Hvigor entry unit tests。

必须重点覆盖：

- MediaSource remote identity。
- RemoteReadSession <-> RandomAccessSource adapters。
- Storage provider registry。
- Range 200/206/416。
- Proxy release/cancel。
- SystemMediaProbe。
- SystemThumbnailExtractor。
- ThumbnailTimePolicy。
- PlaybackEngine stale session event protection。
- SEEKING -> seekDone 状态恢复。
- Backend selector。
- settings persistence。

## 4. 网络协议实验室

进入：

`test-lab/protocols`

运行：

```sh
./scripts/setup.sh
./scripts/up.sh
./scripts/status.sh
./scripts/endpoints.sh
./scripts/verify.sh
```

分别测试：

### WebDAV

- Basic Auth。
- Guest。
- 多级目录。
- 中文/空格文件名。
- Range。
- 错误密码。
- 服务器停止。
- 恢复后重新打开。

### SMB

- 密码。
- Guest。
- 自动共享枚举。
- 指定 Share。
- 大文件 seek。
- 服务断开/恢复。

### SFTP

- 密码认证。
- host fingerprint。
- 错误 fingerprint。
- 读取取消。
- seek。

### FTP

- 普通被动模式。
- Anonymous。
- 明确确认 FTPS/主动模式当前限制提示。

### NFS

- 正常只读。
- denied 配置。
- 大文件随机读。

每个协议必须至少播放：

- 一个 MP4。
- 一个 MKV。
- 一次 50% seek。
- 一次 90% seek。

## 5. MediaProxy 测试

验证：

- 只监听 127.0.0.1。
- token URL 不包含远端路径、账号、密码。
- HEAD 正常。
- GET 正常。
- Range bytes=0-0。
- Range 中段。
- suffix Range。
- 416。
- 非法 Range。
- release 后 URL 失效。
- 一个 source 的并发 read 不破坏顺序。
- source cancel 后 native handle 最终 close。

记录 diagnostics：

- activeSources。
- activeClients。
- readRequests。
- bytesRead。
- releasedSources。

关键验证：

seek 到远程文件 70% 时，不允许从文件 0 开始顺序下载到 70%。

## 6. Metadata 测试

当前 System 路径：

- MP4 H264/AAC。
- MP4 HEVC/AAC。
- MKV H264。
- MKV HEVC。
- Main10。
- 多音轨。
- 多字幕。

检查：

- duration。
- width/height。
- 无法获取的字段保持 unknown/undefined，不伪造。

当 FFmpeg analyzer 落地后，同一套 case 再跑：

- System。
- FFmpeg。
- merged result。

并检查 field origin。

## 7. Thumbnail 测试

### 时间点

- 20 秒视频 -> 4 秒附近。
- 10 分钟 -> 60 秒。
- 2 小时 -> 60 秒。

### 尺寸

必须保持比例：

- 1920x1080 -> 480x270。
- 3840x1600 -> 480x200。
- 1080x1920 -> 152x270。

### 格式

新生成文件：

- 必须 WebP。
- quality=80。
- 不允许生成新的 JPG fallback。

旧 JPEG cache：

- 可以继续读取。
- 不要求批量迁移。
- 新生成必须转向 WebP。

### Cache identity

修改以下任一配置必须产生不同 key：

- frame time。
- width。
- height。
- quality。
- algorithmVersion。

## 8. MPV 基础播放

设置：

`播放器内核 = MPV`

测试：

- Local MP4。
- Local MKV。
- WebDAV MP4。
- WebDAV MKV。
- SMB MKV。

检查：

- attachSurface。
- surface resize。
- prepare。
- first frame。
- play/pause。
- seek。
- duration/position。
- buffering。
- EOF。
- release。

重复进入/退出 50 次，不允许：

- 黑屏累积。
- Surface 泄漏。
- 音频残留。
- proxy lease 残留。

## 9. System 基础播放

设置：

`播放器内核 = 系统`

测试：

- H264/AAC MP4。
- HEVC/AAC MP4。
- HLS。
- 本地文件。
- MediaProxy URL。

检查：

- prepare。
- first frame。
- seekDone。
- buffering。
- completed。
- release。

系统不支持的样本必须明确失败，而不是静默黑屏。

## 10. Auto Backend

设置：

`播放器内核 = 自动`

当前策略只是 baseline，不是最终性能结论。

验证：

- System candidate prepare 成功时只暴露 System 事件。
- System prepare 失败时只 fallback 一次 MPV。
- 第一个失败 candidate 的 duration/tracks/HDR/error 不污染 committed backend。
- 用户明确强制 System 时不 fallback。
- 用户明确强制 MPV 时不 fallback。

## 11. Seek

每个核心 case：

- 0%。
- 10%。
- 50%。
- 90%。
- 接近结尾。

记录：

- seek start。
- seek complete。
- elapsedMs。
- backend。
- source type。
- bytesRead。
- rangeRequests。

检查 SEEKING 最终恢复成 seek 前合理状态。

## 12. Track / Subtitle

MPV：

- 多视频轨。
- 多音轨。
- 多字幕。
- ASS。
- PGS。

当前公共 contract 已能上报 tracks，但 track selection command 若仍未实现，则记录为待实现项，不误判为通过。

System：

记录实际能够枚举/切换的能力，不能用 MPV 结果代替 System 结果。

## 13. HDR

样本：

- SDR。
- HDR10。
- HLG。
- Dolby Vision。

记录：

- backend。
- decoder。
- pixel format。
- hw pixel format。
- primaries。
- transfer。
- HDR label。
- TV/手机是否实际进入 HDR/DV mode。

注意：

DV-aware rendering 不等于 native Dolby Vision output。

## 14. Audio

样本：

- AAC。
- AC3。
- EAC3。
- DTS。
- DTS-HD MA。
- TrueHD。
- Atmos。
- DTS:X。

每项记录：

- 能否播放。
- decode-to-PCM 或 passthrough。
- 输出声道。
- AVR/TV 指示。
- 是否发生降级。

不要把“有声音”记成“DTS-HD MA passthrough 成功”。

## 15. Benchmark

使用：

`test-lab/benchmark/cases.json`

每个 case 至少重复 5 次。

记录 NDJSON。

### Analysis

记录：

- engine。
- success。
- completeness。
- elapsedMs。
- bytesRead。
- rangeRequests。
- memoryBytes。

### Playback

记录：

- first-frame。
- seek。
- buffering。
- backend。
- CPU。
- memory。
- power/temperature。

生成报告：

```powershell
node scripts/summarize-benchmark.cjs results.ndjson report.md
```

Auto selector 只有在数据完成后才能调优。

## 16. 长稳测试

### 2 小时播放

检查：

- crash。
- A/V sync。
- memory。
- CPU。
- temperature。
- battery。
- network reconnect。

### 50 次换源

检查：

- memory 回落。
- proxy activeSources 回到 0。
- 无旧 session event。
- 无音频残留。

### 前后台

测试：

- Home。
- 恢复。
- 锁屏。
- 解锁。
- 分屏。
- 旋转。
- Ability 重建。

## 17. 故障注入

至少覆盖：

- Wi-Fi 断开。
- Wi-Fi 切换。
- NAS 停止。
- NAS 重启。
- 认证过期。
- 错误密码。
- 文件被删除。
- 文件大小变化。
- Range 不支持。
- HTTP 416。
- timeout。
- 本地磁盘空间不足。
- cache 文件损坏。

必须检查：

- cancellation。
- handle close。
- proxy lease release。
- UI 错误恢复。
- retry 不造成重复后台任务。

## 18. 安全测试

确认日志中没有：

- Authorization。
- Cookie。
- password。
- SMB credential。
- SFTP private key。
- signed URL query。

MediaProxy：

- 只绑定 localhost。
- URL 使用随机 token。
- token 中不出现 upstream locator。

## 19. FFmpeg Analyzer 验收（阻塞解除后）

只有 FFMPEG_INTEGRATION_BLOCKER.md exit criteria 全满足后执行。

必须验证：

- local MP4 metadata。
- MediaProxy MKV metadata。
- HDR/color metadata。
- audio/subtitle tracks。
- chapters。
- thumbnail decode。
- WebP 仍由统一 encoder 处理，而不是 FFmpeg encoder。

## 20. 发布门槛

正式合并/发布前必须：

- verify.ps1 全绿。
- arm64 Debug HAP 构建通过。
- arm64 Release HAP 构建通过。
- MPV package lock 正常生成。
- 目标真机 MPV/System 基础矩阵通过。
- WebDAV/SMB 关键路径通过。
- 50 次换源通过。
- 2 小时长稳通过。
- 没有 credential 泄漏。
- blocker 文档中的未验证能力不得在 UI 宣称为已支持。
