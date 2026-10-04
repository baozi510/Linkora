# Codex FFmpeg Analyzer Integration Phase 2 Runbook

> Branch: `feat/ffmpeg-analyzer-integration-phase2`  
> Base: `fix/simulator-default-dependency-restore`  
> Goal: integrate FFmpeg as a real media-analysis plugin and validate System/FFmpeg functional correctness and completeness without changing the current user-facing production probe/thumbnail policy.  
> Do not merge during this phase.

## 1. Accepted baseline

The following are already accepted and must not be re-litigated:

- simulator/default dependency restoration hardening;
- exact default native artifact set;
- FFmpeg 8.1.3 pinned dual-ABI bootstrap;
- `linkora_ffmpeg` native module;
- real x86 NAPI runtime;
- local MP4/MKV probe;
- raw RGBA frame extraction;
- WebDAV -> RandomAccessSource -> MediaProxy -> FFmpeg runtime;
- AVIOInterruptCB timeout/cancel;
- concurrency/lifecycle smoke;
- arm64 Debug/Release builds;
- Hypium 164/164 at the prior baseline.

The current branch additionally tightens the default native audit so an unexpected tenth arm64 `.so` is rejected.

## 2. Architecture rule

FFmpeg integration must preserve:

```text
Storage
  ↓
RandomAccessSource
  ↓
Media analysis input resolver
  ↓
shared MediaProxy
  ↓
localhost URL
  ↓
System or FFmpeg analyzer
```

Do not let `linkora_ffmpeg` know about:

- WebDAV;
- SMB;
- SFTP;
- FTP;
- NFS;
- NetworkServerStore;
- credentials;
- database;
- playback.

Do not use libmpv's private FFmpeg symbols.

## 3. Phase-2 scope

Implement:

1. a shared analysis-input resolver in `entry`;
2. `FfmpegMediaProbeAdapter implements IMediaProbe`;
3. `SystemMediaProbeAdapter implements IMediaProbe`;
4. `FfmpegThumbnailExtractorAdapter implements IThumbnailExtractor`;
5. a System-vs-FFmpeg comparison service/harness;
6. deterministic adapter/resolver/comparison tests;
7. x86 simulator comparison runs;
8. arm64 build regression.

Do **not** yet:

- replace `NetworkMediaLoader` production result with FFmpeg;
- merge System and FFmpeg fields into cache;
- change `ProbePolicy` or invent a final policy;
- make FFmpeg the default thumbnail extractor;
- change playback Auto/System/MPV;
- add AVIOContext direct callbacks;
- add FFmpeg playback.

## 4. Analysis input resolver

Create an entry-level service, suggested name:

`MediaAnalysisInputResolver`

Return a lease object containing:

- `ResolvedMediaInput`;
- stable source identity;
- release action;
- optional proxy diagnostic baseline.

Use the existing `ResolvedMediaInput` contract.

### REMOTE_FILE

Resolve through the same storage architecture:

```text
NetworkServerStore
-> NetworkDirectoryService
-> openSource()
-> RandomAccessSource
-> shared NetworkFileProxy
-> ResolvedMediaInput(PROXY_URL)
```

The resolver must be protocol-agnostic. It must not branch on SMB/WebDAV/SFTP/FTP/NFS.

### Direct HTTP/HTTPS file-style NETWORK_LINK

Do not pass arbitrary external URL/credentials directly to native FFmpeg.

For file-style HTTP/HTTPS media such as MP4/MKV/TS:

```text
HttpRemoteReadSession
-> RandomAccessSource adapter
-> MediaProxy
-> localhost URL
```

This keeps FFmpeg's native input boundary credential-free and consistent with remote storage.

### HLS / DASH

Phase 2: return unsupported for FFmpeg adapter unless the current resolver can safely proxy the complete nested-resource model.

Do not pretend proxying only the manifest is sufficient.

System may remain capable of probing these independently.

### LOCAL_DOCUMENT

Phase 2 FFmpeg adapter may return `canProbe=false` / `canExtract=false` unless there is already a safe app-accessible native path.

Do not add content-URI bypass hacks.

## 5. Lease ownership

A resolved analysis input must have idempotent release.

On:

- success;
- probe failure;
- frame failure;
- cancel;
- timeout;
- adapter close;

the lease/source must eventually release.

Do not return a bare proxy URL with no owner.

Add tests for double release and failure during resolve.

## 6. FFmpeg IMediaProbe adapter

Implement an entry-level or integration-layer adapter using:

- `createFfmpegAnalysis()`;
- `FfmpegMediaInfoMapper`;
- the analysis input resolver.

It must implement the existing `IMediaProbe` signature unchanged.

### canProbe

Return true only when this phase can resolve a supported file-like input safely.

Do not open the media in `canProbe`.

### probe

Flow:

```text
resolve input
-> create/request FFmpeg analysis
-> native probe
-> map NativeProbeResult -> MediaInfo
-> ProbeResult
-> release input
```

Use unique internal request IDs.

### completeness semantics

Use `ProbeRequirement` as actual requested completeness.

Recommended:

- LIST: COMPLETE when open/stream-info succeeds and basic duration/primary dimensions are available; otherwise PARTIAL if useful metadata exists.
- DETAIL: COMPLETE when stream enumeration succeeds; PARTIAL if usable metadata exists but expected structural fields are unavailable.
- ADVANCED: COMPLETE only when the FFmpeg result contains the full structural analysis available from this implementation; absence of optional chapters/tags by itself is not failure.

Do not make `COMPLETE` synonymous with “every field non-empty”.

### diagnostics

Populate functional diagnostics only:

- engine = `ffmpeg`;
- completion/error state;
- MediaProxy read-request / Range semantics when useful to prove random-access behavior;
- bounded notes.

Existing timing fields may remain populated if the contract already carries them, but Phase 2 must not use simulator timing as an acceptance criterion, ranking signal or policy input.

No source URL/token/credential in notes.

### errors

Map native string errors to stable numeric adapter-local codes.

Do not change the public `ProbeResult.errorCode` type.

Cancellation/timeout must not be reported as generic success with UNAVAILABLE.

## 7. System IMediaProbe adapter

Wrap the existing System analysis implementation; do not rewrite AVMetadataExtractor.

Use the same input resolver for file-like remote sources so System-vs-FFmpeg comparison measures engines over equivalent MediaProxy input.

Map System data to `MediaInfo` conservatively.

Current System stage only provides duration/resolution, so it is acceptable to create a partial primary `VideoTrackInfo` containing dimensions with unknown codec/profile.

Do not invent codec/audio/subtitle/HDR fields.

Recommended completeness:

- LIST: COMPLETE if required basic metadata is available;
- DETAIL: PARTIAL when only current System basic fields exist;
- ADVANCED: PARTIAL or UNAVAILABLE according to whether usable basic metadata exists.

Field provenance must use engine = `system`.

## 8. FFmpeg IThumbnailExtractor adapter

Implement the existing `IThumbnailExtractor` contract without changing it.

Flow:

```text
resolve input
-> native extractFrame
-> FfmpegRawThumbnail
-> release input lease
```

Requirements:

- use `ThumbnailExtractRequest.timeMs/maxWidth/maxHeight`;
- preserve current 480x270 policy inputs;
- raw RGBA only;
- no WebP encoding;
- cancel current native request correctly;
- close is idempotent.

The existing common WebP encoder remains the persistent encoder.

## 9. System thumbnail path

Do not replace the current System thumbnail production path.

For comparison, it is acceptable to invoke the existing System extractor path separately.

If you add a System `IThumbnailExtractor` adapter for symmetry, keep it a thin wrapper and do not rewrite `SystemThumbnailExtractor`.

## 10. Comparison model

Create a pure comparison result type.

At minimum capture per engine:

- success/error;
- completeness;
- media duration;
- primary width/height;
- container;
- video/audio/subtitle counts;
- primary video codec/profile/bit depth;
- HDR type;
- audio codec/channel count;
- remote access semantics where applicable: Range/random-access observed, sequential-only, or unavailable.

Do not include engine execution time, median, p95, throughput or memory/CPU ranking in Phase 2 decisions.

Capture differences without declaring one engine correct merely because it is richer.

Classify differences such as:

- MATCH;
- SYSTEM_MISSING;
- FFMPEG_MISSING;
- VALUE_DIFFERENCE;
- ENGINE_UNAVAILABLE.

Do not merge fields yet.

## 11. Comparison execution

Use a simulator-only diagnostic harness.

Do not expose a production settings toggle yet.

For each case, run engines independently with fresh analysis leases.

The purpose is functional comparison only:

- whether the engine succeeds;
- whether returned fields match fixture truth;
- which fields are missing;
- whether cancellation and cleanup work;
- whether remote access preserves Range/random-access semantics.

Repeat a case only when needed to prove determinism, lifecycle or cleanup. Do not collect simulator timing samples for performance comparison, and do not rank System vs FFmpeg by speed.

## 12. Fixture matrix

At minimum attempt:

1. H.264 + AAC MP4;
2. HEVC Main + AAC MKV;
3. HEVC Main10 sample;
4. HDR10 metadata sample;
5. HLG metadata sample;
6. multi-audio-track sample;
7. text subtitle sample such as ASS/SRT-in-container;
8. bitmap subtitle sample such as PGS if the local fixture toolchain can generate/provide one safely;
9. long-GOP sample;
10. one existing WebDAV remote file.

If a fixture cannot be generated, mark NOT RUN with reason.

Do not download copyrighted commercial samples merely to satisfy the matrix.

## 13. Metadata correctness checks

For generated fixtures, keep independent ffprobe evidence on the host as fixture truth.

Compare Linkora FFmpeg result against fixture truth for:

- container;
- duration tolerance;
- codec;
- profile;
- width/height;
- frame rate;
- bit depth;
- transfer/primaries where generated;
- track counts;
- languages/titles where set;
- subtitle kind.

System output should be judged only for fields it claims.

## 14. HDR rules

Keep current conservative mapping:

- explicit DOVI side data -> DOLBY_VISION;
- SMPTE ST 2084 -> HDR10;
- ARIB STD-B67 -> HLG;
- BT.2020 primaries alone must not imply HDR.

Do not turn metadata analysis into a device-output support claim.

## 15. Thumbnail comparison

Use the same requested timestamp and max bounds for both engines where the System API allows it.

Record:

- requested time;
- actual dimensions;
- success/failure;
- pixel format / byte-count validity;
- whether the existing shared WebP encoder can consume the extracted frame in a diagnostic path.

Do not compare extraction speed or encoded size as performance evidence in Phase 2.

Do not persist comparison thumbnails into the normal production cache unless they are produced by the unchanged production path.

## 16. No production behavior switch

At the end of Phase 2, these must still be true:

- `NetworkMediaLoader` uses its existing production System path;
- existing thumbnail cache semantics unchanged;
- user does not see FFmpeg-derived metadata because of this phase;
- playback selector unchanged;
- FFmpeg adapter is packaged/available but not automatically selected for production.

The phase produces evidence needed for the next policy decision.

## 17. Tests

Add deterministic tests for:

- analysis resolver source kinds;
- HLS/DASH unsupported decision;
- lease cleanup on success/error/cancel;
- FFmpeg adapter error mapping;
- FFmpeg completeness;
- System completeness;
- System partial MediaInfo mapping;
- provenance;
- comparison classification;
- diagnostics do not contain locator/token;
- FFmpeg thumbnail adapter lifecycle;
- exact arm64 native-set guard including unknown-extra rejection.

Hypium must be >= 164 and have zero failures.

Do not weaken existing tests.

## 18. Simulator validation

Required:

- simulator HAP build/install/launch;
- real x86 FFmpeg adapter through `IMediaProbe`;
- real System adapter through `IMediaProbe`;
- real WebDAV -> resolver -> proxy -> each adapter;
- FFmpeg thumbnail adapter;
- cancellation/close cleanup;
- comparison matrix.

Confirm active proxy sources return to zero after each case.

## 19. Arm64 regression

Run:

`./scripts/verify.ps1`

Confirm Debug and Release default HAPs contain exactly the expected 9 AArch64 native libraries.

Do not require arm64 runtime if no device exists.

## 20. Functional evidence only

Performance benchmarking is explicitly deferred to a real arm64 device.

Phase 2 must not produce or use:

- System-vs-FFmpeg speed rankings;
- median/p95 latency;
- CPU/GPU utilization comparisons;
- memory-efficiency rankings;
- throughput comparisons;
- power/thermal conclusions.

For each achievable fixture, collect only functional evidence:

- success/failure;
- correctness against fixture truth;
- completeness;
- stable error mapping;
- cancellation/cleanup;
- Range/random-access behavior for remote sources;
- thumbnail output validity.

MediaProxy byte/read counters may be used only to prove functional random-access behavior, such as avoiding an unintended full sequential download. They must not be treated as performance benchmark results.

All analyzer and playback performance decisions are deferred to arm64 real-device testing.

## 21. Report

Fill:

`docs/FFMPEG_ANALYZER_INTEGRATION_REPORT.md`

Include:

- tested SHA;
- adapter architecture;
- resolver cases;
- test totals;
- simulator artifact/install;
- fixture truth;
- System vs FFmpeg functional results;
- thumbnail functional results;
- proxy access-semantics diagnostics;
- cancellation/cleanup;
- arm64 build;
- remaining device-only gaps;
- recommendation for the next policy phase.

## 22. Stop conditions

Stop and return for architecture review after:

- FFmpeg IMediaProbe adapter passes real simulator runtime;
- System IMediaProbe adapter passes;
- FFmpeg IThumbnailExtractor adapter passes;
- resolver cleanup is proven;
- comparison fixture matrix is attempted;
- full default regression passes.

Also stop early if:

- implementing adapters requires changing a core public contract;
- local document support requires unsafe URI/path behavior;
- comparison reveals a storage/MediaProxy architecture defect;
- System/FFmpeg results conflict in a way that requires product semantics decisions.

Do not implement final merger/policy routing without review. Do not make performance-based policy decisions until real arm64 device benchmarks exist.
