# FFmpeg Phase 1B Runtime Validation Report

> Status: NOT RUN  
> Branch: `test/ffmpeg-media-analysis-phase1b-runtime`

## Git

- Base branch: `feat/ffmpeg-media-analysis-phase1`
- Starting SHA:
- Final tested source SHA:
- Final docs SHA:

## Environment

- Host:
- DevEco:
- SDK:
- Hvigor:
- ohpm:
- Emulator:
- Emulator ABI:
- Native SDK:

## Review Fix

- Dolby Vision explicit profile 0 preserved as string "0": NOT RUN
- targeted test:
- full Hypium:

## Build

| Artifact | Result | SHA256 / ABI |
| --- | --- | --- |
| linkora_ffmpeg simulator HAR | NOT RUN | |
| simulator HAP | NOT RUN | |
| packaged liblinkora_ffmpeg.so | NOT RUN | |
| default arm64 Debug HAP | NOT RUN | |
| default arm64 Release HAP | NOT RUN | |

Simulator native contents:

- liblinkora_ffmpeg.so count:
- real libmpv present:
- native protocol .so present:
- unknown .so present:

## Install / Launch

- signing:
- install:
- cold launch:
- native loader errors:

## Real NAPI Initialization

- `linkora_ffmpeg/Native` import:
- createFfmpegAnalysis:
- probe export:
- extractFrame export:
- cancel export:
- result:

## Local H264/AAC MP4 Probe

- fixture provenance:
- native path redacted:
- container:
- duration:
- size:
- video codec/profile:
- resolution:
- frame rate:
- audio codec:
- channels/layout:
- sample rate:
- result:

## Secondary MKV Probe

- codec/container:
- video:
- audio:
- subtitles:
- result:

## Local Frame Extraction

- requested timestamp:
- requested max:
- actual timestamp:
- dimensions:
- pixel format:
- bytes:
- pixel hash:
- aspect/no-upscale:
- RawThumbnail read-copy:
- double release:
- post-release read rejection:
- result:

## MediaProxy Remote Probe

- source type: WebDAV / other
- container:
- tracks:
- duration:
- proxy read request delta:
- proxy byte delta:
- upstream Range evidence:
- full sequential download avoided:
- locator/token logged:
- result:

## MediaProxy Remote Frame

- requested timestamp:
- actual timestamp:
- dimensions:
- bytes:
- proxy delta:
- release:
- result:

## Timeout

- source: simulator-only stalling RandomAccessSource -> real MediaProxy
- timeoutMs:
- actual error:
- elapsed:
- Promise settled:
- lease/source released:
- subsequent request:
- result:

## Cancellation

- active request type:
- cancel timing:
- actual error:
- unrelated request unaffected:
- cleanup:
- 10-cycle result:

## Invalid / Corrupt Inputs

| Case | Result | Error code | Leakage |
| --- | --- | --- | --- |
| invalid scheme | NOT RUN | | |
| malformed localhost | NOT RUN | | |
| embedded userinfo | NOT RUN | | |
| control characters | NOT RUN | | |
| missing local file | NOT RUN | | |
| corrupt regular file | NOT RUN | | |

## Concurrency

- two probes:
- probe + frame:
- cancel one / other completes:
- result:

## Lifecycle

- 20 create/use/close cycles:
- force-stop/relaunch:
- background/foreground:
- crashes:
- unresolved Promise:
- thread observation:
- result:

## Security

- Authorization leakage:
- Cookie leakage:
- full proxy token leakage:
- upstream path leakage:
- signed URL leakage:
- native FFmpeg logging:
- result:

## Production Isolation

- NetworkMediaLoader unchanged:
- NetworkMediaProbe routing unchanged:
- playback selector unchanged:
- MPV unchanged:
- native protocol transports unchanged:
- direct AVIO callback absent:

## Final Regression

- simulator parity:
- full verify.ps1:
- Hypium:
- default arm64 Debug:
- default arm64 Release:
- simulator final build:

## Fixes During Runtime Validation

| Commit | Red evidence | Root cause | Change | Green evidence |
| --- | --- | --- | --- | --- |

## Remaining Gaps

-

## Decision

Choose one:

- READY FOR FFMPEG ANALYZER INTEGRATION REVIEW
- BLOCKED — X86 NAPI LOAD
- BLOCKED — FFMPEG RUNTIME
- BLOCKED — MEDIAPROXY INTERACTION
- BLOCKED — CANCEL/TIMEOUT
- VALIDATION FAILED
