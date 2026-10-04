# Simulator Validation Report

> Status: BLOCKED — EMULATOR PLATFORM
> Branch: `test/simulator-validation`  
> x86_64 模拟器结果不替代 ARM64 真机验证；没有执行/没有采集的项目保持 NOT RUN。

## 1. Git / scope

- Starting SHA: `c26ed66d86ee0e2c72ae34fd23a4c4bf665b7ebc`。
- Final tested source SHA: `04814840403b54d8dd0e0e61798be1fb3f8f8da8`。
- Final documentation SHA: 见交接消息和 `git log -1`；文档不嵌入自身 commit hash。
- Checkout: `D:\Linkora-validation`；原 `D:\Linkora` dirty main 未 checkout、提交或修改生产源码。
- 完整依次阅读 SIMULATOR_TEST_MANUAL、FFMPEG_BOOTSTRAP、原 SIMULATOR_VALIDATION_REPORT，按 gate→build→runtime→bootstrap 执行。
- 未 merge、未修改 Auto policy / 公共 Architecture Contract / 生产 native transport 边界，未实现或集成 FFmpegMediaProbe/ThumbnailExtractor。

## 2. Environment

| Item | Actual environment |
| --- | --- |
| Host | Windows11 Pro10.0.26200 x64 / PowerShell |
| DevEco / SDK | 26.0.0.821 / 26.0.0.105 API26 |
| Hvigor / ohpm | 6.26.4 / 26.0.0.630 |
| Node | 最终 Studio bundled24.14.1；早期 default02 为 PATH24.13.1 |
| Emulator | HDC127.0.0.1:5555；OpenHarmony7.0.0.105；API26；x86_64 |
| Resolution | 1256x2760；全屏横向2760x1256 |
| UI automation | SDK hdc/uitest，按实时 dumpLayout bounds 操作 |
| Native SDK | `C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\native` |
| Target compiler | SDK clang15.0.4 OHOS；明确 OHOS triple / SDK sysroot |
| POSIX build | Git Bash；ignored local MSYS2 GNU make4.4.1 |
| Physical ARM64 device | NOT RUN：当前只有 x86_64 emulator |

## 3. Dependency / Sync

`git fetch --all`、指定分支 checkout/status、正常 `ohpm install` 已执行。真实 `@mpv-ohos/mpv-arkts@1.0.0` 正常解析，没有手工伪造 lock。

CLI Project Sync：首次 FAIL00303038，修复 schema 后 PASS/exit0；没有声称 GUI Sync。multi-target plugin 正常解析7.0.0，Seq 实际注册在 project root。simulator plugin 正常 OHPM 将 stub 注册 local。最终 `ohpm install` PASS（715ms），恢复真实 mpv dependency；最终 lock 与 Git baseline 无 diff。

## 4. Production Regression Gate / build matrix

`./scripts/verify.ps1` 完整 attempt02、03、06、最终07 PASS/exit0，失败未跳过。最终07 在正常 ohpm install 后执行，源码 SHA 如上。

| Tests | Result |
| --- | --- |
| Hypium | PASS：149 tests /18 suites /0 Failure /0 Error /0 Ignore |
| Seek regression red run | FAIL：149 tests /4 Failure /145 Pass，证明新增测试重现缺陷 |
| MPV adapter regression | PASS：5/5 |
| Architecture guard fixtures | PASS：5/5 |
| Architecture / simulator parity guards | PASS |
| Persistence / HTTP Range / network media list checks | PASS：完整入口真实执行 |

| Build artifact | Debug | Release |
| --- | --- | --- |
| linkora_core HAR | PASS | PASS |
| linkora_proxy HAR | PASS | PASS |
| linkora_media_probe HAR | PASS | PASS |
| entry@default arm64-v8a HAP | PASS | PASS |

现存 ArkTS warnings 与 unsigned default signing warning 保留，不表示验证失败，也不声称已为 default 真机安装签名。

## 5. Simulator parity

`node scripts/check-simulator-product.cjs` PASS。同源 UI、AdaptivePlaybackPort、BackendSelector、PlaybackEngine、Controller、Provider、shared MediaProxy、DB、probe 保留。Auto/System/MPV 实际可见；五种协议 picker/配置/路由实测。Native transport 与 MPV 替换均只在最终 native 边界。没有为 x86 修改生产架构。

## 6. Simulator build / install / launch

`./scripts/verify-simulator.ps1` attempt03/04/05 PASS/exit0；project-root assembleHapSeq，传 module=entry@simulator。

- Latest unsigned HAP SHA256：`9a48bf15b17a2efe87e977990cfec2f380dec368d340f47d83507c53c9beae1c`。
- Latest signed HAP SHA256：`3119dfb05f1fa22a31b30dc2414ae4d09c4c4d599eb3b07bac5c452f4765ad07`。
- Path：`entry/build/simulator/outputs/simulator/linkora-simulator.hap`；final副本在 ignored artifacts。
- Bundle：com.linkora.player；archive native检查 PASS：无libmpv、生产协议.so、未知.so；FFmpeg未集成。
- Unsigned install01 FAIL9568332/sign info inconsistent（HDC exit0不是成功）；latest signed install03 PASS。
- 兼容开发签名仅本地临时添加，finally原字节恢复 build-profile；无 uninstall/数据清空/签名材料提交。
- Force-stop/aa start 冷启动、本地/设置/串流/网络/播放页导航 PASS。

## 7. Playback preferences / Forced MPV / Auto

三 backend选择和重启持久化 PASS。原始 Auto，最终 cleanup 恢复并检查。

Forced MPV：本地 System可播H264-only文件受控 LNK-PLAY-007、Retry、Back PASS，没有转到System播放、native loader crash；不代表真实MPV支持。精确configure/open stack及resource count NOT RUN。

Auto+真实H264/AAC MKV（60s/640x360）10轮彩色首帧及播放中 PASS，stub不能实例化，因此成功最终backend为System。精确MPV-first selector/candidate次数、one-shot/no-second-fallback、瞬时stale状态、cleanup telemetry均 NOT RUN，不用能播放替代事件证据；deterministic Adaptive Hypium分别覆盖事件顺序。Auto策略没有调整。

## 8. System playback

| Case | Prepare / first frame | Pause/resume | Seek | EOF / replay | Release |
| --- | --- | --- | --- | --- | --- |
| Required Local H264/AAC MP4 | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN |
| Required HTTPS H264/AAC MP4 | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN |
| HEVC/AAC MP4,10s | FAIL5400106/LNK-PLAY-001 | NOT RUN | NOT RUN | NOT RUN | PASS：Back；资源计数NOT RUN |
| Local legacy H264-only MP4,2s | PASS | NOT RUN | NOT RUN | PASS | PASS：Back |
| HTTP H264/AAC MKV,60s | PASS | PASS | 50%/高位PASS | NOT RUN | PASS：Back |
| WebDAV H264/AAC MP4,60s | PASS | PASS | 10%/50%/90%PASS | NOT RUN | PASS：20轮Back/reopen |
| WebDAV H264/AAC MP4,600s | PASS | PASS | 50%/约93%PASS | NOT RUN | PASS：Back |
| HTTPS H264-only MP4,10s | PASS | PASS | 10%/50%/90%PASS | PASS | PASS：Back |

HEVC标为 SYSTEM_SIMULATOR_UNSUPPORTED，不外推ARM64codec。有效HTTPS为 [test-videos H264](https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_1MB.mp4)，HEAD200，ffprobe H264-only1280x720/10s/969201bytes，无AAC，不能伪记规定AAC样本PASS。此前公共URL404/403也保留。Local AAC未成功导入：sandbox/shared-media读取拒绝、hdc smode明确undebuggable；未绕过权限。

## 9. Network configuration / WebDAV

| Protocol | Fields/save/edit/restart | Delete/restart | Connection test | Directory/open |
| --- | --- | --- | --- | --- |
| WebDAV | PASS | PASS | PASS207；错误密码拒绝 | PASS真实Provider |
| SMB | PASS | PASS | PASS受控unavailable | PASS受控unavailable；native I/O NOT RUN |
| SFTP | PASS | PASS | PASS受控unavailable | PASS受控unavailable；native I/O NOT RUN |
| FTP | PASS | PASS | PASS真实ArkTS TCP | PASS受控unavailable；native I/O NOT RUN |
| NFS | PASS | PASS | PASS真实ArkTS TCP | PASS受控unavailable；native I/O NOT RUN |

使用现有 test-lab/protocols。WSL IP 对host/emulator路由超时，仅测试端宿主172.23.0.1 TCP→WSL stdio转发19280→19080、19221→12121、19249→12049，没有修改App网络实现。原用户profiles不删。

WebDAV正确/错误认证、root/Movies/Action多级目录、中文空格/City Chase空格文件、保存编辑重启、播放 PASS；20轮directory进出 PASS。Refresh 原动态插入重复旧sample行，修复RepeatItem Builder后即时正确显示，PASS。

Paused seek 原buffering卡住；修复后10轮50%/90%保持PAUSED，约30s/54s；10% resume PASS。

## 10. MediaProxy diagnostics

| Diagnostic | Actual evidence |
| --- | --- |
| activeSources before/during/after | NOT RUN：没有内部计数 |
| activeClients/releasedSources | NOT RUN |
| readRequests/bytesRead | 一次metadata probe delta为5/991017，非全程/active值 |
| localhost only | static/unit PASS；观察127.0.0.1:41127未关联PID，完整runtime断言NOT RUN |
| token无credential/upstream path | static/unit PASS；runtime token inspection NOT RUN |
| HEAD/GET/Range/suffixRange/416 | deterministic PASS；App localhost endpoint runtime矩阵NOT RUN |
| random remote seek | PASS：真实WebDAV upstream ledger |
| release source→0 | NOT RUN，不以Back成功代替资源计数 |

隔离长视频136060722bytes：121GET+1HEAD，总wire31503326bytes（含HTTPheaders，不当作App bytesRead）。50%从end10493951跳start66283018；高位约93%从end76768777跳start125216723，此前仅21004966wirebytes，未顺序读byte0到目标。精确90%由60s样本另验。提交ledger只有method/range/own-fixture标记和计数，不含auth/header/url/path。

## 11. Metadata / thumbnail

| Check | Result/evidence |
| --- | --- |
| duration/width-height/visible thumbnail | PASS：实测10s/640x360，目录实际缩略图 |
| Generation plan | PASS：hilog thumbnailPlan=2000:480:270:80:1，imageEncodingMs22/probe thumbnailMs83 |
| quality80/time/max480x270 | runtime计划+deterministic PASS；实际文件参数检查NOT RUN |
| aspect ratio | deterministic PASS；实际缓存尺寸NOT RUN |
| new WebP/no new JPEG | static/unit PASS；落盘magic/目录扫描NOT RUN |
| algorithmVersion/cache reuse | deterministic PASS；真实文件复用NOT RUN |

App/private/shared目录读取被拒绝，未伪造cache PASS。没有新增JPEG fallback或让MediaProbe编码缓存。

## 12. DB/settings/lifecycle

Remember position/keep screen on/experimental storage/cellular：反转、重启确认、恢复原值 PASS。外观Dark/Blue重启PASS，已恢复Follow system/system accent。扩展名新增.linkoratest保存重启、恢复完整原列表 PASS；首次UITest包装引号造成输入错误，改逗号单token后重跑通过，无生产代码修改。未观察DB迁移错误；独立旧DBmigration fixture NOT RUN。

| Cycle | Result |
| --- | --- |
| Player open/first frame/fullscreen/exit/back/reopen ×20 | PASS |
| Landscape/portrait ×20 | PASS |
| WebDAV directory enter/exit ×20 | PASS |
| Paused50%/90%seek pairs ×10 | PASS |
| Home/background→foreground ×10 | PASS：暂停约9s保留 |
| Auto MKV opens ×10 | PASS：最终System播放；精确fallback事件NOT RUN |

20张首图Pillow检查均有彩色testsrc，人工抽检1/10/20。早期测试误用两次Back退出全屏，按“退出”按钮改正、完整20轮重跑。重复远端screenshot filename留旧PNG尾部，后改唯一filename；只提交统计和新的独立截图。

内存中途VmRSS251152KB/49threads，循环后256392KB/47threads；缺初始baseline，不能证明无泄漏。Residual audio、forced surface recreation、精确stale-session、proxy leak count NOT RUN。期间未观察crash/ANR/black surface，不声称全面稳定性保证。

## 13. Error recovery / security

HTTP404/500/bad payload/60s stall均受控PlaybackFailure、Retry/Back PASS，恢复normal后重开PASS。stall为LNK-PLAY-006/5400102，精确timeout mapping NOT RUN。HEVC unsupported受控错误PASS（播放能力FAIL）。WebDAV错密码Retry/Close、stop directory2300052/重新加载/Back/recover PASS；播放中断网/invalid path NOT RUN。五种native unavailable控制路径PASS，不代表I/O能力。

WebDAV拒绝认证UI使用通用“服务器要求身份验证/当前直链没有携带认证信息”措辞；可证明拒绝和恢复正确凭据后207成功，不能证明精确区分缺凭据与错误密码。此文案/分类问题保留审查，未在收口阶段扩展error policy。

四份runtime hilog按测试密码、Authorization Basic/Bearer、Cookie、embedded URL credential、signed query模式扫描全零，PASS（仅这些模式/窗口）；sanitized JSON提交，raw日志ignored。Signing原配置恢复，新提交不含签名材料。Runtime proxy token/locator准确泄漏检查NOT RUN，零匹配不是全面安全保证。

## 14. FFmpeg bootstrap

Pin8.1.3/n8.1.3；HEAD1041abdc962f4cc4f394aa8de9dc5236c0c3b9e7；tag object23151b11c75aa44d9ab8db796a53c76acf00f6c0。Fetch02和existing-pin03 PASS。01失败refspec由`${Tag}`最小修复。

Target --target=x86_64-linux-ohos/aarch64-linux-ohos，真实SDK sysroot，--target-os=linux假设实际验证。Local junction仅避开路径空格，没有伪造header/lib。LGPL-default/static，disable programs/encoders/muxers/hwaccels/avdevice/avfilter/swresample/autodetect；无enable-gpl/nonfree。

| Step | x86_64 | arm64-v8a |
| --- | --- | --- |
| Fetch/pin | PASS | PASS：同源 |
| Configure | PASS | PASS |
| Four .a + headers + manifest | PASS | PASS |
| ELF machine / profile audit | PASS：四库全部X86-64 | PASS：四库全部AArch64 |

Host01 FAIL gcc:command not found→汇总C11缺失；host02 MSVC cl FAIL不接受-std=c17/c11；host03 Windows clang/MSVC环境成功。Host headers仅用于host工具，目标始终强制OHOSsysroot。两ABI构建均exit0，没有patch FFmpeg。各ABI133个include文件、四.a库、manifest齐全；readelf逐库所有archive members的machine均正确。config.h实测LGPL2.1-or-later、GPL/NONFREE/SHARED/FFMPEG/FFPROBE/FFPLAY/ENCODERS/MUXERS/HWACCELS全部0、STATIC1；prefix中无.exe/.so。Hashes、配置和可重现环境见`docs/validation/simulator/FFMPEG_BUILD_EVIDENCE.md`及audit JSON；生成的headers/libs只留ignored prebuilt，不混入HAP。

FFmpegMediaProbe/FFmpegThumbnailExtractor/System-vs-FFmpeg benchmark：NOT RUN，未接入App。

## 15. Fix commits / failure evidence

| Commit | Failure/original error | Root cause/changed files | Full retry |
| --- | --- | --- | --- |
| 1a417bdc91eb516eba267476448a4652085629fd | Sync/default01 00303038 targets[0].buildOption | schema层级；entry/build-profile.json5、check-simulator-product.cjs | Sync02/parity/default02 PASS |
| bae6cfd536d741592616e97d46a8db68eb52ac02 | simulator01 ParserError line72 unexpected Simulator | regex截断/重复finally；verify-simulator.ps1 | parser PASS；02到真实scope错误 |
| b6ea52ceeaf9d375ef4ecf26db44a31bbd87b281 | simulator02 00306054 assembleHapSeq not found | project task用module mode；verify-simulator.ps1/bundledNode | simulator03 PASS |
| b7a58e1b50d336ed0218a25a80b170c0d646ba34 | Pausedseek buffering；red4FAIL | 重叠seek/buffer END覆盖意图；PlaybackEngine.ets+4Hypiumcases | default03 149/149+8 builds；sim04/runtime10轮PASS |
| 1fab9e09bbdcec766029eb383d2a833d821dad4a | Refresh重复旧行；default04/05静态guardFAIL | Builder只收.item无Repeat复用绑定；NetworkDirectoryBrowser.ets/media-list静态匹配 | 误改detailLabels已纠正；default06/sim05/refresh PASS |
| 04814840403b54d8dd0e0e61798be1fb3f8f8da8 | fetch invalid refspec refs/tags//tags/n8.1.3 | PowerShell $Tag:refs scope歧义；fetch-source.ps1界定${Tag} | fetch02/03 pin PASS；最终default07 PASS |

各提交更新报告。完整失败/build/config日志本地ignored artifacts/simulator-validation保留；精简证据见docs/validation/simulator。Refresh依据[OpenHarmony官方Repeat说明](https://github.com/openharmony/docs/blob/master/en/application-dev/ui/rendering-control/arkts-new-rendering-control-repeat.md)，保留virtual list/cache/provider。

## 16. Cleanup / device-only / remaining gaps

五种测试profiles和两个串流链接已删除，force-stop/start后均不返回；原用户profiles保留。原Auto/两个player toggles、theme/network/scanning extensions已恢复，Auto最终截图人工确认。只删除自己生成的两个lab fixture目录，停止自己的HTTP fixture/TCP转发Node进程；原WebDAV Docker服务实测running，其它服务未停止。Cleanup初次工具误把空text的Button当确认文字，未确认删除；改按真实“删除服务器”dialog与Text确认重跑，逐个删除完成。最后重启时一次HDC超时，随后重新连接、重启结果和两页删除持久化独立确认。

真实MPV、SMB/SFTP/FTP/NFS native I/O、HDR10/HLG/native DolbyVision、DTS-HD/TrueHD passthrough、Atmos/DTS:X/AudioVivid、arm64 hardware decode/power/thermal：全部NOT RUN/DEVICE REQUIRED。声音或播放文件不证明native输出。

Benchmark NDJSON/report NOT RUN，不用emulator数据决定Auto。仍缺Local/HTTPS AAC规定样本、Auto精确telemetry、MediaProxy runtime完整矩阵/source回零、缩略图落盘证据。报告未将这些项目写成PASS。

## 17. Handoff decision

**BLOCKED — EMULATOR PLATFORM**

Default完整回归、八项生产构建、simulator build/install、可执行的功能循环、FFmpeg双ABI bootstrap均通过；当前模拟器不能完成规定Local AAC导入/私有cache检查、HEVC播放，且缺App内部proxy/Auto telemetry，因此完整功能与资源验收不能宣称全部PASS。对应NOT RUN/FAIL已逐项列明，不扩展产品代码来绕过平台限制。交回架构审查，保留真机/额外可观测性和fixture准备事项；不merge，不实现Analyzer，不进入下一阶段。
