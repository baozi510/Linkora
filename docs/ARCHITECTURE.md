# 技术架构

## 原则

- 原生优先：ArkTS、ArkUI、Media Kit，不在首发版本引入跨平台播放器壳。
- 系统能力优先：媒体解封装与解码先走 `AVPlayer`，仅在明确存在格式缺口时评估 C/C++ 扩展。
- 凭据与地址分离：URL、请求头、账号和密钥是不同数据对象，禁止把凭据拼进 URL。
- 状态单向流动：系统播放器事件进入状态机，UI 只订阅状态并派发意图。
- 本地优先：播放历史与设置默认仅在设备保存，云同步必须另行征得同意。
- 错误单一来源：平台错误只在适配层包装一次，业务含义与用户文案统一由 `FailureCatalog` 生成。

## 当前分层

```text
ArkUI pages / components
        │
feature controllers（linkora_core HAR）
        │
use cases: open, play, seek, retry
        │
domain: MediaSource, PlaybackState, Playlist
        │
repositories / protocol adapters
        │
Media Kit · Network Kit · RDB · Preferences · Asset Store / HUKS
```

纯模型、错误契约、播放状态机、功能控制器和协议插件接口已经迁入独立 `linkora_core` HAR。该 HAR 不依赖 ArkUI 或 HarmonyOS `@kit.*`，可被其他鸿蒙应用作为本地包复用。

`PlaybackEngine` 只依赖注入的 `PlaybackPort`，系统 `AVPlayer`、Surface 绑定和本地文件描述符由 `SystemPlaybackPort` 封装。`LinkoraFeatures` 是 entry 中唯一的默认依赖装配入口。页面销毁、系统报错或快速换源时必须释放当前端口。WebDAV、SMB、SFTP、FTP 和 NFS 只负责资源发现与读取，不直接操纵 UI。协议适配器最终产出统一的 `MediaSource`：HTTP/WebDAV 交给 `AVPlayer` 的网络缓冲；SMB/SFTP/FTP/NFS 通过 `AVDataSrcDescriptor` 读取增长中的有界缓存，播放器不等待完整文件下载完成。

### 网络文件播放

网络文件协议的点击链路是：创建缓存文件 → 启动协议下载任务 → 立即创建播放器 → `dataSrc.callback` 按播放器请求读取当前已落盘的数据。下载端每个块写入后立即 flush，使播放器能观察到缓存增长；缓存尚未到达的位置返回等待，协议失败返回不可恢复错误。协议账号和密码仍只保留在协议服务对象中，不能拼进播放定位信息。

详细依赖规则和 UI 重做接入方式见 [MODULE_BOUNDARIES.md](MODULE_BOUNDARIES.md)。

错误契约、恢复动作、诊断码和测试门槛见 [ERROR_HANDLING.md](ERROR_HANDLING.md)。页面不得直接解释 HTTP 状态或系统播放器数字错误码。

UI 的设计令牌、组件边界、导航与文案规则见 [UI_ARCHITECTURE.md](UI_ARCHITECTURE.md)。视觉改版必须停留在 `ui`、`components` 和 `pages` 层，不得让页面直接依赖系统播放器或协议实现。

本地媒体库使用系统 `PhotoAccessHelper` 作为权威索引，权限、查询和 UI 状态分层规则见 [LOCAL_MEDIA.md](LOCAL_MEDIA.md)。应用不复制整套系统媒体数据库，也不通过全盘文件遍历绕过用户授权。

媒体实体、来源成员关系、最近播放和播放状态的持久化规则见 [LOCAL_DATABASE.md](LOCAL_DATABASE.md)。UI 和功能控制器不得直接执行 SQL。

## 播放状态

业务状态不会直接照搬系统字符串，目标状态为：

```text
idle → resolving → preparing → ready → playing
                    │          ↔ paused
                    └→ failed     │
                         completed ←
```

每次打开资源都分配 session id。迟到的旧事件必须被忽略，防止快速换源时污染新会话。

## 网络与安全

- 默认 HTTPS；HTTP 在 UI 明示非加密风险。
- 支持重定向时校验每一跳的 scheme，并限制跳转次数。
- 请求超时、重试和 Range 行为由媒体请求策略统一管理。
- 完整 URL 可能含签名和用户标识，日志只记录不可逆 source id、协议、媒体类型和错误码。
- Authorization、Cookie、Referer、查询参数不得写入日志、崩溃附件或剪贴板历史。
- 用户凭据使用系统安全能力保存；退出账号或删除资源时同步删除。
- 不内置公共盗版源，不绕过 DRM，不抓取第三方站点受保护播放地址。
- 网络扫描仅由用户主动发起，限定当前局域网，可取消并设置硬超时。
- 扫描只发现服务，不自动登录、不尝试默认密码、不执行漏洞探测。
- SMB 仅支持 SMB 2/3；SFTP 固定主机指纹；FTP 明文连接必须提示风险；NFS 首发只读。

## 数据对象

当前入口已统一为 `MediaSource`：网络直链保存原始定位信息，本地文件保存系统选择器返回的授权 URI；页面和播放器不再以裸 URL 作为通用参数。后续扩展通过组合对象实现：

- `MediaSource`：展示名、位置、来源类型和推测格式；稳定 id 在持久化阶段补充
- `RequestPolicy`：headers、超时、重定向、证书策略
- `CredentialRef`：安全存储引用，不携带明文
- `PlaybackBookmark`：进度、时长、更新时间；完成后直接清理
- `SubtitleSource`：位置、语言、编码、偏移
- `RemoteConnection`：协议、主机、端口、根路径、凭据引用
- `DiscoveredService`：发现方式、服务类型、地址和安全提示
- `RemoteFileReader`：stat、随机读取、取消与关闭
- `LocalMediaAsset`：系统媒体 URI、名称、时长、分辨率、大小和修改时间

## 兼容与演进

当前工程以 API 26 编译并以 API 26 为目标版本，最低兼容 API 20。现有低版本判断与降级代码暂时保留，本阶段不再专门验证 API 12—19；调用 API 21—26 新增能力时仍须按系统版本或能力做运行时判断。播放器内核接入前先建立真实设备格式矩阵，记录协议、封装、视频编码、音频编码、字幕、HDR 和最大分辨率的结果。

当前书签持久化只保存媒体定位信息的 SHA-256 键、进度、时长和更新时间，不保存完整网络 URL。含查询参数的最近播放地址使用 Asset Store 保存敏感定位信息，关系库只持有不可逆主键与资产别名。书签距开头不足 5 秒或距结尾不足 30 秒时不恢复。
