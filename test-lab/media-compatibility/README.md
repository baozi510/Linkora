# 媒体兼容性实验室

本目录用于生成固定、短时、可重复的媒体样本，不属于生产应用代码。

## 准备样本

要求 PowerShell 7、FFmpeg 和 FFprobe 已加入 `PATH`。

```powershell
./generate-samples.ps1
./fetch-external-samples.ps1
```

除 APE 外，样本都由 `generate-samples.ps1` 在本机生成。APE 使用 FFmpeg 项目的公开样本，并通过固定 SHA-256 校验。生成物位于 `samples/`，已加入 `.gitignore`。

## 临时提供 HTTP 服务

```powershell
Set-Location ./samples
python -m http.server 18080 --bind 0.0.0.0
```

HarmonyOS 模拟器可通过 `http://10.0.2.2:18080/` 访问宿主机服务。不要在不受信任的网络中长期开放该端口。

## 判定口径

- 视频通过：AVPlayer 进入播放状态，并收到首帧渲染事件。
- 音频通过：AVPlayer 进入播放状态后稳定保持 800 ms。
- 单项超时：12 秒。
- 网络轮：59 项，包括 56 个文件和 3 个流媒体清单。
- 本地轮：56 项；样本先下载到应用沙箱，再走与系统选择器一致的 `fdSrc` 播放通路。

该口径不能替代真机上的声音确认、字幕显示、seek、长时间稳定性、HDR、音画同步、硬件解码与功耗测试。生产入口不包含兼容性实验室页面，避免公开 Ability 被参数触发后批量下载样本。

完整实测结果见 [../../docs/MEDIA_COMPATIBILITY_REPORT.md](../../docs/MEDIA_COMPATIBILITY_REPORT.md)。


## Future unified Media Capability Corpus

This lab is the seed corpus for the project-wide capability matrix.

Do not create a separate analyzer-only or playback-only media library. The same fixture set is intended to feed:

- System metadata;
- FFmpeg metadata;
- System thumbnail;
- FFmpeg thumbnail;
- System playback;
- MPV playback;
- Advanced AV validation.

Results remain independent: a PASS in one engine/capability does not imply PASS in another.

Acceptance tiers are defined in `docs/MASTER_IMPLEMENTATION_PLAN.md`:

- Tier A: mainstream/core release-gated coverage;
- Tier B: real-world legacy coverage, investigate failures but not automatically release-blocking;
- Tier C: rare/obsolete/emerging observation coverage; successful handling is desirable but not mandatory, while crashes/hangs/resource leaks remain unacceptable.

The historical simulator report remains historical System/AVPlayer evidence only. Real-arm64 System/MPV/Analyzer results must be collected afresh.
