# 三种原生循环模式封装与验证 — 2026-10-16

## 结果

已统一封装顺序播放、单曲循环、列表循环，并替换播放页的布尔开关。系统播放器在 API26 x86_64 模拟器中通过本地两项列表的自然 EOF 检查；真实 WebDAV 六项列表也通过末项回首项检查。MPV 完成接口、原生属性映射与主机回归，本轮没有真实 MPV 设备播放证据。

基础提交：`4651cbef7ca9a64ed71ec00c4b90d8644b3cae13`。候选分支：`codex/linkora-playlist-loop-modes-v1`，未合入生产分支。此次是已获用户确认的现有功能扩展，不重开旧自动派发任务；定时检查没有恢复。

## 接口与语义

`PlaybackLoopMode` 由 `linkora_core` 导出，统一用于端口、引擎、控制器、事件与快照：

| 值 | 当前项播完 | 末项播完 |
| --- | --- | --- |
| `SEQUENCE` / `sequence` | 下一项 | 停止 |
| `SINGLE` / `single` | 重播当前项 | 重播当前项 |
| `LIST` / `list` | 下一项 | 回到第一项 |

```ts
engine.setLoopMode(PlaybackLoopMode.LIST);
// 端口确认：PlaybackPortObserver.onLoopModeChange(mode)
// 对外状态：PlaybackSnapshot.loopMode
// 控制器：setLoopMode(mode) 或 cycleLoopMode()
```

- 旧内部 `setLoop(boolean)`、`onLoopChange(boolean)`、`snapshot.loop` 和 `toggleLoop()` 已迁移为三态接口，仓库调用者、假对象及测试同步更新；没有增加旧布尔 API 兼容层。其他消费者若单独依赖旧接口，也须迁移。
- 界面按钮依次切换“顺序播放 → 单曲循环 → 列表循环”，显示确认后的状态；横竖屏两个调用位置及无障碍文案共用同一控制器。
- 引擎区分请求值与确认值，旧会话回调不能改写新状态，停止后重播会重新应用请求的循环模式。模式不保存到全局设置，新播放页默认顺序播放。
- System 原生队列使用 API26 `PlaylistLoopMode.NONE / ONE / ALL`，沿用异步设置后的原生查询及请求 ID 隔离。非队列单源使用原生 `loop`；对一个源而言，单曲循环与列表循环行为相同。
- MPV 使用原生 `loop-file`、`loop-playlist` 的 `no/inf`，每次显式设置二者以清除上一模式。观察原生属性并回读模式，不采信包装层 `playlistMode` 通知作为确认。两种重复模式均不能因 EOF 后的 playing=false 错报为一次性完成。
- `PortStreamEnd.looping` 仍是布尔事件信息，表示当时是否启用重复；具体模式看 `loopMode`。没有应用层 EOF 重开循环，没有修改网络代理地址注册或按需读取机制。
- 随机播放、手动上一项/下一项的边界规则、持久化默认模式、字幕均未扩展。普通顺序/循环只驱动既有原生列表，不递归扫描目录或动态增删项目。

## 本轮验证与失败记录

| 项目 | 结果 |
| --- | --- |
| 新行为 RED | 先加入 5 个生产代码行为测试；旧实现缺少三态 API，5 项明确失败，原有用例仍通过 |
| 主机完整播放/网络/架构与产物回归 | 104/104，通过；0 失败、取消、跳过（含 22 项 guard） |
| 网络媒体缓存/数据库/取消回归 | PASS |
| SDK `entry@default` 单元测试 | 1 次，253/253 Success；BUILD SUCCESSFUL，无 Failure/Error/Ignore，不代表 ARM64 原生运行 |
| 架构边界、实际 simulator lock、diff 空白 | PASS |
| simulator 构建 1 | FAIL：按钮参数的 `ResourceStr` 联合类型不满足重载，ArkTS 10505001；外层 assembleHapSeq 00308018。没有安装这次失败构建 |
| 原因修正 | 文案函数实际只返回资源，将返回类型改为 `Resource`；未放宽编译器或修改播放逻辑 |
| simulator 构建 2 | BUILD SUCCESSFUL，native exit0；此前失败保留，不算两次均成功 |
| 新 HAP 严格 ABI 审核 | PASS：一个获准的 x86_64 FFmpeg so，无 ARM64 混入 |
| 正常安装与启动 | 明确 install bundle successfully / start ability successfully，没有卸载、清数据、签名绕过或手工 sign-app |
| 独立源码复核 | 无可行动 finding；复核者另跑适配器/引擎 70/70，通过；未声称其检查过 SDK 或设备 |

最终安装 HAP SHA256：`3B5724071782AA0B03E2B89E4FD64D160CB5EBEC5836E8718890808B74BE38D6`。逻辑代码对应本轮差异；报告在构建后补齐。已有 ArkTS 警告没有被清除或当成新增通过项。

## 实际应用操作

CLI 操作实际 `com.linkora.player.simulator` 应用，后端固定系统播放器。复用既有本地嵌套测试目录的两段 12 秒、640×360 MP4，没有创建或替换媒体；其来源清单见 `docs/validation/playlist-native-local-fixture-20261016.json`。本地原生顺序实际为 root-02 → root-01，以确认后的 1/2、2/2 索引记录，不猜文件名排序。

| 操作 | 实际结果 |
| --- | --- |
| 暂停时由顺序切到单曲，再切到列表 | 标签按原生确认依次变化，仍暂停 |
| 列表循环，选择末项 2/2 从头播放，等待 13 秒后暂停 | 变为 1/2，约 0:03/0:12；自然 EOF 回到首项，未拖进度 |
| 单曲循环，选择末项 2/2 从头播放，等待 13 秒后暂停 | 仍为 2/2，约 0:03/0:12；自然 EOF 重播当前项 |
| 顺序播放，末项停止后重播，等待 13 秒 | 仍为 2/2，0:12/0:12，“播放完成”，未回首项 |
| 已完成时切为列表循环，再停止、重播、暂停 | 仍为选中的 2/2，约 0:01，标签仍“列表循环”；截图确认实际红色视频画面 |
| 真实 WebDAV 六项 H.264 1080p MKV 列表，点击末项 | 6/6、约 0:05/49:10、1920×1080，暂停并切为列表循环 |
| 将该网络末项拖到末尾并播放 | 自动变为 1/6，约 0:03/47:58、播放中、1920×1080；随后暂停，截图确认首项真实画面。这是 seek 触发 EOF，未连续观看完整 49 分钟 |

应用最后停在真实 WebDAV 第 1/6 项，列表循环、暂停且有画面。本轮两个真实服务器条目继续保留，没有删除配置或修改服务器内容。截图和布局等原始证据仅本机保存，不发布用户媒体路径、文件清单、服务地址、凭据或设备标识。

## 限制

本轮证明 System 的这些有界操作，不证明任意格式、长时间稳定性、听觉输出或资源计数。MPV x86_64 仍是 compile-only stub，此次只补充所用 `MpvFormat.STRING` 声明，没有伪造真实解码能力；MPV 三态需 ARM64 或真实 HarmonyOS x86 MPV 包验证。前轮 22 项 4K/60fps 目录的打开超时未在本轮重试或修复，历史失败保持。

未修改、构建或清理原 workspace。隔离 checkout 四个生成锁文件继续保持未提交变化，不恢复、不 stage，不声称整个 checkout 干净。只提交本轮接口、适配器、界面、资源、测试与本报告。没有新增依赖、后台调度或额外兼容路线。
