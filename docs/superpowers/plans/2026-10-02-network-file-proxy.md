# Network File Proxy Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox syntax for tracking. Execution method awaits the user's selection; this plan does not authorize delegation by itself.

**Goal:** 提供可移除的网络文件代理实验模块，先证明四种协议的按需随机读取和本机 HTTP 输出正确，再进入媒体信息与缩略图阶段。

**Architecture:** `linkora_proxy` HAR 消费 core 已有的 `RemoteReadSession`，使用系统 TCP 服务提供本机 HTTP 字节范围读取。entry 复用现有 native 协议库提供读取会话，在 `LinkoraFeatures` 装配，通过 Debug 内部测试入口验证。

**Tech Stack:** ArkTS、HarmonyOS API 20+ NetworkKit、N-API/C++17、已有 libsmb2/libssh2/libnfs/FTP 实现、Hypium、Node 内置库和 hdc。

**Spec:** [已批准的设计](../specs/2026-10-02-network-file-proxy-design.md)

## Global Constraints

- HTTP/HTTPS 串流保持直连，不做代理。WebDAV 保持已有 HTTP 文件直连。
- 不增加设置开关、插件管理页面、动态安装机制、新第三方依赖或数据库 schema。
- 最低 API 20；保留已有兼容路径，本次不验证 API 12–19。
- 代理只绑定 `127.0.0.1`，系统分配端口；凭据、原始路径和令牌不进入日志或持久化。
- 读取/发送块最多 256 KiB；头部上限 16 KiB，头部超时 8 秒；最多 8 个活跃句柄、16 个客户端。
- 所有远程操作有超时与取消路径，包括连接建立；不得释放在途操作仍在使用的资源。
- 基础名称、类型、大小、日期继续独立于代理；本阶段不提取时长、分辨率或缩略图，不切换既有播放链路。
- 工作区已有大量未提交修改：执行时保留其内容，提交只包括本任务新增内容及精确审阅过的改动；不得用整目录 git add 或重置工作区。

## Review Focus

- 目录缓存大小过期、超大偏移与短读：实际 stat 定长，使用精确整数，继续读到目标范围或明确中断；任务 1、3、4 验证。
- 头部分片、重复 Range、慢客户端：完整解析且有大小/时间限制，不重复处理；任务 2 验证。
- cancel/close 与读操作竞争：令牌先失效，原生清理等待读退出，重复释放不报错；任务 2、3 验证。
- FTP 截断传输后的控制回复、SFTP 严格策略缺少指纹：后续读取不串回复，不放宽认证；任务 4 验证。
- 模块关闭时存在连接、重新打开模块与去掉装配：没有残留客户端或旧地址，基础应用仍可构建；任务 2、5 验证。

## 文件结构

- 新 HAR：`linkora_proxy/{oh-package.json5,build-profile.json5,hvigorfile.ts,Index.ets,obfuscation-rules.txt,src/main/module.json5}`，按现有 `linkora_core` 最小 HAR 结构创建。
- `linkora_proxy/src/main/ets/HttpByteRange.ets`：纯范围解析；`NetworkFileProxy.ets`：监听、注册、HTTP 输出及释放，不依赖 entry。
- `entry/src/main/cpp/remote_reader.h`：四库共享的读取句柄登记、参数验证和 N-API 异步生命周期小工具，不做新的协议框架。
- 修改四个现有 `*_init.cpp`/`napi_init.cpp` 和对应 `types/liblinkora_*/index.d.ts`，增加随机读取导出。
- `entry/src/main/ets/services/NativeRemoteReadSession.ets`：native 句柄到 core 会话的转换、串行读取、超时和取消。
- 修改 `SmbBrowserService.ets`、`SftpBrowserService.ets`、`FileProtocolBrowserService.ets`、`NetworkDirectoryService.ets`，增加 `openReader`。
- 修改 `build-profile.json5`、`entry/oh-package.json5`、`LinkoraFeatures.ets` 和 `scripts/verify.ps1`，接入 HAR 和构建验证。
- 单元检查：`entry/src/test/NetworkFileProxy.test.ets`，在既有 `List.test.ets` 注册。
- 设备检查：`entry/src/main/ets/services/NetworkProxySmokeTest.ets`、`scripts/check-network-proxy.cjs`，只通过 Debug Want 入口运行；修改 `EntryAbility.ets` 接入测试入口，不增加用户页面。

## Task 1: HAR 与字节范围解析

**Interfaces:** `resolveHttpByteRange(range: string, size: number): HttpByteRange`；结果字段 `status: number`、`offset: number`、`length: number`、`contentRange: string`。未提供范围为 200，合法范围为 206，不可满足为 416，畸形 bytes 表达式为 400；多范围或未知单位忽略并返回 200。

- [ ] 在 `NetworkFileProxy.test.ets` 写范围断言并注册：`bytes=0-9,size=100 → 206,0,10,"bytes 0-9/100"`；`bytes=95-,100 → 95,5`；`bytes=-8,100 → 92,8`；`bytes=100-,100 → 416,"bytes */100"`；空文件无范围 → 200/长度 0；空文件有范围 → 416。
- [ ] 添加 `bytes=1-0`、负号/非数字/不安全整数、重复范围表达式、多范围、未知单位、超过末尾、大小 `5 GiB` 的断言。运行 Hvigor `test`，记录新接口缺失的失败证据。
- [ ] 创建最小 HAR、在构建配置/entry 依赖中登记并实现纯解析器；公开导出解析结果与函数供已有 Hypium 测试消费。
- [ ] 运行同一 `test`，确认断言通过；独立构建代理 HAR。审阅并只提交本任务差异。

## Task 2: 本机代理与生命周期

**Consumes:** Task 1 解析器、core 的 `RemoteReadSession`。

**Produces:** `class ProxyUrlLease { readonly url: string; release(): Promise<void> }`；`class NetworkFileProxy { buildProxyUrl(reader: RemoteReadSession, contentType: string): Promise<ProxyUrlLease>; close(): Promise<void> }`。取消/关闭必须幂等。释放后原令牌返回 404；整个模块 close 后该实例不再接受注册，新建实例可以重启。

- [ ] 在同一个测试文件新增 `FakeRemoteReadSession`：记录 read 参数和 close 次数，可手动延迟/失败/短读。为真实设备 smoke 定义断言：HEAD 正文为空且 read 次数为 0；GET 指定范围正文精确一致；release 两次 close 次数为 1；9 个句柄的第 9 次注册失败并关闭其 reader。
- [ ] 先运行已有测试与最小设备 probe，记录缺失 `NetworkFileProxy` 的失败；设备入口的完整装配由任务 5 完成，在这里保留可调用测试函数，不能以平台 mock 声称真 TCP 测试通过。
- [ ] 实现系统 TCP 服务、随机令牌、受限客户端映射、分片头部累积与 8 秒定时器、GET/HEAD/405/404、Range 响应和发送背压。响应使用 Content-Length、Accept-Ranges、Content-Type 和 `Connection: close`；拒绝重复 Range、请求体/请求管线，不处理上传。
- [ ] 对同一 reader 串行执行块读取；短读继续，不允许零长度提前 EOF 被当成完整成功。注册失败关闭 reader；close 先撤销所有令牌，关闭客户端、取消 reader，再等待读取退出和资源关闭。
- [ ] 实现 8 句柄/16 客户端限制，以及分片、超长头、超时头、无效令牌、读取失败和关闭竞争设备断言。通过独立 HAR 构建和可运行检查后，只提交本任务差异；真正设备验证待任务 5 统一执行。

## Task 3: 共享 native 句柄、SMB 与 core 会话适配

**Native interfaces:** 每个已有 native 默认对象增加 `openReader(...现有连接参数, remotePath: string): Promise<NativeRemoteFile>`、`read(handle: number, offset: number, length: number): Promise<ArrayBuffer>`、`cancel(handle: number): void`、`closeReader(handle: number): Promise<void>`；`NativeRemoteFile` 字段为 `handle: number`、`size: number`。保留旧方法签名。

四库的 openReader 参数与现有 download 去掉 localPath 一致，顺序固定：

- SMB：`host, port, share, path, username, password, domain, remotePath`。
- SFTP：`host, port, path, username, password, privateKeyPath, passphrase, expectedFingerprint, hostKeyPolicy, authMode, remotePath`。
- FTP：`host, port, rootPath, username, password, securityMode, passiveMode, encoding, remotePath`。
- NFS：`host, port, rootPath, version, remotePath`。

上述 port/hostKeyPolicy/authMode/securityMode/passiveMode/version 为 number，其余参数为 string。各 native 类型包各自导出相同字段的 `NativeRemoteFile`，不相互依赖。

**ArkTS interfaces:** `NativeRemoteReadSession` 实现 core 会话；构造参数为 `file: NativeRemoteFile` 及 read/cancel/closeReader 回调（使用对应 native 方法签名）。`SmbBrowserService.openReader(remotePath: string): Promise<RemoteReadSession>`。

- [ ] 新增会话检查：read(0,10) 返回相同字节；无效偏移/超出 256 KiB 拒绝；排队的第二次读取不早于第一次；cancel 后排队读取不进入 native；close 两次只释放一次。用 fake 回调在 Hvigor 中运行，确认新适配器缺失时失败。
- [ ] 实现共享 native 句柄/异步工具。句柄不可当裸指针；查找保持会话存活；取消置位且阻止新读；close 原子撤销句柄并在工作线程等待读结束，避免主线程析构联网资源和并发破坏协议上下文。
- [ ] 为 SMB 实现只读打开、fstat 和 pread；实际大小和参数必须是精确整数。读取前后检查取消，EOF 短读按实际长度返回；接入原服务器参数及现有路径解析，不绕过认证。先在 ArkTS 检查偏移与大小安全，再在 native 检查 uint64 范围，不能依靠强制转换纠正非法输入。
- [ ] 实现 ArkTS 串行队列和取消。连接建立先用系统异步 DNS 做有界解析（8 秒，晚返回忽略），native 使用数值地址以避免无界同步 DNS；协议连接/读取沿用不超过 8 秒的 I/O 超时。若取消发生在打开期间，晚到达的句柄立即关闭，不能注册到代理。
- [ ] 实现 `SmbBrowserService.openReader`。运行单元检查、Debug 构建；设备验证 SMB 实际大小、头/尾/中间数据、错误凭据和读取中取消，由任务 5 驱动。仅提交审阅过的本任务差异。

## Task 4: SFTP、NFS、FTP 随机读取

**Consumes:** Task 3 的 native 句柄工具与 ArkTS 会话适配。

**Produces:** `SftpBrowserService.openReader(path)`、`FileProtocolBrowserService.openReader(path)` 及 FTP/NFS 实现，均返回 `Promise<RemoteReadSession>`；`NetworkDirectoryService.openReader(path: string): Promise<RemoteReadSession>` 分派现有协议服务，对不需代理的 WebDAV 明确拒绝。

- [ ] 在统一设备 smoke 中定义三协议同样的精确字节断言，并新增：FTP 连续读尾部→头部不串控制回复、REST 不支持时失败、路径/账号包含 CR/LF 时在发命令前拒绝；SFTP 严格策略缺指纹或指纹不符均失败；NFS 文件失效时读取失败。先对缺失接口运行并记录失败。
- [ ] SFTP 原生增加打开/fstat、seek64/read；共享同会话串行规则、现有认证选项和严格身份要求。若当前保存数据不足以提供安全认证参数，拒绝该配置并记录限制，不补造凭据或静默降级。
- [ ] NFS 原生增加打开/fstat/pread，保留原版本/挂载选项，按共享超时/取消规则关闭。
- [ ] FTP 原生用 TYPE I/SIZE 确认大小，REST/RETR 随机起读，按块返回；范围结束必须正确结束或重建传输，避免残留 426/226 回复影响下一请求。拒绝不支持的 REST、FTPS、主动模式；对新会话连接/命令参数做 CR/LF、长度和端口验证。
- [ ] 三服务和统一目录服务增加 openReader，保留列表与下载；运行单元与 Debug 构建，再通过任务 5 的各协议端点验证。不以编译通过代替协议正确性。仅提交本任务差异。

## Task 5: 装配、模拟器验证与移除验证

**Interfaces:** `LinkoraFeatures.createNetworkFileProxy(): NetworkFileProxy`；`NetworkProxySmokeTest.run(context: common.UIAbilityContext, configPath: string): Promise<void>`；启动参数 `linkoraProxySmokeConfig` 指向应用私有临时 JSON 配置。仅 `BuildProfile.DEBUG` 时识别；Release 不执行测试入口。测试输出使用通过/失败、字节长度和失败类型，不输出地址令牌或凭据。

- [ ] 创建 Debug smoke：内存 reader 验证 Task 2 所有 HTTP/生命周期场景；协议 fixture JSON 指定服务器配置、远程路径及预期头/尾/中间字节，用 Task 4 服务提供 reader，再通过系统 HTTP 客户端访问本机 URL 对比正文。
- [ ] 在 `EntryAbility` Debug 生命周期接入，`LinkoraFeatures` 唯一装配；冷启动无测试参数不启动代理。`scripts/check-network-proxy.cjs` 用 Node 内置库与 hdc 安装 Debug、上传受限 fixture、启动测试、读取结构化结果、清理 fixture。凭据不放命令参数、日志或提交文件。
- [ ] 执行无凭据的本机 smoke，必须包含 HEAD/GET/206/416/400/404/405、分片头、慢头、短读、超额连接/句柄、取消、关闭后重建和旧令牌失效。
- [ ] 从实际可访问的测试端点执行四协议 smoke；没有可用端点时逐项报告未验证状态，保留可运行脚本，不能自动进入下一阶段。失败时定位根因后重跑受影响检查。
- [ ] 更新 `verify.ps1` 构建 core 和 proxy 的 Debug/Release HAR、运行既有测试与新增单元检查、构建 Debug/Release HAP。运行 `powershell -File scripts/verify.ps1`，检查 test_result 及构建退出码；最后恢复安装 Debug 版本用于模拟器操作。
- [ ] 在隔离的临时验证副本中移除代理 HAR 构建项、entry 依赖、装配方法和 Debug smoke 导入/调用，构建基础应用；不对主工作区做破坏式切换。模拟器操作本地/网络目录、已有协议播放及串流直连，确认基础信息仍在且无意外代理请求。
- [ ] 在 `docs/DEVELOPMENT.md` 记录构建、smoke 参数、接入/移除步骤、各协议证据和已知限制。审阅 diff、提交本任务内容，交付测试结果；代理验收完成后才开始下一阶段。

## 验证命令约定

在仓库根目录设置 `DEVECO_SDK_HOME=C:\Program Files\Huawei\DevEco Studio\sdk`、`JAVA_HOME=C:\Program Files\Huawei\DevEco Studio\jbr`，并把 `jbr\bin` 加入当前 PATH。以下命令的可执行文件均使用 Studio 的 `tools\hvigor\bin\hvigorw.bat`：

- 单元检查：`hvigorw.bat test --mode module -p module=entry@default -p product=default --no-daemon`；退出 0 且 `entry/.test/default/intermediates/test/coverage_data/test_result.txt` 的 Failure/Error 为 0。
- HAR：`hvigorw.bat assembleHar --mode module -p module=linkora_proxy@default -p product=default -p buildMode=debug --no-daemon`；退出 0，Release 同样验证。
- HAP：`hvigorw.bat assembleHap --mode module -p module=entry@default -p product=default -p buildMode=debug --no-daemon`；退出 0。
- 设备 smoke：Studio 的 `tools/node/node.exe scripts/check-network-proxy.cjs`，可追加本机 fixture JSON 路径；基础 smoke 必须通过，四协议结果必须逐项列出。
- hdc：`C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe`，目标 `127.0.0.1:5555`；安装使用仓库相对 HAP 路径，避免已知的绝对路径解析问题。

执行方式待用户审阅计划并选择。本计划推荐本会话直接执行，因为 HTTP 生命周期与 native 读取接口紧密相关，连续上下文更容易控制变更范围。
