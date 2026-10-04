# Build Isolation Hardening Report

Status: PASS — READY FOR FFMPEG ANALYZER INTEGRATION

仅表示本轮构建隔离验证完成，交回架构审查；未开始 analyzer 接入，不 merge。

## Git / Environment

- 日期：2026-10-04；分支 `fix/simulator-default-dependency-restore`。
- Starting SHA：`c9f8ee03e0b8ac9b9d48b421f7e19aa3b1332dee`；开始时 clean checkout。
- Final tested source SHA：`ce24be1daf12892bfaa028bcd138fca25116a320`。随后仅报告和脱敏证据变化。
- Final docs SHA：用 `git log -1 --format=%H -- docs/BUILD_ISOLATION_HARDENING_REPORT.md` 查询包含本报告的提交；交付消息给出最终 SHA，避免写入文件自身 SHA。
- 隔离目录：`D:/Linkora-validation`。原 `D:/Linkora` 的 main、用户修改未动。
- Host：Windows / PowerShell 7；DevEco 26.0.0.821；SDK 26.0.0.105 / API 26；Hvigor 6.26.4；ohpm 26.0.0.630。
- Emulator：7.0.0.107(SP8DEVC00E999R4P11)，x86_64，HDC 127.0.0.1:5557。
- 完整阅读并执行 [CODEX_BUILD_ISOLATION_HARDENING.md](CODEX_BUILD_ISOLATION_HARDENING.md)。证据索引：[validation/build-isolation/README.md](validation/build-isolation/README.md)。

## Default Baseline

文档要求的初始正常 `ohpm install`：PASS。整个测试只有这次人工初始化 install；后续没有人为插入 install，依赖恢复均来自 `verify-simulator.ps1` 的 finally。

完整 `scripts/verify.ps1`：exit 0，architecture、persistence、adapter checks、FFmpeg pure、Hypium、8 HAR + 2 HAP 构建完成。实际 Debug / Release HAP 各有全部 9 个 AArch64 native libs；分别留存 manifest 与哈希，不把后来的 Release 输出冒充 Debug。

## 两轮 simulator → default 连续验证

| 验收轮次 | Simulator | 自动恢复 | 紧接着 default | Debug / Release native set | 手动补 install |
| --- | --- | --- | --- | --- | --- |
| Cycle 1 | exit 0；1 x86 FFmpeg .so | finally 正常 ohpm install 完成 | exit 0；完整 verify | 9 AArch64 / 9 AArch64 | NO |
| Cycle 2 final | exit 0；签名 HAP，1 x86 FFmpeg .so | finally 正常 ohpm install 完成 | exit 0；完整 verify；Hypium 164/164 | 9 AArch64 / 9 AArch64 | NO |

调用顺序是实际 `verify-simulator.ps1` → `verify.ps1`，没有另行运行 restore/helper install。记录的外层调用间隔分别为 23ms、64ms（不表示子进程启动耗时）。[commands.json](validation/build-isolation/commands.json) 和 [restoration-sequences.json](validation/build-isolation/restoration-sequences.json) 记录实际退出码/时间。

保留未计入验收的第一次 Cycle 2 采集：构建、ABI audit、自动恢复日志正常，但 Windows PowerShell 5 的外层采集器未取得 child ExitCode，记录为 null，不能认作 exit 0。修正 ignored host collector：先保持 process handle、拒绝空退出码、改用 PowerShell 7，然后重跑整轮 simulator → default。原始 null 记录保留并标记 acceptanceCounted=false；没有为了绕过失败修改仓库 verify 脚本。

Ruling：Debug HAP 在其成功 audit marker 后立即只读捕获，随后由 Release 覆盖同一 output path。理由是各模式必须有真实独立 artifact evidence；漏采的代价是重跑该轮，不能推断 Debug 哈希。本次各轮均捕获成功。

## Failure-path Restoration

- 临时故障：安全核对绝对路径后，将 ignored `third_party/ffmpeg/prebuilt/x86_64` 目录移到同级临时 aside；没有修改 tracked lockfile、manifest、headers 或 libs 的内容。
- 实际 target dependency resolution 先执行：日志中 real MPV package 被 simulator override 移除、ohpm install 完成，随后才进入 Native build。
- 预期失败：`simulator@BuildNativeWithNinja`，00303300；`libavformat.a ... missing and no known rule to make it`；`verify-simulator.ps1` exit **1**。
- finally 实际执行正常 ohpm install，重新解析 registry `@mpv-ohos/mpv-arkts@1.0.0`，完成恢复。
- 只还原 x86 目录，manifest SHA256 原样核对：`4a037eb0d3be8feb5b29af6a9b21f42bd4163f7711e8e26fc4541529d7c21b8b`；aside 不再存在。
- 未手动执行 install。紧接着完整 default verify：exit **0**；8 HAR + 2 HAP；Debug / Release 各 9 AArch64 native libs；Hypium **164/164**，Failure 0 / Error 0 / Ignore 0。

结论：**PASS**，失败发生在真实 simulator 依赖解析之后，自动 cleanup 恢复经后续真实 default 两种产物验证。Intentional simulator failure 本身记录 FAIL / exit 1，不将失败命令写成 PASS。证据：[failure-mechanism.json](validation/build-isolation/failure-mechanism.json)、command-evidence.json。

## Artifact Guard

最终 `node --test scripts/check-ffmpeg-artifact.test.cjs`：**16/16 PASS**。

- 完整 9-library arm64 fixture：PASS。
- 逐一仅缺 aki_jsbind、c++_shared、FFmpeg、SMB、SFTP、FTP、NFS、MPV、MPV wrapper：各自被拒绝，PASS。
- simulator 仅接受一个 x86 FFmpeg library；错误 ELF machine、生产 native library、unknown library 被拒绝：PASS。
- Missing analyzer、invalid ELF、旧 simulator-contaminated incomplete default fixture 被拒绝：PASS。

本次仅补充缺库独立 fixtures / unknown simulator fixture，不修改既有 guard 实现。新 tests 对已有实现首次运行即 GREEN，不伪造 pre-fix RED。

## FFmpeg Manifest Guard

真实 pinned manifests 包含 exact `ffmpeg_commit=1041abdc962f4cc4f394aa8de9dc5236c0c3b9e7` 与各自 exact ABI 行；真实 arm64 / x86 native builds 已通过。

另在 ignored 独立目录复制 manifest，通过真实 SDK CMake 对生产 CMakeLists.txt configure：

| Copied fixture | 实际结果 |
| --- | --- |
| wrong commit line | 非零退出，精确 manifest guard 拒绝：PASS |
| wrong ABI line | 非零退出，精确 manifest guard 拒绝：PASS |
| expected commit 仅作为 prefix/suffix value 子串 | 非零退出，精确 manifest guard 拒绝：PASS |

三个最终失败均命中 `FFmpeg prebuilt manifest must contain exact commit and ABI lines for x86_64`，不是用 unrelated configure error 代替。未改真实 pinned manifest，未伪造 headers/libs。

首次本地测试 driver 漏传 Hvigor 所需 OHOS_SDK_NATIVE / HMOS_SDK_NATIVE，CMake 在加载 toolchain 前失败，**不计为 manifest guard PASS**。根据真实 Hvigor CMakeCache 补齐 SDK root 参数、使用新的 isolated build dirs 后重跑，三项有效 negative checks 全部 PASS。初次环境错误保留在 evidence 摘要。

[manifest-negative-results.json](validation/build-isolation/manifest-negative-results.json) 包含实际 configure argument arrays 和退出码；原始 ignored configure logs 的哈希及 guard 错误在 command-evidence.json。

## Final Artifacts

最终 default 取故障恢复后那次完整 verify 的实际两个模式产物：

| Artifact | SHA256 | Native result |
| --- | --- | --- |
| Default Debug HAP | 8358f17d723de006a18f0c0a54ea2707e8468492c2a49582b6697bf7dae5337f | 9 libs，全部 ELF64 / AArch64 machine 183 |
| Default Release HAP | 18d7a44e8c3c0e218c123017a8229365eb92e90f8f43bcb24448a9a9e6026917 | 9 libs，全部 ELF64 / AArch64 machine 183 |
| Final signed simulator HAP | cac76b95e511e13547f83477c3e1e6120bfb3d35cff92a75cb8e6784e765ba1d | 1 lib，ELF64 / X86-64 machine 62 |
| Simulator packaged FFmpeg .so | f7a500c641e228753ea066ce7ecefb8b0e0694c6d5ab1bf476e3527b8de1e606 | 与已验收 Phase1B 相同 |

每个 default Debug/Release manifest 都包含：

```text
libaki_jsbind.so
libc++_shared.so
liblinkora_ffmpeg.so
liblinkora_smb.so
liblinkora_sftp.so
liblinkora_ftp.so
liblinkora_nfs.so
libmpv.so
libmpv_wrapper.so
```

实际 ELF/path/SHA256 清单：[failure-default-debug.json](validation/build-isolation/failure-default-debug.json)、[failure-default-release.json](validation/build-isolation/failure-default-release.json)；baseline 和两个 accepted cycles 的逐模式 manifest 也已提交。

Simulator 没有 real libmpv、生产 SMB/SFTP/FTP/NFS .so 或 unknown .so。临时使用已有开发者签名材料；本地 build-profile 字节原样恢复，材料/配置未提交。最终 signed HAP 保存后执行 `hdc install -r` 实际成功，普通 launch 成功，3 秒后 app PID 31552 仍存在且 Ability FOREGROUND；保留用户数据，无诊断参数。

本轮 install/launch smoke：PASS；不是 fresh 46-case runtime matrix。文档说明没有实际 install/runtime regression 时无需重复该矩阵；本次没有改 FFmpeg runtime 或观察到这类 regression。

## Final Regression / Tracked State

- 最终完整 default verify：PASS；architecture/persistence/HTTP adapter/media list/MPV mapping 等检查均未跳过。
- linkora_core / linkora_proxy / linkora_media_probe / linkora_ffmpeg：Debug + Release HAR 全部 PASS。
- entry default arm64 Debug + Release HAP：PASS，各 9 个 native libs。
- simulator parity guard：PASS；FFmpeg pure：15/15 PASS；最终 Hypium：164/164 PASS。
- tracked lockfiles diff：empty，包含 entry、linkora_ffmpeg 和 root；无人工 lockfile 构造。
- signing config diff：empty；byte-exact restore 确认。
- generated FFmpeg binaries tracked：none；temporary aside 已还原。
- Runtime source / MediaProxy / core contracts / main app / playback / production probe 路由相对起点无 diff。整个 hardening 分支的 FFmpeg C++ 变化仅构建 CMake manifest guard。
- 本次提交前只变更测试 fixtures、报告和脱敏证据；commit 后 final status 应为 clean，交付时再核对。

## Fixes / Execution Ledger

| Commit / 本地诊断 | 内容 | Verification |
| --- | --- | --- |
| 分支已有 920102e | simulator finally 正常恢复 default dependencies | 两轮 success + 一轮 post-resolution failure 恢复真实 PASS |
| 分支已有 a3aa5e0 / c99c77a | 完整 production native set guard / fixture | 每个实际 HAP 的 9-library audit + fixtures PASS |
| 分支已有 25d4c6a | exact-line CMake manifest matching | 真实两 ABI build + 三个 copied negative configure PASS |
| ce24be1daf12892bfaa028bcd138fca25116a320 | 新增逐一缺库及 unknown simulator fixtures | 16/16 PASS，完整 verify 使用同一源码 |
| ignored host collector 修正 | PS5 空 ExitCode 不计 PASS，缓存 handle / 使用 PS7 / 拒绝 null | 完整 Cycle2 重跑有效 exit0；原记录保留 |
| ignored CMake driver 修正 | 缺 SDK root 的初次 configure 不计 guard PASS，补实际 Hvigor 参数 | 全部三个有效 negative 命中 exact guard |

本次未新增生产修复。过程中按 baseline、Cycle1、Cycle2（含未接受采集和完整重跑）、intentional failure/default recovery、fixtures、manifest negatives、install/launch 的顺序持续填写进度；最终将所有结果汇总于本报告。Full raw logs、HAP、signing materials、临时 copied prebuilts 均留在 ignored artifacts。

## Independent Review / Rulings

一次 fresh whole-branch 只读审查覆盖 `47d5bf0 → ce24be1` 的完整 hardening diff 和实际证据：Critical / Important 均无。审查者独立重新打开 10 个 accepted HAP，逐一核对 whole-file/native SHA256、ELF 和 8 个 default 包内 module.json 的 Debug=true / Release=false；全部匹配。唯一 minor 是审查启动时报告仍为模板，已按原计划完整填写，无延期 minor。

对审查者 declined-to-judge 项作以下明示决定：

- Ruling：null exit 的初次 Cycle2 和未进入 manifest guard 的初次 SDK driver failure 不计验收；完整重试后才计 PASS。代价为额外验证耗时，不能省略失败记录。
- Ruling：本轮只新增所要求的 install/launch smoke，不重复已验收的 46-case matrix，不把它外推为新的 device/runtime PASS。理由是文档明确无 regression 时无需重跑；代价是本轮没有新的完整 runtime/真机证据。
- Ruling：最终报告由执行者按 raw evidence 自查；一次独立审查已核验源码和实际 artifacts，不再为最终文字发起第二次审查。代价是最终报告措辞没有第二次独立复核。

## Decision

**READY FOR FFMPEG ANALYZER INTEGRATION**（交回架构审查，未执行接入）。两轮 clean switches、一个 intentional failure 自动恢复、最终完整 default regression、artifact / manifest guards 均通过，达到文档停止条件。

未 merge，未修改 FFmpeg runtime、播放策略、生产 analyzer 路由。停止，不继续下一阶段。
