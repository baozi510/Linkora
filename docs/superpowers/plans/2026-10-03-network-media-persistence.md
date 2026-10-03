# Network Media Persistence Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans in the current session. Follow the checkbox steps and perform one final fresh-context review.

**Goal:** 元数据存数据库，图片持久保存且不按数量/时间淘汰，优先WebP。
**Architecture:** 复用LinkoraDatabase迁移/写队列；NetworkMediaCache对接RDB和filesDir；loader仍串行复用proxy及probe。
**Tech Stack:** ArkTS、HarmonyOS RDB/ImageKit、现有Node SQLite源文件检查。
**Spec:** docs/superpowers/specs/2026-10-03-network-media-persistence-design.md

## Global Constraints

- 用户免除确认，当前会话执行，不新增依赖/设置项；proxy保留。
- schema9；filesDir/network-media；无持久记录数量/时间淘汰；内存24条。
- quality85、优先image/webp、系统不支持时JPEG回退；安全单图256KiB。
- 原v8数据、原缓存迁移失败不得丢失；只处理可见网络视频。

## Review Focus

- v9中断回滚且不破坏v8本地数据（Task1迁移故障测试）。
- 冷启动/旧时间戳/第129张仍命中（Task1缓存测试）。
- 只有元数据或坏图片，保留数值并允许抽帧重试（Task1缓存+loader）。
- 数据库/文件写失败后仍可使用与重试，删服务器不留新持久图片（Task1源检查）。
- 真设备WebP支持与JPEG回退，既有取消和模块停用不受影响（Task2设备+审查）。

## Task 1: 持久化及编码

**Files:** LinkoraDatabase.ets、NetworkMediaCache.ets、NetworkMediaLoader.ets、NetworkServerStore.ets；scripts/check-local-persistence.cjs、check-network-media-list.cjs。
**Interfaces:** NetworkMediaCache(context,serverId)、get/put/key沿用；CachedNetworkMedia.imageData与imageFormat；NetworkMediaCache.removeFiles(context,keys)供服务器删除。用户后续明确刷新保留缓存，已移除刷新失效及未使用的invalidate接口。
- [x] 先写v9回滚、旧缓存迁移、超128永久保存、独立元数据/缺图、删服务器及故障检查，运行看到RED。
- [x] 新增v9表，改cache与loader，服务器删除收集key清理图片，复用写队列及现有编码器，不改probe两步接口。
- [x] 缓存/loader/持久化检查GREEN，原单元与构建通过，精确提交。

## Task 2: 模拟器、审查、原项目交付

**Files:** check-network-media-list-ui.cjs、README、DEVELOPMENT；验证记录及账本。
- [x] UI脚本查看持久目录，验证真实WebP RIFF/WEBP文件、数值与缩略图、重启命中、刷新、删服务器后图片清理，保留既有取消检查。
- [x] Debug/Release及123原单元/持久化全通过；一次最终全差异只读审查，必要项一次修复并RED→GREEN。
- [x] 只回写本基线之后差异，原项目构建/模拟器安装复测，保存安全证据，恢复启用。
- [x] 归档临时工作树；完成状态以原项目artifacts/network-media-persistence/progress.md记录为准。
