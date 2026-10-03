# Linkora

Linkora 是一个面向 HarmonyOS 的原生网络媒体播放器。产品分为 V1 流媒体直链版本和 V2 网络存储版本；当前工程已经形成 V1 可运行 MVP，正在等待设备媒体矩阵验证。

## 当前能力

- HarmonyOS Stage 模型，ArkTS + ArkUI
- phone / tablet 双设备类型
- HTTP、HTTPS 地址规范化
- HLS、DASH、MP4、Matroska、MPEG-TS 和常见音频扩展名识别
- 拒绝 URL 内嵌账号密码，避免凭据进入历史记录和日志
- AVPlayer + XComponent 网络播放闭环
- 实验性 WebDAV、SMB、SFTP、FTP、NFS 目录浏览与渐进式缓存播放；该入口首发默认关闭，可在设置中主动启用
- 系统文件选择器与本地媒体 `fdSrc` 播放通路
- 播放、暂停、进度拖动、倍速、音量、全屏、缓冲反馈、错误重试和资源释放
- 横滑进度、左右竖滑亮度/音量、三区双击和长按临时倍速手势
- 加密关系型数据库保存最近播放与播放进度，恢复播放、播完自动清理
- 网络密码保存在系统 Asset Store，关系数据库只保存凭据引用；旧数据库记录会在加载时自动迁移
- 本地视频、相册和归属关系写入加密媒体索引，列表通过数据库回读
- 应用退到后台及音频被抢占时自动暂停，播放期间保持亮屏
- 独立 `linkora_core` HAR，功能控制器和网络来源插件契约可跨 UI 复用
- 本地单元测试与 Debug / Release HAR、HAP 可重复构建
- 已声明最小网络权限；只有用户打开播放器后才请求媒体地址

## 本地环境

- DevEco Studio：26.0.0.821（DS-261.23567.138.36.2600821）
- SDK：HarmonyOS 26.0.0 / API 26
- compatible SDK：HarmonyOS 6.0.0 / API 20

使用 DevEco Studio 打开本目录，配置开发者签名后运行 `entry` 模块。本地媒体必须由用户通过系统文件选择器授权，应用不申请宽泛的存储权限。

可以在 PowerShell 中执行 `./scripts/verify.ps1`，一次完成单元测试、Debug/Release HAR 和 Debug/Release HAP 构建。DevEco Studio 不在默认安装目录时，通过 `-StudioRoot` 指定位置。

## Material Symbols 图标

界面图标统一通过 `AppIcon` 使用。应用内嵌的是从 Google 官方 Material Symbols Outlined 可变字体生成的静态 TTF 子集，仅包含 `scripts/material-icons/icons.json` 清单中的图标；日常构建不会访问网络。

新增或更新图标时：

1. 在 `scripts/material-icons/icons.json` 增加图标枚举、业务值和 Google 官方图标名称。需要实心样式时增加 `"fill": 1`。
2. 执行 `./scripts/update-material-icons.ps1`。首次运行需要 Python 和 `fonttools`。
3. 在 ArkTS 中通过 `AppIcon({ name: AppIconName.图标枚举 })` 使用，不要直接填写 Unicode 编码。

脚本会重新下载官方源字体与 codepoints，生成空心/实心静态字体子集、ArkTS 映射和记录源文件哈希的 lock 文件。生成结果应提交到仓库，保证其他开发环境和离线构建可直接使用。

## 项目状态

详细里程碑见 [docs/PRODUCT_PLAN.md](docs/PRODUCT_PLAN.md)，网络协议计划见 [docs/NETWORK_SOURCE_PLAN.md](docs/NETWORK_SOURCE_PLAN.md)，技术边界见 [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)，数据库规则见 [docs/LOCAL_DATABASE.md](docs/LOCAL_DATABASE.md)，模块边界见 [docs/MODULE_BOUNDARIES.md](docs/MODULE_BOUNDARIES.md)，开发与设备运行方式见 [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md)。

## 发布前必须替换

- `com.linkora.player`：替换为开发者实际拥有并在 AGC 创建的包名
- 应用名称、图标、开发者主体与版权信息
- 隐私政策 URL、用户协议 URL、备案信息
- release 签名配置与密钥管理方案
