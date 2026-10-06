# Codex Validation Task

> State: READY
> Task ID: phase8a-mate60-playback-foundation
> Repository: `baozi510/Linkora`
> Branch: `feat/playback-capability-phase8`
> Phase 7A accepted baseline: `e81766309fab4bf61222c64f95c25bd9ad5fd148`
> Phase 8A source: `fd76b28a85522a94db40e754dd87c62960dc71ad`
> Role: BUILD / RUNTIME TEST / EVIDENCE / REPORT ONLY

## 1. Purpose

Validate the existing real-arm64 playback foundation on Mate60 before the project expands into the broad media capability corpus.

Read completely:

`docs/PLAYBACK_PHASE8_MATE60_RUNBOOK.md`

This task does not authorize source fixes, Auto policy tuning, performance routing, Direct I/O, or the broad 59-case compatibility matrix.

## 2. Source safety

Use a new isolated checkout/worktree, for example:

`D:\Linkora-playback-phase8a`

Do not mutate the user's dirty `D:\Linkora`.

Before testing:

1. fetch `feat/playback-capability-phase8`;
2. checkout current remote HEAD;
3. initialize/verify pinned submodules;
4. prove tracked checkout clean;
5. prove `fd76b28a85522a94db40e754dd87c62960dc71ad` is an ancestor of HEAD;
6. run:

```powershell
git diff --name-only fd76b28a85522a94db40e754dd87c62960dc71ad..HEAD
```

The only permitted path is:

```text
docs/CODEX_VALIDATION_TASK.md
```

Anything else => STOP.

Also prove `e81766309fab4bf61222c64f95c25bd9ad5fd148` is an ancestor of the Phase 8A source.

Record actual tested checkout SHA separately.

## 3. Required reading

Read completely:

1. `docs/AI_WORKFLOW.md`
2. `docs/MASTER_IMPLEMENTATION_PLAN.md`
3. `docs/ARCHITECTURE_TARGET.md`
4. `docs/ARCHITECTURE_MIGRATION.md`
5. `docs/IMPLEMENTATION_STATUS.md`
6. `docs/SESSION_HANDOFF.md` — CURRENT STATE first
7. `docs/CODEX_VALIDATION_TASK.md`
8. `docs/PLAYBACK_PHASE8_MATE60_RUNBOOK.md`
9. `docs/PLAYBACK_PHASE8_REPORT.md`
10. `docs/MEDIA_COMPATIBILITY_REPORT.md`
11. `test-lab/media-compatibility/README.md`

Historical simulator compatibility results are context only, never fresh Mate60 PASS.

## 4. Read-only architecture confirmation

Before execution, confirm:

- `AdaptivePlaybackPort` supports forced System / forced MPV / Auto;
- Auto fallback is one-shot around prepare;
- candidate observer prevents failed-candidate events from reaching committed session;
- `NetworkPlaybackSourceResolver` maps REMOTE_FILE through RandomAccessSource -> NetworkFileProxy;
- `MpvPlaybackPort` attaches the XComponent surface and handles FILE_LOADED / PLAYBACK_RESTART / EOF;
- MPV error-level log lines are diagnostics, not automatically fatal runtime events;
- `SystemPlaybackPort` and `MpvPlaybackPort` are both production backends;
- no production playback policy/source diff was introduced by the Phase 8A preparation commit.

Contradiction => STOP.

## 5. Fresh preparation/build gate

Run exactly one normal:

```powershell
ohpm install
```

Use the established strict EOL-only proof/restore only for the known allowlisted lockfiles if Windows normalization occurs.

Then run one fresh:

```powershell
./scripts/verify.ps1
```

Do not reuse Phase 7A build results as fresh Phase 8A PASS.

Record:

- architecture fixtures;
- FFmpeg/analysis pure counts;
- MPV mapping count;
- actual Hypium count;
- Debug/Release HAR/HAP;
- exact-nine AArch64 audits;
- final verifier marker.

Any build/static gate failure => STOP:

`FAIL — BUILD`

Do not patch source or retry after a source/test gate failure.

## 6. Fresh exact-source signed HAP

After the fresh verifier passes, prepare a fresh signed default/debug arm64 HAP.

Use the already accepted signing rules:

- temporary root `build-profile.json5` signing-only overlay;
- no SDK/module/dependency/ABI/source/build-option change;
- no raw secret/signing paths in evidence;
- sanitized overlay summary + SHA-256;
- build exact signed HAP once;
- run the existing artifact checker on that exact HAP;
- record HAP SHA-256 and byte size;
- restore overlay to HEAD and prove clean;
- explicitly install that exact HAP on Mate60.

Signature mismatch:

`BLOCKED — SIGNING/DEPLOYMENT`

Do not uninstall/reset app data automatically.

## 7. Target and controlled fixtures

Use the real Mate60 arm64 target.

Freshly record sanitized:

- HDC version;
- architecture/API;
- bundle/version;
- process/launch result.

Reuse the controlled HTTPS WebDAV fixture environment if still available.

Freshly verify hashes for:

- H.264/AAC MP4 1280x720 ~20 s;
- HEVC/AAC MKV 1280x720 ~20 s;
- corrupt MP4 if still available.

Do not publish private endpoint/server name/path/credentials/device ID/SSH/signing material.

If the two valid controlled files are unavailable or hashes no longer match:

`BLOCKED — TEST ENVIRONMENT`

## 8. Runtime gates

Follow `docs/PLAYBACK_PHASE8_MATE60_RUNBOOK.md`.

### P01 forced System — H.264/AAC MP4

Required PASS:

- committed backend System;
- visible first frame;
- play/pause/resume;
- seek ~50%;
- seek ~90%;
- completion/EOF;
- clean leave/release;
- no MPV fallback.

### P02 forced MPV — H.264/AAC MP4

Required PASS:

- committed backend MPV;
- real visible frame;
- surface attach;
- play/pause/resume;
- seek ~50%;
- seek ~90%;
- completion/EOF;
- clean release;
- recoverable MPV diagnostic log does not by itself tear down playback.

### P03 forced MPV — HEVC/AAC MKV

Required PASS:

- MPV prepare/first frame;
- play;
- seek 50%/90%;
- completion/EOF;
- clean release.

### P04 Auto — H.264/AAC MP4

Required PASS:

- current baseline commits System when System succeeds;
- normal playback/seek/release;
- no failed-candidate event pollution.

### P05 Auto — HEVC/AAC MKV

Required PASS:

- current baseline commits MPV;
- normal playback/seek/release;
- no System-candidate event pollution.

## 9. Capability observation

Run forced System on HEVC/AAC MKV once if safe.

Record:

- PASS;
- UNSUPPORTED;
- or stable FAIL.

This result does not fail Phase 8A solely because System lacks format support.

It **does** fail infrastructure if it causes crash, ANR, unbounded prepare, fallback despite forced mode, or unreleased playback state.

## 10. Negative path

If the controlled corrupt fixture is still available, test forced MPV.

Require:

- bounded failure;
- no infinite loading;
- no crash/ANR;
- no repeated fallback;
- no credential/upstream/private token leakage;
- a valid file can be opened afterward.

If the controlled corrupt fixture is unavailable, record NOT RUN with preflight reason. Do not synthesize a replacement during this task.

## 11. Lifecycle

Run 20 MPV open/play/leave cycles on one known-good controlled source.

Require:

- first frame every cycle;
- short playback;
- clean leave;
- no stale old-session UI/events;
- no residual audio;
- no accumulating black surface;
- no crash/ANR.

Also perform if safe:

- one background/foreground round trip;
- one fullscreen/orientation round trip.

## 12. MediaProxy behavior

Confirm production remote playback resolves through:

```text
REMOTE_FILE
-> NetworkDirectoryService.openSource
-> RandomAccessSource
-> NetworkFileProxy
-> localhost token URL
-> backend
```

Evidence should confirm:

- localhost token;
- no upstream credential/path in token URL;
- seek produces high-offset/non-sequential remote access behavior rather than a full sequential read from zero;
- playback lease is released behaviorally after leaving.

Direct shared-production proxy diagnostics are NOT mandatory because no external diagnostics endpoint exists.

Do not add instrumentation for this task.

## 13. Interpretation boundaries

Do not use Phase 8A to claim:

- final Auto selection;
- System vs MPV speed ranking;
- broad codec/container support;
- HDR/Dolby Vision output;
- DTS-HD/TrueHD/Atmos/DTS:X passthrough;
- memory/power/thermal ranking;
- Direct I/O need.

Do not start the 59-case matrix in this task.

## 14. Security/protection

Scan evidence for:

- Authorization;
- Cookie;
- password;
- private WebDAV server/path;
- proxy token;
- private target identifier;
- signing paths/material;
- SSH data.

Before commit, prove production source/test/build/task files remain unchanged from tested HEAD.

The original dirty user workspace must remain unchanged.

## 15. Authorized repository output

Codex may update only:

- `docs/PLAYBACK_PHASE8_REPORT.md`
- one new evidence directory:
  `test-lab/playback/phase8a-mate60-foundation-20261006/`

Suggested evidence:

- source-state.json;
- required-reading.json;
- dependency/EOL proof;
- fresh build summary/raw outputs;
- signing/artifact provenance;
- sanitized target/fixture preflight;
- P01-P05 observations;
- optional System/MKV observation;
- negative-path observation;
- 20-cycle lifecycle evidence;
- MediaProxy behavioral evidence;
- security review;
- protected audit.

Do not commit HAP, screenshots containing private server information, private config, credentials or signing material.

## 16. Handoff

After completion:

1. restore signing overlay;
2. prove checkout contains only authorized report/new evidence;
3. fetch remote;
4. stop on unexpected protected drift;
5. commit report + evidence only;
6. push without force;
7. fetch again;
8. prove remote containment;
9. return the remotely visible evidence SHA.

## 17. Final classification

Use exactly one:

- `PASS — PHASE 8A PLAYBACK FOUNDATION ACCEPTED`;
- `FAIL — BUILD`;
- `FAIL — SYSTEM PLAYBACK FOUNDATION`;
- `FAIL — MPV PLAYBACK FOUNDATION`;
- `FAIL — AUTO PLAYBACK FOUNDATION`;
- `FAIL — PLAYBACK LIFECYCLE`;
- `BLOCKED — SIGNING/DEPLOYMENT`;
- `BLOCKED — TEST ENVIRONMENT`;
- `BLOCKED — EVIDENCE NOT PUSHED`;
- another precise infrastructure classification.

Do not patch source.
Do not tune Auto.
Do not implement Direct I/O.
Do not start Phase 8B.
