# 开发与运行

## 网络文件代理实验（2026-10-02）

独立 HAR `linkora_proxy` 在 `LinkoraFeatures` 装配，协议随机读取由 entry 适配到 core 的 `RemoteReadSession`。HTTP 串流、WebDAV、现有渐进下载播放保持原链路；无设置选项或数据库变更。接入/移除步骤见 `linkora_proxy/README.md`。

- 构建与单元检查：`powershell -File scripts/verify.ps1`，包括 core/proxy 的 Debug/Release HAR 与 HAP。
- 无网络端点 smoke：Studio Node 运行 `scripts/check-network-proxy.cjs`；使用真实模拟器 TCP/HTTP，验证范围、短读、头部分片、16 KiB/8 秒头部限制、8 句柄/16 连接限制、取消、关闭与重建。
- 协议 smoke：追加一个被 Git 忽略的 fixture JSON 路径。格式为 `{ "cases": [...] }`；每项含 protocol、host、port、rootPath、remotePath、username、password、fingerprint、size、headHex、tailHex、middleHex。字节样本取原文件头尾各 32 字节和 `floor(size/2)` 起的 32 字节；SFTP 指纹必须匹配协商使用的主机密钥算法。
- 原生读取中取消：Studio Node 运行 `scripts/check-network-proxy-inflight.cjs <fixture路径>`。临时 TCP 端点确认读取请求到达后扣住回复，再通知应用取消；四协议断言读取拒绝、原生完成后关闭且不能继续读。FTP 被动数据端口通过 EPSV 重写为临时宿主端口；仅支持普通 FTP。省略 fixture 可单独验证 FTP 未结束的多行回复：取消、8 秒绝对截止时间、64 KiB 回复上限。
- fixture 通过仅监听 Windows 127.0.0.1 的临时 HTTP 服务传入 Debug 应用，入口只接受模拟器宿主桥地址 10.0.2.2 和随机路径；应用存入私有临时文件并在结束后删除。账号密码不进入命令参数或输出。脚本最后恢复普通应用启动。
- `LINKORA_HDC_TARGET` 可指定设备，默认 `127.0.0.1:5555`。结果在应用私有 cache 和本地 `artifacts/proxy-smoke-result.json`，只含检查名称与受控错误分类。

本次验证使用 API 26 模拟器和协议实验室：SMB、SFTP（严格指纹）、普通被动 FTP、NFSv4。不把这些结果扩展为 API 20 设备、NFSv3、FTPS、主动 FTP 或长时间播放的实测结论。WSL 实验室在测试期间须保持运行，否则短命令退出后的自动停止会中断容器。时长、分辨率与缩略图仍属于下一阶段。

## 工程规则

- 实现任何平台能力前先查阅当前 HarmonyOS 官方指南、API Reference 和本机 DevEco SDK 类型定义；优先使用系统 Kit，确认系统能力不满足后才能引入自实现或第三方依赖，并记录兼容 API、权限和降级方案。
- 页面只负责渲染状态和派发用户意图；Media Kit、Network Kit、文件与持久化 API 必须封装在对应服务或端口中。
- 跨模块数据使用明确模型，不用裸字符串或松散对象传递媒体、连接和错误信息。
- 新功能先定义接口与状态，再实现系统适配器；WebDAV、SMB、SFTP、FTP、NFS 不得直接依赖页面。
- 用户可见错误统一遵守 [ERROR_HANDLING.md](ERROR_HANDLING.md)，禁止在页面内散落错误码和重复文案。
- 异步请求必须处理重复触发、页面离开和迟到回调；持有系统资源的对象必须提供确定的释放路径。
- 每次提交至少通过单元测试、Debug/Release HAR 和 Debug/Release HAP 构建；设备相关能力还要记录模拟器或真机结果。

## DevEco Studio

使用 DevEco Studio 打开项目根目录 `D:\Linkora`，等待工程同步完成后选择 `entry` 模块。

- ArkUI Previewer 只能验证静态布局。打开 `PlayerPage.ets` 并启动 Previewer 时，页面使用内置预览状态，不会创建真实 `AVPlayer` 或访问文件。
- 真正的视频播放必须使用 Local Emulator 或已连接真机运行应用。
- 本地视频应在应用首页点击“选择本地媒体”，通过系统文件选择器授权；不能把电脑上的文件路径直接填给模拟器。
- 本机媒体扫描需要用户首次点击“开始扫描”并允许读取图片和视频。授权后应用启动时会自动刷新，扫描只读系统媒体库。
- 安装到设备前需要在 DevEco Studio 中配置自动调试签名或开发者证书。仓库不保存任何签名材料。

## 自动验证

在 PowerShell 中运行：

```powershell
./scripts/verify.ps1
```

脚本依次执行本地单元测试、`linkora_core` Debug/Release HAR 和 entry Debug/Release HAP 构建，并检查测试结果中是否存在失败。若 DevEco Studio 不在默认目录：

```powershell
./scripts/verify.ps1 -StudioRoot 'D:\Tools\DevEco Studio'
```

HAR 默认输出到 `linkora_core/build/default/outputs/default/`，未签名 HAP 默认输出到 `entry/build/default/outputs/default/`。成功打包不能替代正式签名和设备回归。

安装 Debug HAP 并启动模拟器后，可运行 `node scripts/check-stream-ui.cjs`，验证串流与服务器入口分离、地址校验、404 错误、系统媒体信息提取、查询参数保留、编辑/删除持久化、播放和历史记录。脚本使用本机测试视频与临时 HTTP 服务，结束后删除它创建的串流配置；播放历史中会保留带 `Stream regression API20` 名称的测试记录。

## 设备验收顺序

1. 使用系统文件选择器打开 H.264/AAC MP4，验证首帧、暂停、拖动、退出和再次打开后的进度恢复。
2. 首次拒绝与允许媒体库权限，验证错误恢复、空媒体库、非空列表、搜索、刷新和点击播放。
3. 验证 HTTPS MP4 与 HLS VOD；再验证 HTTP 地址的风险提示和系统版本兼容行为。
4. 执行前后台、来电/音频抢占、横屏全屏、断网和错误重试。
5. 扩展到 MKV、H.265、MPEG-TS、音频、多码率 HLS 与长时间播放矩阵。

自动构建不能替代设备验收。模拟器适合验证系统播放器、网络访问和页面流程；硬件解码兼容性、音画同步、功耗、温升与长稳数据仍必须使用目标真机完成。

# 网络媒体提取实验（2026-10-02）

`linkora_media_probe` 独立提供系统媒体信息和缩略图，此阶段先完成内部测试，之后正式接入见下节。Debug 构建后用 Studio Node 执行 `scripts/check-network-media-probe.cjs <私有协议fixture路径>`；fixture 沿用代理阶段的四协议配置，只从随机宿主 URL 传递，不进入命令行。宿主已有 ffprobe/ffmpeg 只用于测试参考与图像校验，不打包到应用。脚本结束恢复普通启动、关闭本次 HTTP 服务并删除设备临时图像/结果。

测试证据在忽略的 `artifacts/media-probe/`：`device-result.json`、实际 JPEG、系统头部独立对照及验证日志。设备为 API26 模拟器，不能当作 API20 实机结论。SMB/SFTP/FTP/NFS 与鉴权 WebDAV 经已有代理；普通 HTTP 直连。系统未转发自定义请求头的限制已通过绕开 HAR 的原生对照复现，因此 WebDAV 鉴权由应用 HTTP 客户端完成。

16 项真实场景覆盖五种协议/HTTP、缺失及错误鉴权、尾部索引、200ms短视频、不支持内容、确认系统已发起请求后的取消、八秒超时、实际 close、鉴权 WebDAV 在途取消及后续提取。缩略图请求224×126，本次实际也是224×126，导出JPEG经独立解码及视觉检查。代理统计实际 reader 返回字节与次数；HTTP统计宿主写入响应的正文量，不能把后者当作客户端实际消费量。本次991017字节小样本各代理协议均完整读取，短视频55502字节；适配器每次最多256KiB，没有整文件缓存或落盘回退。

完整验证仍使用 `scripts/verify.ps1`，覆盖持久化、所有单元、core/proxy/media-probe Debug/Release HAR 和应用。模块移除步骤见 `linkora_media_probe/README.md`；移除验证在独立工作树，当前项目保留模块。
# 网络列表正式接入

NetworkMediaLoader 串行提取可见网络视频，NetworkMediaCache 复用应用数据库并维护私有图片文件；本地与串流不接新模块。下拉刷新只更新目录列表，不清除媒体元数据或缩略图；文件未变化时复用缓存，新增或版本变化的文件按新键获取。列表复用 FileMediaPreview，文件夹只显示年月日日期；网格无chip。停用生产提取只改 LinkoraFeatures.ets 的 NETWORK_MEDIA_ENABLED=false，代理HAR和工厂保留。

实际源文件回归：Studio Node运行 `scripts/check-network-media-list.cjs`。真实页面验证：先构建Debug包，再运行 `scripts/check-network-media-list-ui.cjs`；脚本确认安装成功，创建并删除自己的临时WebDAV服务器，检查真实WebP文件、时长/分辨率/图像、可见项子集、重入及冷启动缓存、目录切换和取消。停用构建后以 `--disabled` 运行，断言基础列表可用且没有视频请求。新截图和受控证据在 artifacts/network-media-persistence，前一阶段在 artifacts/network-media-list。模拟器为API26，接口保持API20。


网络媒体持久化（2026-10-03后续）：schema9的network_media_metadata保存数值，filesDir/network-media保存WebP（设备不支持或编码失败则JPEG），无时间/数量淘汰；内存24条。沙箱缩略图不注册媒体库。旧JSON/JPEG访问时迁移，保留提取开关与proxy边界。元数据仍可在图片缺失时使用，后续可见请求重试抽帧；服务器删除清理对应持久记录和图像。详见network-media-persistence设计及模块README。
