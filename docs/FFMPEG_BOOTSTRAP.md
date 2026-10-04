# FFmpeg Analyzer Bootstrap

## Status

FFmpeg work has started as a reproducible dependency/build phase.

It is **not yet linked into Linkora**, and no FFmpeg analyzer capability is claimed yet.

Pinned upstream:

- FFmpeg 8.1.3
- tag: `n8.1.3`
- verified tag object: `23151b11c75aa44d9ab8db796a53c76acf00f6c0`
- pinned commit: `1041abdc962f4cc4f394aa8de9dc5236c0c3b9e7`

Initial license/build profile:

- LGPL-default profile
- no `--enable-gpl`
- no `--enable-nonfree`
- static libraries
- no ffmpeg/ffprobe/ffplay programs
- no encoders
- no muxers
- no hardware accelerators
- no avdevice
- no avfilter
- no swresample

Required libraries:

- libavformat
- libavcodec
- libavutil
- libswscale

## Why dual ABI from day one

The formal Linkora runtime remains arm64-v8a.

The simulator should run as much real analysis code as possible, so FFmpeg is planned for:

- arm64-v8a
- x86_64

This allows the x86_64 simulator to run the real future FFmpeg metadata and frame-decode implementation while MPV and native network transports remain platform substitutions.

## Fetch the exact source

From repository root:

```powershell
./scripts/ffmpeg/fetch-source.ps1
```

The script checks out the exact pinned commit.

Generated source:

`third_party/ffmpeg/source`

is ignored by Git.

## HarmonyOS Native SDK input

The build script deliberately does not hard-code a DevEco installation path.

Pass the HarmonyOS Native SDK root containing:

```text
llvm/bin/clang
llvm/bin/clang++
llvm/bin/llvm-ar
llvm/bin/llvm-ranlib
llvm/bin/llvm-nm
llvm/bin/llvm-strip
sysroot/
```

Example:

```bash
export OHOS_NATIVE_ROOT="/path/to/harmony/native"
```

## Build x86_64

Run from a POSIX shell such as Git Bash/MSYS2/WSL with GNU make:

```bash
scripts/ffmpeg/build-harmony.sh x86_64 "$OHOS_NATIVE_ROOT"
```

Expected:

```text
third_party/ffmpeg/prebuilt/x86_64/
  include/
  lib/libavformat.a
  lib/libavcodec.a
  lib/libavutil.a
  lib/libswscale.a
  linkora-build-manifest.txt
```

## Build arm64-v8a

```bash
scripts/ffmpeg/build-harmony.sh arm64-v8a "$OHOS_NATIVE_ROOT"
```

Expected:

```text
third_party/ffmpeg/prebuilt/arm64-v8a/
  include/
  lib/libavformat.a
  lib/libavcodec.a
  lib/libavutil.a
  lib/libswscale.a
  linkora-build-manifest.txt
```

## target-os assumption

Upstream FFmpeg 8.1.3 does not currently provide a dedicated HarmonyOS target-os entry in its configure script.

The bootstrap therefore uses:

```text
--target-os=linux
--target=aarch64-linux-ohos / x86_64-linux-ohos through compiler wrappers
--sysroot=<HarmonyOS Native SDK sysroot>
```

This is an explicit assumption to validate.

If configure or compilation exposes a Linux-only assumption:

1. keep the complete failure log;
2. add the smallest HarmonyOS patch;
3. store it under `third_party/ffmpeg/patches/`;
4. record patch purpose/hash in `manifest.json`;
5. rerun both ABIs.

Never silently fall back to host headers or libraries.

## First-generation input path

Remote input remains:

```text
RandomAccessSource
        ↓
shared MediaProxy
        ↓
localhost HTTP
        ↓
FFmpeg
```

No AVIOContext callback yet.

That keeps storage independent from analyzer implementation and lets System/FFmpeg share the same remote-access infrastructure.

## Next implementation after both ABI builds succeed

Create a dedicated native analyzer module, not code inside MPV:

```text
linkora_ffmpeg
  ├─ FFmpegMediaProbe
  └─ FFmpegThumbnailExtractor
```

### FFmpegMediaProbe

Initial output:

- container/format
- duration
- overall bitrate
- video/audio/subtitle streams
- codec/profile/level
- width/height/fps
- bit depth/pixel format
- primaries/transfer/colorspace
- HDR-relevant side data
- chapters
- tags

### FFmpegThumbnailExtractor

Responsibilities:

- receive target timestamp from ThumbnailTimePolicy
- seek
- decode one frame
- swscale to raw RGBA/BGRA
- return raw frame

It must **not** encode WebP.

The existing common WebP encoder remains the only persistent thumbnail encoder.

## Acceptance gate before policy wiring

For each ABI:

1. clean FFmpeg build succeeds;
2. exact source commit/toolchain is recorded;
3. local H.264 MP4 probe succeeds;
4. local MKV/HEVC probe succeeds;
5. MediaProxy-hosted MKV probe succeeds;
6. software thumbnail frame decode succeeds;
7. no ffmpeg/ffprobe executable is packaged;
8. license/third-party manifest is updated.

Only after this should System-vs-FFmpeg benchmark and analyzer policy work begin.
