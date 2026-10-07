# Linkora Player Architecture — Implementation Status

## CURRENT EXECUTION SUMMARY — 2026-10-06

Project-wide technical baseline: `docs/MASTER_IMPLEMENTATION_PLAN.md`.

Operational GPT/Codex workflow: `docs/AI_WORKFLOW.md`.

Current branch: `feat/ffmpeg-analyzer-policy-phase3`.

Phase 3 implementation source:

`44d0f62816b73ebd3bab8069be5b74f51e2c6999`

Reviewed build/static evidence:

`e95feef35fa2541322216f9ce9336da3cad9060f`

Reviewed Mate60 runtime evidence:

`bf99989fff7cbcf17e2410e5df5258a586f12e6f`

### Acceptance status

**FFmpeg Analyzer Production Policy Phase 3: ACCEPTED.**

Build/static/pure acceptance:

- default -> simulator -> immediate-default PASS;
- ArkTS compilation PASS;
- Hypium 209/209 PASS twice;
- Debug/Release HAR/HAP and exact-nine AArch64 audits PASS;
- Loader/cache/lifecycle and policy pure suites PASS.

Production runtime acceptance on Mate60:

- exact-source signed default/debug arm64 HAP provenance established;
- app-side authenticated WebDAV preflight PASS;
- H.264/AAC MP4 cold + reopen PASS;
- HEVC/AAC MKV cold + reopen PASS;
- FFmpeg-first remote WebP thumbnail generation PASS;
- corrupt/both-thumbnail-unavailable behavior PASS;
- observed cancellation/refresh/stale-generation behavior PASS within naturally exercisable scope;
- production lifecycle 20/20 PASS;
- no observed crash/ANR or accumulating stale rows;
- direct proxy counters NOT RUN because no production diagnostic endpoint exists, as allowed by the reviewed contract;
- natural FFmpeg->System successful fallback NOT RUN because no safe natural fixture exists;
- HLS/DASH target smoke NOT RUN because no prepared streaming fixture exists; their System-only policy remains covered by fresh 3g pure evidence.

### R10 local-document ruling

The Mate60 run proved DocumentViewPicker import, 20 s / 720P metadata, 1280x720 playback and completion.

The list thumbnail remained a placeholder because `LocalMediaThumbnailLoader` only resolves `PhotoAsset` thumbnails and has no DocumentViewPicker frame-extraction fallback.

Independent review confirmed that loader is byte-identical from at least `15db3f8a3e87f75edc209c1919f944f39c0b9fcb` through the accepted Phase 3 implementation and current evidence.

Therefore the placeholder is a **pre-existing document-thumbnail limitation, not a Phase 3 regression**. R10 is accepted for Phase 3 because local import/metadata/playback remain functional, LOCAL_DOCUMENT stays System-only, and no content-URI/native-path workaround was introduced.

No production source change or rerun is required for this ruling.

### Current architecture action

**Phase 8A playback functional foundation: ACCEPTED. Fullscreen/player-layout refinement is non-blocking UI follow-up.**

Phase 7A Analysis Benchmark baseline is ACCEPTED.

This stage adds measurement infrastructure only:

- target-side debug benchmark runner using the accepted System/FFmpeg adapters;
- real MediaProxy HTTP Range counting;
- adapter prepare/probe timing;
- NDJSON schema and summary tooling;
- stable Phase 7 benchmark manual.

`ProductionMediaAnalysisPolicy` remains unchanged until benchmark evidence is reviewed.

The first validation attempt exposed a desktop pure-harness/platform-clock boundary defect. GPT corrected it by injecting the clock into the adapters and supplying the real monotonic HarmonyOS clock from target-specific AnalysisComposition.

The corrected rerun passed the full build chain and collected 240 real-Mate60 WebDAV records. GPT independently accepted the baseline at evidence commit `92017b8fd95cb944c03a30c2eb909cd8ad70dff5`.

The baseline shows meaningful System-vs-FFmpeg differences, especially thumbnail latency/upstream bytes, but only for H.264/AAC MP4 and HEVC/AAC MKV. Production analysis routing remains unchanged because two cases are insufficient for a global policy rewrite.

Broader codec/container/audio coverage will not reopen the accepted Analysis phase. It is now part of the shared Media Capability Corpus and will be exercised during Playback/Advanced AV validation with Analyzer and Playback results recorded independently.

Phase 8A first validates that the current real-arm64 playback foundation itself is trustworthy: System/MPV forced modes, Auto selection/fallback boundary, surface lifecycle, remote MediaProxy playback, seek/EOF/release, and bounded negative behavior. The first device run exposed MPV unified-state/EOF/surface-unit defects; GPT corrected them. Rerun 1 then passed P01-P05, System/MKV observation, corrupt-MPV recovery, 20/20 MPV lifecycle and background/foreground on the real Mate60. That run also exposed a PlayerPage fullscreen overflow, which is retained as a real but non-blocking UI/layout issue. Phase 8A is accepted on playback-function evidence. The next mainline step is Phase 8B media capability coverage using the shared Tier A/B/C corpus.


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

**ACCEPTED THROUGH PHASE 3 PRODUCTION FUNCTIONAL POLICY.**

Accepted implementation includes:

- FFmpeg 8.1.3 pinned to commit `1041abdc962f4cc4f394aa8de9dc5236c0c3b9e7`;
- native `linkora_ffmpeg` module;
- System and FFmpeg probe adapters;
- FFmpeg thumbnail extraction;
- protocol-agnostic analysis input resolver;
- shared MediaProxy remote input;
- production LIST / DETAIL / ADVANCED routing policy;
- FFmpeg-first remote thumbnail policy with System fallback;
- common WebP encoding/cache path;
- cancellation and lifecycle handling;
- SFTP trust-ownership correction;
- real Mate60 remote MP4/MKV runtime acceptance.

Latest reviewed runtime evidence:

`bf99989fff7cbcf17e2410e5df5258a586f12e6f`

Known non-blocking limitation:

- DocumentViewPicker local-document list thumbnail may remain a placeholder because the pre-existing local thumbnail loader only resolves PhotoAsset-backed URIs.

This limitation is outside the Phase 3 remote analyzer production-policy scope and must not be misreported as an FFmpeg analyzer regression.

### Analysis benchmark: System vs FFmpeg

**NEXT ANALYZER PHASE — READY TO PLAN ON REAL ARM64 HARDWARE.**

Phase 3 production functional policy is accepted. Performance-based routing remains intentionally deferred.

The benchmark format and test procedure are defined in `test-lab/benchmark` and `TEST_MANUAL.md`. Before execution, GPT must review the current benchmark assets against the accepted Phase 3 architecture and dispatch a dedicated benchmark task.

Do not derive final routing policy from x86/simulator data.

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

**ACCEPTED — BUILD/STATIC/PURE + MATE60 PRODUCTION RUNTIME.**

Reviewed evidence:

- build/static/pure: `e95feef35fa2541322216f9ce9336da3cad9060f`;
- Mate60 runtime: `bf99989fff7cbcf17e2410e5df5258a586f12e6f`.

No Phase 3 rerun is pending.

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
