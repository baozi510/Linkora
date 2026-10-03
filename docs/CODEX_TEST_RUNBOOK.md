# Codex Test Runbook

## Purpose

This runbook is for the first real build/test pass after the player architecture migration.

The task is **validation first**. Do not continue feature development until the validation gates below are completed.

## Git branch policy

Architecture baseline:

`feat/player-architecture-phase8`

Validation work branch:

`test/player-architecture-validation`

Rules:

1. Do not test or patch directly on `main`.
2. Do not merge Phase branches during this task.
3. Perform all build/test fixes on `test/player-architecture-validation`.
4. Keep fixes small and separately committed.
5. Do not rewrite architecture just to make a test pass.
6. If an architectural conflict is found, stop feature expansion, document the conflict, and preserve the Phase 8 contracts unless there is direct build/runtime evidence that they are invalid.
7. The latest architecture/specification in this repository takes precedence over older implementation behavior.

## Read before changing code

Read these files in this order:

1. `docs/SESSION_HANDOFF.md`
2. `docs/IMPLEMENTATION_STATUS.md`
3. `docs/TEST_MANUAL.md`
4. `docs/FFMPEG_INTEGRATION_BLOCKER.md`
5. `docs/ARCHITECTURE_TARGET.md`
6. `docs/ARCHITECTURE_MIGRATION.md`
7. `docs/PHASE4_REPORT.md`
8. `docs/PHASE5_REPORT.md`
9. `docs/PHASE6_REPORT.md`
10. `docs/PHASE7_REPORT.md`
11. `docs/PHASE8_REPORT.md`

## Hard constraints

Do not:

- remove the StorageProvider / RandomAccessSource boundary;
- make player code depend directly on WebDAV/SMB/SFTP/FTP/NFS implementations;
- make media probe own WebP encoding or thumbnail persistence;
- make UI depend directly on SystemPlaybackPort or MpvPlaybackPort;
- restore protocol-specific branching inside NetworkDirectoryService;
- replace shared MediaProxy with per-job listeners;
- reintroduce progressive-download playback as the new default remote path;
- generate new JPEG thumbnails;
- claim Dolby Vision / passthrough / Atmos / DTS:X support without target-device evidence;
- implement FFmpegMediaProbe against private libmpv symbols;
- fabricate FFmpeg headers/libraries or package-lock contents.

## Stage 1 — repository and dependency preparation

From the repository root:

```powershell
git fetch --all
git checkout test/player-architecture-validation
git status
```

The working tree must start clean.

Then run:

```powershell
ohpm install
```

Goals:

- resolve `@mpv-ohos/mpv-arkts@1.0.0`;
- regenerate package lock through the package manager only;
- confirm no unexpected dependency downgrade.

If the generated lockfile changes, keep it on the validation branch and commit it as a dedicated dependency-resolution commit.

Record:

- DevEco Studio version;
- HarmonyOS SDK version;
- target API;
- ohpm version;
- resolved mpv-arkts version;
- device model / OS version for device tests.

## Stage 2 — static and build verification

Run:

```powershell
./scripts/verify.ps1
```

This must run architecture guards, unit tests, HAR builds, and HAP builds.

If it fails:

1. identify the first root-cause failure;
2. make the smallest justified fix;
3. commit the fix separately;
4. rerun the full `verify.ps1`;
5. do not skip failing checks.

For every failure/fix record:

- command;
- failure output;
- root cause;
- files changed;
- commit SHA;
- rerun result.

## Stage 3 — explicit build outputs

Confirm separately:

- linkora_core Debug HAR;
- linkora_core Release HAR;
- linkora_proxy Debug HAR;
- linkora_proxy Release HAR;
- linkora_media_probe Debug HAR;
- linkora_media_probe Release HAR;
- entry arm64 Debug HAP;
- entry arm64 Release HAP.

Do not mark this stage passed from stale historical artifacts.

## Stage 4 — unit/regression tests

Run all registered Hypium tests.

Pay special attention to:

- MediaSource remote identity;
- RemoteReadSession / RandomAccessSource adapters;
- StorageProvider registry;
- MediaProxy Range handling;
- cancellation and close ownership;
- SystemMediaProbe;
- SystemThumbnailExtractor;
- Thumbnail policy;
- PlaybackEngine stale-session protection;
- SEEKING / seekDone;
- Auto backend candidate gating;
- settings persistence.

Report total/pass/fail.

## Stage 5 — protocol lab

Follow:

`test-lab/protocols/README.md`

Run the lab verification and then exercise application access for:

- WebDAV authenticated;
- WebDAV guest;
- SMB authenticated;
- SMB guest;
- SFTP;
- FTP;
- NFS.

At minimum test a remote MP4 and MKV where the protocol supports the test corpus.

Record failures by protocol and whether failure occurs in:

- authentication;
- list;
- stat;
- RandomAccessSource open;
- readAt;
- MediaProxy;
- System backend;
- MPV backend.

## Stage 6 — MediaProxy validation

Follow section 5 of `docs/TEST_MANUAL.md`.

Mandatory observations:

- binds to localhost only;
- token URL contains no credentials/upstream path;
- HEAD works;
- GET works;
- closed/open/suffix ranges work;
- 416 works;
- release invalidates lease;
- seek into a large remote file does not sequentially download from byte 0;
- activeSources returns to zero after release.

Capture diagnostics:

- readRequests;
- bytesRead;
- releasedSources.

## Stage 7 — thumbnail validation

Confirm newly generated remote-video thumbnails:

- use WebP;
- use quality 80;
- obey duration-based time policy;
- fit within 480x270 preserving aspect ratio;
- produce no new JPEG fallback;
- use algorithmVersion in cache identity.

Legacy JPEG read compatibility may remain.

## Stage 8 — target-device playback smoke test

A real arm64 HarmonyOS device is required.

Test three settings separately:

- Auto;
- System;
- MPV.

Minimum corpus:

- local H.264/AAC MP4;
- local HEVC/AAC MP4;
- local MKV;
- WebDAV MP4;
- WebDAV MKV;
- SMB MKV.

For each record:

- prepare success;
- active backend;
- first frame;
- play/pause;
- 50% seek;
- 90% seek;
- duration;
- position;
- buffering;
- EOF;
- release.

For Auto specifically verify that a failed candidate does not leak stale duration/tracks/HDR/error state before fallback commits.

## Stage 9 — targeted compatibility matrix

Use:

`test-lab/benchmark/cases.json`

Prioritize:

- H.264/AAC;
- HEVC/AAC;
- HEVC Main10;
- HDR10;
- HLG;
- Dolby Vision;
- DTS;
- DTS-HD MA;
- TrueHD;
- ASS;
- PGS;
- long GOP;
- 4K remux.

Do not interpret "audio is audible" as proof of DTS-HD/TrueHD passthrough.

Do not interpret Dolby-Vision-aware rendering as native Dolby Vision output.

## Stage 10 — benchmark collection

Playback benchmark can run now.

Run each important case at least 5 times and write NDJSON records following:

`test-lab/benchmark/README.md`

Then generate:

```powershell
node scripts/summarize-benchmark.cjs test-lab/benchmark/results.ndjson test-lab/benchmark/report.md
```

Do not tune `PlaybackBackendSelector` until there is enough data.

System-vs-FFmpeg analysis benchmark remains blocked until the FFmpeg analyzer exists.

## Stage 11 — stability

Required before reporting validation complete:

- 50 source changes;
- proxy activeSources returns to 0;
- no stale player events;
- no audio residue;
- no accumulating black surfaces.

If practical, also run the 2-hour playback test from TEST_MANUAL.md.

## Stage 12 — security review

Search runtime logs and generated reports for:

- Authorization;
- Cookie;
- password;
- signed URL query;
- SMB credentials;
- SFTP private keys.

No test artifact committed to Git may contain real credentials.

## Allowed fixes during validation

Codex may fix:

- compile/type errors;
- incorrect imports/exports;
- package integration errors;
- lifecycle bugs demonstrated by tests;
- resource leaks demonstrated by tests;
- incorrect event mapping demonstrated by tests;
- deterministic unit/regression-test defects.

Codex should not independently add new architectural features during validation.

## Required output

Create or update:

`docs/VALIDATION_REPORT.md`

It must contain:

1. exact branch and final commit SHA;
2. environment versions;
3. dependency-resolution result;
4. verify.ps1 result;
5. build matrix;
6. unit-test totals;
7. protocol-lab result;
8. System playback result;
9. MPV playback result;
10. Auto fallback result;
11. thumbnail result;
12. MediaProxy diagnostics;
13. benchmark files/report if run;
14. all fixes made with commit SHAs;
15. remaining blockers;
16. clear PASS / FAIL / NOT RUN per test area.

Do not describe an unexecuted test as passed.

## Stop condition and handoff

Stop validation work and return to the architecture owner when any of these is true:

- `verify.ps1` passes and device smoke tests have meaningful results;
- a build/API conflict requires an architecture decision;
- mpv-arkts behavior materially differs from the adapter assumptions;
- a target-device HDR/audio behavior requires policy decisions;
- FFmpeg analyzer work is requested;
- benchmark data is ready to tune Auto selection;
- a blocker cannot be resolved without changing architectural contracts.

At that point provide:

- `docs/VALIDATION_REPORT.md`;
- relevant logs with credentials redacted;
- benchmark NDJSON/report if available;
- final validation branch commit SHA.

Then ask the architecture owner to review the evidence before continuing feature development.
