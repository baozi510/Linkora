# Network media probe

独立 HAR：`NetworkMediaProbe.inspect(url, headers, options)` 使用系统 API20 的 AVMetadataExtractor，返回毫秒时长、视频宽高、状态、可空 PixelMap 及分阶段耗时。模块没有协议、数据库、页面或缓存依赖；调用前验证 HTTP/HTTPS URL 及请求头，不接受 URL 内凭据。

```ts
const probe = new NetworkMediaProbe();
try {
  const result = await probe.inspect(sourceUrl);
  try { /* 使用 result.durationMs、width、height、thumbnail */ }
  finally { await result.thumbnail?.release(); }
} finally { await probe.close(); }
```

每个实例只允许一个任务；完成后可复用。`cancel()` 及时返回取消状态并启动清理，`close()` 等待实际创建、提取和释放退出，重复关闭安全。关闭后不可复用；取消后的旧原生工作仍未退出时，新请求返回 busy。八秒期限覆盖创建、读取与抽帧；超时可带已获得的信息，不代表原生资源已经退出。调用方须在取消后撤销代理租约，再等待 close。返回的 PixelMap 由调用方释放，模块不会再释放它；迟到图像由模块释放。

SMB/SFTP/FTP/NFS 使用已有 `linkora_proxy`。本轮 API26 模拟器的系统提取器没有转发自定义请求头，故按用户确认，WebDAV 使用 entry 的 `HttpRemoteReadSession` 携带现有鉴权访问，再经代理提取；HAR 仍只接收 URL。HTTP 适配需要成功的 HEAD/Content-Length，以及精确 206/Content-Range；不支持 Range 的来源明确失败，不回退整文件下载。普通无鉴权 HTTP/HTTPS 点播可直连。串流页不增加代理或提取调用。

模块使用 API20 接口，验证设备是 API26 模拟器。系统支持范围不能推广到全部格式、HLS/DASH 或直播。信息接口有时返回空对象而不抛异常：`metadataComplete` 只表示接口成功；无数值时为零，抽帧失败可返回 `metadata_only`。系统可能读取完整小文件；本次 991017 字节样本在各代理协议上均读完，不是固定只读文件头。

内部测试只有 Debug Want `linkoraMediaProbeSmokeConfig` 会启动，普通启动及 Release 不启动内部测试。生产接入由 entry 的 NetworkMediaLoader 独立装配，仅网络列表当前可见的视频会提取；本地与串流页沿用现有流程。不添加设置项或批量扫描，复用现有应用数据库保存元数据。

## 正式接入与停用

在 `entry/src/main/ets/foundation/LinkoraFeatures.ets` 将 `NETWORK_MEDIA_ENABLED` 改为 `false` 并重新构建，即可停用生产媒体提取。工厂返回null，网络目录仅显示名称、类型图标、大小和日期，不读取媒体缓存或视频内容。linkora_proxy及其工厂不受这个开关影响，保留在项目中。

NetworkMediaLoader 使用现有协议读取器→proxy→本HAR，串行一个任务，相同请求合并。滚出视口、换目录、离页和进入后台会取消；总8秒期限包含连接和代理建立。及时取消不代表系统HTTP底层连接已立即退出；实际清理完成前不启动下一任务。SFTP严格模式需填写已信任的SHA256指纹，缺失/不匹配不自动降级。

网络媒体元数据持久保存在现有加密RDB的network_media_metadata（schema9），新缩略图优先使用系统WebP编码，设备不支持或编码失败时JPEG回退。图片位于filesDir/network-media，不放易被系统清除的cacheDir。持久记录和图片没有时间期限或数量淘汰；只限制内存24条和单图256KiB安全读取边界。数据库不存凭据或代理地址。

缩略图直接写入应用私有沙箱，不注册媒体库，也不需要相册权限；只有用户主动导出到系统图库时才需要媒体库流程。目录通过Context获取，不硬编码沙箱物理路径。filesDir用于长期保存，cacheDir可能被系统清理，见[应用沙箱目录](https://github.com/openharmony/docs/blob/master/zh-cn/application-dev/file-management/app-sandbox-directory.md)。

文件版本/服务器配置改变使用新键；主动刷新只重新获取目录列表，已有元数据和图片继续使用缓存，不清除或重写；新增或版本变化的文件按新键获取。删除服务器先清理其图片，成功后才级联删除元数据；清理失败保留记录，供重试。既有cacheDir/network-media中的JSON/JPEG按访问迁移，成功后才删除旧文件；过期时间戳仍迁移，写失败保留旧文件供重试。图片缺失或损坏不丢元数据，补取结果未知的字段沿用已有数值，宽高作为一对更新；后续可见请求可以重试，失败30秒抑制重试，主动刷新允许失败项重试。旧JPEG继续支持，不为转换格式重新读取网络视频。

`options.mode` 支持 `ProbeMode.BOTH`（默认）、`METADATA`、`THUMBNAIL`。元数据模式不调用抽帧；缩略图模式不调用 fetchMetadata，可传 `durationHintMs` 使用已缓存时长选择取帧点。BOTH 复用同一 AVMetadataExtractor；`options.onMetadata` 在元数据读完后立即交付快照，尚未抽帧。回调只包含元数据，不交付 PixelMap。

生产列表加载期间先显示大小和修改日期；元数据与缩略图在抽帧、编码、解码结束后统一显示，命中缓存也等图像解码后再显示增强信息。中间取得的元数据仍单独缓存；完整元数据已有缓存、图片缺失时只补抽帧。图片失败或超时时，在该次请求结束后按已有部分信息回退，取消或离页不交付增强信息。`result.timings` 使用系统单调时钟，分别返回 `prepareMs`（创建与设置来源）、`metadataMs`、`thumbnailMs`、`totalMs`。单位毫秒，null 表示未执行，取消/失败记录该阶段已耗时间；总耗时包括当前调用等待的清理，不包含调用方准备代理或图片编码。结果是快照，迟到清理不会改变已返回的耗时。生产日志另记连接/代理准备和编码时间，不含 URL、文件名或凭据；命中缓存不打印提取耗时。

模拟器分阶段测量：Studio Node 执行 `scripts/check-network-media-probe.cjs --timings`，用已有已知视频对鉴权 WebDAV 代理来源分别运行三种模式各五次，输出原始阶段数据到 `artifacts/media-probe/device-result.json`，导出真实 WebP/JPEG 验证解码。元数据单独提取的整次耗时包含独立创建；BOTH 中的抽帧耗时使用已解析来源，不能与独立 THUMBNAIL 调用的整次耗时直接等同。

如需彻底移除 HAR，保留 proxy，并按以下顺序处理（只停用自动读取时，前面的一个常量已经足够）：

1. 工厂 `createNetworkMediaLoader` 固定返回 `null`，移除 `NetworkMediaProbe` 的导入及 `createNetworkMediaProbe`。
2. 将 `NetworkMediaLoader.ets` 替换为下面的空适配，保留现有列表回调签名。缓存类可以保留，但工厂为 null 时不会实例化或访问。
3. 移除 EntryAbility 的 MediaProbeBuildProfile、NetworkMediaProbeSmokeTest 导入、mediaProbeSmokeConfig 字段、对应 Want 判断及测试调用；移除 `NetworkMediaProbeSmokeTest.ets`、`NetworkMediaProbe.test.ets`，以及 `List.test.ets` 的导入/调用。
4. 从根 `build-profile.json5` 删除 linkora_media_probe 模块，从 entry `oh-package.json5` 删除其依赖，然后执行 ohpm install。删除 HAR 目录。
5. 删除 `scripts/check-network-media-list.cjs`、`scripts/check-network-media-list-ui.cjs`、`scripts/check-network-media-probe.cjs`；从 verify.ps1 删除两个媒体检查调用及 HAR 构建数组中的 linkora_media_probe。代理检查、core、协议读取器和基础目录不删除。
6. 运行基础应用测试及 Debug/Release 构建，普通启动，验证本地/网络基础列表和串流直连。

```ts
import { image } from '@kit.ImageKit';
import { NetworkDirectoryEntry } from '../models/NetworkDirectoryState';
export class NetworkMediaLoader {
  reset(_entries: NetworkDirectoryEntry[], _force: boolean): void {}
  async load(_entry: NetworkDirectoryEntry, _consumerId: string = ''): Promise<image.PixelMap | null> { return null; }
  cancel(_path: string, _consumerId: string = ''): void {}
  close(): void {}
}
```

空适配没有 HAR 依赖，也不会创建代理或读取缓存；以后若永久清理 UI 接线，可一并删除它和工厂。数据库和串流页不受拆除影响。
