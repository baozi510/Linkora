# Network Media List Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans. 用户要求无需确认直接完成，沿用当前会话执行，省略人工设计/计划审批。

**Goal:** 网络可见视频正式显示真实媒体信息及缩略图，提取可独立停用，proxy保留。
**Architecture:** entry loader串行调用已有reader/proxy/probe，专用缓存使用已有哈希及系统文件/图片API；UI共用FileMediaPreview，通过可空工厂装配。
**Tech Stack:** ArkTS API20、既有HAR/Hypium/Node/hdc。
**Spec:** ../specs/2026-10-03-network-media-list-design.md

## Global Constraints
- 仅网络视频；本地、串流、播放流程及数据库不接新提取。
- 8秒期限包括连接；单浏览器一任务；消费者独立图片所有权。
- 128条磁盘缓存、每图256KiB、24小时、内存24条、失败30秒；配置/文件变化失效。
- 工厂返回null即可停用；保留proxy。SFTP严格指纹不降级。

## Review Focus
- 滚动/目录刷新时迟到创建、图片与旧回调：取消及时且资源有主；Task1/2。
- 相同文件多消费者：合并提取，各自图片，无提前释放；Task1。
- 缓存损坏/过期/文件改变：回退不改基础条目、不泄漏路径凭据；Task1。
- 提取失败/存储失败：可用部分信息仍显示，不阻断目录播放；Task1/2。
- 停用与严格SFTP：无自动提取，不绕过身份校验，proxy正常；Task2/3。

## Task 1: 缓存与网络媒体加载
**Files:** services/NetworkMediaCache.ets、NetworkMediaLoader.ets；scripts/check-network-media-list.cjs。
**Consumes:** SourceIdentity.value、NetworkDirectoryService.openReader、NetworkFileProxy.buildProxyUrl、NetworkMediaProbe.inspect/cancel/close。
**Produces:** NetworkMediaLoader(context,server,onMetadata)、load(entry):Promise<PixelMap|null>、cancel(path)、reset(entries,force)、close():void；NetworkMediaCache get/put/decode/invalidate。
- [x] 先写实际源文件VM检查，运行确认缺失实现失败。
- [x] 实现专用数值/JPEG缓存及串行队列，取消/截止时间/迟到清理、合并、负缓存。
- [x] 检查串行、独立解码、失效、损坏和取消通过，精确提交。

## Task 2: UI与可空装配
**Files:** FileMediaPreview.ets、NetworkDirectoryBrowser.ets、LinkoraFeatures.ets；NetworkServerStore.ets、NetworkPage.ets、NetworkDirectoryService.ets。
**Consumes:** Task1签名，既有LocalMediaAsset格式化方法。
**Produces:** 网络可见项延迟加载、仅当前目录媒体数值；工厂常量停用；严格SFTP可传已知指纹。
- [x] 写装配/可见请求/基础回退检查，确认旧源无接入失败。
- [x] 加可见加载与取消回调（默认不影响本地），补网络列表信息，网格无chip。
- [x] 可空工厂和严格指纹字段传递，失败回退；全部单元及Debug构建通过后精确提交。

## Task 3: 模拟器与停用回归交付
**Files:** scripts/check-network-media-list-ui.cjs、README及DEVELOPMENT说明、verify.ps1。
- [x] 真实网络页面列表/网格、缓存命中/冷启动、目录切换、失败回退；媒体16场景回归。
- [x] 暂时停用工厂构建/安装，检查基础列表与原proxy；恢复启用。
- [x] 原测试、持久化与Debug/Release构建通过；一次最终只读审查，修复必需项。
- [x] 只将基线之后的差异回写D:/Linkora，再构建安装复测，保存证据并归档工作树。


最终验证：原项目123/123、持久化、各HAR/HAP Debug/Release及API26页面复测通过。一次只读审查提出的7项Important已修复，拆卸说明也补全并实际验证；HAR彻底脱离构建后118/118、基础列表零媒体读取与串流4组通过。详见 artifacts/network-media-list/verification.md 及裁决账本。最后归档临时工作树，不改原项目Git历史。
