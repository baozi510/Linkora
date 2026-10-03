# linkora_proxy

开发阶段的独立 HAR，把 `RemoteReadSession` 转为短期本机 HTTP 文件地址。最低 API 20；不包含协议客户端、页面、媒体解析或数据库。

通过 `LinkoraFeatures.createNetworkFileProxy()` 装配。每次 `buildProxyUrl(reader, contentType)` 接管 reader，包括注册失败的清理。句柄的 `release()` 关闭该文件；实例 `close()` 撤销全部地址、关闭客户端与 reader。关闭后的实例不能重新注册，需要新建实例。

```ts
const proxy = LinkoraFeatures.createNetworkFileProxy();
const reader = await directoryService.openReader(path);
const lease = await proxy.buildProxyUrl(reader, 'video/mp4');
try {
  // 交给消费者；原始来源身份单独保留。
} finally {
  await lease.release();
  await proxy.close();
}
```

仅绑定 127.0.0.1。支持 GET、HEAD、单字节范围；每块最多 256 KiB。最多 8 个文件句柄、16 个客户端。URL 不保存到最近播放、书签或数据库，也不记录到日志。

移除：删除 `LinkoraFeatures` 中的导入和装配方法、`EntryAbility` 中的 Debug smoke 导入与调用、相应 smoke/测试文件，再去掉 root build-profile 和 entry 包依赖的 `linkora_proxy` 项及 verify.ps1 的代理 HAR 构建项。core 读取契约、协议读取适配和目录基础信息保留。现有播放与串流没有依赖代理实例。

SMB/SFTP/FTP/NFS 的 `openReader` 适配在 entry 中；HTTP 串流和 WebDAV 继续直连。SFTP 严格模式必须显式提供可信指纹，当前沿用 native 的 `SHA256:xx:xx:…` 十六进制格式；本阶段不添加指纹设置或持久化。FTP 支持普通被动模式和 REST，不支持 FTPS、主动模式。

FTP 连续读取保留数据连接，跳转时重建控制连接，避免未完成传输的回复污染后续命令。暂未针对频繁 seek 的持续播放优化，代理目前只接入开发测试。

FTP reader 每次原生操作共用 8 秒绝对截止时间，控制回复累计最多 64 KiB；取消最多间隔 100 ms 检查一次，关闭只释放传输而不等待 QUIT。其他协议沿用已有原生库的超时，取消后等待工作线程退出再销毁资源。
