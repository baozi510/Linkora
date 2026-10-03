# Player Architecture Validation Report

> 2026-10-04（Asia/Shanghai）。构建/单测门槛 PASS；真机及性能门槛 NOT RUN。
> 第 14 次完整 verify 已通过，Debug/Release arm64 HAP 均构建成功。停止代码扩展，交回架构审查。

## Post-validation 修正（本轮进行中）

已完整阅读 `CODEX_POST_VALIDATION_ACTIONS.md`，同步至 `145c6ed` 后按 A→B→C→D 执行。下文原验证记录保留为历史证据，本轮结果以本节后续更新为准。

- A：四个实际 MPV Adapter 的桌面 VM 回归修复前全部 FAIL（prepare 被日志提前拒绝、timeout 被取消、post-prepare onError）；现在 error stream 仅保存最近诊断，FILE_LOADED/12 秒 timeout 保持成功/失败依据。测试使用 wrapper double/受控时钟，无新增生产注入接口；不等于 native MPV 实测。新增检查加入 verify，原检查全部保留。
- A 回归：4/4 PASS；commit `ffe02c6`。修复前原始输出 `artifacts/validation/post-A-before.log`，修复后 `post-A-after.log`。
- B：新增 4 个 Hypium 测试（open 前尺寸、open 后更新、round/clamp、controller detach/reopen 旧事件隔离）。修复前 Hvigor test exit 1：`10505001 Property 'setSurfaceSize' does not exist on type 'PlayerFeatureController'`。UI 在 attach 前和 area-change 时转发，controller 委托现有 engine，不改变尺寸保存设计。
- B 修复后：Hvigor test exit 0，141/141 PASS，0 Failure/Error/Ignore；日志 `artifacts/validation/post-B-after.log`。
- B commit：`0d78d17`。
- C：新增 4 个 Hypium metadata-label 测试。修复前 Hvigor test 返回 exit 0，但 Hypium 为 145 total / 144 PASS / 1 Failure（`doesNotLabelBt2020SdrAsHdr: expect HDR equals [empty]`），因此不认定为通过。移除 primaries-only HDR 分支，保留 colorPrimaries 数据；PQ/2084→HDR10，HLG→HLG，其余空值，不声明 native HDR 输出。
- C 修复后：Hvigor test exit 0，145/145 PASS，0 Failure/Error/Ignore；原始日志 `artifacts/validation/post-C-before.log` / `post-C-after.log`。
- D、完整 verify、模拟器安装结果：PENDING。

## Git 与执行范围

- 仓库：`baozi510/Linkora`。
- 唯一工作分支：`test/player-architecture-validation`。
- 起始 SHA：`f46ffeec9afafe16e946b0636fbc4a13563a5e4a`。
- 最终已验证代码 SHA：`f3730df81239177711e68099c34a8648deb4b2b4`；此后的提交只归档报告/证据。
- 包含本报告的最终分支提交：以本报告所在的 Git commit 为准，交付消息给出完整 SHA；本地可执行 `git log -1 --format=%H -- docs/VALIDATION_REPORT.md` 定位。
- 干净检出：`D:\Linkora-validation`。原 `D:\Linkora` 位于 main，有大量用户未提交改动且没有 remote；原目录及其分支未修改。
- 已按用户顺序阅读 SESSION_HANDOFF、IMPLEMENTATION_STATUS、CODEX_TEST_RUNBOOK、TEST_MANUAL、FFMPEG_INTEGRATION_BLOCKER、ARCHITECTURE_TARGET、ARCHITECTURE_MIGRATION、PHASE4–8_REPORT。
- `git fetch --all`、`git checkout test/player-architecture-validation`、`git status` 按顺序执行，开始时工作树干净。
- 未修改 main/Phase 0–8 分支，未 merge PR，未调整 Auto BackendSelector，未实现 FFmpeg。

## 环境与依赖

| 项目 | 实测/检查值 |
| --- | --- |
| Host | Windows 11 Pro 10.0.26200，x64；PowerShell |
| DevEco Studio | 26.0.0.821，build 261.23567.138.36.2600821 |
| SDK | HarmonyOS 26.0.0.105，API 26 |
| 项目 target / compatible | 26.0.0 / 6.0.0(20) |
| Hvigor | 6.26.4 |
| ohpm | 26.0.0.630 |
| 构建 Node | DevEco bundled v24.14.1 |
| HDC | 唯一目标 127.0.0.1:5555；model=emulator，ABI=x86_64 |
| arm64 真机 / OS build | 无可用目标；NOT RUN |
| 协议实验室 | 现有 WSL Ubuntu Docker lab，执行时 IP 172.19.89.109 |

首次 `ohpm install` FAIL：`ohpm` 未在 PATH。将已安装 DevEco 的 tools/ohpm/bin、tools/node 加入本次命令 PATH 后，同一命令 exit 0。

`@mpv-ohos/mpv-arkts@1.0.0` 从 OHPM registry 正常下载/解析，生成 entry lock 中的版本、resolved URL 和 SHA512 integrity。没有手工修改或伪造 lock；没有 dependency downgrade。根目录/proxy lock 只有换行差异，经 Git 归一化后无实际 diff。依赖提交：`08f914df81685848c7e141bb0ad48dac9e2c2c9d`。

## verify.ps1

最终结果 **PASS / exit 0**。所有 14 次均运行原完整 `./scripts/verify.ps1`，未删除检查、未跳过失败步骤、未修改 verify 脚本。

第 14 次完成：architecture boundary、ArkUI V1 guard、桌面 SQLite persistence、HTTP/probe regression、media-list/cache regression、Hypium 编译及执行、全部 Debug/Release HAR/HAP。

```text
Verification completed: architecture boundaries, persistence checks, unit tests, HAR and HAP builds passed.
```

- 架构 guard PASS；另有受控 fixture 验证：生成 .test 中平台 import 被忽略，同一 import 放到 core/src 中仍 FAIL，纯平台无关源码 PASS。
- 桌面 persistence 7 个检查组 PASS；HTTP/probe 4 个输出组 PASS；media-list/cache/UI 回归 PASS。这些不是设备播放测试。
- 非阻断 warning：ArkTS API/deprecation/throw 提示、HAR applyToProducts、第三方 MPV bytecode 未 obfuscate/sourceMapsPath 缺失、无 signingConfig。保留原日志，不将 warning 解释为 runtime PASS。
- [逐次 verify 摘要](validation/verify-summary.txt)。完整原始日志在本地 `artifacts/validation/verify-01.log` 至 `verify-14.log`，被 Git 忽略。

## Build matrix

以下均来自本次 verify 第 14 轮。Debug 产物在 Release 覆盖共同输出目录前单独保存；已读取每个 HAR 的 metadata.debug 和每个 HAP 的 app.debug，分别确认模式。

| Target | Debug | Release | Debug bytes | Release bytes |
| --- | --- | --- | ---: | ---: |
| linkora_core HAR | PASS | PASS | 139340 | 84207 |
| linkora_proxy HAR | PASS | PASS | 23155 | 14803 |
| linkora_media_probe HAR | PASS | PASS | 22460 | 15637 |
| entry arm64 HAP | PASS（unsigned） | PASS（unsigned） | 49842031 | 46380428 |

命令：`hvigorw.bat assembleHar --mode module -p module=<module>@default -p product=default -p buildMode=<debug/release> --no-daemon`；HAP 对应 `assembleHap` / `module=entry@default`。

两个 HAP 均确认只包含 arm64-v8a native libraries，包括 libmpv.so、libmpv_wrapper.so、libaki_jsbind.so、libc++_shared.so 和四个 liblinkora 协议适配库。没有复制原工作区的签名材料。

[八个产物的路径、大小、SHA256](validation/build-artifacts.json)。实际二进制保存在 `D:\Linkora-validation\artifacts\validation\build\debug` 与 `release`；不提交 HAR/HAP 到 Git。构建成功不证明可安装或播放成功。

## Hypium 单元测试

verify 内结果：**137 total / 137 PASS / 0 Failure / 0 Error / 0 Ignore**，18 个已注册 suite 全部执行。

构建矩阵确认后，按要求独立再次运行 `hvigorw.bat test --mode module -p module=entry@default -p product=default --no-daemon`：**PASS / exit 0；137 total、137 PASS、0 Failure、0 Error、0 Ignore**。

| Suite | Total | Pass | Fail |
| --- | ---: | ---: | ---: |
| NetworkLinkParser | 9 | 9 | 0 |
| MediaSource | 5 | 5 | 0 |
| ArchitectureContracts | 6 | 6 | 0 |
| NetworkStorageProvider | 2 | 2 | 0 |
| PlaybackEngine | 9 | 9 | 0 |
| PlaybackBookmark | 3 | 3 | 0 |
| FailureCatalog | 7 | 7 | 0 |
| LocalMediaAsset | 17 | 17 | 0 |
| FeatureModules | 36 | 36 | 0 |
| PlayerGestureController | 4 | 4 | 0 |
| NetworkAddressParser | 5 | 5 | 0 |
| LocalMediaOrdering | 7 | 7 | 0 |
| AppNavigationParams | 6 | 6 | 0 |
| NetworkDirectoryState | 3 | 3 | 0 |
| NetworkFileProxy | 8 | 8 | 0 |
| SystemMediaStages | 2 | 2 | 0 |
| ThumbnailPolicy | 3 | 3 | 0 |
| NetworkMediaProbe | 5 | 5 | 0 |

[原始逐项结果](validation/hypium-results.txt)，[结构化汇总](validation/hypium-summary.json)。SDK unit runner 使用平台 mock；不能替代真机原生 API、codec、surface 或 transport 验证。Auto selector 基线有单测，Adaptive candidate fallback/event isolation 实际运行仍 NOT RUN。

## System / MPV / Auto 真机 smoke

| 样本 | System | MPV | Auto |
| --- | --- | --- | --- |
| Local H264/AAC MP4 | NOT RUN | NOT RUN | NOT RUN |
| Local HEVC/AAC MP4 | NOT RUN | NOT RUN | NOT RUN |
| Local MKV | NOT RUN | NOT RUN | NOT RUN |
| WebDAV MP4 | NOT RUN | NOT RUN | NOT RUN |
| WebDAV MKV | NOT RUN | NOT RUN | NOT RUN |
| SMB MKV | NOT RUN | NOT RUN | NOT RUN |

每行的启动/prepare、active backend、first frame、play/pause、50% seek、90% seek、duration/position、buffering、EOF、release 均 **NOT RUN**。MPV 包和两个 HAP 都为 arm64；未将 x86_64 模拟器当作真机，也未改 ABI 绕过限制。

Auto one-shot fallback、失败 candidate duration/tracks/HDR/error 隔离、强制 System/MPV 不 fallback 的 runtime smoke 均 NOT RUN。没有发现经运行证明的 mpv API/Adapter 不一致；目前仅能确认真实包类型可编译，错误日志是否 fatal 等行为仍需设备。

## 网络协议实验室

运行验证分支的 `test-lab/protocols/scripts/verify.sh`，使用现有 lab/media/keys，exit 0。服务端检查与应用验证严格区分：

| 协议 | 服务端本轮结果 | Linkora list/stat/open/readAt | 应用 MediaProxy | System / MPV / Auto |
| --- | --- | --- | --- | --- |
| WebDAV | PASS：auth、guest、401、206 Range 1024 bytes | NOT RUN | NOT RUN | NOT RUN |
| SMB | PASS：password、guest、invalid password | NOT RUN | NOT RUN | NOT RUN |
| SFTP | PASS：password、key、host fingerprint | NOT RUN | NOT RUN | NOT RUN |
| FTP | PASS：password、anonymous、invalid password | NOT RUN | NOT RUN | NOT RUN |
| NFS | PASS：v4 read-only export | NOT RUN | NOT RUN | NOT RUN |

[服务端原始输出](validation/protocol-lab.txt)。应用中的 MP4/MKV、50%/90% seek、断连/恢复、指纹拒绝、取消等手册检查 NOT RUN。未把服务端 PASS 外推成应用协议播放 PASS。

## MediaProxy

| 检查 | 单测/静态证据 | 应用 runtime |
| --- | --- | --- |
| Range parsing / unsafe offsets / serialized read / cancellation ownership | NetworkFileProxy suite 8 PASS | NOT RUN |
| 新实例空 diagnostics / 重复 close | Hypium PASS | 有 lease/source 的实际退出未测 |
| localhost only / token 隐私 | 源码检查通过相关架构门槛 | NOT RUN |
| HEAD / GET / closed/open/suffix Range / 416 | parsing unit 不等于 TCP response | NOT RUN |
| lease release、URL invalidation、activeSources 最终 0 | 无应用会话证据 | NOT RUN |
| 远程 70% seek 不从 byte 0 顺序下载 | 无读取轨迹/bytesRead 证据 | NOT RUN |

**Runtime diagnostics 未采集**：activeSources、activeClients、readRequests、bytesRead、releasedSources 均 NOT COLLECTED。media-list desktop mock 的 bytesRead/readRequests=0 是测试桩值，不是实际 proxy 诊断，更不是资源无泄漏证明。

## Thumbnail

| 要求 | 已执行确定性测试 | 真机生成/文件检查 |
| --- | --- | --- |
| 新 WebP / quality 80 | PASS：真实 encoder 逻辑对 mock packer 发出 WebP/80 请求 | NOT RUN |
| WebP 不可用/编码失败不生成新 JPEG | PASS：loader 返回无缩略图，metadata 保留，无新 JPEG fallback | NOT RUN |
| duration 时间策略 | PASS：20s→4s；正常/长视频 60s cap | NOT RUN |
| <=480x270、比例保持 | PASS：480x270、480x200、152x270 的 policy 单测 | NOT RUN |
| algorithmVersion cache identity | PASS：实际 cache/key 与 SourceIdentity 代码验证 time/width/height/quality/algorithmVersion 任一变化均改变 key，同配置保持 key | NOT RUN |
| legacy JPEG read/migration | PASS：桌面缓存回归 | NOT RUN |

[直接 cache-key 对比结果](validation/thumbnail-cache-key.txt)。该检查运行真实 ETS cache/policy/SourceIdentity，只有平台 crypto binding 替换为桌面 SHA256；不验证设备文件系统。桌面假图像字节不是可解码 WebP 证据。新 pipeline 独立 NetworkThumbnailCache 路径已在回归中验证；MediaProbe 未承担编码/缓存。未新增 JPEG fallback。

## 媒体兼容、稳定性、安全与性能

- H264/AAC、HEVC/AAC、HEVC Main10、HDR10、HLG、Dolby Vision、DTS、DTS-HD MA、TrueHD、ASS、PGS、long GOP、4K remux：应用播放兼容性全部 **NOT RUN**。
- Native Dolby Vision mode、DTS-HD MA/TrueHD passthrough、Atmos、DTS:X、Audio Vivid、输出通道/AVR/TV 指示：**NOT RUN**；没有支持声明。
- 50 次换源、2 小时播放、内存/音频/surface/lease 回收、前后台/锁屏/旋转/分屏/Ability 重建、故障注入：**NOT RUN**。
- 本次报告/证据/修改文件扫描：PASS（见 security-scan.txt；未发现私钥/签名密码/真实认证 header/cookie；只代表归档内容）；设备 runtime credential log scan：**NOT RUN**。
- Benchmark：**NOT RUN**，没有 arm64 目标设备，verify 完成前也不作性能结论。没有每 case 至少 5 次的实测记录；没有生成 results.ndjson/report.md；未运行 summarize-benchmark，不伪造空记录或把 mock timing 当性能样本。
- Auto 策略保持现有 baseline，当前数据不足以调优。
- System vs FFmpeg analysis benchmark：**BLOCKED**，FFmpeg exit criteria 未全部满足。

## 失败、根因、修复 commit 与完整重试

所有下表失败由完整 `./scripts/verify.ps1` 捕获。子命令、原始错误、文件和重试均在表内，全文命令及更多错误见 verify-summary。每次修复后先独立 commit，再从脚本入口完整重跑。

| Attempt / 失败子命令 | 原始错误 / root cause | 修改文件 / commit SHA | 完整重试结果 |
| --- | --- | --- | --- |
| 01 / Node check-network-media-probe.cjs --unit | `TypeError: SystemMediaProbe_1.SystemMediaProbe is not a constructor`；VM resolver 为拆分后的相对 imports 返回空 exports | scripts/check-network-media-probe.cjs；`e6f0aa87f021067320059f65b175b35ec4a43951` | 02：probe PASS，下一项 media-list FAIL |
| 02 / Node check-network-media-list.cjs | `TypeError: linkora_core_1.DefaultThumbnailTimePolicy is not a constructor`；旧 mock 未更新 core/source API，旧 JPEG fallback/cache 路径预期违反当前规范 | scripts/check-network-media-list.cjs；`41f51bc489994f0fe2d63fae97f0b2e6c3779406` | 03：media-list PASS，Hvigor package config FAIL |
| 03 / Hvigor test GenerateLoaderJson | `00306046`，`Bytecode HAR [@mpv-ohos/mpv-arkts] not supported when useNormalizedOHMUrl is not true.`；项目未启用真实包要求的 normalized URL | build-profile.json5；`806fb5eafec01655387c9a2342b198f909bc3623`（初次放置错误） | 04：架构 guard 被旧生成物阻断；normalized 设置尚未验证成功 |
| 04 / Node check-architecture-boundaries.cjs | `.test/testability` 的 Index.ets/TestAbility.ets 被误判 core-platform-free violation；guard 扫描 Hvigor 生成文件 | scripts/check-architecture-boundaries.cjs；`27b133d046bfb9e545f0410ba9bdce90cbe8c393` | 05：guard PASS，schema FAIL；另有 fixture 确认真实 src violation 仍被拒绝 |
| 05 / Hvigor test schema validation | `00303038`：root only allows app/modules；我将 buildOption 放错到根层 | build-profile.json5；`96a15c53c25ed36d80b43f8f7d2303197b7095c7`（中间 app 层仍错） | 06：schema 继续 FAIL |
| 06 / Hvigor test schema validation | `00303038`：app also rejects buildOption；实际 schema 定义于 products.items.properties | build-profile.json5；`0d909926dc841bdf40026bbd3b1ce347aeaae075`，最终位于 app.products[0].buildOption.strictMode | 07：normalized/package/schema PASS，Native CMake FAIL |
| 07 / Hvigor test BuildNativeWithCmake | 首错 CMakeLists.txt:10 `third_party/libsmb2` absent；also libnfs absent / `No module named mbedtls_framework`；初始远程快照保留 .gitmodules 却丢失 gitlinks | 三个 native gitlinks；`cbbb29d6b327e5be090289e51250cb95ee79fad8` | 08：native PASS，ArkTS 编译 FAIL |
| 08 / Hvigor test UnitTestArkTS | `10605040 arkts-no-obj-literals-as-types`，ThumbnailPolicy:53；私有 fit 返回匿名对象类型不合法 | linkora_core/src/main/ets/thumbnail/ThumbnailPolicy.ets，内部 named interface；`328cb3c7d294d6b2136efe2014e1fa81751062d1` | 09：该 3 项错误消失，static-this FAIL |
| 09 / Hvigor test UnitTestArkTS | `10605093 arkts-no-standalone-this`；static methods 使用 this | NetworkMediaSourceFactory.ets、LinkoraFeatures.ets；`f26b9840a78e1bbc8628fddfdcb53bbe025916c0` | 10：static 错误消失，typed throw FAIL |
| 10 / Hvigor test UnitTestArkTS | `10605087 arkts-limited-throw`；catch 对象类型不能直接 rethrow | NetworkPlaybackSourceResolver.ets、AdaptivePlaybackPort.ets，保留原 error 的类型断言；`672d609ebfeff1bf0033278716a555b522827cd9` | 11：throw 错误消失，SDK 可选尺寸 stub FAIL |
| 11 / Hvigor test UnitTestArkTS | `10605999`，`number | undefined` cannot assign to number；PixelMapParams width/height 可选 | SystemMediaStages.test.ets；`fed71b5d9751f9b922a77656bc1934763a04de67` | 12：尺寸错误消失，PlaybackPort stub contract FAIL |
| 12 / Hvigor test UnitTestArkTS | `10505001`：FakePlaybackPort missing setSurfaceSize；测试桩没跟上 Phase 7 | PlaybackEngine.test.ets、FeatureModules.test.ets；`5375095ef7e304162203a2295c418eedc0a01de3` | 13：编译 PASS；Hypium 136 PASS / 1 FAIL |
| 13 / Hypium pausesSeeksAndClampsVolume | `expect seeking equals paused`；旧测试没有发送 seekComplete，却要求已恢复 PAUSED | PlaybackEngine.test.ets，先检查 SEEKING、发送完成、检查 PAUSED；`f3730df81239177711e68099c34a8648deb4b2b4` | 14：完整 verify PASS，137/137 单测及八个构建 PASS |

另有 dependency commit `08f914df81685848c7e141bb0ad48dac9e2c2c9d`，只包含 ohpm 正常生成的 entry lock。构建配置两次层级错误已完整记录，未隐藏或写成通过。

恢复的 native revisions 来自原本地 Git index，相关 libssh2/mbedtls CMake blobs 与远程相同，随后从 upstream checkout 精确 SHA：

- libsmb2 `b3d560c02fb1268320d2fd1c17fe841b0d93b85f`。
- libnfs `cee4ca723e081e6a18f51b838690a4c21e14bb2c`。
- mbedtls-framework `7d726d145d678aa7f5a7df3b9e7ee3dbce6ea1bf`。

后续干净 checkout 需要 `git submodule update --init --recursive`。没有任意选择新版本、修改 native library 实现或生成假库。

## 剩余 blocker 与交接

1. 真实 arm64 HarmonyOS 设备、对应 OS/build、签名/安装流程及固定媒体样本。当前仅 x86_64 emulator，两个 HAP unsigned；smoke、runtime proxy、真实 WebP、高级 AV/长稳/故障注入/性能均待实测。
2. Benchmark 缺实测 NDJSON 和每 case 至少 5 次数据，不能决定 Auto policy。
3. FFmpeg 仍为明确 blocker：缺 pinned reproducible arm64 build、headers/libav artifacts、license manifest、真实工具链 CMake integration 和 local MP4 / proxy MKV smoke 全套 exit criteria；本任务不开始实现。
4. MPV error stream 是否所有 error-level 行都应视为 fatal、first-frame/output/event 行为仍需要真实媒体/设备确认。Common track/external subtitle selection 是既有未实现项，本任务不扩展。

**Handoff decision: BLOCKED — TOOLCHAIN/DEVICE REQUIRED（具体缺少 arm64 目标设备/部署验证，已安装 SDK 构建可用）。**

已达到 verify PASS 和 Debug/Release arm64 HAP 构建成功的停止条件。提交验证分支及证据供架构审查；不 merge，不继续下一阶段。
