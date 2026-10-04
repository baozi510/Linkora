# Codex FFmpeg Media Analysis Phase 1 Runbook

> Branch: `feat/ffmpeg-media-analysis-phase1`  
> Base: `test/simulator-validation`  
> Status: IMPLEMENTATION AUTHORIZED  
> Do not merge during this phase.

## 1. Architecture review verdict

The simulator-validation round is accepted.

Accepted production/runtime fixes:

- target-scoped native build configuration;
- simulator Seq build task correction;
- PlaybackEngine overlapping seek/buffering state fix;
- NetworkDirectoryBrowser RepeatItem refresh fix;
- pinned FFmpeg fetch refspec fix.

Accepted validation evidence:

- default `verify.ps1` PASS;
- 149/149 Hypium PASS;
- Debug/Release default arm64 HAP PASS;
- x86_64 simulator HAP build/install/launch PASS;
- real WebDAV/System/MediaProxy seek path exercised;
- FFmpeg 8.1.3 static bootstrap built successfully for x86_64 and arm64-v8a;
- archive members were audited as X86-64 / AArch64 respectively.

The simulator still cannot validate real MPV/native protocol I/O/HDR/passthrough. Those remain device-only.

## 2. Phase 1 goal

Implement a dedicated native FFmpeg analysis module that can run on:

- x86_64 simulator;
- arm64-v8a HarmonyOS build.

This phase is deliberately **below** policy/routing.

Do not yet modify:

- PlaybackBackendSelector;
- Auto policy;
- SystemPlaybackPort;
- MpvPlaybackPort;
- NetworkMediaLoader production routing;
- IMediaProbe public signature;
- IThumbnailExtractor public signature;
- direct AVIO callbacks.

## 3. New module

Create a dedicated module:

```text
linkora_ffmpeg/
  Index.ets
  build-profile.json5
  oh-package.json5
  hvigorfile.ts
  src/main/module.json5
  src/main/ets/
  src/main/cpp/
```

Its native output should be:

```text
liblinkora_ffmpeg.so
```

Do not put FFmpeg code inside:

- entry native CMake;
- libmpv wrapper;
- linkora_media_probe System implementation.

## 4. FFmpeg dependency

Use only the pinned bootstrap:

- FFmpeg 8.1.3
- tag `n8.1.3`
- commit `1041abdc962f4cc4f394aa8de9dc5236c0c3b9e7`

Generated libraries remain ignored:

```text
third_party/ffmpeg/prebuilt/x86_64
third_party/ffmpeg/prebuilt/arm64-v8a
```

Required libraries:

- libavformat.a
- libavcodec.a
- libavutil.a
- libswscale.a

Do not commit generated FFmpeg binaries or headers.

The module build must fail with an actionable message if the required ABI prebuilt directory is missing.

## 5. Build targets

The new module must support both target ABIs.

Expected relation:

```text
default product
  -> linkora_ffmpeg arm64-v8a

simulator product
  -> linkora_ffmpeg x86_64
```

Do not package x86 code in the default arm64 HAP.

Do not package arm64 code in the simulator HAP.

Update simulator native whitelist so `liblinkora_ffmpeg.so` is allowed only when its ELF architecture matches x86_64.

Add equivalent default artifact checks confirming its FFmpeg module is arm64/AArch64.

## 6. Native API boundary

Phase 1 should expose a small async URL/path API.

Recommended shape:

```text
probe(requestId, input, timeoutMs) -> Promise<NativeProbeResult>
extractFrame(requestId, input, timeMs, maxWidth, maxHeight, timeoutMs)
  -> Promise<NativeFrameResult>
cancel(requestId) -> void
```

Exact ArkTS names may differ, but preserve these properties:

- every long operation is async;
- every operation has a stable request ID;
- cancellation is per request;
- timeout is enforced natively;
- cancellation/timeout reaches FFmpeg through `AVIOInterruptCB`;
- no global "cancel everything" state shared between unrelated requests.

Do not block the ArkTS UI thread with FFmpeg work.

## 7. Allowed inputs in Phase 1

Keep the first surface intentionally narrow.

Allow:

1. an application-accessible local native file path used by smoke tests;
2. localhost MediaProxy URL:
   - `http://127.0.0.1:<port>/<token>`
   - localhost equivalent only if already emitted by MediaProxy.

Do not add arbitrary remote credential/header handling to the native module in Phase 1.

Remote production architecture remains:

```text
RandomAccessSource
  -> shared MediaProxy
  -> localhost URL
  -> FFmpeg
```

No AVIOContext callback yet.

Reject:

- embedded userinfo credentials;
- CR/LF/NUL;
- unbounded input strings;
- unsupported URI schemes.

## 8. Native probe implementation

Use:

- `avformat_open_input`
- `avformat_find_stream_info`

Return structured data, not JSON scraped from ffprobe.

At minimum collect:

### Format

- format/container name;
- duration;
- overall bitrate;
- input size when FFmpeg can determine it.

### Video tracks

- stream index/id;
- codec name;
- profile;
- level;
- width/height;
- frame rate;
- bitrate;
- pixel format when known;
- bit depth when derivable;
- color primaries;
- transfer;
- colorspace;
- default disposition;
- language/title.

### Audio tracks

- stream index/id;
- codec;
- profile when known;
- channel count;
- channel layout;
- sample rate;
- bitrate;
- default disposition;
- language/title.

### Subtitle tracks

- stream index/id;
- codec;
- text vs bitmap when FFmpeg descriptor properties can determine it;
- forced/default disposition;
- language/title.

### Chapters/tags

- chapter start/end/title;
- bounded format tags.

Cap metadata count and total tag bytes. Do not copy unbounded arbitrary metadata into ArkTS.

## 9. HDR mapping

Be conservative.

Map:

- SMPTE ST 2084 / PQ -> HDR10 generic label;
- ARIB STD-B67 -> HLG;
- explicit Dolby Vision configuration side data -> Dolby Vision;
- otherwise do not infer HDR from BT.2020 primaries alone.

This must match the existing Linkora HDR rule.

Do not claim physical HDR/Dolby Vision output. This is metadata analysis only.

## 10. Frame extraction

Implement one-frame software extraction.

Flow:

```text
open input
-> find video stream
-> open decoder
-> seek near requested timestamp
-> flush decoder
-> decode forward
-> select first suitable frame
-> swscale
-> return RGBA/BGRA raw bytes
```

Requirements:

- preserve aspect ratio;
- fit inside requested max width/height;
- never upscale unless explicitly justified;
- default request remains compatible with 480x270;
- validate output allocation size before allocating;
- raw byte count must equal width * height * 4;
- no WebP encoding inside FFmpeg module.

The existing SystemWebPEncoder remains the persistent encoder.

## 11. Cancellation / timeout

Every native operation must use an interrupt state containing:

- deadline;
- atomic cancelled flag.

`AVIOInterruptCB` must abort blocking open/read operations when:

- request is cancelled;
- timeout expires.

ArkTS Promise completion after cancellation must be deterministic.

No use-after-free if:

- cancel arrives during open;
- cancel arrives during stream-info;
- cancel arrives during decode;
- ArkTS caller releases its wrapper before worker completion.

## 12. Error contract

Create a small stable FFmpeg-native error model.

At minimum distinguish:

- invalid input;
- open failed;
- stream info failed;
- no video stream;
- decoder unavailable;
- decode failed;
- timeout;
- cancelled;
- allocation/size rejected.

Preserve FFmpeg native error text only as bounded diagnostic detail.

Do not expose credentials or complete signed URLs in errors.

Do not reuse arbitrary libav negative values as the long-term public app error code.

## 13. ArkTS wrapper

The module's ArkTS layer should convert the native result into strongly typed data.

Do not return `Object` bags throughout application code.

Prefer explicit classes/interfaces for:

- format;
- video stream;
- audio stream;
- subtitle stream;
- chapter;
- probe result;
- frame result;
- error.

It is acceptable for Phase 1 types to be module-local.

Do not modify the public `IMediaProbe` contract in this phase.

## 14. MediaInfo adapter

Add a pure ArkTS mapper:

```text
NativeProbeResult -> linkora_core.MediaInfo
```

Unit-test the mapper without native runtime.

Also produce `ProbeFieldOrigin` values with engine = `ffmpeg` when used in smoke/adaptor code.

Do not yet make FFmpeg the production default probe.

## 15. RawThumbnail adapter

Add a module-local implementation of `RawThumbnail` backed by the native RGBA result.

Requirements:

- width/height/pixel format;
- `readPixels()`;
- idempotent `release()`;
- no double free;
- after release, reads must fail predictably.

Do not encode WebP here.

## 16. x86_64 simulator smoke

After native module integration, run on the simulator.

Required cases:

### Local path

Use an app-accessible copied test fixture, not a security bypass.

Probe:

- H.264/AAC MP4;
- HEVC/MKV if decoder is present in the bootstrap.

Validate expected container/tracks/duration/resolution.

### MediaProxy

Use existing WebDAV fixture:

```text
WebDAV
-> RandomAccessSource
-> MediaProxy
-> localhost URL
-> FFmpeg probe
```

Required:

- MKV metadata probe;
- at least one thumbnail frame extraction;
- seek does not require downloading the full file sequentially.

### Error/cancel

- invalid input;
- corrupt media;
- stalled localhost response -> timeout;
- cancellation while request is active.

## 17. arm64 build gate

Even without a real device, build the module into the default arm64 product.

Confirm:

- `liblinkora_ffmpeg.so` is AArch64;
- all linked FFmpeg archives are AArch64;
- default Debug HAP builds;
- default Release HAP builds;
- existing MPV/native protocol libraries are unchanged.

Runtime arm64 FFmpeg smoke remains device-required if no real device is connected.

## 18. Tests

Add deterministic tests for:

- native result -> MediaInfo mapping;
- HDR mapping;
- subtitle type mapping;
- bounded metadata;
- raw frame size validation;
- aspect-fit math;
- released frame behavior;
- timeout/cancel state machine where mockable.

Do not delete or weaken existing tests.

Final expected Hypium count must be >= current 149.

## 19. Verification order

Every code fix:

1. run targeted test;
2. run simulator parity guard;
3. run full `scripts/verify.ps1`;
4. rebuild FFmpeg bootstrap if build scripts changed;
5. run simulator module build;
6. install simulator HAP;
7. run FFmpeg smoke;
8. rebuild default arm64 Debug/Release.

Record red-before/green-after when fixing an actual defect.

## 20. Evidence

Create:

`docs/FFMPEG_PHASE1_REPORT.md`

Record:

- branch SHA;
- FFmpeg source commit;
- SDK/toolchain;
- x86 module SHA256 / ELF machine;
- arm64 module SHA256 / ELF machine;
- build matrix;
- tests;
- local probe output;
- MediaProxy probe output;
- frame dimensions/bytes;
- cancellation/timeout evidence;
- all fixes/commit SHAs;
- remaining blockers.

Do not commit:

- HAP binaries;
- generated FFmpeg archives/headers;
- credentials;
- raw authorization headers.

## 21. Explicitly out of scope

Do not implement yet:

- FFmpeg as production default probe;
- System/FFmpeg merger;
- ProbePolicy tuning;
- ThumbnailPolicy benchmark routing;
- AVIOContext direct callbacks;
- hardware FFmpeg decode;
- FFmpeg playback backend;
- MPV changes;
- Auto backend tuning;
- direct SMB/SFTP/NFS/FTP into FFmpeg;
- HDR output decisions.

## 22. Stop conditions

Stop and return for architecture review when any is true:

1. x86 `liblinkora_ffmpeg.so` builds and simulator smoke passes;
2. arm64 `liblinkora_ffmpeg.so` builds;
3. MediaProxy FFmpeg probe/frame smoke passes;
4. FFmpeg/HarmonyOS needs a source patch;
5. NAPI async/cancel semantics require a public contract change;
6. local document URI access requires redesign;
7. module integration exposes LGPL packaging/relinking implications that require a distribution decision;
8. a core public contract would need modification.

Do not continue into policy integration without review.
