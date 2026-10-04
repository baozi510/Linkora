# FFmpeg Phase 1B Runtime Validation Report

Status: PASS — READY FOR FFMPEG ANALYZER INTEGRATION REVIEW

2026-10-04，分支 `test/ffmpeg-media-analysis-phase1b-runtime`。完整阅读并执行 [Runtime Runbook](CODEX_FFMPEG_PHASE1B_RUNTIME_RUNBOOK.md)。全部可执行 runtime gate 已完成；停止等待架构审查，不 merge，不接入生产 probe 策略。

## Git 与范围

- Base：`feat/ffmpeg-media-analysis-phase1`；本次起点 `40a43ef56a7b6b37f7d0736c1dd37cf43290f2ba`。
- 最终测试源码：`d8dad1d757c5b7e6a13b9603d540903aba99567a`；其后只有本报告和脱敏证据变化。
- Native 类型修复：`f99b4fd0a65ede8d7d019bd4f7a83ad1e8e27a49`。
- Harness / 验证守卫：`d8dad1d757c5b7e6a13b9603d540903aba99567a`。
- 最终报告 commit：包含本文件的最后提交，用 `git log -1 --format=%H -- docs/FFMPEG_PHASE1B_RUNTIME_REPORT.md` 查询；交付消息给出该 SHA，避免文件内写自身 SHA。
- 隔离工作目录 `D:/Linkora-validation`，原 `D:/Linkora` 的 main 和用户修改保留。

证据索引：[README](validation/ffmpeg-phase1b/README.md)。原始日志/签名材料/fixture 二进制/完整 hilog 保留在 ignored artifacts，未提交。

## 环境

| 项目 | 实际环境 |
| --- | --- |
| Host | Windows / PowerShell；既有 WSL Ubuntu + Docker 协议实验室 |
| DevEco Studio | 26.0.0.821 |
| SDK | 26.0.0.105，API 26 |
| Hvigor / ohpm / Node | 6.26.4 / 26.0.0.630 / 24.14.1 |
| Native SDK | Studio sdk/default/openharmony/native，OHOS Clang 15.0.4 |
| Emulator | 7.0.0.107(SP8DEVC00E999R4P11)，API 26，x86_64，HDC 127.0.0.1:5557 |
| FFmpeg | 8.1.3 / n8.1.3，pin `1041abdc962f4cc4f394aa8de9dc5236c0c3b9e7`；既有两 ABI 静态产物，无 bootstrap/native C++ 改动 |
| arm64 真机 | 无可用设备；runtime NOT RUN |

## Build gate 与最终回归

首次按顺序执行：`ohpm install` → project Sync → simulator parity guard → FFmpeg pure tests → 完整 `scripts/verify.ps1` → `scripts/verify-simulator.ps1`。正常 ohpm 解析 `@mpv-ohos/mpv-arkts@1.0.0`，没有手工生成 lock。失败项见下文，未跳过。

| 检查 / Artifact | 最终结果 | 证据 |
| --- | --- | --- |
| 默认 architecture / persistence / adapter / simulator isolation guards | PASS | `default-final-04.log` 摘要 |
| FFmpeg deterministic pure tests | PASS 15/15 | `pure-initial.txt`、最终 verify |
| Hypium | PASS 164/164，Failure 0 / Error 0 / Ignore 0 | `hypium.json` |
| Native artifact guard fixtures | PASS 6/6 | `default-mpv-guard-green.txt` |
| linkora_core default Debug / Release HAR | PASS / PASS | 最终 verify 完整顺序构建 |
| linkora_proxy default Debug / Release HAR | PASS / PASS | 同上 |
| linkora_media_probe default Debug / Release HAR | PASS / PASS | 同上 |
| linkora_ffmpeg default Debug / Release HAR | PASS / PASS | 同上 |
| entry default arm64 Debug / Release HAP | PASS / PASS | 两次 ABI audit，各 9 个 AArch64 native libs |
| linkora_ffmpeg simulator Debug HAR | PASS | `simulator-har.log`，37 tasks，真实显式 assembleHar |
| entry simulator Debug HAP | PASS | 最终 `verify-simulator.ps1`，恰好 1 个 x86_64 FFmpeg .so |
| simulator 临时签名 / 安装 | PASS | 两次真实 `hdc install -r` 成功，保留用户数据；build-profile 恢复原样 |

最终完整 `verify.ps1` exit 0（`default-final-04.log`），包含 8 HAR、2 HAP、164 Hypium。之后补做同源码 simulator HAR，正常 `ohpm install` 恢复/确认 default dependency graph；锁文件及签名配置无 diff，现存 default HAP 再审计仍为 9 个 AArch64 libs。未修改生产 MPV 实现。

Simulator HAR SHA256：`d2344e75150ae88e752ee3e265f69835f124b1c764a178bfc4e03a7a1353f9e1`。

Simulator packaged `liblinkora_ffmpeg.so` SHA256：`f7a500c641e228753ea066ce7ecefb8b0e0694c6d5ab1bf476e3527b8de1e606`；ELF64、machine 62；HAP/HAR 相同。真实 libmpv、生产 SMB/SFTP/FTP/NFS .so、unknown .so 均 absent。最终 unsigned simulator HAP SHA256：`83e2462b19964435728ec1800bc9a878b15ccb6576292625c56d7c86228ab615`。签名 HAP 哈希未留存，不将 unsigned 哈希冒充签名哈希。

现存 default Release HAP SHA256：`24589f6664e602706ab2956d26c6e92594ab178aa6ab6249d5dd03443515fd6f`；FFmpeg 为 machine 183 / AArch64；包含真实 MPV 的三个 .so。[final-artifacts.json](validation/ffmpeg-phase1b/final-artifacts.json) 记录逐库哈希。

Dolby Vision explicit profile 0 的既有修正：PASS，纯测试 `requires explicit Dolby Vision configuration` 同时检查 profile 8 和字符串 `"0"`。未复现 pre-fix parent，没有伪造 RED；不代表 native Dolby Vision 播放支持。

## Native / NAPI 与真实运行轮次

Simulator-only `linkora_ffmpeg/Native` import → `createFfmpegAnalysis()` → actual async `probe`、`extractFrame`、`cancel` 均 PASS。实际 metadata/frame/FF_CANCELLED 证明 exports 可调用和模块已注册；未 mock native 对象。未观察到 loader/NAPI failure。

| 冷启动轮次 | caseRun 矩阵 | 原始结论 |
| --- | --- | --- |
| 01 | 45 PASS / 1 FAIL | WebDAV HEAD 在进入 FFmpeg 前 8034ms 超时；其余 runtime 完成，cleanup 0/0 |
| 02 | 46 PASS / 0 FAIL | WSL 实验室保持运行后，全矩阵重跑；新 PID 17943 |
| 03 | 46 PASS / 0 FAIL | 最终测量/Range 记录，全矩阵重跑；新 PID 24363；含后台/前台 |

`native-initialize` PASS 和 `complete` 聚合记录独立于 46 项计数；DATA 不是额外测试。01/02 旧 host keep-alive Range collector 不完整，不记为 Range PASS；03 完整 ledger 支持 Range 结论。

## Local probe / frame

Fixtures 用既有 WSL `/usr/bin/ffmpeg` 的 lavfi testsrc2 + sine 生成，H264 libx264 / HEVC libx265 / AAC，24fps。通过 simulator-only HTTP 下载，ArkTS fileIo 写 `context.filesDir` 的真实 regular files，再传给 native；没有 HDC 读写 app 私有目录。结束删除本次 app fixtures。哈希及独立 ffprobe 数值：[fixtures.json](validation/ffmpeg-phase1b/fixtures.json)。

| Native 结果 | Local MP4 | Local MKV |
| --- | --- | --- |
| Result | PASS | PASS |
| Container | mov,mp4,m4a,3gp,3g2,mj2 | matroska,webm |
| Duration / file size | 10000ms / 2362050 bytes | 4021ms / 174146 bytes |
| Video | 1 × h264 / Constrained Baseline | 1 × hevc / Main |
| Dimensions / frame rate | 640×360 / 24fps | 320×180 / 24fps |
| Audio | 1 × AAC LC / 2ch / 48000Hz | 1 × AAC LC / 2ch / 48000Hz |
| Subtitles | 0 | 0 |

Fixture ffprobe layout 为 stereo；Native evidence 核对/记录 2 channels，未声称测试单独 native layout field。原生路径不出现在 runtime JSON。

| Source | Request | Actual | RGBA bytes | Pixel FNV-1a |
| --- | --- | --- | --- | --- |
| MP4 | 3000ms，max 480×270 | 3000ms，480×270 | 518400 | c115927c |
| Small HEVC MKV | 1000ms，max 480×270 | 1000ms，320×180 | 230400 | 92271e90 |

PASS：非零 timestamp、宽高边界、16:9 比例、small source 不 upscale、rgba_8888、byteLength = width × height × 4。构造真实 FfmpegRawThumbnail；readPixels 是独立 copy，修改 copy 不改变 original；double release 安全，post-release read rejects。未提交 raw RGBA。

## Real WebDAV / MediaProxy

使用既有 test-lab guest WebDAV 的本次独立 fixture。Host 仅转发到既有服务并记录脱敏 method/Range/bytes。实际路径：NetworkDirectoryService → provider RandomAccessSource → 一个共享 NetworkFileProxy → localhost token URL → FFmpeg。未改 provider、proxy 或 timeout。

Ruling：整个 harness 共享一个真实 NetworkFileProxy 测试实例；未暴露或修改 LinkoraFeatures 私有 UI 实例。代价：未测量与既有 UI proxy 实例的交互；本次 provider/socket/lease 路径均为真实实现。

Remote probe PASS：matroska,webm；60021ms；14243631 bytes；H264 Constrained Baseline 640×360/24fps，AAC LC/2ch/48000Hz，无字幕。

| 操作 | Native-only elapsed | Proxy delta | Frame |
| --- | --- | --- | --- |
| Remote probe | 44ms | 1 read / 262144 bytes | metadata PASS |
| Remote frame 70% | 215ms | 9 reads / 2097762 bytes | request 42014ms，actual 42042ms，480×270，518400 RGBA，hash 2d7b1e78 |

Lease release 后 activeSources = 0，activeClients = 0，releasedSources = 1。每轮 complete 都为 sources/clients 0。

[Range ledger](validation/ffmpeg-phase1b/upstream-range-ledger.json)：03 为 1 HEAD + 11 GET，含 `14243021-14243630` EOF Range 及 `9953081-10215224` 的 70% frame seek 跳转；其前未从 byte 0 下载至目标。总 upstream wireBytes（含 headers）2625156，明显小于 14243631-byte fixture；这是本 fixture 的有界随机访问证据。Proxy bytes 是 snapshot delta，会有 in-flight/prefetch，与 wireBytes 不同，不能相加作为唯一下载总量。

## Timeout / active cancellation

Simulator-only StallingSource → real proxy socket → real FFmpeg I/O；取消前必须 source.reads > 0 且 Promise 未完成。

| Case | Real result | Round03 observation | Cleanup |
| --- | --- | --- | --- |
| Timeout 600ms | PASS，FF_TIMEOUT | 656ms，startedReads 1 | closes 1、sources/clients 0/0；独立及后续 local probe 成功 |
| 10 active cancel cycles | PASS，FF_CANCELLED | 106–112ms；5 probe + 5 extractFrame；每次 startedReads 1 | 每次 closes 1、0/0；另一个 wrapper 相同 external ID 请求成功 |
| close active request | PASS，FF_CANCELLED | 106ms，startedReads 1 | closes 1、0/0 |

异步 Promise 均 settle；未观察到 crash/use-after-free。来自实际阻塞 native IO，不以 pure mock cancel 代替。

## Invalid / corrupt inputs

| 实际 native 输入 | 结果 | Error code |
| --- | --- | --- |
| invalid scheme | PASS | FF_INVALID_INPUT |
| malformed localhost | PASS | FF_INVALID_INPUT |
| embedded userinfo | PASS | FF_INVALID_INPUT |
| CR / LF / NUL（三项） | PASS / PASS / PASS | FF_INVALID_INPUT |
| nonexistent file | PASS | FF_OPEN_FAILED |
| corrupt regular file | PASS | FF_OPEN_FAILED |

Harness 检查 detail ≤256 且不含完整输入/localhost；只输出 error category，没有打印 locator/detail。没有放宽 API contract。

## Concurrency / lifecycle

PASS：两个 independent probes 同时运行；probe + extract 同时运行；cancel 一个 blocked request 时另一个 wrapper 相同 external ID probe 成功。未超越 active job cap。

每轮均完成 20 次 create → alternating probe/frame → close twice → post-close request rejects。未观察到未 settle Promise、stale ID collision、loader failure、crash。02/03 force-stop 后新进程重跑；03 在 lifecycle 序列中 Home 观察 BACKGROUND，aa start 观察 FOREGROUND，余下循环继续完成。

| Round03 process observation | Threads | VmRSS KiB |
| --- | --- | --- |
| Cold launch | 15 | 99044 |
| Native initialized | 36 | 183412 |
| Lifecycle start | 38 | 232172 |
| Lifecycle 10 | 39 | 227164 |
| Complete | 36 | 233612 |

仅用 public `/proc/<pid>/status` 采样，没有访问私有 app storage。循环期间未见持续 thread 增长；native load 后线程增加不能当作泄漏。有限 RSS 样本不能证明 leak-free，也不是 heap/native allocation profiling。

## Security / production isolation

Round03 app PID 的 1041 行 hilog：Authorization、Cookie、proxy token URL、upstream fixture path、userinfo、signed URL query 检测匹配均为 0（[security-scan.json](validation/ffmpeg-phase1b/security-scan.json)）。结论限于该窗口及所列 pattern。Native AV_LOG_QUIET 保留；runtime JSON 白名单仅 case/codec/container/numeric/hash，无 native detail/input/config；raw hilog 不提交。

NetworkMediaLoader、NetworkMediaProbe、System probe/extractor routing、PlaybackBackendSelector / Auto、AdaptivePlaybackPort、MpvPlaybackPort、protocol transports、IMediaProbe / IThumbnailExtractor 均未修改。没有 direct AVIO storage callback、FFmpeg playback、hardware decode。

Common EntryAbility 仅 import/configure/run entry/RuntimeDiagnostics；default no-op，simulator 启动参数才运行 harness，无 UI 按钮/ABI if。Static guard PASS；default Debug/Release source maps 实际没有 FfmpegRuntimeSmoke 或 simulator RuntimeDiagnostics，仅 default no-op（[default-isolation.json](validation/ffmpeg-phase1b/default-isolation.json)）。

## 失败、root cause、最小修复与重试

| 失败命令 / 原始错误 | Root cause / 修改 | Commit | 完整重试 |
| --- | --- | --- | --- |
| 首次 verify-simulator.ps1 CompileArkTS：10605030 Structural typing is not supported，Native.ets:5:84 | NAPI index.d.ts 重复模型，与 ArkTS nominal type 不一致；candidate d.ts import 又失败 10605999 Importing ArkTS files in JS and TS files is forbidden。改 index.d.ets 引用 NativeModels，更新 native package types，删除重复 d.ts | f99b4fd0a65ede8d7d019bd4f7a83ad1e8e27a49 | simulator03/final PASS；完整 default03/final04 PASS；真实 factory runtime PASS |
| default02 verify.ps1 exit 0，但 HAP 仅 6 libs、缺真实 MPV | simulator override 污染后续 default dependency graph。新 negative fixture RED Missing expected exception；guard 拒绝 Missing production MPV library: libmpv.so；正常 ohpm install 恢复，无手改 lock | d8dad1d757c5b7e6a13b9603d540903aba99567a | guard 6/6 GREEN；default03/final04 两种 HAP 各 9 AArch64 libs。旧 default02 artifact 记 FAIL |
| runtime01 HEAD 8034ms 超时；host 同请求约 9800ms | WSL 冷启动/容器恢复超过 provider 8s deadline。host helper 保持既有 distro warm，HEAD 156ms；未改 app/provider deadline | d8dad1d757c5b7e6a13b9603d540903aba99567a | runtime02/03 全套各 46/46 PASS |
| Fixture 初次生成：Unknown encoder libx264 | host /usr/local/bin/ffmpeg 无编码器；改现成 /usr/bin/ffmpeg，无 Harmony bootstrap 改动 | 无生产代码修复 | generation02 PASS，独立 ffprobe 与 native 数值一致 |
| Host Range ledger 01/02 未完整记录 GET | collector 未解析 keep-alive 后续请求；修 host-only parser 逐请求记录 | d8dad1d757c5b7e6a13b9603d540903aba99567a | 03 实际 11 GET + 1 HEAD；旧 Range evidence 不记 PASS |

Native 类型变更只涉及声明，C++/公共 architecture contract 未变。新增 boundary guard 先 missing target RED 再 GREEN。所有源码小提交，最终报告独立提交。原始错误摘要及 ignored source log SHA：[command-evidence.json](validation/ffmpeg-phase1b/command-evidence.json)。

## 清理、剩余范围与决定

本次 host fixture/config helper、自己的 WSL keeper/子进程已停止；原 test-lab 中自己的 remote fixture 经 SHA256 比对后删除；未停止既有协议服务或 shutdown 用户 WSL。App 清理本次文件；最后 force-stop 后无 smoke 参数普通 launch 成功。[cleanup.json](validation/ffmpeg-phase1b/cleanup.json)。

- arm64 device runtime：NOT RUN，无设备；AArch64 build PASS 不代替 runtime。
- 与私有 UI shared proxy 实例交互：NOT RUN；测试用一个共享真实 proxy 实例。
- 长时间内存/heap profiling：NOT RUN；不宣称 leak-free。
- HDR/Dolby Vision TV mode、Atmos/DTS-HD/TrueHD passthrough、hardware decode：NOT RUN，不从 metadata/fixture 解码推断。
- System / MPV / Auto 比较 benchmark、Auto 调整：NOT RUN。elapsed 是诊断数据，不是五次重复 benchmark；无策略修改。
- 无需修改公共 architecture contract 的 blocker；production analyzer/routing integration 未开始。

Decision：**READY FOR FFMPEG ANALYZER INTEGRATION REVIEW**。全部可执行 gate 完成，已停止；不 merge，不继续下一阶段。
