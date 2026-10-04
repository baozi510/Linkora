# FFmpeg Media Analysis Integration Blocker

## Status

Dependency bootstrap is **COMPLETE FOR PHASE-1 ENTRY**.

Validation produced real FFmpeg 8.1.3 static libraries for both x86_64 and arm64-v8a using the HarmonyOS SDK toolchain, and archive members were audited as X86-64 / AArch64.

The dedicated analyzer module implementation is now authorized on:

`feat/ffmpeg-media-analysis-phase1`

Policy integration remains blocked until the native module itself passes x86 simulator smoke and arm64 build verification.

Read:

- `docs/FFMPEG_BOOTSTRAP.md`
- `docs/CODEX_FFMPEG_INTEGRATION_RUNBOOK.md`

## What is present

The current native build already contains protocol libraries and adapters for SMB/NFS/SFTP/FTP.

It does not contain:

- FFmpeg/libav headers
- linkable HarmonyOS libavformat/libavcodec/libavutil/libswscale artifacts
- verified generated FFmpeg artifacts from the pinned repository build scripts
- completed arm64-v8a and x86_64 ABI build manifests

## Why the implementation is deliberately blocked

A fake NAPI module that compiles only against undeclared local headers would make the repository non-reproducible.

The libmpv package internally contains an FFmpeg build, but that does not make libav* an API contract available to a separate Linkora media-analysis module.

Linkora must not depend on internal/private symbols of libmpv for metadata analysis.

## Required dependency deliverable

Before implementing `FFmpegMediaProbe` and `FFmpegThumbnailExtractor`, add one reproducible option:

### Option A — dedicated static FFmpeg build

Pin:

- FFmpeg source revision/version
- HarmonyOS NDK/API target
- arm64-v8a and x86_64 toolchain flags
- enabled/disabled components
- third-party decoder dependencies
- patches
- artifact checksums

Produce linkable libraries for:

- libavformat
- libavcodec
- libavutil
- libswscale

This is the recommended first integration because it is isolated from mpv.

### Option B — shared libav artifacts

Refactor the media stack so both libmpv and Linkora media analysis consume the same shared libav libraries.

This reduces duplicate code size but adds substantially more native-build complexity and should not be the first integration.

## Initial FFmpeg module contract

When the artifacts exist, implement a Native analysis module only.

Do not add ffmpeg or ffprobe command-line executables.

Initial functionality:

```text
FFmpegMediaProbe
  -> format
  -> streams/tracks
  -> codec/profile/level
  -> dimensions/fps/bitrate/bit depth
  -> color metadata/HDR
  -> chapters/tags/side data

FFmpegThumbnailExtractor
  -> seek
  -> decode frame
  -> swscale
  -> raw RGBA
```

Remote first-generation input:

```text
RandomAccessSource
   ↓
MediaProxy
   ↓
localhost URL
   ↓
FFmpeg
```

Do not implement AVIOContext direct callbacks until benchmark evidence justifies them.

## Exit criteria for this blocker

The FFmpeg phase may resume when all of these are available:

1. reproducible arm64-v8a and x86_64 FFmpeg builds succeed
2. pinned version/revision matches `third_party/ffmpeg/manifest.json`
3. headers and static link artifacts are generated for both ABIs
4. license/third-party manifest is updated
5. clean Linkora native-module integration succeeds on the HarmonyOS toolchain
6. one local MP4 probe smoke test succeeds on x86_64 simulator
7. one MediaProxy MKV probe smoke test succeeds on x86_64 simulator
8. corresponding arm64 probe smoke tests succeed on device before release claims
