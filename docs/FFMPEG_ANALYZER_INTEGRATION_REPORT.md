# FFmpeg Analyzer Integration Phase 2 Report

> Status: NOT RUN  
> Branch: `feat/ffmpeg-analyzer-integration-phase2`

## Git / Environment

- Starting SHA:
- Final tested source SHA:
- Final docs SHA:
- Host:
- DevEco / SDK:
- Emulator:
- arm64 device:

## Build Isolation Baseline

- simulator -> default automatic restore:
- exact 9-library arm64 guard:
- unexpected arm64 native rejection:
- Hypium baseline:

## Architecture

- MediaAnalysisInputResolver:
- FfmpegMediaProbeAdapter:
- SystemMediaProbeAdapter:
- FfmpegThumbnailExtractorAdapter:
- production NetworkMediaLoader unchanged:
- playback policy unchanged:

## Resolver Matrix

| Source | System | FFmpeg | Input kind | Cleanup |
| --- | --- | --- | --- | --- |
| REMOTE_FILE | NOT RUN | NOT RUN | | |
| HTTP MP4/MKV | NOT RUN | NOT RUN | | |
| HLS | NOT RUN | expected System-only | | |
| DASH | NOT RUN | expected System-only | | |
| LOCAL_DOCUMENT | NOT RUN | expected unsupported unless safely resolved | | |

## Unit / Deterministic Tests

- Hypium:
- resolver:
- completeness:
- provenance:
- error mapping:
- comparison classification:
- thumbnail lifecycle:
- diagnostics redaction:
- artifact guard:

## Simulator Runtime

- HAP build:
- install:
- launch:
- x86 FFmpeg artifact:
- System adapter actual runtime:
- FFmpeg adapter actual runtime:
- FFmpeg thumbnail adapter:
- activeSources final:

## Comparison Matrix

| Fixture | System result | FFmpeg result | Key functional differences | Remote access semantics |
| --- | --- | --- | --- | --- |
| H264/AAC MP4 | NOT RUN | NOT RUN | | |
| HEVC/AAC MKV | NOT RUN | NOT RUN | | |
| HEVC Main10 | NOT RUN | NOT RUN | | |
| HDR10 | NOT RUN | NOT RUN | | |
| HLG | NOT RUN | NOT RUN | | |
| Multi-audio | NOT RUN | NOT RUN | | |
| Text subtitle | NOT RUN | NOT RUN | | |
| Bitmap subtitle | NOT RUN | NOT RUN | | |
| Long GOP | NOT RUN | NOT RUN | | |
| WebDAV remote | NOT RUN | NOT RUN | | |

## FFmpeg Correctness vs Fixture Truth

- container:
- duration:
- codec/profile:
- dimensions/fps:
- bit depth:
- HDR metadata:
- track counts:
- language/title:
- subtitle kind:

## Completeness

- System LIST:
- System DETAIL:
- System ADVANCED:
- FFmpeg LIST:
- FFmpeg DETAIL:
- FFmpeg ADVANCED:

## Thumbnail

- System extraction:
- FFmpeg extraction:
- same requested timestamp:
- bounds/aspect:
- FFmpeg raw release:
- common WebP encoder diagnostic:
- production cache unchanged:

## Cancellation / Cleanup

- System cancel:
- FFmpeg cancel:
- resolver error cleanup:
- adapter close:
- proxy activeSources=0:
- leak claim: NOT CLAIMED unless measured

## Security

- URL/token leakage:
- credentials:
- diagnostics notes:
- hilog scan:

## Arm64 Regression

- verify.ps1:
- Hypium:
- Debug HAP:
- Release HAP:
- native count:
- exact expected set:

## Production Isolation

- NetworkMediaLoader unchanged:
- NetworkMediaCache semantics unchanged:
- PlaybackBackendSelector unchanged:
- AdaptivePlaybackPort unchanged:
- MpvPlaybackPort unchanged:
- no AVIO direct callback:
- no production analyzer switch:

## Findings

-

## Functional Recommendation for Next Policy Review

- System functional role:
- FFmpeg functional role:
- merger needed:
- thumbnail functional role:
- unresolved semantic conflicts:
- performance decision: DEFERRED TO ARM64 REAL DEVICE
- device evidence still required:

## Performance Scope

- simulator timing comparison performed: NO
- median/p95 collected: NO
- System-vs-FFmpeg speed ranking: NOT CLAIMED
- CPU/GPU/power/thermal comparison: NOT RUN
- performance benchmark target: ARM64 REAL DEVICE

## Decision

Choose one:

- READY FOR ANALYZER POLICY REVIEW
- BLOCKED — INPUT RESOLVER
- BLOCKED — ADAPTER CONTRACT
- BLOCKED — SYSTEM/FFMPEG SEMANTIC CONFLICT
- BLOCKED — MEDIAPROXY
- VALIDATION FAILED

## Execution ledger
Starting SHA c5429529094d0a8b6c0fbf34e3d22f81b50a41a0, clean isolated branch. Latest runbook fully read. Implementation plan follows authorized existing architecture; pure adapter tests written first and missing resolver implementation RED retained. No performance data/production policy changes. Resolver/probe/thumbnail/comparison → real platform/simulator functional matrix → complete default regression → one independent review/report/commit/stop.

First full verify attempt: ArkTS compiler rejected enum-valued object literal in AnalysisOperation and arbitrary-object throw in FfmpegThumbnailExtractorAdapter. Root causes were integration source syntax incompatible with strict ArkTS. Minimal correction: explicit switch mapping and typed AnalysisError rethrow. Full verify retry phase2-typed-default completed successfully: all HAR/HAP builds and exact 9-library AArch64 audits. Adapter pure tests 23/23 PASS. Simulator matrix remains NOT RUN until real execution below.
Simulator compile attempt found actual RawThumbnail contract uses width()/height()/pixelFormat() methods, and proxy registration requires explicit contentType. Corrected integration callers only; existing contracts and implementations preserved. verify-simulator failure path automatically restored normal dependencies.
Runtime run1: 38/39 cases passed, activeSources=0. System corrupt input returned all-zero snapshot with numeric errorCode=0. Independent adapter unit reproduced 0 != SYSTEM_FAILED(22001) RED. Adapter now rejects entirely unusable System metadata with stable 22001; System stage unchanged. Pure retry 30/30 PASS. Full matrix retry pending. Added cleanup assertion inside System thumbnail finally, including unavailable result path.
Final independent review: no Critical, one Important (cancelled pending rejection lost CANCELLED identity), one Minor (stream-count comparison regression assertion could be more explicit). Review fix pass added eight deterministic cases and watched all eight fail. Also reproduced cancelled success during delayed lease release (three of eight) and graded this Important because close must suppress late results until cleanup finishes. Fixed operation-aware error mapping and post-cleanup cancellation checks; thumbnail discards/releases late raw output. Pure suite 38/38 GREEN. Delayed-release tests prove close stays pending and rejects new work until cleanup finishes. Minor stream-count assertion expansion deferred; implementation is correct and functional comparison records independently confirm unknown System counts versus FFmpeg enumerated counts. Full simulator/default rerun pending for fix source.
Ruling: LOCAL_DOCUMENT adapters remain unsupported — no existing safely resolved native path — cost: local-document integration requires a later reviewed resolver change. Ruling: PGS fixture NOT RUN — no owned bitmap source and host has no PGS encoder — cost: bitmap runtime coverage remains open. Ruling: production analyzer merger/policy and arm64 output/performance are deferred — explicit user/runbook scope — cost: production choice awaits device evidence and architecture review. Accepted bootstrap/native internals remain untouched.
Reviewed simulator retry: 39/39 runtime cases and 352/352 independent functional checks PASS, owned source/temporary server/helper cleaned. Reviewed full default verifier then rejected new multi-engine unit tests at lines98/123 for ArkTS structural typing (inferred conditional concrete classes). Minimal test-only fix: explicitly declare IMediaProbe on the two conditional probe variables; production source unchanged. Full default retry pending, stale prior test_result is not counted for this failed attempt.
