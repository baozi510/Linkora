# Linkora 媒体兼容性实测报告

测试日期：2026-09-01  
应用引擎：HarmonyOS `media.AVPlayer` + `XComponent`  
测试设备：DevEco Mate 80 Pro 模拟器  
系统版本：HarmonyOS 6.1.0.126（SP1DEVC00E120R4P11），API 24

## 结论

| 路径 | 通过 | 失败 | 总数 | 通过率 |
| --- | ---: | ---: | ---: | ---: |
| 网络 URL | 39 | 20 | 59 | 66.1% |
| 本地 `fdSrc` | 37 | 19 | 56 | 66.1% |

网络与本地文件的 56 项结果完全一致，说明文件失败项来自当前模拟器的系统解码器或封装解析能力，不是 HTTP 传输路径导致。流媒体额外结果为：HLS/H.264 通过、HLS/HEVC 失败、DASH/H.264 通过。

本报告只描述这台模拟器。HEVC、AV1、VP9、HDR、杜比相关格式与高分辨率硬件能力必须在目标真机重新测试，不能把模拟器失败直接等同于 HarmonyOS 真机不支持。

当前本地文件选择器公开的 13 类后缀（`.mp4`、`.m4v`、`.mov`、`.mkv`、`.webm`、`.ts`、`.m2ts`、`.mp3`、`.aac`、`.m4a`、`.flac`、`.ogg`、`.wav`）均已覆盖。后缀只是容器提示，最终能否播放仍取决于容器内部的视频、音频编码组合。例如 `.mkv` + H.264/AAC 通过，但 `.mkv` + HEVC/AAC 在本模拟器失败。

## 视频与容器

| 结果 | 组合 |
| --- | --- |
| 通过 | MP4/H.264/AAC |
| 通过 | MP4/MPEG-4 Part 2/AAC |
| 通过 | M4V/H.264/AAC、MOV/H.264/AAC |
| 通过 | MP4/H.264 High/1080p、MP4/H.264 High/4K |
| 通过 | MP4/H.264 High 10/AAC |
| 通过 | MKV/H.264 + AAC、AC-3、DTS、FLAC、Opus |
| 通过 | MKV/H.264/AAC/内嵌 SRT（仅验证媒体首帧，不代表字幕已显示） |
| 通过 | MPEG-TS/H.264/AAC、M2TS/H.264/AAC |
| 通过 | AVI/MPEG-4 Part 2/MP3、AVI/MJPEG/PCM |
| 通过 | FLV/H.264/AAC、MPEG-PS/MPEG-2/MP2、VOB/MPEG-2/AC-3、3GP/H.263/AAC |
| 失败 | MP4、MKV、MPEG-TS 中的 HEVC/H.265 |
| 失败 | MP4/AV1/AAC |
| 失败 | MP4/VP9/AAC、MKV/VP9/Opus |
| 失败 | WebM/VP8/Vorbis、WebM/VP9/Opus |
| 失败 | MKV/H.264/E-AC-3 |
| 失败 | WMV/WMV2/WMA、Ogg/Theora/Vorbis、MOV/ProRes/PCM |
| 失败 | RealMedia/RV20、MKV/FFV1/FLAC |

## 音频

| 结果 | 格式 |
| --- | --- |
| 通过 | MP3、AAC/ADTS、M4A/AAC |
| 通过 | FLAC、M4A/ALAC、APE、WMA |
| 通过 | Ogg/Vorbis、Ogg/Opus |
| 通过 | WAV/PCM、AIFF/PCM、CAF/ALAC |
| 通过 | AMR-NB、AMR-WB、AC-3、DTS |
| 失败 | E-AC-3、WavPack、TTA、TrueHD、MLP |

## 流媒体

| 结果 | 格式 |
| --- | --- |
| 通过 | HLS/H.264/AAC |
| 通过 | DASH/H.264/AAC |
| 失败 | HLS/HEVC/AAC |

## 原始失败依据

失败事件都由 AVPlayer 返回，主要错误码为 `5400106`（Unsupported Format）：

- HEVC、AV1、VP8、VP9：系统明确返回对应视频 decoder interface 不支持。
- MKV/E-AC-3、WMV、Ogg Video、ProRes/PCM、RealMedia、FFV1：demuxer 或 parser 失败。
- 裸 E-AC-3、WavPack、TTA、TrueHD、MLP：系统返回 container format 不支持。

DASH 首轮曾因生成器把媒体分片写到错误目录而返回 `5411007`。修正分片路径并复测后，DASH/H.264 首帧输出成功，最终统计已使用修正后的结果。

## 测试方法与边界

每个样本均通过生产使用的 `PlaybackEngine` 和 `SystemPlaybackPort` 打开。视频以 AVPlayer 进入播放且收到首帧事件为通过；音频以进入播放后稳定 800 ms 为通过；单项超时 12 秒。本地轮先把相同字节下载到应用沙箱，再由 `MediaSource.fromLocalDocument` 走 `fileIo`/`fdSrc`。

当前自动化没有验证：实际可听声音、全片解码、seek 精度、变速、字幕渲染、多音轨切换、HDR/Dolby Vision、声道布局、损坏文件恢复、断网续播、内存、温度、功耗和 2 小时以上长稳。这些必须进入真机发布门禁。

样本生成和复测说明位于 [../test-lab/media-compatibility/README.md](../test-lab/media-compatibility/README.md)。APE 样本来自 FFmpeg 官方样本库，并使用固定 SHA-256 校验。
