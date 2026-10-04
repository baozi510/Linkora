# Linkora x86_64 模拟器测试手册

> 适用分支：test/simulator-validation  
> 目的：在不改变正式 arm64 产品架构的前提下，尽可能验证 ArkUI、System AVPlayer、HTTP/WebDAV、数据库、生命周期和错误恢复。

## 1. 设计边界

模拟器验证是独立产物，不是正式播放器产品。

正式产品保持：

~~~text
default product
  ↓
entry@default
  ↓
arm64-v8a Native
  ├─ MPV
  ├─ SMB
  ├─ SFTP
  ├─ FTP
  └─ NFS
~~~

模拟器产品：

~~~text
simulator product
  ↓
entry@simulator
  ↓
no CMake / no native .so
  ↓
System AVPlayer only
  +
HTTP / WebDAV only
~~~

模拟器 bundleName：

~~~text
com.linkora.player.simulator
~~~

正式产品 bundleName 仍然来自 AppScope：

~~~text
com.linkora.player
~~~

因此两个应用的数据、设置和安装身份互相隔离。

## 2. 模拟器产物明确不验证什么

下列项目在 x86_64 模拟器中必须标记 NOT RUN，而不是 PASS 或 FAIL：

- MPV runtime
- libmpv
- SMB native
- SFTP native
- FTP native
- NFS native
- FFmpeg analyzer
- OHCodec 真机硬件覆盖
- HDR10 真实显示输出
- HLG 真实显示输出
- Dolby Vision 原生输出
- DTS-HD MA passthrough
- TrueHD passthrough
- Atmos
- DTS:X
- Audio Vivid
- HDMI / AVR 行为
- 真机功耗、温度和电池
- arm64 Native 性能

模拟器测试不能替代 docs/ARM64_DEVICE_VALIDATION_RUNBOOK.md。

## 3. 当前 simulator target 的隔离规则

模拟器 target 必须满足：

- entry@simulator 不配置 externalNativeOptions。
- HAP 内不包含任何 .so。
- MPV 依赖使用 compile-only ArkTS stub。
- stub 如果被意外实例化必须立即失败。
- PlaybackComposition 强制返回 SystemPlaybackPort。
- 设置页只展示系统播放器。
- NetworkPage 只展示 WebDAV。
- HTTP 直链仍通过串流页测试。
- NetworkDirectoryService 在 simulator target 只注册 WebDAV / HTTP provider。
- simulator protocol test registry 不引用 SMB/SFTP/FTP/NFS adapter。

不要为了模拟器增加生产代码中的 CPU ABI 判断。

## 4. 测试前准备

开发环境至少记录：

- Windows 版本
- DevEco Studio 版本
- HarmonyOS SDK 版本
- Hvigor 版本
- ohpm 版本
- 模拟器系统版本
- 模拟器 API
- 模拟器 CPU ABI
- 模拟器分辨率

确认模拟器：

~~~text
model = emulator
CPU ABI = x86_64
~~~

准备媒体：

1. H.264 + AAC MP4，约 30 秒。
2. H.264 + AAC MP4，至少 10 分钟，用于 seek。
3. HEVC + AAC MP4，可选。
4. WebDAV 目录中放置同样的 MP4。
5. 一个不存在的 URL。
6. 一个错误认证 WebDAV 配置。
7. 一个支持 HTTP Range 的 HTTPS MP4。

不要在测试文档或 Git 中写真实账号密码。

## 5. Git 准备

~~~powershell
git fetch --all
git checkout test/simulator-validation
git status
~~~

工作树必须干净。

然后：

~~~powershell
ohpm install
~~~

再执行 DevEco Project Sync，使 multi-target package plugin 安装完成。

不要手工编辑 lockfile。

## 6. 第一门槛：正式 default 产品不能回退

模拟器分支首先仍需验证正式产品。

执行：

~~~powershell
./scripts/verify.ps1
~~~

必须：

- architecture guard PASS
- persistence regression PASS
- network probe/list regression PASS
- MPV adapter regression PASS
- Hypium PASS
- default Debug HAR/HAP PASS
- default Release HAR/HAP PASS

如果 default 产品因为 simulator 改造而失败：

停止模拟器测试。

优先修复 target 隔离，不允许删除正式功能来迁就模拟器。

## 7. 第二门槛：模拟器静态隔离

执行：

~~~powershell
node scripts/check-simulator-product.cjs
~~~

预期：

~~~text
Simulator product static checks passed.
~~~

它必须确认：

- simulator product 存在
- 独立 bundleName
- entry@default 与 entry@simulator 分离
- default 仍然 arm64 native
- simulator 无 CMake 配置
- MPV 使用 target-specific stub
- simulator playback = System only
- simulator network = WebDAV/HTTP only
- target override 文件存在
- main 层通过 target composition 注入

## 8. 第三门槛：构建 simulator HAP

执行 Debug：

~~~powershell
./scripts/verify-simulator.ps1
~~~

如需 Release：

~~~powershell
./scripts/verify-simulator.ps1 -BuildMode release
~~~

脚本会：

1. 执行 simulator static guard。
2. 查找官方 multi-target dependency plugin 提供的 assembleHap Seq task。
3. 构建 entry@simulator / product=simulator。
4. 找到 simulator HAP。
5. 解包检查。
6. 如果发现任意 .so，直接 FAIL。

成功时必须看到：

~~~text
No native .so entries were found in the simulator HAP.
~~~

### 如果找不到 Seq task

先执行 DevEco Project Sync，再查看：

~~~powershell
hvigorw tasks --no-daemon
~~~

记录真实 task 名。

只允许修正 scripts/verify-simulator.ps1 的任务发现逻辑。

不要因此改变生产依赖或 target 架构。

## 9. 安装模拟器 HAP

确认模拟器：

~~~powershell
hdc list targets
hdc shell param get const.product.cpu.abilist
~~~

预期 x86_64。

安装 simulator HAP。

成功后确认安装的是：

~~~text
com.linkora.player.simulator
~~~

而不是：

~~~text
com.linkora.player
~~~

若依然报 ABI mismatch：

1. 不继续运行测试。
2. 检查 simulator HAP 内容。
3. 若 HAP 中仍有 .so，则记为构建隔离 FAIL。
4. 若 HAP 无 .so 但安装仍失败，保存完整 bundle/install 诊断并停止交回架构审查。

## 10. App 启动测试

启动 simulator bundle。

验证：

- 冷启动成功。
- 首页正常渲染。
- 媒体库页可进入。
- 串流页可进入。
- 网络页可进入。
- 历史页可进入。
- 设置页可进入。
- 系统原生组件页可进入。
- Back 导航正常。
- 不出现 MPV native load 错误。
- 不出现 liblinkora native load 错误。

记录启动耗时仅作诊断，不作为性能 benchmark。

## 11. 模拟器产品 UI 限制验证

进入 设置 → 播放器。

必须：

- 只看到 系统播放器。
- 不显示 Auto 选择。
- 不显示 MPV 选择。
- 显示模拟器验证构建提示。

进入 网络 → 添加服务器。

必须：

- 只允许 WebDAV。
- 不显示 SMB。
- 不显示 SFTP。
- 不显示 FTP。
- 不显示 NFS。

如果 Native 协议仍可从 UI 创建，测试 FAIL。

## 12. 设置与数据库

验证设置保存：

- 记住播放位置
- 播放时保持亮屏
- 移动网络播放
- 实验性网络存储
- 主题
- 主题色
- 本地媒体后缀

操作：

1. 修改设置。
2. 完全关闭 App。
3. 重启。
4. 确认设置恢复。

数据库：

- App 首次启动数据库初始化无异常。
- 添加 WebDAV Server。
- 编辑 Server。
- 重启 App。
- Server 仍存在。
- 删除 Server。
- 重启后不应恢复。

检查日志无数据库 migration failure。

## 13. System AVPlayer — HTTPS 直链

进入串流页。

使用一个公开或测试环境中的 H.264/AAC HTTPS MP4。

验证：

- URL 校验
- 打开播放器
- PREPARING
- READY
- PLAYING
- first frame
- duration
- position
- pause
- resume
- 50% seek
- seek complete
- 90% seek
- completion
- replay
- back / release

记录每项 PASS / FAIL。

如果 HEVC 在模拟器不支持，记录：

~~~text
NOT SUPPORTED BY SIMULATOR SYSTEM BACKEND
~~~

不要外推到真机。

## 14. System AVPlayer — 本地 MP4

如果模拟器文件选择器和媒体文件导入能力可用：

- 导入 H.264/AAC MP4。
- 播放。
- pause/resume。
- seek 50%。
- seek 90%。
- completion。
- reopen。

如果模拟器无法提供可用本地文件选择环境：

记录 NOT RUN，并说明平台限制。

不要为了这一项在代码中写模拟器专用文件路径 hack。

## 15. WebDAV 连接测试

使用 test-lab/protocols 或一个可从模拟器访问的 WebDAV 服务。

验证：

- 添加 WebDAV。
- 正确账号密码 Test 成功。
- 错误密码 Test 失败。
- 保存。
- 目录 list。
- 多级目录。
- 中文文件名。
- 空格文件名。
- 返回上级。
- refresh。
- 删除服务器。

不要把密码写进日志或报告。

## 16. WebDAV 视频播放

使用 H.264/AAC MP4。

路径：

~~~text
WebDAV
  ↓
RandomAccessSource
  ↓
shared MediaProxy
  ↓
localhost URL
  ↓
System AVPlayer
~~~

验证：

- 打开
- first frame
- 播放 30 秒
- pause/resume
- seek 50%
- seek 90%
- completion
- replay
- back/reopen

如果失败，定位阶段：

- WebDAV auth/list
- HttpRemoteReadSession
- MediaProxy
- System AVPlayer prepare
- Surface
- seek

不要直接把所有失败归类为 AVPlayer。

## 17. MediaProxy 模拟器运行时

这是模拟器上非常有价值的一项。

对 WebDAV 视频记录：

- activeSources
- activeClients
- readRequests
- bytesRead
- releasedSources

验证：

- 仅 localhost listener。
- token URL 不包含 username/password。
- token URL 不包含远端 WebDAV path。
- HEAD 正常。
- GET 正常。
- Range 正常。
- seek 50% 后发生目标区域随机读。
- seek 90% 后不从 byte 0 顺序下载到目标。
- 退出播放器后 lease 被释放。
- activeSources 最终回到 0。

如果现有 UI/log 没有暴露 diagnostics，可用已有 debug/smoke test 接口收集；不要把凭据写入证据。

## 18. 网络 Metadata 与 Thumbnail

进入包含视频的 WebDAV 目录。

验证 System MediaProbe：

- duration 能显示。
- width/height 能显示。
- probe failure 不导致列表崩溃。

验证 Thumbnail：

- 实际出现缩略图。
- 新生成缓存为 .webp。
- 不生成新的 .jpg。
- quality 请求为 80。
- 横屏视频保持比例。
- 竖屏视频保持比例。
- 超宽视频保持比例。
- 最大 bounding box 为 480x270。
- 再次进入优先复用 cache。

如果系统模拟器不支持某容器抽帧：

记录 System extractor limitation，不得伪造 PASS。

## 19. Surface 与播放器生命周期

运行 HTTPS / WebDAV H.264 MP4。

验证：

- 首次进入正常显示。
- 全屏进入。
- 全屏退出。
- 改变模拟器方向。
- Surface size 更新后画面比例正常。
- Home / Background。
- 回到前台。
- Back 退出。
- 再次打开。

重复至少 20 次。

检查：

- 不持续黑屏。
- 不残留音频。
- 不收到旧 session 的状态。
- 不 crash。
- 不持续增加 MediaProxy activeSources。

## 20. Seek 状态测试

每个可播放 H.264 case：

- 10%
- 50%
- 90%
- 接近结尾

观察：

~~~text
PLAYING/PAUSED
  ↓
SEEKING
  ↓
seekDone
  ↓
恢复原合理状态
~~~

检查：

- position 更新。
- seekDone 只影响当前 session。
- 旧播放器 callback 不污染新播放器。

## 21. 错误恢复

测试：

### URL

- 空 URL
- 非 HTTP/HTTPS
- 404
- 500
- timeout
- 不支持的视频

### WebDAV

- 错误密码
- 不存在目录
- 服务端停止
- 播放中断开服务
- 恢复服务后重新打开

验证：

- UI 出现正确 Failure。
- Retry 可以重试。
- Back 可退出。
- 不死循环。
- 不重复创建后台任务。
- Proxy lease 能释放。

## 22. 前后台与配置变化

验证：

- 播放中 Home。
- 回到 App。
- 旋转。
- 横竖屏。
- 分屏（模拟器支持时）。
- Ability 重建（可操作时）。

记录播放状态是否符合当前产品设计。

模拟器结果只证明 System/ArkUI 生命周期，不证明 MPV 生命周期。

## 23. 安全检查

收集日志后搜索：

- Authorization
- Cookie
- password
- WebDAV 密码
- signed URL query
- proxy upstream locator

提交 Git 前必须脱敏。

确认 simulator bundle 不包含：

- libmpv.so
- liblinkora_smb.so
- liblinkora_sftp.so
- liblinkora_ftp.so
- liblinkora_nfs.so

## 24. 模拟器稳定性

最低要求：

- 20 次播放器进入/退出。
- 20 次 WebDAV 目录进入/退出。
- 10 次 50% / 90% seek。
- 10 次前后台切换。

观察：

- crash
- ANR
- UI 卡死
- Surface 黑屏
- 音频残留
- proxy source 泄漏
- 数据库异常

这不是 2 小时真机长稳替代品。

## 25. 不做性能结论

模拟器不要用于决定：

- System vs MPV 谁更快。
- Auto BackendSelector。
- first-frame 真机性能。
- seek 真机 P95。
- CPU/GPU 功耗。
- 温度。
- 硬件解码能力。

因此 simulator 结果不进入正式播放性能 Benchmark。

## 26. 测试报告

持续填写：

~~~text
docs/SIMULATOR_VALIDATION_REPORT.md
~~~

只能写：

- PASS
- FAIL
- NOT RUN
- BLOCKED

不得把未执行项写成 PASS。

必须记录：

- 测试 branch SHA
- DevEco / SDK
- emulator version / ABI
- simulator HAP SHA256
- HAP native-entry 检查
- default verify 结果
- simulator build 结果
- install result
- UI
- System playback
- HTTPS
- WebDAV
- MediaProxy
- Thumbnail
- DB/settings
- lifecycle
- errors
- security
- fixes + commit SHA

## 27. 允许修什么

模拟器验证过程中允许修：

- simulator target 构建配置
- sourceRoots 路径错误
- target-specific dependency 配置
- simulator-only composition/registry
- System AVPlayer runtime bug
- WebDAV ArkTS bug
- MediaProxy ArkTS bug
- UI / lifecycle bug
- database bug
- 确定性测试发现的问题

所有生产行为修复必须同时重新运行 default verify。

## 28. 不允许怎么修

禁止：

- 给生产代码增加 x86 ABI 分支。
- 伪造 x86 libmpv。
- 把 MPV 从 default product 删除。
- 把 Native 协议从 default product 删除。
- 为通过模拟器而改变默认 Auto 策略。
- 把 simulator stub 用进 default product。
- 用 simulator 结果宣布 HDR/DV/passthrough 支持。
- 开始 FFmpeg Analyzer。

## 29. 每次修复后的回归顺序

如果修改公共 main 源码：

1. node scripts/check-simulator-product.cjs
2. ./scripts/verify.ps1
3. ./scripts/verify-simulator.ps1
4. 重新安装 simulator HAP
5. 重跑受影响 runtime case

如果只修改 simulator target 文件：

1. check-simulator-product
2. verify-simulator
3. 受影响 simulator runtime case

在最终交付前，无论如何都要再跑一次完整 default verify。

## 30. 完成标准

模拟器阶段可以交回架构审查的最低标准：

- default verify PASS
- simulator static guard PASS
- simulator Debug HAP build PASS
- simulator HAP 无 .so
- x86_64 emulator install PASS
- App launch PASS
- 设置/System-only UI PASS
- HTTPS H.264 smoke 有结果
- WebDAV list 有结果
- WebDAV H.264 playback 有结果
- 50% / 90% seek 有结果
- MediaProxy runtime 有结果
- Thumbnail runtime 有结果
- 20 次 open/close 有结果
- Security log scan 有结果
- SIMULATOR_VALIDATION_REPORT 完整

其中受模拟器平台能力限制的单项允许 NOT RUN，但必须说明原因。

完成后：

- 不 merge。
- 不开始 FFmpeg。
- 不调整 Auto。
- 提交报告与脱敏证据。
- 返回架构审查。
