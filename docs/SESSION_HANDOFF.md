# Linkora Session Handoff

## CURRENT STATE — read this before historical sections

Repository: `baozi510/Linkora`

Current implementation branch:

`feat/ffmpeg-analyzer-policy-phase3`

Current phase:

**FFmpeg Analyzer Production Policy Phase 3 — implementation complete; post-review validation rerun required.**

The first Codex test-only run tested source `72e74d11a790bd0d258e219e3a8de18f3c59fd17` and stopped at the first default verification gate. Evidence/report commit `50fc19fbc91337e21180fc8c8a856750a4a20b95` proves the failure was a static-check false positive: a service method parameter named `onMetadata` matched the ArkUI plain-output regex. Codex did not modify production source.

This architecture-review commit narrows that plain-output check to actual ArkUI component/page sources. It does **not** convert the incomplete validation run into PASS. The full Phase 3 validation manual must be rerun from the new branch HEAD.

### Source-of-truth order for a new session

Read these in order before changing code:

1. `docs/MASTER_IMPLEMENTATION_PLAN.md` — project-wide technical implementation baseline.
2. `docs/ARCHITECTURE_TARGET.md` — current engineering target architecture.
3. `docs/ARCHITECTURE_MIGRATION.md` — current strangler-migration path.
4. `docs/IMPLEMENTATION_STATUS.md` — current completed/pending implementation state.
5. this `docs/SESSION_HANDOFF.md` CURRENT STATE section.
6. the latest phase implementation report and validation report/evidence.
7. inspect the actual Git branch/HEAD and affected source before making changes.

Do not rely on prior chat memory. Repository state and the documents above are the durable project memory.

### Approved Phase 3 interpretation of the Master Plan

The Master Plan originally places final analysis policy after System-vs-FFmpeg benchmark. The project later established that x86 simulator performance must not be used for System-vs-FFmpeg ranking. Therefore Phase 3 intentionally introduces only a **functional production policy** before the real arm64 benchmark:

- LIST: System primary, FFmpeg controlled fallback for resolvable file-like sources.
- DETAIL / ADVANCED: FFmpeg primary, System fallback only when FFmpeg is unusable.
- thumbnail: FFmpeg primary for resolvable file-like remote sources, existing System fallback.
- HLS / DASH / LOCAL_DOCUMENT remain System-only.
- no System+FFmpeg field merger in this phase.
- no performance-derived routing in this phase.
- no playback backend policy change.

This is a staged migration decision, not a claim that the long-term analysis architecture is finished.

### Phase 3 review findings

- SFTP semantic bug fix is correct at the storage boundary: analysis no longer passes `MediaSource.fingerprint` as a host-key fingerprint; SFTP provider/browser resolve trust from `NetworkServerEntry.advancedOptions.sftpFingerprint`.
- Storage remains protocol-aware; FFmpeg remains protocol-agnostic and continues through RandomAccessSource -> shared MediaProxy -> localhost.
- default and simulator `AnalysisComposition` remain symmetric at the analyzer boundary.
- PlaybackBackendSelector / Auto/System/MPV playback policy is unchanged.
- `NetworkMediaAnalysisCoordinator` is accepted as a Phase 3 production orchestration facade, but the long-term Master Plan still targets explicit `MediaProbeService` / `ThumbnailService` application services. Do not proliferate direct adapter construction into business/UI call sites.
- the only issue proven by the completed Codex run is the verifier false positive described above. Runtime/load/cache/fallback lifecycle cases were not reached and are not PASS.

### Next action

Codex remains test/report-only for Phase 3.

From a clean checkout of the new HEAD:

1. run normal `ohpm install`;
2. run full `scripts/verify.ps1`;
3. only if the default gate passes, continue the Phase 3 simulator/runtime cases in `docs/CODEX_PHASE3_FUNCTIONAL_VALIDATION.md`;
4. update `docs/FFMPEG_ANALYZER_POLICY_PHASE3_REPORT.md` with only actually executed evidence;
5. do not patch production source from Codex;
6. return failures to ChatGPT for implementation review.

Performance remains deferred to a real arm64 device.

### End-of-phase documentation rule

Every implementation/validation phase must close by updating all applicable durable state in the same branch:

- `docs/IMPLEMENTATION_STATUS.md`;
- the phase implementation/report document;
- the phase validation report/evidence document;
- `docs/SESSION_HANDOFF.md` CURRENT STATE / NEXT ACTION.

If a validation rerun follows a source fix, old failed evidence remains historical evidence; do not rewrite it as if it had passed.

# Historical milestones

> The material below is preserved for provenance. It contains earlier "current" statements that may now be stale. For present work, the CURRENT STATE and source-of-truth order above take precedence.

## Purpose

This file is the durable context handoff for a new ChatGPT/Codex session.

If a new session has no prior conversation context, read this file first and then follow the repository documents referenced below.

## Repository

Repository:

`baozi510/Linkora`

Current architecture baseline branch:

`feat/player-architecture-phase8`

Validation branch:

`test/player-architecture-validation`

Do not start new work from `main` until the stacked architecture work is reviewed and merged.

## Current stacked branch/PR chain

```text
main
 ↓
Phase 0  chore/player-architecture-phase0
 ↓
Phase 1  feat/player-architecture-phase1
 ↓
Phase 2  feat/player-architecture-phase2
 ↓
Phase 3  feat/player-architecture-phase3
 ↓
Phase 4  feat/player-architecture-phase4
 ↓
Phase 5  feat/player-architecture-phase5
 ↓
Phase 6  feat/player-architecture-phase6
 ↓
Phase 7  feat/player-architecture-phase7
 ↓
Phase 8  feat/player-architecture-phase8
```

Pull requests:

- PR #1 — Phase 0
- PR #2 — Phase 1
- PR #3 — Phase 2
- PR #4 — Phase 3
- PR #5 — Phase 4
- PR #6 — Phase 5
- PR #7 — Phase 6
- PR #8 — Phase 7
- PR #9 — Phase 8

## Product direction

Linkora is a modular HarmonyOS NEXT network media player.

Primary sources:

- local files;
- WebDAV;
- SMB;
- SFTP;
- FTP;
- NFS;
- future Jellyfin / Emby / Plex integrations.

Playback architecture:

```text
StorageProvider
    ↓
RandomAccessSource
    ↓
MediaSource / MediaProxy
    ↓
AdaptivePlaybackPort
   /                  \
System AVPlayer      MPV
```

Media analysis architecture:

```text
MediaSource
   ↓
MediaProbeService (target)
   ├─ SystemMediaProbe
   └─ FFmpegMediaProbe (blocked)
```

Thumbnail architecture:

```text
metadata
  ↓
ThumbnailTimePolicy
  ↓
thumbnail extractor
  ↓
PixelMap/raw frame
  ↓
WebP encoder
  ↓
thumbnail cache
```

## Non-negotiable architecture rules

1. Protocol/storage code must not know player implementation.
2. Player implementation must not know WebDAV/SMB/SFTP/FTP/NFS implementations.
3. MediaProbe must not know UI.
4. UI must not know FFmpeg internals or concrete player backend internals.
5. Thumbnail extraction, image processing/encoding and cache persistence are separate responsibilities.
6. New remote playback should use RandomAccessSource -> shared MediaProxy -> backend.
7. Do not force all media bytes through ArkTS if a lower-level fast path is later justified, but do not implement direct I/O before benchmark evidence.
8. Auto backend selection must eventually be data driven.
9. Failed backend candidates must not leak events into the committed playback session.
10. Credentials must be referenced through configuration/session identity and never logged in URLs.
11. Newly generated video thumbnails are WebP, not JPEG.
12. Architecture/specification from the latest phase wins when old code conflicts.

## Current thumbnail standard

- short video (<30s): approximately 20%;
- normal video: min(duration * 10%, 60 seconds);
- bounding box 480x270;
- preserve aspect ratio;
- WebP;
- quality 80;
- algorithmVersion participates in cache identity;
- legacy JPEG may be read but new JPEG should not be generated.

## Current network/data rules

Random-access semantics are central.

Important edge cases:

- Range / 206;
- 416;
- unknown length;
- auth expiry;
- ETag / Last-Modified/fingerprint;
- seek cancellation;
- reconnect;
- bounded prefetch;
- no full-file read for a remote seek.

MediaProxy is shared infrastructure and should remain localhost-only with random token URLs.

## Current playback rules

Three user modes:

- Auto;
- System;
- MPV.

Current Auto policy is only a temporary baseline.

Do not treat it as a final ranking.

System is preferred for ordinary native/direct-play cases when it actually works.

MPV is the compatibility path for complex media.

Fallback in Auto is one-shot and occurs around prepare/open, not arbitrary mid-session switching.

Unified state includes:

- IDLE;
- PREPARING;
- READY;
- PLAYING;
- PAUSED;
- SEEKING;
- BUFFERING;
- COMPLETED;
- ERROR;
- RELEASED.

## MPV integration

Current dependency target:

`@mpv-ohos/mpv-arkts@1.0.0`

Current public upstream package is arm64-v8a oriented and declares HarmonyOS compatible SDK 20+.

Linkora currently adapts:

- surface attach/detach;
- surface size;
- open/prepare;
- play/pause;
- seek;
- position/duration;
- buffering;
- EOF;
- tracks;
- video params/color information.

All of this still requires real DevEco/arm64 target validation.

## FFmpeg analyzer status

DEPENDENCY BOOTSTRAP IN PROGRESS.

Pinned source:

- FFmpeg 8.1.3
- n8.1.3
- commit 1041abdc962f4cc4f394aa8de9dc5236c0c3b9e7

The repository now contains reproducible source-fetch and HarmonyOS dual-ABI bootstrap scripts for:

- arm64-v8a
- x86_64

The analyzer itself is still NOT IMPLEMENTED until both ABI builds produce verified libavformat/libavcodec/libavutil/libswscale artifacts.

Never use private libmpv-linked FFmpeg symbols.

Read:

- `docs/FFMPEG_BOOTSTRAP.md`
- `docs/FFMPEG_INTEGRATION_BLOCKER.md`

## Claims that require device evidence

Do not claim these are proven merely from code:

- native HDR output;
- native Dolby Vision output;
- Dolby Vision mode signaling;
- DTS-HD MA passthrough;
- TrueHD passthrough;
- Atmos passthrough/object rendering;
- DTS:X passthrough/object rendering;
- Audio Vivid behavior;
- power efficiency;
- real hardware decode coverage.

## What to read for current status

Read in this order:

1. `docs/IMPLEMENTATION_STATUS.md`
2. `docs/TEST_MANUAL.md`
3. `docs/CODEX_TEST_RUNBOOK.md`
4. `docs/FFMPEG_INTEGRATION_BLOCKER.md`
5. `docs/ARCHITECTURE_TARGET.md`
6. `docs/ARCHITECTURE_MIGRATION.md`
7. latest phase reports

## Current next action

Do not continue feature development first.

Run validation on:

`test/player-architecture-validation`

Follow:

`docs/CODEX_TEST_RUNBOOK.md`

Expected first commands:

```powershell
git fetch --all
git checkout test/player-architecture-validation
git status
ohpm install
./scripts/verify.ps1
```

Then perform target-device smoke tests and write:

`docs/VALIDATION_REPORT.md`

## When to return to architecture/design work

Return with evidence after one of these milestones:

- verify.ps1 fully passes;
- arm64 Debug and Release HAP both build;
- System + MPV + Auto target-device smoke test results exist;
- benchmark data exists;
- an adapter/API mismatch requires redesign;
- FFmpeg dependency artifacts are ready.

The next architecture session should read VALIDATION_REPORT.md first.

## Preferred engineering style

- modular and pluggable;
- small reviewable commits;
- reuse existing protocol/native implementations;
- confirmed facts separated from inference;
- no fake support claims;
- no speculative large refactors when measurement can answer the question;
- errors and logs must not expose credentials;
- preserve rollback paths during migration.

## New-session prompt

A user can start a new assistant session with:

```text
Open GitHub repository baozi510/Linkora.
Read docs/SESSION_HANDOFF.md first, then docs/IMPLEMENTATION_STATUS.md,
docs/VALIDATION_REPORT.md if it exists, docs/TEST_MANUAL.md, and
docs/FFMPEG_INTEGRATION_BLOCKER.md.

Use the latest repository documents as the source of truth.
Continue from the documented current branch/status.
Do not redesign or merge branches until you have reviewed the validation evidence.
```


## Post-validation review update

Architecture review after the first validation pass is complete.

Before any further runtime testing or feature work, read:

`docs/CODEX_POST_VALIDATION_ACTIONS.md`

Current next action is:

1. keep the accepted validation fixes;
2. correct MPV error-log handling;
3. wire surface size from PlayerPage -> PlayerFeatureController -> PlaybackEngine;
4. correct HDR labeling so BT.2020 alone is not treated as HDR;
5. tighten the architecture-boundary scanner;
6. rerun the full verify.ps1;
7. attempt the current HAP on the available x86_64 emulator without production ABI hacks;
8. update VALIDATION_REPORT.md and stop for architecture review.

Do not start FFmpeg or Auto-policy tuning before this review loop is complete.


## ARM64 device validation handoff

The post-validation correction pass has now been architecture-reviewed and accepted at the source/build level.

Current next step requires a real arm64 HarmonyOS device.

Read and follow:

`docs/ARM64_DEVICE_VALIDATION_RUNBOOK.md`

Do not continue simulator-specific production changes. The available x86_64 emulator cannot install the current arm64-v8a HAP.

Do not merge PR #10 until arm64 runtime evidence has been reviewed.


## x86_64 near-production simulator product

Current active simulator branch:

`test/simulator-validation`

It is based on `test/player-architecture-validation` and must not be merged before validation.

The simulator is no longer a System/WebDAV-only product. It intentionally mirrors production business behavior:

- same SettingsPage with Auto/System/MPV
- same NetworkPage with WebDAV/SMB/SFTP/FTP/NFS
- same PlaybackEngine
- same PlaybackBackendSelector
- same AdaptivePlaybackPort
- same NetworkDirectoryService
- same database/config models
- same MediaProxy
- exact same shared HTTP/WebDAV providers

Only the final platform boundaries are replaced:

- real arm64 MPV package -> compile-only x86 simulator MPV replacement
- real SMB/SFTP/FTP/NFS Native storage providers -> explicit simulator unavailable transport provider

This means Auto fallback and native-protocol configuration/error paths can be tested without pretending the real Native implementation ran.

Simulator bundle:

`com.linkora.player`

Read:

- `docs/SIMULATOR_TEST_MANUAL.md`
- `docs/SIMULATOR_VALIDATION_REPORT.md`
- `docs/FFMPEG_BOOTSTRAP.md`

Required order:

1. `./scripts/verify.ps1`
2. `node scripts/check-simulator-product.cjs`
3. `./scripts/verify-simulator.ps1`
4. install the x86_64 simulator HAP
5. execute the near-production simulator manual
6. build pinned FFmpeg for x86_64 and arm64-v8a if the Native SDK is available
7. update reports
8. stop for architecture review

The simulator HAP must never contain real libmpv or production SMB/SFTP/FTP/NFS native libraries.

A future `liblinkora_ffmpeg.so` is the only planned x86 native runtime addition after FFmpeg integration.

Simulator evidence still does not replace ARM64 device validation.


## Simulator validation accepted / FFmpeg Phase 1 authorized

The near-production simulator validation round is architecture-reviewed and accepted.

Accepted tested source SHA from that round:

`04814840403b54d8dd0e0e61798be1fb3f8f8da8`

The simulator branch later added evidence/documentation only.

Confirmed validation highlights:

- default `verify.ps1` PASS;
- Hypium 149/149 PASS;
- default arm64 Debug/Release HAP PASS;
- simulator HAP build/install/launch PASS;
- Auto/System/MPV UI parity preserved;
- WebDAV real shared provider path exercised;
- real MediaProxy random seek evidence collected;
- overlapping seek/buffering bug fixed and regression-tested;
- RepeatItem refresh bug fixed and runtime-tested;
- FFmpeg 8.1.3 bootstrap built for both x86_64 and arm64-v8a;
- static archives audited as X86-64 / AArch64.

Still device-only / not proven:

- real MPV runtime;
- real SMB/SFTP/FTP/NFS native I/O;
- native HDR/Dolby Vision output;
- DTS-HD/TrueHD/Atmos/DTS:X passthrough;
- arm64 hardware decode/power/thermal.

Current implementation branch:

`feat/ffmpeg-media-analysis-phase1`

Read first:

1. `docs/CODEX_FFMPEG_INTEGRATION_RUNBOOK.md`
2. `docs/FFMPEG_PHASE1_REPORT.md`
3. `docs/FFMPEG_BOOTSTRAP.md`
4. `docs/SIMULATOR_VALIDATION_REPORT.md`

Current authorization:

- create dedicated `linkora_ffmpeg` module;
- link the pinned FFmpeg static libraries;
- support x86_64 simulator and arm64-v8a build;
- implement async native metadata probe;
- implement async one-frame RGBA extractor;
- implement cancellation/timeout via AVIOInterruptCB;
- run local + MediaProxy simulator smoke.

Still forbidden before the next architecture review:

- making FFmpeg the production default probe;
- changing IMediaProbe public signature;
- changing Auto/PlaybackBackendSelector;
- System/FFmpeg policy tuning;
- AVIOContext direct callbacks;
- FFmpeg playback backend.


## FFmpeg Phase 1A accepted / Phase 1B runtime required

Phase 1A branch:

`feat/ffmpeg-media-analysis-phase1`

Phase 1A validated source:

`772889a48aabec8d8c427a1222126c1709159ca4`

Accepted Phase 1A results:

- dedicated `linkora_ffmpeg` module exists;
- pinned static FFmpeg linkage is isolated from MPV;
- arm64-v8a native Debug/Release link passes;
- default arm64 HAP Debug/Release passes;
- NAPI work/request/cancel design passed source/unit review;
- Hypium 164/164 passed at the validated source;
- no production analyzer/playback policy was changed.

Phase 1A did **not** execute the x86 simulator native runtime because the previous runbook stop condition fired after arm64 link success. This is not sufficient for analyzer integration.

Current runtime-validation branch:

`test/ffmpeg-media-analysis-phase1b-runtime`

Read:

1. `docs/CODEX_FFMPEG_PHASE1B_RUNTIME_RUNBOOK.md`
2. `docs/FFMPEG_PHASE1B_RUNTIME_REPORT.md`
3. `docs/FFMPEG_PHASE1_REPORT.md`

Phase 1B must attempt real x86:

- HAP packaging/install;
- `liblinkora_ffmpeg.so` load;
- NAPI factory;
- local probe;
- local frame extraction;
- WebDAV -> MediaProxy -> FFmpeg probe/frame;
- real timeout;
- real cancellation;
- concurrency;
- lifecycle cycles.

Still forbidden:

- production FFmpeg routing;
- probe-policy tuning;
- System/FFmpeg merger;
- AVIO direct storage callbacks;
- MPV/Auto changes.


## FFmpeg Phase 1B runtime accepted / build isolation hardening required

Phase 1B runtime validation is accepted.

Validated source:

`d8dad1d757c5b7e6a13b9603d540903aba99567a`

Confirmed:

- real x86 `liblinkora_ffmpeg.so` packaged and loaded;
- real NAPI import/factory/probe/frame/cancel;
- local MP4 and MKV probe;
- software RGBA frame extraction;
- WebDAV -> RandomAccessSource -> MediaProxy -> FFmpeg;
- high-offset Range seek evidence;
- real FF_TIMEOUT through stalling MediaProxy source;
- 10 active FF_CANCELLED cycles;
- concurrency isolation;
- 20 lifecycle cycles;
- final default arm64 Debug/Release builds;
- Hypium 164/164.

One important build-system issue remains before production analyzer routing:

A simulator target dependency resolution previously left the workspace in a state where a subsequent default HAP omitted real MPV until normal `ohpm install` restored the default dependency graph.

Current hardening branch:

`fix/simulator-default-dependency-restore`

Read:

- `docs/CODEX_BUILD_ISOLATION_HARDENING.md`
- `docs/BUILD_ISOLATION_HARDENING_REPORT.md`

This branch:

- makes simulator verification restore the default ohpm dependency graph automatically;
- requires all 9 expected production native libraries in default artifact audits;
- tightens FFmpeg bootstrap manifest checks to exact lines.

Do not start production FFmpeg analyzer routing until this hardening report passes.


## Build isolation hardening accepted / FFmpeg Analyzer Phase 2 active

Build isolation hardening is accepted.

Validated hardening source:

`ce24be1daf12892bfaa028bcd138fca25116a320`

Confirmed:

- two simulator -> immediate default cycles passed with no manual restore;
- one intentional simulator build failure still restored default dependencies automatically;
- default Debug and Release HAPs each contained the required 9 AArch64 native libraries;
- simulator HAP contained only x86_64 `liblinkora_ffmpeg.so`;
- artifact guard fixtures passed;
- exact FFmpeg manifest negative checks passed;
- Hypium 164/164 passed;
- tracked dependency/signing state remained clean.

Current branch:

`feat/ffmpeg-analyzer-integration-phase2`

Read:

1. `docs/CODEX_FFMPEG_ANALYZER_INTEGRATION_PHASE2.md`
2. `docs/FFMPEG_ANALYZER_INTEGRATION_REPORT.md`
3. `docs/FFMPEG_PHASE1B_RUNTIME_REPORT.md`
4. `docs/BUILD_ISOLATION_HARDENING_REPORT.md`

Current authorization:

- implement analysis input resolver;
- implement FFmpeg `IMediaProbe` adapter;
- implement System `IMediaProbe` adapter;
- implement FFmpeg `IThumbnailExtractor` adapter;
- run simulator System-vs-FFmpeg comparison/diagnostic matrix;
- collect completeness, correctness, error/cleanup and remote Range/random-access functional evidence. Performance evidence is deferred to real arm64 device testing.

Still forbidden before the next review:

- switching `NetworkMediaLoader` production results to FFmpeg;
- merging System/FFmpeg fields into cache;
- final analyzer policy;
- default FFmpeg thumbnail routing;
- playback Auto changes;
- AVIOContext direct callbacks;
- FFmpeg playback.

This branch also tightens the default artifact audit to reject unexpected extra arm64 native libraries.


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


## FFmpeg Analyzer Production Policy Phase 3 — implemented, awaiting test-only validation

Current branch:

`feat/ffmpeg-analyzer-policy-phase3`

Implementation ownership for this phase:

- ChatGPT implements/fixes source;
- Codex tests and reports only;
- Codex must not patch source on validation failures.

Implemented functional policy:

```text
LOCAL_DOCUMENT / HLS / DASH
  -> System-only policy

file-like REMOTE_FILE / HTTP
  LIST
    -> System first
    -> FFmpeg only if System is incomplete/unusable

  DETAIL / ADVANCED
    -> FFmpeg first
    -> System only if FFmpeg is unusable
    -> no field merger

thumbnail
  -> FFmpeg first
  -> existing System thumbnail fallback
  -> common WebP encoder/cache
```

Production `NetworkMediaLoader` now uses `NetworkMediaAnalysisCoordinator`.

Additional lifecycle/security fixes in this phase:

- policy cancellation cannot start a later fallback engine;
- coordinator cancellation cannot continue into thumbnail fallback;
- `MediaSource.fingerprint` is no longer misused as an SFTP host-key fingerprint;
- FFmpeg raw RGBA frames use the existing System WebP encoder;
- no performance-based routing was introduced.

Read for validation:

1. `docs/CODEX_PHASE3_FUNCTIONAL_VALIDATION.md`
2. `docs/FFMPEG_ANALYZER_POLICY_PHASE3_REPORT.md`

Performance remains deferred to arm64 real-device testing.

If Codex reports a source failure, return to ChatGPT for the fix. Do not let Codex patch the implementation branch.
