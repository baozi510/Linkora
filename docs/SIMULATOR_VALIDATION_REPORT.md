# Simulator Validation Report

> Status: NOT RUN（default/parity/simulator build/安装/冷启动已 PASS；功能矩阵执行中）
> Branch: `test/simulator-validation`  
> This report validates the near-production x86_64 simulator product. It does not replace ARM64 device validation.

## 1. Git

- Base branch: `test/player-architecture-validation`
- Simulator branch: `test/simulator-validation`
- Starting SHA: `c26ed66d86ee0e2c72ae34fd23a4c4bf665b7ebc`；干净检出 `D:\Linkora-validation`，原 D:\Linkora 用户工作区不动。
- Final tested SHA: `1fab9e09bbdcec766029eb383d2a833d821dad4a`（当前源码；最终 full default 仍会在交接前重跑）
- Final documentation SHA:

## 2. Environment

- Host OS: Windows 11 Pro 10.0.26200 x64 / PowerShell
- DevEco Studio: 26.0.0.821
- HarmonyOS SDK: 26.0.0.105 / API 26
- Hvigor: 6.26.4
- ohpm: 26.0.0.630
- Node: default 回归实际使用 PATH 24.13.1；Studio bundled 24.14.1 可用。simulator 第三次重试改用 bundled Node 满足 plugin README 要求。
- Emulator model: emulator；HDC 127.0.0.1:5555
- Emulator OS/build: OpenHarmony-7.0.0.105
- Emulator API: 26
- Emulator ABI: x86_64
- Emulator resolution: 1256x2760，RenderService hidumper 实测
- HarmonyOS Native SDK root used for FFmpeg:

## 3. Dependency / Sync

- `ohpm install`: PASS / exit 0；正常生成/解析 lock，未手工修改。
- DevEco Project Sync: PASS（CLI Sync 重试 exit 0，四模块 init 完成）；首次 00303038 配置失败已记录，未声称执行 GUI Sync。
- multi-target plugin resolved: PASS；Hvigor install 下载 7.0.0，pnpm 安装成功。
- default real mpv dependency resolved: PASS；OHPM 使用真实 1.0.0 依赖，未替换 default。
- simulator MPV target replacement resolved: PASS；Seq 实际运行 OHPM，将本地 stub 注册为 local，包中没有 .so。插件生成当前 target lock，后续 default 回归须正常重新解析真实依赖，不手工改 lock。

## 4. Production Regression Gate

Command:

```powershell
./scripts/verify.ps1
```

- Result: PASS / exit 0（完整 attempt 02、03、06）；失败尝试均保留，未跳项。
- Hypium: 初始 145/145；补充 seek 顺序测试后 149/149 PASS、18 suites、0 Failure/Error/Ignore。
- MPV adapter regression: PASS，5/5
- architecture/parity guards: PASS；guard fixtures 5/5，parity/isolation PASS
- default Debug HAP: PASS，unsigned / arm64-v8a；同时三个 Debug HAR PASS。
- default Release HAP: PASS，unsigned / arm64-v8a；同时三个 Release HAR PASS。
- notes: 全量入口首个真实错误为 Hvigor test 的 00303038 schema validation，尚未进入 Hypium/build。本地原始日志 artifacts/simulator-validation/default-verify-01.log。已按 SDK schema 将 default native buildOption 移至 targets[0].config.buildOption，仍保持 arm64-v8a；同步 parity guard 的读取/隔离检测路径。

## 5. Simulator Parity Gate

Command:

```powershell
node scripts/check-simulator-product.cjs
```

- Result: PASS，输出 `Simulator product parity/isolation checks passed.`；UI/runtime 已执行。

Confirm:

| Parity requirement | Result | Notes |
| --- | --- | --- |
| Auto/System/MPV UI same as production | PASS | 同一 UI 源码，实际三选项可见 |
| SMB/SFTP/FTP/NFS/WebDAV UI same as production | PASS | 五种 picker/配置/路由实测 |
| AdaptivePlaybackPort retained | PASS | parity/architecture guard + simulator 编译 |
| BackendSelector retained | PASS | 同上，无策略修改 |
| WebDAV provider shared with default | PASS | 同源 Provider + 实际认证/列表/播放 |
| MediaProxy shared | PASS | static composition/guards；内部 runtime source 计数另列 NOT RUN |
| Native transport replacement only at provider boundary | PASS | 配置/保存成功、directory 明确 unavailable |
| MPV replacement only at target dependency boundary | PASS | plugin OHPM 实际 target 替换，default real 1.0.0 |

## 6. Simulator Build

Command:

```powershell
./scripts/verify-simulator.ps1
```

- Result: PASS / exit 0（attempt 03、04、05）；先前失败保留日志。
- Discovered Seq task: assembleHapSeq，在项目根 node 注册（tasks 原始输出已保存）。
- HAP path: entry/build/simulator/outputs/simulator/linkora-simulator-unsigned.hap；本地开发签名后 linkora-simulator.hap
- HAP SHA256: unsigned `bd223c72214aa6f53eafb0d8c06ddeca93c6356c6255c69418d6f8aa15db47f7`；signed `5f11c2b17db94149cea699210cdb06cef91d31965f08af2615a112c77e84b143`
- Bundle: `com.linkora.player`
- libmpv packaged: PASS（未打包）
- SMB/SFTP/FTP/NFS production native SO packaged: PASS（未打包）
- FFmpeg analyzer SO packaged: PASS（未集成，无 .so）
- unknown SO packaged: PASS（无 .so）
- notes:

## 7. Install / Launch

- target: 127.0.0.1:5555
- ABI: x86_64
- install: PASS（signed install 02）；unsigned install 01 FAIL / 9568332 install sign info inconsistent，HDC process exit 0 不代表成功。
- cold launch: PASS；aa force-stop 后 aa start 成功，实际截图显示本地页。
- navigation: PASS（本地→设置→播放器→串流→网络，以及播放页返回）；其余功能矩阵继续执行。
- crash/native loader error: 冷启动未观察到；尚无完整稳定性结果。
- evidence: artifacts/simulator-validation/install-{01,02}.txt、launch.txt、launch.png、launch-layout.json。

已有同 bundle 签名应用；使用本机现有开发签名材料兼容更新，未 uninstall/清空应用数据。临时 signingConfigs 仅在本地构建期间加入，finally 原字节恢复 build-profile；签名材料/密码不打印、不提交，原 D:\Linkora 文件未修改。签名 log 已遮蔽 material 值，二进制仅本地保存。

## 8. Playback Preference UI

| Check | Result | Notes |
| --- | --- | --- |
| Auto visible | PASS | 实际播放器设置页 layout/screenshot |
| System visible | PASS | 同页，已选择 System |
| MPV visible | PASS | 同页，已选择 MPV |
| preference persists restart | PASS | MPV、System、Auto 重启检查；已恢复原始 Auto（截图确认） |

## 9. Forced MPV Replacement Path

Expected simulator behavior: same production PlaybackEngine/AdaptivePlaybackPort path, then fail only when target-specific MPV package attempts to instantiate native backend.

- configure/open reaches adaptive stack: NOT RUN
- controlled backend unavailable error: PASS（forced MPV 打开本地视频出现 LNK-PLAY-007 + 重试；不是 real MPV 播放 PASS）
- no crash/native SO load: PASS（此 smoke 未 crash；包本身不含 .so）
- forced MPV does not fallback: PASS（同一个 System 可播放的本地 H264 文件在 forced MPV 明确失败；没有转入 System 播放）
- resource cleanup: NOT RUN

## 10. Auto Fallback

Use at least one MPV-first sample such as MKV.

- selector chose MPV first: NOT RUN
- simulator MPV replacement failed at final boundary: NOT RUN
- one-shot fallback attempted: NOT RUN
- failed candidate did not leak stale state: NOT RUN
- System fallback final result: PASS（Auto + 真实 H264/AAC MKV，60s/640x360、移动色条首帧、播放中；实际 stub 不可实例化，成功 backend 因此为 System）。精确 candidate 次数/瞬时事件未采集，下面 NOT RUN 不能以源码推断改为 PASS。
- no second fallback: NOT RUN

## 11. System Playback

| Case | Prepare | First frame | Pause/resume | Seek 50% | Seek 90% | Completion | Release |
| --- | --- | --- | --- | --- | --- | --- | --- |
| HTTPS H264/AAC MP4 | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN |
| Local H264/AAC MP4 | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN |
| HEVC/AAC MP4 | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN |

附加已测：本地 album_b_video_03.mp4（原始 fixture ffprobe 为 H264-only，2s，没有 AAC）System 首帧、播放完成、replay、返回 PASS；不能记为上表 H264/AAC。HTTP H264/AAC MKV（生成 fixture）System 能播放，50%/90% UI position 跳至约 30s/56s；暂停/seekDone 后 buffering 状态恢复仍需继续确认，未提前记 PASS。

## 12. Network Configuration Parity

| Protocol | UI fields | Save/edit/delete | Connection test | Directory/open |
| --- | --- | --- | --- | --- |
| WebDAV | PASS | PASS（删除待执行） | PASS / HTTP 207、错误密码拒绝 | PASS |
| SMB | PASS | PASS（删除待执行） | PASS / controlled unavailable | PASS / SIMULATOR_NATIVE_TRANSPORT_UNAVAILABLE |
| SFTP | PASS | PASS（删除待执行） | PASS / controlled unavailable | PASS / SIMULATOR_NATIVE_TRANSPORT_UNAVAILABLE |
| FTP | PASS | PASS（删除待执行） | PASS / real ArkTS TCP 19221 | PASS / controlled unavailable |
| NFS | PASS | PASS（删除待执行） | PASS / real ArkTS TCP 19249 | PASS / controlled unavailable |

## 13. WebDAV

| Check | Result | Notes |
| --- | --- | --- |
| Correct authentication | PASS | 实际 HTTP 207 |
| Wrong auth rejected | PASS | 明确认证错误 + Retry/Close |
| Root list | PASS | test-lab root |
| Nested list | PASS | Movies/Action；自己的测试子目录 |
| Chinese filename | PASS | 中文 样本.mp4 列表/播放 |
| Space filename | PASS | City Chase 1080P.mp4 列表/播放 |
| Refresh | PASS | 修复后新增目录即时正确显示，无重复旧行 |
| H264 MP4 playback | PASS | H264/AAC 60s 和 600s，20轮打开/关闭 |
| Seek 50% | PASS | 10轮，约30s，保持暂停 |
| Seek 90% | PASS | 10轮，约54s，保持暂停 |

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
- 50% random access: PASS（测试 upstream Range ledger；10min/136060722-byte 文件，从 10493951 跳至 66283018）
- 90% avoids sequential byte-0 read: PASS（高位 seek 实际约93%；跳至125216723之前只传输21004966 wire bytes；60s样本精确90%已测）
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

- settings persistence: PASS（remember position / keep screen on / experimental storage / cellular；反转、重启恢复、还原）；theme/extensions 尚 NOT RUN
- player preference persistence: PASS（原始 Auto 已恢复）
- WebDAV server persistence: PASS
- SMB config persistence: PASS
- SFTP config persistence: PASS
- FTP config persistence: PASS
- NFS config persistence: PASS
- delete persistence: NOT RUN
- DB migration errors:

## 17. Surface / Lifecycle

- fullscreen enter/exit: PASS（20轮，全屏退出用真实“退出”按钮）
- orientation: PASS（20轮横屏/竖屏）
- background/foreground: PASS（10轮，暂停位置保留）
- surface recreate: NOT RUN
- stale-session isolation: NOT RUN
- 20 player open/close: PASS（20轮 ledger、first-image screenshot；Pillow 分析20/20含真实彩色 testsrc；人工抽检1/10/20）
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

Fetch attempt 01 FAIL：`git fetch --no-tags origin "refs/tags/$Tag:refs/tags/$Tag"` 得到 `fatal: invalid refspec 'refs/tags//tags/n8.1.3'`。PowerShell 将 `$Tag:refs` 当作带 scope 的变量，丢失 refspec 前半段。仅将变量明确界定为 `${Tag}`，未改版本或 pin。失败生成的 checkout 移入 ignored artifacts 保存，正常脚本重试 02 PASS；HEAD 与 tag object 分别实测为上述 commit 和 `23151b11c75aa44d9ab8db796a53c76acf00f6c0`。已存在源码再次运行 attempt 03 PASS。修复独立提交，SHA 在最终修复表记录。

x86 configure attempt 01 FAIL：`Host compiler lacks C11 support`；完整 config.log 的首个实际错误为 `gcc: command not found`，OHOS target clang 的编译/链接测试已成功。正在使用本机已有 MSVC host compiler 重试；不使用 host headers/libs 替代 OHOS target sysroot。

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

Runtime progress: WebDAV 实测错误密码拒绝、正确认证 HTTP 207、保存、root/Movies/Action 多级目录、空格文件播放、中文空格文件列表及 H264/AAC MP4 首帧 PASS。WSL IP 对模拟器超时，测试端使用宿主机 TCP→WSL stdio 转发（只转发 test-lab 服务，未修改生产代码）。原数据未删除。

Paused seek 真实 FAIL：暂停于 14s 后 seek 50%/90%，UI 留在 buffering；系统日志已有 BUFFERING_END 和 OnSeekDone(30000/56000)。Engine 将 seek 前的暂停意图覆盖为 BUFFERING，且 END 在 SEEKING 状态被忽略；重复 Slider seek 又保存 SEEKING 为返回状态。新增四个事件顺序/暂停与播放/重复 seek 组合测试，修复前实跑 149 tests / 4 Failure / 145 Pass。最小 bookkeeping 修复不改变 public contract/Auto 策略；default 全量 attempt 03 PASS / exit 0，149/149 Hypium 和八项构建全部通过，之后须 simulator 重建和 runtime 复测。

Refresh 动态新增目录时，列表出现重复 sample 行且遗漏新目录；返回再进入恢复。root cause：virtual Repeat 的 Builder 只接收 repeatItem.item，无法跟踪节点复用后的新 item。按 [OpenHarmony 官方 Repeat 文档](https://github.com/openharmony/docs/blob/master/en/application-dev/ui/rendering-control/arkts-new-rendering-control-repeat.md)，将 list/grid/metadata Builder 改为接收完整 RepeatItem，保留虚拟列表/缓存/Provider/MediaProxy。default 04 因原静态检查仍匹配旧 entry 名失败；调整检查时误改了仍使用 entry 的 detailLabels 匹配，05 再次失败；已纠正，06 完整回归 PASS / exit 0，149/149 Hypium + 八项构建。原始失败日志均保留，无跳过检查。simulator 05 PASS，signed HAP `3119dfb05f1fa22a31b30dc2414ae4d09c4c4d599eb3b07bac5c452f4765ad07` install 03 PASS。

Seek 修复后 runtime：WebDAV 60s H264/AAC MP4，暂停状态重复十轮 50%/90% seek，十轮均保持 PAUSED，position 约 30s/54s；NOT RUN 项不由此自动改为 PASS。逐轮 ledger/screenshot 本地保存。四种 Native 配置已完成编辑、保存、重启恢复（edited 名称）；待删除持久化检查。

Home/foreground 十轮，均回到暂停的相同 position（约 9s），未自动继续，未观察到 crash。刷新修复后真实新增目录插入、refresh list 顺序及显示 PASS（无重复旧行、无需重进）；截图、layout 保存。二十轮 player/fullscreen 横屏/exit/back/reopen 正在执行。当前日志扫描测试密码、Authorization/Cookie 值、URL embedded credentials、signed query 均零匹配；扫描范围与缺少 raw-cache 权限明确保留，不作全面安全保证。

SMB/SFTP 已填写、保存并进入目录，真实页面显示 `SIMULATOR_NATIVE_TRANSPORT_UNAVAILABLE`，connection-test UI 显示相同平台限制，未 crash；不能证明 native auth/I/O。

FTP/NFS 的真实 ArkTS TCP test PASS（宿主机转发端口 19221/19249，对应 test-lab 12121/12049），directory/open 在 transport boundary 明确不可用。四种新增 native 协议配置 force-stop/start 后仍存在。模拟器拒绝读取应用/共享文件目录，`hdc smode` 返回 Cannot set root run mode in undebuggable version；未绕过安全边界，缓存落盘与完整 runtime diagnostics 暂 NOT RUN。

| Commit | Failure | Root cause | Files | Verification |
| --- | --- | --- | --- | --- |
| `1a417bdc91eb516eba267476448a4652085629fd` | Sync / default verify 01：00303038 targets[0].buildOption schema error | Native target option 配置层级不合法，SDK 只接受 config.buildOption | entry/build-profile.json5；check-simulator-product.cjs；本报告 | CLI Sync 02 exit 0，parity PASS；default 全量 02 进行中 |
| `bae6cfd` | verify-simulator 01：ParserError line 72 unexpected token Simulator | native .so 检查段被重复/截断，两个 regex 字符串未闭合，finally 和尾部重复 | scripts/verify-simulator.ps1；本报告 | PowerShell parser PASS；02 成功发现 Seq，随后作用域错误 |
| 待本次独立提交 | verify-simulator 02：00306054 Task assembleHapSeq was not found | 插件将 Seq 注册在 project root，脚本却 --mode module；tasks 和真实插件源码一致证明作用域错误，尚未执行依赖替换 | scripts/verify-simulator.ps1；本报告 | 改为 project 调用，仍传入 entry@simulator；使用 bundled Node 24.14.1；第三次重试待执行 |

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
