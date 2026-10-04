# Linkora Player Architecture — Implementation Status

## CURRENT EXECUTION SUMMARY — 2026-10-05

Project-wide technical baseline: `docs/MASTER_IMPLEMENTATION_PLAN.md`.

Operational GPT/Codex workflow: `docs/AI_WORKFLOW.md`.

Current branch: `feat/ffmpeg-analyzer-policy-phase3`.

Phase 3 production analyzer policy is implemented in source but is **not yet accepted**.

Current implementation source remains:

`15db3f8a3e87f75edc209c1919f944f39c0b9fcb`

Validation history:

- source `72e74d11a790bd0d258e219e3a8de18f3c59fd17`: stopped at an over-scoped ArkUI static checker; reviewed/fixed.
- source `81ed0684b273e25afbed056a055ee23aded0b661`: ArkUI gate passed, then desktop Loader harness stopped on unresolved target alias; reviewed/fixed.
- source `15db3f8a3e87f75edc209c1919f944f39c0b9fcb`: isolated validation setup succeeded; `ohpm install` then rewrote four lockfiles LF→CRLF only. Evidence commit `59d626bc647dfe257a60c34feb9f9e02ad9e9165` proves normalized blobs/content unchanged. No default verifier/runtime gate ran.

The LF→CRLF stop is classified as **non-semantic validation-environment drift**. The durable workflow now permits Codex to self-recover from this exact class only after strict normalized-blob/content verification and only inside an isolated validation checkout.

Current Phase 3 invariants remain unchanged:

- LIST = System primary with controlled FFmpeg fallback for resolvable file-like inputs;
- DETAIL / ADVANCED = FFmpeg primary, System fallback only when FFmpeg is unusable;
- no field merger in Phase 3;
- remote thumbnail = FFmpeg primary + existing System fallback;
- HLS / DASH / LOCAL_DOCUMENT = System-only;
- WebP/cache/time policy unchanged;
- PlaybackBackendSelector and Auto/System/MPV policy unchanged;
- performance ranking remains deferred to real arm64 hardware.

A fresh Codex validation round must use the current `docs/CODEX_VALIDATION_TASK.md`. Old partial results cannot be spliced into a new PASS.


This file is the current execution status for the architecture migration.

## Completed in code

### Phase 0 — Repository audit

Completed.

Artifacts:

- ARCHITECTURE_CURRENT.md
- ARCHITECTURE_TARGET.md
- ARCHITECTURE_MIGRATION.md
- MIGRATION_CALLSITES.md

### Phase 1 — Contracts and adapters

Completed in code.

Includes:

- MediaInfo / track models
- StorageProvider
- RandomAccessSource
- IMediaProbe contracts
- thumbnail contracts
- playback backend contracts
- MediaSource remote identity fields

### Phase 2 — Storage provider productionization

Completed in code.

Production directory access now resolves through provider registry.

Adapters exist for:

- WebDAV
- SMB
- SFTP
- FTP
- NFS

Existing protocol implementations are reused.

### Phase 3 — System analysis split

Completed in code.

Separated:

- SystemMediaProbe
- SystemThumbnailExtractor

NetworkMediaProbe remains a compatibility facade and preserves one-extractor behavior for BOTH mode.

### Phase 4 — WebP thumbnail pipeline

Completed in code.

Current target policy:

- short video: 20%
- normal video: min(10%, 60 seconds)
- 480 x 270 bounding box
- preserve aspect ratio
- WebP quality 80
- algorithmVersion in cache identity
- no new JPEG generation

### Phase 5 — shared MediaProxy

Completed in code.

Includes:

- RandomAccessSource-first registration
- shared production proxy
- Range transport
- diagnostics
- bytes-read and request counters

### Phase 6 — dual playback foundation

Completed in code and build-verified on the validation branch. Device runtime is still not verified.

Includes:

- @mpv-ohos/mpv-arkts 1.0.0 dependency
- MpvPlaybackPort
- SystemPlaybackPort as PlaybackBackend
- AdaptivePlaybackPort
- Auto/System/MPV preference
- remote playback through RandomAccessSource -> MediaProxy
- network browser creates REMOTE_FILE MediaSource
- progressive-download path retained only for compatibility

### Phase 7 — playback contract enrichment

Completed in code and build/unit-regression verified. Device runtime is still not verified.

Includes:

- SEEKING
- seek complete
- surface size
- tracks
- video color/HDR metadata
- backend identity
- buffered duration

## Blocked / not complete

### FFmpeg media analysis

NATIVE RUNTIME VERIFIED; PHASE-2 ANALYZER ADAPTER/COMPARISON INTEGRATION ACTIVE.

Current repository state:

- FFmpeg 8.1.3 pinned to commit `1041abdc962f4cc4f394aa8de9dc5236c0c3b9e7`
- reproducible source fetch script
- HarmonyOS arm64-v8a bootstrap build script
- HarmonyOS x86_64 bootstrap build script
- generated source/build/prebuilt directories excluded from Git
- intended libraries: libavformat/libavcodec/libavutil/libswscale
- no CLI programs, encoders, muxers or hwaccels in the initial analyzer profile

Verified by simulator validation:

- x86_64 FFmpeg bootstrap build succeeded
- arm64-v8a FFmpeg bootstrap build succeeded
- exact build manifests/audits were captured
- no HarmonyOS FFmpeg source patch was required for bootstrap

Current required work:

- create and link dedicated `linkora_ffmpeg` native module
- run x86 simulator local/MediaProxy probe + frame smoke
- build the module for arm64-v8a
- prove cancellation/timeout/error handling
- return for review before production policy wiring

See:

- `docs/FFMPEG_BOOTSTRAP.md`
- `docs/FFMPEG_INTEGRATION_BLOCKER.md`

### Analysis benchmark: System vs FFmpeg

BLOCKED by FFmpeg analyzer.

The benchmark format and test procedure are defined in test-lab/benchmark and TEST_MANUAL.md.

### Playback benchmark: System vs MPV

READY TO RUN, but requires:

- ohpm install
- DevEco/Hvigor arm64 build
- target HarmonyOS device
- fixed media corpus

No benchmark-derived Auto policy should be merged before this test.

### Advanced AV validation

REQUIRES TARGET DEVICE.

Pending validation:

- HDR10
- HLG
- Dolby Vision profiles
- native Dolby Vision output
- DTS
- DTS-HD MA
- TrueHD
- Atmos behavior
- DTS:X behavior
- Audio Vivid
- ASS
- PGS
- hardware decode fallback
- HDMI/audio passthrough if target hardware supports it

### Direct I/O

NOT IMPLEMENTED by design.

Do not implement OH_AVDataSource / AVIOContext / libmpv stream callbacks until benchmark data proves localhost MediaProxy is a bottleneck.

## Mandatory next steps outside this environment

1. On `test/simulator-validation`, run `ohpm install` and Project Sync.
2. Run `scripts/verify.ps1` to prove default arm64 behavior still passes.
3. Run `scripts/check-simulator-product.cjs`.
4. Run `scripts/verify-simulator.ps1`.
5. Install `com.linkora.player.simulator` on the x86_64 emulator.
6. Execute `docs/SIMULATOR_TEST_MANUAL.md` and fill `docs/SIMULATOR_VALIDATION_REPORT.md`.
7. Run `scripts/ffmpeg/fetch-source.ps1`.
8. Build FFmpeg for x86_64 and arm64-v8a using `docs/FFMPEG_BOOTSTRAP.md`.
9. If both FFmpeg builds succeed, return for architecture review before wiring `FFmpegMediaProbe`.
10. After simulator evidence is reviewed, continue the arm64 device manual for real MPV/native/HDR/audio validation.
11. Collect benchmark data before tuning `PlaybackBackendSelector`.
12. Do not implement direct I/O until MediaProxy benchmark evidence justifies it.


### Phase-2 analyzer integration goals

Current branch: `feat/ffmpeg-analyzer-integration-phase2`

Validated prerequisites:

- FFmpeg 8.1.3 dual-ABI bootstrap;
- real x86 NAPI probe/frame runtime;
- WebDAV -> MediaProxy -> FFmpeg runtime;
- timeout/cancel/concurrency/lifecycle smoke;
- arm64 Debug/Release build;
- simulator/default dependency restoration hardening.

Current work:

- formal `IMediaProbe` adapters for System and FFmpeg;
- formal FFmpeg `IThumbnailExtractor` adapter;
- protocol-agnostic analysis input resolver;
- simulator functional comparison matrix with field completeness/correctness/error/cleanup and remote access-semantics diagnostics. Performance comparison is deferred to real arm64 device testing.

Production NetworkMediaLoader behavior remains unchanged until policy review.


## Performance policy for this phase

Simulator Phase 2 is functional-only.

Do not use x86 simulator data for:

- System-vs-FFmpeg speed ranking;
- median/p95 latency;
- throughput;
- CPU/GPU utilization;
- memory-efficiency ranking;
- power/thermal conclusions;
- final analyzer or playback policy.

Remote byte/range counters may only be used to verify functional random-access behavior and cleanup.

Performance benchmarking and performance-based policy decisions are deferred to real arm64 device testing.


### Phase 3 — FFmpeg analyzer production functional policy

IMPLEMENTED; FIRST TEST-ONLY RUN STOPPED AT A REVIEWED STATIC-CHECK FALSE POSITIVE. CHECKER FIXED IN CURRENT REVIEW COMMIT; FULL VALIDATION RERUN REQUIRED.

Current branch:

`feat/ffmpeg-analyzer-policy-phase3`

Implemented:

- `ProductionMediaAnalysisPolicy`;
- `PolicyMediaProbe` with non-merging one-step fallback;
- production `NetworkMediaAnalysisCoordinator`;
- FFmpeg-first remote thumbnail extraction with existing System fallback;
- raw RGBA -> existing WebP encoder bridge;
- `NetworkMediaLoader` production routing through the coordinator;
- cancellation generation guards;
- SFTP media-fingerprint/host-key semantic correction;
- policy unit tests.

Functional routing:

- LIST: System first, FFmpeg fallback for file-like sources;
- DETAIL/ADVANCED: FFmpeg first, System fallback only if FFmpeg is unusable;
- HLS/DASH/LOCAL_DOCUMENT: System-only policy;
- thumbnail: FFmpeg first for file-like remote sources, System fallback.

No field merger is implemented.
No performance-based policy is implemented.
Playback routing is unchanged.

Validation owner: Codex, report-only.
Source fixes remain owned by ChatGPT.
