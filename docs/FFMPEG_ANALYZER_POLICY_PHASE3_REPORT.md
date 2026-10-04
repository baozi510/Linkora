# FFmpeg Analyzer Production Policy Phase 3 Report

> Status: NOT RUN  
> Branch: `feat/ffmpeg-analyzer-policy-phase3`  
> Codex role: test/report only; no source fixes.

## Git / Environment

- Starting SHA:
- Tested source SHA:
- Report SHA:
- Host:
- DevEco / SDK:
- Hvigor / ohpm:
- Emulator:
- arm64 device:

## Build Gates

- initial `ohpm install`:
- first `verify.ps1`:
- Hypium:
- default Debug HAP:
- default Release HAP:
- exact 9 AArch64 libraries:
- `verify-simulator.ps1`:
- immediate post-simulator `verify.ps1` without manual restore:

## Policy Unit Semantics

| Case | Result | Evidence |
| --- | --- | --- |
| LIST System complete stops FFmpeg | NOT RUN | |
| LIST System partial -> FFmpeg | NOT RUN | |
| DETAIL FFmpeg unavailable -> System | NOT RUN | |
| DETAIL usable FFmpeg partial retained | NOT RUN | |
| no field merger | NOT RUN | |
| cancel prevents fallback start | NOT RUN | |
| local/System-only policy | NOT RUN | |
| HLS/DASH System-only policy | NOT RUN | |

## WebDAV MP4 Production Loader

- directory/list:
- metadata:
- thumbnail:
- metadataEngine:
- thumbnailEngine:
- new cache extension:
- reopen cache:
- activeSources after:
- result:

## WebDAV HEVC/MKV Production Loader

- directory/list:
- metadata:
- thumbnail:
- metadataEngine:
- thumbnailEngine:
- cache:
- activeSources after:
- result:

## FFmpeg Thumbnail -> System Fallback

- fixture/condition:
- FFmpeg failure observed:
- System fallback observed:
- WebP persisted:
- thumbnailEngine:
- cleanup:
- result:

## Both Thumbnail Engines Unavailable

- fixture:
- list remains usable:
- metadata retained:
- invalid thumbnail absent:
- cleanup:
- result:

## Cache Compatibility

- existing WebP read:
- legacy JPEG read:
- new JPEG generated:
- new WebP generated:
- cache key unchanged:
- result:

## Cancellation / Refresh

- navigate-away cancellation:
- refresh cancellation:
- stale metadata:
- stale thumbnail:
- fallback-after-cancel:
- activeSources final:
- result:

## 20-cycle Loader Lifecycle

- cycles:
- crash/ANR:
- duplicate rows:
- proxy source growth:
- cache decode:
- result:

## HTTP File-like

- production consumer applicable:
- resolver proxy:
- FFmpeg functional result:
- credential/native-boundary safety:
- result:

## HLS / DASH

- FFmpeg attempted:
- System path unchanged:
- result:

## LOCAL_DOCUMENT

- existing local flow:
- FFmpeg attempted:
- content URI workaround present:
- result:

## DETAIL / ADVANCED Contract

- FFmpeg complete:
- FFmpeg usable partial:
- FFmpeg unavailable fallback:
- no merger:
- result:

## SFTP Semantics

- media fingerprint no longer used as host-key fingerprint:
- persisted trust configuration retained:
- optional arm64 smoke:
- result:

## Security

- Authorization leakage:
- Cookie leakage:
- password leakage:
- proxy token leakage:
- upstream locator leakage:
- new analysis log safe:
- result:

## Performance Scope

- simulator speed ranking performed: NO
- median/p95: NO
- CPU/GPU/power/thermal: NOT RUN
- performance target: arm64 real device

## Failures / Feedback

| Area | Status | Exact evidence | Source change required? |
| --- | --- | --- | --- |

## Decision

Choose one:

- READY FOR ARCHITECTURE REVIEW
- FAIL — POLICY
- FAIL — NETWORK MEDIA LOADER
- FAIL — THUMBNAIL PIPELINE
- FAIL — CANCELLATION/CLEANUP
- FAIL — BUILD
- BLOCKED — TEST ENVIRONMENT
