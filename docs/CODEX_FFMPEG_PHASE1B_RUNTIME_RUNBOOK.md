# Codex FFmpeg Phase 1B Runtime Validation Runbook

> Branch: `test/ffmpeg-media-analysis-phase1b-runtime`  
> Base: `feat/ffmpeg-media-analysis-phase1`  
> Purpose: finish the runtime half of FFmpeg Phase 1 on the x86_64 emulator.  
> Do not merge.

## 1. Architecture review result

Phase 1A is accepted for build/unit quality.

Accepted:

- dedicated `linkora_ffmpeg` module;
- pinned FFmpeg 8.1.3 static linkage;
- arm64-v8a Debug/Release native link;
- arm64 default HAP Debug/Release build;
- async NAPI work model;
- request isolation;
- AVIOInterruptCB deadline/cancel state;
- bounded metadata/result allocation;
- raw RGBA frame ownership;
- pure `NativeProbeResult -> MediaInfo` mapping;
- 164/164 Hypium at the Phase 1A tested SHA;
- no production Auto/System/MPV/NetworkMediaLoader policy wiring.

Phase 1A stopped too early because the old §22 stop condition fired after the arm64 link succeeded.

**Do not stop merely because x86 native link succeeds.**

This phase stops only after the runtime matrix below has been attempted and documented, or a real architecture blocker is reached.

## 2. Existing review fix

This branch already contains a small review correction:

- preserve Dolby Vision profile string `"0"` when explicit DOVI configuration exists with profile 0;
- corresponding deterministic test.

Run the test first and retain red/green evidence only if you intentionally reproduce the pre-fix parent behavior.

## 3. Scope

Allowed:

- x86_64 `linkora_ffmpeg` build and packaging;
- simulator HAP build/sign/install;
- actual import of `linkora_ffmpeg/Native`;
- actual NAPI initialization;
- actual `probe()`;
- actual `extractFrame()`;
- actual `cancel()`;
- actual native timeout;
- simulator-only diagnostic/smoke harness;
- local fixture copy into app-accessible native path;
- existing WebDAV -> RandomAccessSource -> MediaProxy -> FFmpeg smoke;
- simulator-only fake/stalling RandomAccessSource for deterministic timeout/cancel.

Still forbidden:

- production probe routing;
- changing `NetworkMediaLoader` to use FFmpeg;
- changing System metadata/thumbnail policy;
- changing `IMediaProbe`;
- changing `IThumbnailExtractor`;
- Auto/PlaybackBackendSelector changes;
- MPV changes;
- AVIOContext direct storage callbacks;
- FFmpeg playback;
- hardware decode.

## 4. Smoke harness boundary

Prefer a simulator-only harness under `entry/src/simulator`.

It must not add a production-visible diagnostic button.

Acceptable mechanisms include:

- simulator-only launch-parameter hook;
- simulator-only diagnostic runner;
- simulator-only test page not packaged into default;
- another target-only mechanism that leaves default behavior untouched.

If a common-source hook is unavoidable, it must delegate to:

```text
entry/RuntimeDiagnostics
```

with:

- `src/default/RuntimeDiagnostics.ets` = no-op;
- `src/simulator/RuntimeDiagnostics.ets` = smoke implementation.

Do not add CPU-ABI conditionals into shared business code.

Add a static guard proving the runtime smoke harness is absent from the default target path.

## 5. Runtime evidence transport

Do not rely on reading private app storage from HDC.

Emit bounded sanitized lines to hilog, for example:

```text
LINKORA_FFMPEG_SMOKE:{...}
```

Never include:

- credentials;
- Authorization;
- Cookie;
- complete signed URL;
- MediaProxy token;
- upstream path.

The smoke JSON should use case names and numeric/codec/container results only.

Keep each emitted record reasonably small.

## 6. Build gate

Run in this order:

1. `ohpm install`
2. project Sync
3. `node scripts/check-simulator-product.cjs`
4. targeted FFmpeg pure tests
5. full `./scripts/verify.ps1`
6. `./scripts/verify-simulator.ps1`

Required simulator artifact:

- exactly one `liblinkora_ffmpeg.so`;
- ELF64;
- machine X86-64;
- no real libmpv;
- no production SMB/SFTP/FTP/NFS .so;
- no unknown .so.

Record SHA256 of packaged `liblinkora_ffmpeg.so`.

## 7. Install and real native import

Sign/install the simulator HAP using the same safe temporary signing procedure from the accepted simulator validation.

Then perform a smoke that executes:

```ts
import { createFfmpegAnalysis } from 'linkora_ffmpeg/Native'
```

and creates a real `FfmpegAnalysis`.

This must prove:

- NAPI module registration succeeds;
- `liblinkora_ffmpeg.so` is loadable;
- the native object exports `probe`, `extractFrame`, `cancel`.

If this import/initialization fails, stop after recording the exact loader/NAPI error.

## 8. Local fixture smoke

Use an app-accessible native regular file.

Do not bypass platform sandbox rules.

Preferred flow:

1. bundle or download a small test fixture through a simulator-only test mechanism;
2. copy it using ArkTS into `context.filesDir`;
3. pass the resulting absolute native path to FFmpeg.

Required fixture A:

- MP4;
- H.264 video;
- AAC audio;
- known duration/resolution.

Validate from real native result:

- container contains mov/mp4 family;
- duration tolerance reasonable;
- one H.264 video stream;
- one AAC audio stream;
- expected dimensions;
- sample rate/channels when known;
- nonzero file size when FFmpeg reports it.

Required fixture B if available:

- MKV;
- HEVC or H.264;
- optional subtitle track.

A simulator decoder limitation is not expected here because FFmpeg uses software decoders from the static build. If the required decoder was compiled out, report it as a bootstrap configuration defect.

## 9. Local frame extraction

On fixture A:

- request a nonzero timestamp;
- max 480x270;
- call real native `extractFrame`.

Validate:

- width > 0;
- height > 0;
- width <= 480;
- height <= 270;
- aspect ratio is consistent;
- no upscale for a smaller source;
- pixel format = `rgba_8888`;
- `pixels.byteLength === width * height * 4`;
- frame timestamp is sensible;
- construct real `FfmpegRawThumbnail`;
- `readPixels()` returns a copy;
- double release is safe;
- post-release read rejects.

Optional but useful:

- compute a hash of pixel bytes;
- do not commit raw uncompressed frames.

## 10. Real MediaProxy probe

Use the actual shared production path:

```text
WebDAV
-> NetworkDirectoryService
-> RandomAccessSource
-> shared NetworkFileProxy
-> 127.0.0.1 token URL
-> linkora_ffmpeg native probe
```

Use an existing test-lab fixture with no credentials committed.

Required:

- metadata probe succeeds;
- container/tracks are plausible;
- proxy URL itself is never logged;
- upstream Range ledger shows bounded/random access rather than forced whole-file sequential download when the source/format permits seek.

Do not change the production provider or MediaProxy implementation to make this test pass.

## 11. Real MediaProxy frame extraction

Using the same remote source:

- request a frame at a nonzero timestamp;
- fit <= 480x270;
- validate RGBA byte count;
- release all resources.

Record:

- FFmpeg request duration;
- proxy bytes/read request delta if available;
- target timestamp;
- actual frame timestamp/dimensions.

Do not benchmark System vs FFmpeg yet.

## 12. Deterministic timeout through MediaProxy

Create a simulator-only `RandomAccessSource` whose read operation intentionally stalls longer than the native timeout.

Expose it through the real `NetworkFileProxy`.

Call native FFmpeg with a short but nonzero timeout.

Required real result:

```text
FF_TIMEOUT
```

Confirm:

- Promise rejects;
- operation does not hang indefinitely;
- MediaProxy lease/source is released;
- subsequent independent FFmpeg request still succeeds.

This proves `AVIOInterruptCB` reaches real blocking FFmpeg I/O.

## 13. Deterministic active cancellation

Create another stalling or slow simulator-only `RandomAccessSource`.

Start native probe/extract with a long timeout.

After the operation is actively blocked, call:

```ts
analysis.cancel(requestId)
```

Required:

- Promise rejects with `FF_CANCELLED`;
- cancel does not affect a different request ID;
- a second concurrent/serial request can complete;
- no crash/use-after-free;
- cleanup completes.

Run at least 10 cancel cycles.

## 14. Corrupt and invalid inputs

Real native calls:

- invalid scheme;
- malformed localhost URL;
- embedded userinfo attempt;
- CR/LF/NUL rejection where representable;
- nonexistent local file;
- corrupt regular file.

Validate stable error categories.

No full locator should appear in error detail or hilog.

## 15. Concurrency

Run at least:

- two independent probes simultaneously;
- probe + extract simultaneously;
- cancel one while the other completes.

Confirm independent IDs and no cross-cancellation.

Do not exceed the existing active job cap merely for stress.

## 16. Lifecycle

Repeat at least 20 times:

```text
create analysis
-> probe or frame
-> release wrapper / close
```

Also test:

- app background/foreground during one completed request sequence;
- force-stop/relaunch and rerun smoke.

Watch for:

- crash;
- native loader failure;
- Promise never settling;
- unbounded thread growth;
- stale request collision.

No claim of leak-free operation without measurement.

## 17. Arm64 regression

No arm64 device is required for this 1B phase if unavailable.

But after any shared/native code fix:

- rerun full `scripts/verify.ps1`;
- confirm default Debug/Release HAP;
- confirm packaged `liblinkora_ffmpeg.so` remains AArch64.

Do not claim arm64 runtime.

## 18. Production isolation

Final diff must still show no behavior change in:

- `NetworkMediaLoader`;
- `NetworkMediaProbe`;
- System probe/extractor routing;
- PlaybackBackendSelector;
- AdaptivePlaybackPort;
- MpvPlaybackPort;
- protocol transports.

Simulator-only smoke harness is acceptable.

## 19. Report

Fill:

`docs/FFMPEG_PHASE1B_RUNTIME_REPORT.md`

Statuses:

- PASS
- FAIL
- NOT RUN
- BLOCKED

Do not convert indirect evidence into PASS.

## 20. Completion gate

Do **not** stop just because a build succeeds.

Stop for architecture review after all achievable items below have been attempted:

- x86 module link;
- simulator HAP package;
- install/launch;
- real NAPI import;
- local MP4 probe;
- local frame extract;
- MediaProxy remote probe;
- MediaProxy remote frame extract;
- real timeout;
- real active cancel;
- corrupt/invalid input;
- concurrency;
- 20 lifecycle cycles;
- final full default regression.

If an earlier item exposes a true architecture blocker, document it and stop.

Do not proceed to production probe-policy integration.
