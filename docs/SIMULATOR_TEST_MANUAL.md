# Linkora 近真机 x86_64 模拟器测试手册

> 分支：`test/simulator-validation`  
> 目标：尽量运行与正式 arm64 产品相同的业务代码，只替换 x86_64 无法执行的底层 Native 实现。

## 1. 核心原则

模拟器不是精简版 Linkora。

以下必须与正式产品保持相同：

- ArkUI 页面与导航
- 设置页
- Auto / System / MPV 三种播放器选择
- PlaybackEngine
- PlaybackBackendSelector
- AdaptivePlaybackPort
- PlayerFeatureController
- MediaSource
- StorageProvider / RandomAccessSource
- MediaProxy
- NetworkDirectoryService
- WebDAV / HTTP Provider
- 数据库与缓存
- Metadata / Thumbnail 流程
- 网络服务器配置 UI
- SMB / SFTP / FTP / NFS 配置模型与保存流程
- Failure / Retry UI

只允许在最后平台边界替换：

```text
MPV
  arm64     -> real @mpv-ohos/mpv-arkts + libmpv
  simulator -> compile-only mpv package stub

Native storage transport
  arm64     -> SMB/SFTP/FTP/NFS real native providers
  simulator -> SimulatorUnavailableNativeStorageProvider
```

WebDAV/HTTP 不是模拟实现；default 和 simulator 共用：

`SharedNetworkStorageProviders.ets`

## 2. 当前产品关系

正式：

```text
product=default
entry@default
bundle=com.linkora.player
arm64-v8a
AdaptivePlaybackPort
real MPV
real native storage transports
```

模拟器：

```text
product=simulator
entry@simulator
bundle=com.linkora.player.simulator
x86_64 emulator
AdaptivePlaybackPort
MPV package replacement at final native boundary
native storage transport replacement at final boundary
real System AVPlayer
real HTTP/WebDAV
real MediaProxy
```

## 3. 模拟器能验证什么

重点验证：

- App 启动、页面、导航
- 设置持久化
- Auto/System/MPV 选择流程
- MPV unavailable 时的明确失败
- Auto 中 MPV candidate 失败后的 fallback
- System AVPlayer
- HTTPS 视频
- WebDAV
- RandomAccessSource
- MediaProxy
- Range / seek
- Metadata
- Thumbnail / WebP cache
- 数据库
- SMB/SFTP/FTP/NFS 配置保存、编辑、路由与错误 UI
- 生命周期
- cancellation
- retry
- stale session protection
- 安全日志

## 4. 模拟器不能证明什么

必须保留 NOT RUN / DEVICE REQUIRED：

- real libmpv runtime
- MPV hardware decode
- SMB/SFTP/FTP/NFS native file I/O
- ARM64 ABI 行为
- HDR10/HLG 真实显示输出
- native Dolby Vision output
- DTS-HD MA / TrueHD passthrough
- Atmos / DTS:X
- Audio Vivid
- HDMI / AVR
- 真机 GPU/功耗/温度
- System vs MPV 性能排名

## 5. Git

```powershell
git fetch --all
git checkout test/simulator-validation
git status
```

必须从干净工作树开始。

不要 merge PR #11。

## 6. 依赖

执行：

```powershell
ohpm install
```

然后执行 DevEco Studio Project Sync。

确认：

- 正式 target 仍解析真实 `@mpv-ohos/mpv-arkts@1.0.0`
- simulator target 使用 `entry/simulator-stubs/mpv-arkts`
- multi-target package plugin 正常加载

不要手工修改 lockfile。

## 7. 第一门槛：正式产品回归

每次公共源码发生修改，都先执行：

```powershell
./scripts/verify.ps1
```

必须全部 PASS。

至少确认：

- architecture guards
- simulator parity guard
- Hypium
- MPV adapter regression
- linkora_core Debug/Release
- linkora_proxy Debug/Release
- linkora_media_probe Debug/Release
- entry default Debug/Release arm64 HAP

如果 default 产品失败，先修 default；不能为了 simulator 删除正式能力。

## 8. 第二门槛：近真机同构检查

执行：

```powershell
node scripts/check-simulator-product.cjs
```

必须输出：

```text
Simulator product parity/isolation checks passed.
```

重点确认：

- SettingsPage 仍包含 Auto/System/MPV
- NetworkPage 不隐藏 SMB/SFTP/FTP/NFS
- simulator 使用 AdaptivePlaybackPort
- WebDAV/HTTP 使用 shared provider
- simulator Native provider 只在最后 transport boundary 失败
- real MPV 仅在 target dependency 层替换

## 9. 第三门槛：Simulator HAP

执行：

```powershell
./scripts/verify-simulator.ps1
```

该脚本必须检查 simulator HAP。

禁止出现：

- libmpv.so
- libmpv_wrapper.so
- liblinkora_smb.so
- liblinkora_sftp.so
- liblinkora_ftp.so
- liblinkora_nfs.so

未来允许的唯一 simulator Native 模块：

- `liblinkora_ffmpeg.so`

且只有 FFmpeg Analyzer 真正集成后才允许出现。

## 10. 安装

确认：

```powershell
hdc list targets
hdc shell param get const.product.cpu.abilist
```

目标应为 x86_64 模拟器。

安装 simulator HAP。

确认 bundle：

`com.linkora.player.simulator`

如果仍出现 ABI mismatch：

- 保存完整 install 输出
- 解包 HAP 列出所有 .so
- 不修改正式 ABI
- 停止并返回架构审查

## 11. UI 同构检查

模拟器必须和正式版一样显示：

### 播放器

- 自动
- 系统播放器
- MPV

### 网络协议

- WebDAV
- SMB
- SFTP
- FTP
- NFS

如果模拟器通过隐藏功能来避免错误，本项 FAIL。

## 12. MPV replacement 行为

### 强制 MPV

选择：

`播放器内核 = MPV`

打开任意媒体。

预期：

- 进入真实 PlaybackEngine / AdaptivePlaybackPort
- 到 MPV backend 创建阶段才失败
- UI 显示可恢复错误
- 不 crash
- 不加载 arm64 libmpv
- 不 fallback，因为用户明确强制 MPV

### Auto + MPV-first case

使用 BackendSelector 会优先 MPV 的样本，例如 MKV。

预期：

```text
Auto
 ↓
select MPV
 ↓
simulator MPV backend unavailable
 ↓
one-shot fallback System
```

记录：

- 第一个 candidate 的错误是否泄漏进 committed snapshot
- 是否只 fallback 一次
- System 成功或失败的最终结果

此测试可以验证 Auto fallback 状态机，但不能证明真实 MPV 可播放。

## 13. System backend

强制：

`播放器内核 = 系统`

至少：

- H.264/AAC MP4
- 长视频 H.264/AAC MP4
- HEVC/AAC MP4（若模拟器支持）
- HTTPS MP4

验证：

- prepare
- first frame
- play
- pause
- resume
- seek 10%
- seek 50%
- seek 90%
- seekDone
- completion
- replay
- release

模拟器 codec 不支持时记录 SYSTEM_SIMULATOR_UNSUPPORTED，不外推到真机。

## 14. WebDAV

WebDAV 路径必须是真实共享代码：

```text
NetworkPage
 ↓
NetworkDirectoryService
 ↓
Shared WebDavStorageProvider
 ↓
HttpRemoteReadSession
 ↓
RandomAccessSource
 ↓
MediaProxy
 ↓
System AVPlayer
```

测试：

- 正确认证
- 错误认证
- 保存
- 编辑
- 删除
- 目录
- 多级目录
- 中文文件名
- 空格文件名
- refresh
- H.264 MP4 playback
- seek 50%
- seek 90%

## 15. MediaProxy

记录：

- activeSources
- activeClients
- readRequests
- bytesRead
- releasedSources

验证：

- 127.0.0.1 only
- token 无 credential
- token 无 upstream path
- HEAD
- GET
- Range
- 416
- 50% seek 使用随机区域
- 90% seek 不从 byte 0 顺序读完整文件
- player release 后 activeSources 回到 0

## 16. Native 网络协议的“前半条链路”

### SMB / SFTP

模拟器不可运行真正 native auth/list。

但必须验证：

- 协议可选择
- 所有配置字段可填写
- 保存数据库
- 编辑
- 删除
- 页面路由
- 点击连接测试时得到：
  `SIMULATOR_NATIVE_TRANSPORT_UNAVAILABLE`
- 不 crash
- 不出现找不到 provider 的异常

### FTP / NFS

当前 production 的 connection test 本身使用 ArkTS TCP reachability，因此模拟器可运行同一 adapter。

验证：

- connection-test UI
- host/port parsing
- timeout/error mapping
- 保存/编辑

真正目录浏览/open/read 到 simulator transport boundary 后必须明确报告不可用。

这能验证正式产品在 Native I/O 之前的大部分业务路径。

## 17. Database / Settings

验证：

- Auto/System/MPV preference persistence
- remember position
- keep screen on
- cellular policy
- experimental network storage
- theme/accent
- local file extensions
- WebDAV server
- SMB config
- SFTP config
- FTP config
- NFS config

重启后必须恢复。

删除后不得恢复。

## 18. Metadata / Thumbnail

WebDAV 视频：

- metadata duration
- width/height
- thumbnail visible
- new persistent thumbnail = WebP
- no new JPEG
- quality=80
- target time policy
- max 480x270
- preserve aspect ratio
- cache reuse

如果 AVMetadataExtractor 在模拟器对某容器不支持，记录平台限制。

## 19. Surface / 生命周期

至少 20 次：

- 打开播放器
- first frame
- fullscreen
- rotate
- fullscreen exit
- back
- reopen

同时测试：

- Home
- foreground
- Ability recreate（可执行时）

检查：

- black surface
- stale event
- residual audio
- crash
- proxy leak

## 20. Error injection

### HTTP

- 404
- 500
- timeout
- bad media

### WebDAV

- bad password
- bad path
- server stop
- playback during disconnect
- restore and reopen

### MPV simulator replacement

- forced MPV controlled failure

### Native storage replacement

- SMB/SFTP/FTP/NFS directory open controlled failure

所有错误必须：

- 有明确 Failure UI
- 可 Back
- Retry 不死循环
- resource 最终释放

## 21. 安全

日志搜索：

- Authorization
- Cookie
- password
- signed URL
- SMB password
- SFTP secret
- proxy upstream URL

不得提交真实凭据。

## 22. FFmpeg Bootstrap

FFmpeg 已开始双 ABI bootstrap，但尚未接入 Analyzer。

先读：

`docs/FFMPEG_BOOTSTRAP.md`

### Fetch

```powershell
./scripts/ffmpeg/fetch-source.ps1
```

必须验证最终 commit：

`1041abdc962f4cc4f394aa8de9dc5236c0c3b9e7`

### x86_64

在 POSIX shell：

```bash
scripts/ffmpeg/build-harmony.sh x86_64 "$OHOS_NATIVE_ROOT"
```

### arm64-v8a

```bash
scripts/ffmpeg/build-harmony.sh arm64-v8a "$OHOS_NATIVE_ROOT"
```

本轮目标只要求产出并验证静态库：

- libavformat.a
- libavcodec.a
- libavutil.a
- libswscale.a

如果失败：

- 保存 configure log
- 保存 compiler error
- 不使用 host library 绕过
- 不接入 FFmpegMediaProbe
- 返回架构审查

## 23. FFmpeg 尚不能写成 PASS 的项目

在 `liblinkora_ffmpeg.so` 尚未真正接入前：

- FFmpegMediaProbe = NOT RUN
- FFmpegThumbnailExtractor = NOT RUN
- System vs FFmpeg benchmark = NOT RUN

仅“FFmpeg 静态库双 ABI build”可以独立记 PASS/FAIL。

## 24. 稳定性

最低模拟器稳定性：

- 20 次 player open/close
- 20 次 WebDAV directory enter/exit
- 10 轮 50%/90% seek
- 10 次 background/foreground
- 10 次 Auto MPV-first fallback case

检查：

- crash
- ANR
- memory runaway
- stale event
- proxy source leak

## 25. 不做性能结论

模拟器数据不能用于决定：

- System 比 MPV 快
- Auto 最终 policy
- hardware decode coverage
- power
- thermal
- device seek P95

这些仍需 arm64 真机。

## 26. 报告

持续更新：

`docs/SIMULATOR_VALIDATION_REPORT.md`

状态只能：

- PASS
- FAIL
- NOT RUN
- BLOCKED

必须记录：

- branch SHA
- DevEco/SDK/Hvigor/ohpm
- emulator OS/API/ABI
- default verify
- parity guard
- simulator HAP
- install
- UI parity
- MPV replacement
- Auto fallback
- System playback
- WebDAV
- protocol config paths
- MediaProxy
- Metadata/Thumbnail
- lifecycle
- security
- FFmpeg x86 build
- FFmpeg arm64 build
- fixes + commit SHA

## 27. 修改后的回归顺序

公共代码变化：

1. `node scripts/check-simulator-product.cjs`
2. `./scripts/verify.ps1`
3. `./scripts/verify-simulator.ps1`
4. simulator runtime regression

仅 simulator target 变化：

1. simulator parity guard
2. simulator build
3. affected runtime cases
4. 最终仍跑一次完整 default verify

## 28. 停止条件

出现任一情况就提交证据并停止：

- default regression 失败且需要架构决定
- target dependency 机制与预期不符
- simulator HAP 仍打入 arm64 native 库
- Adaptive fallback 行为与 contract 不符
- MediaProxy 架构问题
- FFmpeg configure 暴露需要正式 HarmonyOS patch
- 公共 contract 需要修改

不要 merge。

不要自行调整最终 Auto policy。

完成后交回架构审查。
