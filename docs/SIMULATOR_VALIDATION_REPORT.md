# Simulator Validation Report

> Status: FAIL（首次 default regression 配置阻断，修复/重试进行中）
> Branch: `test/simulator-validation`  
> This report validates the near-production x86_64 simulator product. It does not replace ARM64 device validation.

## 1. Git

- Base branch: `test/player-architecture-validation`
- Simulator branch: `test/simulator-validation`
- Starting SHA: `c26ed66d86ee0e2c72ae34fd23a4c4bf665b7ebc`；干净检出 `D:\Linkora-validation`，原 D:\Linkora 用户工作区不动。
- Final tested SHA:
- Final documentation SHA:

## 2. Environment

- Host OS: Windows 11 Pro 10.0.26200 x64 / PowerShell
- DevEco Studio: 26.0.0.821
- HarmonyOS SDK: 26.0.0.105 / API 26
- Hvigor: 6.26.4
- ohpm: 26.0.0.630
- Node: DevEco bundled 24.14.1
- Emulator model: emulator；HDC 127.0.0.1:5555
- Emulator OS/build: OpenHarmony-7.0.0.105
- Emulator API: 26
- Emulator ABI: x86_64
- Emulator resolution: 1256x2760，RenderService hidumper 实测
- HarmonyOS Native SDK root used for FFmpeg:

## 3. Dependency / Sync

- `ohpm install`: PASS / exit 0；正常生成/解析 lock，未手工修改。
- DevEco Project Sync: FAIL；执行 Studio Hvigor `--sync --no-daemon`（实际 CLI Sync）；00303038 entry targets[0].buildOption 不在合法 schema；无 GUI Sync 结果。
- multi-target plugin resolved: PASS；Hvigor install 下载 7.0.0，pnpm 安装成功。
- default real mpv dependency resolved: PASS；OHPM 使用真实 1.0.0 依赖，未替换 default。
- simulator MPV target replacement resolved: NOT RUN

## 4. Production Regression Gate

Command:

```powershell
./scripts/verify.ps1
```

- Result: FAIL（attempt 01；重试待执行）
- Hypium:
- MPV adapter regression:
- architecture/parity guards:
- default Debug HAP:
- default Release HAP:
- notes: 全量入口首个真实错误为 Hvigor test 的 00303038 schema validation，尚未进入 Hypium/build。本地原始日志 artifacts/simulator-validation/default-verify-01.log。已按 SDK schema 将 default native buildOption 移至 targets[0].config.buildOption，仍保持 arm64-v8a；同步 parity guard 的读取/隔离检测路径。

## 5. Simulator Parity Gate

Command:

```powershell
node scripts/check-simulator-product.cjs
```

- Result: NOT RUN

Confirm:

| Parity requirement | Result | Notes |
| --- | --- | --- |
| Auto/System/MPV UI same as production | NOT RUN | |
| SMB/SFTP/FTP/NFS/WebDAV UI same as production | NOT RUN | |
| AdaptivePlaybackPort retained | NOT RUN | |
| BackendSelector retained | NOT RUN | |
| WebDAV provider shared with default | NOT RUN | |
| MediaProxy shared | NOT RUN | |
| Native transport replacement only at provider boundary | NOT RUN | |
| MPV replacement only at target dependency boundary | NOT RUN | |

## 6. Simulator Build

Command:

```powershell
./scripts/verify-simulator.ps1
```

- Result: NOT RUN
- Discovered Seq task:
- HAP path:
- HAP SHA256:
- Bundle: `com.linkora.player`
- libmpv packaged: NOT RUN
- SMB/SFTP/FTP/NFS production native SO packaged: NOT RUN
- FFmpeg analyzer SO packaged:
- unknown SO packaged:
- notes:

## 7. Install / Launch

- target:
- ABI:
- install: NOT RUN
- cold launch: NOT RUN
- navigation: NOT RUN
- crash/native loader error:
- evidence:

## 8. Playback Preference UI

| Check | Result | Notes |
| --- | --- | --- |
| Auto visible | NOT RUN | |
| System visible | NOT RUN | |
| MPV visible | NOT RUN | |
| preference persists restart | NOT RUN | |

## 9. Forced MPV Replacement Path

Expected simulator behavior: same production PlaybackEngine/AdaptivePlaybackPort path, then fail only when target-specific MPV package attempts to instantiate native backend.

- configure/open reaches adaptive stack: NOT RUN
- controlled backend unavailable error: NOT RUN
- no crash/native SO load: NOT RUN
- forced MPV does not fallback: NOT RUN
- resource cleanup: NOT RUN

## 10. Auto Fallback

Use at least one MPV-first sample such as MKV.

- selector chose MPV first: NOT RUN
- simulator MPV replacement failed at final boundary: NOT RUN
- one-shot fallback attempted: NOT RUN
- failed candidate did not leak stale state: NOT RUN
- System fallback final result:
- no second fallback: NOT RUN

## 11. System Playback

| Case | Prepare | First frame | Pause/resume | Seek 50% | Seek 90% | Completion | Release |
| --- | --- | --- | --- | --- | --- | --- | --- |
| HTTPS H264/AAC MP4 | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN |
| Local H264/AAC MP4 | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN |
| HEVC/AAC MP4 | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN |

## 12. Network Configuration Parity

| Protocol | UI fields | Save/edit/delete | Connection test | Directory/open |
| --- | --- | --- | --- | --- |
| WebDAV | NOT RUN | NOT RUN | NOT RUN | NOT RUN |
| SMB | NOT RUN | NOT RUN | expected native-boundary unavailable | expected native-boundary unavailable |
| SFTP | NOT RUN | NOT RUN | expected native-boundary unavailable | expected native-boundary unavailable |
| FTP | NOT RUN | NOT RUN | real ArkTS TCP test | expected native-boundary unavailable |
| NFS | NOT RUN | NOT RUN | real ArkTS TCP test | expected native-boundary unavailable |

## 13. WebDAV

| Check | Result | Notes |
| --- | --- | --- |
| Correct authentication | NOT RUN | |
| Wrong auth rejected | NOT RUN | |
| Root list | NOT RUN | |
| Nested list | NOT RUN | |
| Chinese filename | NOT RUN | |
| Space filename | NOT RUN | |
| Refresh | NOT RUN | |
| H264 MP4 playback | NOT RUN | |
| Seek 50% | NOT RUN | |
| Seek 90% | NOT RUN | |

## 14. MediaProxy

- activeSources before:
- activeSources during:
- activeSources after:
- activeClients:
- readRequests:
- bytesRead:
- releasedSources:
- localhost only: NOT RUN
- token privacy: NOT RUN
- HEAD: NOT RUN
- GET: NOT RUN
- Range: NOT RUN
- 50% random access: NOT RUN
- 90% avoids sequential byte-0 read: NOT RUN
- release returns source count to zero: NOT RUN

## 15. Metadata / Thumbnail

| Check | Result | Evidence |
| --- | --- | --- |
| duration | NOT RUN | |
| width/height | NOT RUN | |
| thumbnail visible | NOT RUN | |
| new cache = WebP | NOT RUN | |
| no new JPEG | NOT RUN | |
| quality 80 | NOT RUN | |
| target-time policy | NOT RUN | |
| max 480x270 | NOT RUN | |
| aspect ratio | NOT RUN | |
| cache reuse | NOT RUN | |

## 16. Database / Settings

- settings persistence: NOT RUN
- player preference persistence: NOT RUN
- WebDAV server persistence: NOT RUN
- SMB config persistence: NOT RUN
- SFTP config persistence: NOT RUN
- FTP config persistence: NOT RUN
- NFS config persistence: NOT RUN
- delete persistence: NOT RUN
- DB migration errors:

## 17. Surface / Lifecycle

- fullscreen enter/exit: NOT RUN
- orientation: NOT RUN
- background/foreground: NOT RUN
- surface recreate: NOT RUN
- stale-session isolation: NOT RUN
- 20 player open/close: NOT RUN
- residual audio:
- black surface:
- crash/ANR:

## 18. Error Recovery

| Case | Result | Notes |
| --- | --- | --- |
| HTTP 404 | NOT RUN | |
| HTTP 500 | NOT RUN | |
| timeout | NOT RUN | |
| unsupported media | NOT RUN | |
| WebDAV bad password | NOT RUN | |
| WebDAV server stop/recover | NOT RUN | |
| forced MPV simulator unavailable | NOT RUN | |
| SMB native transport unavailable | NOT RUN | |
| SFTP native transport unavailable | NOT RUN | |
| FTP native transport unavailable | NOT RUN | |
| NFS native transport unavailable | NOT RUN | |

## 19. Security

- Authorization leak scan: NOT RUN
- Cookie leak scan: NOT RUN
- password/credential leak scan: NOT RUN
- proxy upstream locator leak scan: NOT RUN
- signing secret scan: NOT RUN

## 20. FFmpeg Bootstrap

Pinned source:

- version: 8.1.3
- tag: n8.1.3
- commit: 1041abdc962f4cc4f394aa8de9dc5236c0c3b9e7

| Step | x86_64 | arm64-v8a | Evidence |
| --- | --- | --- | --- |
| source fetch/pin | NOT RUN | same source | |
| configure | NOT RUN | NOT RUN | |
| libavformat.a | NOT RUN | NOT RUN | |
| libavcodec.a | NOT RUN | NOT RUN | |
| libavutil.a | NOT RUN | NOT RUN | |
| libswscale.a | NOT RUN | NOT RUN | |
| build manifest | NOT RUN | NOT RUN | |

FFmpegMediaProbe: NOT RUN  
FFmpegThumbnailExtractor: NOT RUN  
System-vs-FFmpeg benchmark: NOT RUN

## 21. Explicit Device-Only Items

Remain NOT RUN regardless of simulator success:

- real MPV runtime
- SMB/SFTP/FTP/NFS native I/O
- native HDR/DV output
- DTS-HD/TrueHD passthrough
- Atmos/DTS:X
- Audio Vivid
- arm64 hardware decode
- power/thermal
- final Auto performance policy

## 22. Fixes During Simulator Validation

| Commit | Failure | Root cause | Files | Verification |
| --- | --- | --- | --- | --- |

## 23. Final Assessment

- production regression:
- parity/isolation:
- simulator build:
- install:
- UI parity:
- System:
- Auto fallback:
- forced MPV replacement:
- WebDAV:
- native-protocol pre-transport path:
- MediaProxy:
- thumbnail:
- lifecycle:
- security:
- FFmpeg x86 build:
- FFmpeg arm64 build:
- blockers:

## 24. Handoff Decision

Choose exactly one:

- READY FOR ARCHITECTURE REVIEW
- BLOCKED — SIMULATOR PRODUCT BUILD
- BLOCKED — EMULATOR PLATFORM
- BLOCKED — FFMPEG TOOLCHAIN/PATCH REQUIRED
- VALIDATION FAILED — FIXES REQUIRED
