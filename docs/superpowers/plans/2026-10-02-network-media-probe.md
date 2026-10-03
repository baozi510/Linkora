# Network Media Probe Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. 用户已选择在当前会话直接执行；保留这一执行方式，不重新询问。

**Goal:** 交付可移除的网络媒体提取 HAR，用模拟器内部测试验证真实时长、分辨率、缩略图及取消清理。

**Architecture:** `linkora_media_probe` 只接收 HTTP/HTTPS URL 与请求头，通过系统 AVMetadataExtractor 提取信息及一张视频帧。entry 内部测试负责协议打开、代理租约与 WebDAV 鉴权；基础目录数据、页面和数据库不依赖提取 HAR。

**Tech Stack:** ArkTS、API20 Media Kit/Image Kit/ArkTS URL、现有 linkora_proxy 与协议服务、Hypium、Node 内置模块、hdc、已有实验室视频。

**Spec:** [已确认设计](../specs/2026-10-02-network-media-probe-design.md)

用户后续确认：鉴权 WebDAV 改为应用 HTTP 客户端携带请求头，经现有代理提取；系统原生对照证实 API26 模拟器丢失自定义 headers。原始直连计划在此点由用户指令覆盖，普通 HTTP 串流仍直连。

## Global Constraints

- 这一阶段先做模块和模拟器内部测试，暂不接入文件列表，也不在播放前自动执行。
- 不添加设置选项；不打包 FFmpeg，不实现 API12 分支，不使用 API26 新增的提取超时接口。
- HAR 不依赖协议客户端、代理 HAR、数据库或页面；不做批量调度、磁盘缩略图缓存、增强信息数据库或扫描。
- 整次 inspect 从创建开始使用八秒调用截止时间；目标尺寸 224×126；时长保持毫秒；缺失或非法数值为零。
- 返回后的 PixelMap 归调用方所有；取消或迟到的 PixelMap 由模块释放；系统实例只释放一次。
- 每个实例仅允许一个活跃任务；重复关闭安全，关闭后禁止提取。及时返回与实际资源退出分别验证。
- SMB/SFTP/FTP/NFS 复用代理，SFTP 严格指纹不降级；WebDAV 和普通 HTTP/HTTPS 直接访问。串流页现有代码保留。
- 不输出 URL、令牌、凭据、请求头或系统原始错误消息；只输出受控状态、数值和测试检查名称。
- 保留原项目所有已有未提交改动；执行前创建隔离工作树并包含当前工作内容，最后只回写本计划新增差异。

## Review Focus

- 创建尚未结束或抽帧迟到时取消：调用及时失效，迟到实例/图像释放且不会交付给旧任务；任务1。
- 已读出信息但解码、超时或释放失败：保留部分信息，不把文件标为不可用，不无限占用活跃槽位；任务1/2。
- 实际 HTTP 鉴权、URL 参数和异常响应：保留合法查询参数，拒绝注入或 URL 内凭据，失败输出不泄密；任务1/2。
- 短视频、尾部索引、非法元数据与无有效帧：时间点不越界，数值不出现 NaN/Infinity，真实图像可解码；任务1/2。
- 普通启动、后台清理和移除模块：无自动提取，原有代理及基础应用仍可构建/启动；任务2/3。

## 文件结构与接口

- 新 HAR `linkora_media_probe/{Index.ets,oh-package.json5,build-profile.json5,hvigorfile.ts,obfuscation-rules.txt,src/main/module.json5}`：复用现有 HAR 最小配置；无产品依赖。
- `linkora_media_probe/src/main/ets/NetworkMediaProbe.ets`：结果、状态、验证、单任务生命周期和系统提取，保持在一个文件，不再包装一层后端框架。
- 公开 `ProbeStatus`：`COMPLETE='complete'`、`METADATA_ONLY='metadata_only'`、`UNAVAILABLE='unavailable'`、`CANCELLED='cancelled'`、`TIMEOUT='timeout'`。
- 公开 `MediaProbeResult`：只读 `durationMs:number`、`width:number`、`height:number`、`metadataComplete:boolean`、`thumbnail:image.PixelMap|null`、`status:ProbeStatus`、`errorCode:number`。
- 公开 `NetworkMediaProbe.inspect(sourceUrl:string, headers:Record<string,string>={}):Promise<MediaProbeResult>`、`cancel():void`、`close():Promise<void>`。构造器仅可注入 `createExtractor:()=>Promise<media.AVMetadataExtractor>`，默认系统创建函数；这一处用于控制异步测试，不另建 extractor 接口。
- `entry/src/test/NetworkMediaProbe.test.ets`：已安装 Hypium 检查，在 `List.test.ets` 注册。
- `entry/src/main/ets/services/NetworkMediaProbeSmokeTest.ets`：真实设备测试、读量记录、PixelMap 导出与清理。
- `scripts/check-network-media-probe.cjs`：临时宿主 HTTP 视频/鉴权/延迟端点、私有夹具传递、设备运行和证据回收。
- 精确修改 root/entry 包配置、`.gitignore`、`LinkoraFeatures.ets`、`EntryAbility.ets`、WebDAV 服务、`scripts/verify.ps1`；移除说明在新 HAR README，验证说明在 `docs/DEVELOPMENT.md`。

## Task 1: 独立 HAR 与单任务提取生命周期

**Consumes:** API20 `media.createAVMetadataExtractor()`、`setUrlSource`、`fetchMetadata`、`fetchFrameByTime`、`release`；现有 Image Kit PixelMap 类型。

**Produces:** 上述 `NetworkMediaProbe`、`MediaProbeResult`、`ProbeStatus`；Index 导出模块自身的 `MediaProbeBuildProfile`，使用 HAR 自动生成的 BuildProfile。

- [ ] 写并注册失败单元检查，替身使用现有 SDK 类型，控制创建/信息/图像 Promise。断言：`duration='1234',videoWidth='1920',videoHeight='1080'` 得到 `1234,1920,1080`；`'NaN'/'Infinity'/'-1'/undefined` 得到零；信息成功而 frame 拒绝返回 METADATA_ONLY、metadataComplete=true、thumbnail=null；信息拒绝不调用 frame。先运行 Hvigor test，记录 HAR/导出不存在的 RED。
- [ ] 新建最小 HAR 并登记构建/依赖。实现上述签名、结果和状态。使用 `url.URL.parseURL` 验证 HTTP/HTTPS、非空 host、无用户名/密码；URL 上限8192字符。请求头键按 HTTP token 验证，值拒绝 CR/LF/NUL；最多16项，单项值最多4096字符，合计最多16KiB。无效输入、活跃时第二调用和关闭后调用在创建系统实例前拒绝。
- [ ] 补资源断言：创建期间 cancel 后立刻得到 CANCELLED；迟到 extractor 只 release 一次。frame 尚未结束时 cancel 后迟到 PixelMap 只 release 一次。成功返回的 PixelMap 在 probe.close 后不被释放，调用方自行释放。对同一个实例再提取成功，重复 close 不重复 release。记录新路径的 RED，再实现任务标识、单任务限制、交付点及幂等清理。
- [ ] metadata 成功后再抽一帧：`timeUs=min(1000000,max(0,(durationMs-1)*1000))`，未知时长为0；使用 AV_IMAGE_QUERY_CLOSEST_SYNC、224×126。单元断言短视频200ms时为199000µs、未知为0、正常时长为1000000µs；headers/query 不被重写，注入型 header 与 userinfo URL 被拒绝。
- [ ] 设置一次8000ms定时器，覆盖创建、信息和图像。到期返回 TIMEOUT 及已获得的信息，取消启动实例释放；跟踪迟到创建和已启动清理，close 等其实际结束。异常信息只保留数值 errorCode，不返回原始错误文本。释放失败不覆盖可用信息或制造重复释放，单元注入 release 拒绝验证后续任务仍可运行。
- [ ] 运行同一 Hvigor test，确认所有新检查及原有118项通过；独立构建新 HAR。审阅并提交本任务精确文件，排除自动生成配置和旧工作区内容。

## Task 2: 真实来源装配与模拟器内部测试

**Consumes:** Task1 接口；`LinkoraFeatures.createNetworkFileProxy()`、`NetworkDirectoryService.openReader(path,expectedFingerprint)`、`directFileUrl(path)`。

**Produces:** `LinkoraFeatures.createNetworkMediaProbe():NetworkMediaProbe`；`NetworkDirectoryService.directFileHeaders():Record<string,string>`；`NetworkMediaProbeSmokeTest.run(context:common.UIAbilityContext,configUrl:string):Promise<void>`；Debug Want `linkoraMediaProbeSmokeConfig`。

- [ ] 写设备 smoke 及脚本的失败断言：四协议和HTTP/WebDAV的 durationMs 与参考值相差不超过250ms，宽高与参考值相等，metadataComplete=true、thumbnail非空、实际图像宽高>0。从已有实验室视频用现有 ffprobe 获取独立参考，不安装或打包解码库。先运行无装配或无实现版本，记录缺少测试结果/能力的 RED，不用 fake 代替设备结论。
- [ ] `WebDavBrowserService.fileHeaders()` 返回现有 `basicAuthorization()` 生成的 Authorization（无账号时为空对象）；统一目录服务分派 directFileHeaders，其他协议为空。复用原函数，不另写Base64编码或认证流程。LinkoraFeatures 装配新 HAR；EntryAbility 仅在 MediaProbeBuildProfile.DEBUG 且专用参数存在时调用测试，普通启动不创建 probe。
- [ ] 脚本复用上一阶段的宿主回环/随机配置URL方式，不把夹具或凭据放进 hdc 命令行。配置不超过64KiB，格式 `{cases:[...]}`；每项含安全 label、protocol、服务器字段、remotePath、fingerprint、`expectedDurationMs/expectedWidth/expectedHeight`。普通HTTP测试和WebDAV鉴权测试使用宿主临时 Range 服务；增加缺失/错误 Authorization 的失败断言，只有正确鉴权的直连成功。请求头和来源URL只存临时私有文件。
- [ ] 每个协议来源打开新 reader、持有租约，使用同一个HAR提取；测试包装已有 RemoteReadSession 记录 read 次数与实际返回字节数。直接HTTP由测试服务计数。用标签输出读量、用时、数值和受控状态，不输出服务器身份。结束时由调用方释放 PixelMap、lease、probe和proxy；取消时先probe.cancel，再撤销租约，再等待close。
- [ ] 导出真实 PixelMap 为JPEG到应用私有临时测试目录，用hdc回收到 artifacts/media-probe；检查图片可解码及非单色有效画面，使用 view_image 视觉确认。输出实际图像尺寸，不假定SDK严格返回224×126。图像回收后删除设备临时图像和配置。
- [ ] 验证正常MP4、尾部索引MP4、200ms短视频及格式不支持样本；输入大小/日期由目录基础层保留，提取失败不改条目。测试图片只作证据，不加入用户媒体列表、播放历史或数据库。
- [ ] 控制端点确认系统已经请求数据再取消；断言 CANCELLED 及时返回、恢复端点或撤销租约后close完成、下一任务正常。另让端点持续等待，断言整次TIMEOUT在约8秒发生（设备允许至10秒），恢复/断开端点后观察实际close，超过10秒记录失败而不是把及时返回当作清理完成。创建/抽帧迟到资源由Task1确定性单元覆盖。
- [ ] 脚本读取 `media-probe-smoke-result.json`，逐个必需场景断言而非仅检查总passed；失败输出受控检查名，异常退出也关闭宿主socket并恢复普通应用。测试普通启动和带同参数的Release均不会运行提取。所有真实设备场景通过后提交本任务精确差异。

## Task 3: 构建、回归、移除与交付

**Consumes:** Tasks1/2全部公开接口及设备证据。

**Produces:** 可独立装卸的模块与安全的验证记录；现有基础应用和用户工作区保持可用。

- [ ] 更新verify.ps1，将 `linkora_media_probe` 纳入现有 core/proxy Debug/Release HAR 循环；运行本地持久化检查、全部单元及Debug/Release HAP。缺少新HAR构建项的验证先失败，再补该项；不新增第二套构建框架。
- [ ] 在独立验证工作树移除新HAR、entry依赖、装配及专用smoke/单元导入，不删除proxy和协议适配。构建Debug HAP并在模拟器普通启动，查看本地/网络基础列表；运行串流页既有回归脚本。验证确实移除了提取模块，不只停止内部参数。
- [ ] 还原安装含模块的Debug包，恢复普通启动；确认本地和网络文件基本字段、原类型图标仍存在。测试期间创建的夹具、图片缓存和宿主辅助服务清理；保留忽略目录中的证据和必要实验室配置。
- [ ] 写HAR README接入、所有权、卸载步骤及API/格式边界；DEVELOPMENT记录运行方法、真实设备版本、四协议/直连/取消/图片证据和实际读取量。不把API26结果写成API20实机、所有格式或长期播放的结论。
- [ ] 提交精确任务差异，按执行技能做一次独立只读最终审查；修复必须项并验证。回写到原项目前用仅新功能的补丁预检查，保留原有改动；回写后再运行单元与Debug构建并安装测试。保存证据后归档本次工作树。

## 验证命令

Studio根目录：`C:/Program Files/Huawei/DevEco Studio`。设置当前进程JAVA_HOME为 `jbr`、DEVECO_SDK_HOME为 `sdk`，PATH加 `jbr/bin`。

- 单元：Studio `tools/hvigor/bin/hvigorw.bat test --mode module -p module=entry@default -p product=default --no-daemon`。检查退出0及 test_result.txt 的 Failure/Error 为0。
- 新HAR：同工具 `assembleHar --mode module -p module=linkora_media_probe@default -p product=default -p buildMode=debug --no-daemon`，Release同样检查。
- 全验证：`powershell -File scripts/verify.ps1`，所有阶段成功。
- 设备：Studio `tools/node/node.exe scripts/check-network-media-probe.cjs <私有fixture路径>`；默认hdc目标127.0.0.1:5555，复用LINKORA_HDC_TARGET；安装HAP使用仓库相对路径。
- 串流回归：Studio Node运行现有 `scripts/check-stream-ui.cjs`。

计划自检：设计要求分别落实到Task1的生命周期/边界、Task2的真实来源/图像/读量和Task3的卸载/回归。没有产品设置、列表接入、缓存或数据库任务。执行方式沿用当前会话直接实现；等待用户审阅此计划后开始代码。

## 2026-10-03：分阶段获取与计时（当前会话执行，沿用用户免确认授权）

1. 现有源码 VM 检查先验证独立耗时、未执行阶段、部分失败及取消快照，再实现 HAR 选项和元数据完成回调。
2. 列表在抽帧等待期间显示并持久化已获取元数据；有效元数据缓存缺图时使用 THUMBNAIL，保留已有数值及取消/删除/串行清理规则。加入现有回归脚本。
3. 内部设备 smoke 输出阶段耗时及编码时间，验证 BOTH / METADATA / THUMBNAIL 和短视频取帧点，以实际模拟器数据交付。
4. 完成既有回归、Debug/Release 构建及模拟器列表测试；一次独立只读最终审查，修复必需项。保留原工作区全部既有改动，不进行批量提交。
