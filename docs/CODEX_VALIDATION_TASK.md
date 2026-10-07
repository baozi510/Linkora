# Codex Validation Task

> State: READY
> Task ID: phase8a-rerun-1-mpv-state-eof-surface
> Repository: `baozi510/Linkora`
> Branch: `feat/playback-capability-phase8`
> Prior failed evidence: `08852ccc0ae1806b8270f2a248113eeedd61b5f9`
> Corrected source: `5146ff923900fd73ff25769783fb2d9732cfad5c`
> Role: BUILD / RUNTIME TEST / EVIDENCE / REPORT ONLY

## 1. Purpose

Freshly rerun Phase 8A on the corrected MPV playback source.

The prior run remains:

`FAIL — MPV PLAYBACK FOUNDATION`

Do not promote any prior NOT RUN item to PASS.

GPT independently reviewed the first evidence and corrected only the proven Phase 8A defects:

1. MPV unified PLAYING/PAUSED state synchronization;
2. EOF terminal-state protection against trailing `playing=false`;
3. ArkUI vp -> physical px conversion at the MPV surface-size boundary;
4. pure MPV event-order regressions.

No Auto policy, codec capability policy, MediaProxy strategy, Direct I/O, thumbnail research, or Phase 8B work is authorized.

## 2. Source safety

Use a fresh isolated checkout/worktree, for example:

`D:\Linkora-playback-phase8a-rerun1`

Do not mutate the user's existing workspace.

Before testing:

1. fetch `feat/playback-capability-phase8`;
2. checkout current remote HEAD;
3. initialize/verify pinned submodules;
4. prove checkout clean;
5. prove prior failed evidence `08852ccc0ae1806b8270f2a248113eeedd61b5f9` is an ancestor of corrected source;
6. prove corrected source `5146ff923900fd73ff25769783fb2d9732cfad5c` is an ancestor of HEAD;
7. run:

```powershell
git diff --name-only 5146ff923900fd73ff25769783fb2d9732cfad5c..HEAD
```

The only permitted path is:

```text
docs/CODEX_VALIDATION_TASK.md
```

Anything else => STOP.

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
10. prior evidence report/evidence at `08852ccc...`
11. `docs/MEDIA_COMPATIBILITY_REPORT.md`
12. `test-lab/media-compatibility/README.md`

Prior evidence is historical failure evidence only, never fresh PASS.

## 4. Read-only correction review

Before execution, verify corrected source contains exactly the intended behavior:

### MPV state

- successful `MpvPlaybackPort.play()` explicitly publishes unified PLAYING;
- successful `pause()` explicitly publishes PAUSED;
- pre-prepare wrapper playing events remain unable to leak as committed candidate state;
- no Auto/fallback semantics were changed.

### EOF

- EOF marks the MPV port terminally completed;
- wrapper `playing=false` after EOF cannot downgrade COMPLETED to PAUSED;
- seek/replay clears the terminal guard and can return to PLAYING.

### Surface units

- PlayerPage keeps gesture/layout geometry in vp;
- only the values sent through `setSurfaceSize` are converted with the active `UIContext.vp2px`;
- no gesture coordinate path is converted to px;
- MPV still receives `ohos-surface-size` through the existing adapter.

### Regression

`scripts/check-mpv-playback-port.cjs` must include controlled regressions for:

- explicit PLAYING/PAUSED publication without relying on wrapper property callbacks;
- EOF -> trailing playing=false remaining COMPLETED;
- replay after EOF becoming PLAYING.

If the suite inventory is otherwise unchanged, expect **7 MPV adapter mapping tests** rather than the historical 5.

Any contradiction => STOP and report it. Do not patch.

## 5. Fresh preparation/build gate

Run exactly one normal:

```powershell
ohpm install
```

Use the established strict four-lock EOL-only proof/restore if Windows normalization occurs.

Then run one fresh:

```powershell
./scripts/verify.ps1
```

Do not reuse the prior build PASS.

Record actual fresh:

- architecture fixtures;
- FFmpeg pure;
- analysis pure;
- artifact fixtures;
- MPV mapping suite and actual count;
- Hypium count;
- Debug/Release HAR/HAP;
- both exact-nine AArch64 audits;
- final verifier marker.

Any gate failure => STOP:

`FAIL — BUILD`

Do not patch or retry-after-fix.

## 6. Fresh exact-source signed HAP

After the verifier passes, create one fresh exact-source signed default/debug arm64 HAP using the previously accepted signing-only overlay procedure.

Requirements:

- signing fields/path only;
- no SDK/module/dependency/ABI/source/build-option changes;
- sanitized overlay summary + SHA-256;
- build exact signed HAP once;
- run existing artifact checker on that exact HAP;
- record exact HAP SHA-256 and byte size;
- restore overlay to HEAD and prove clean;
- explicitly install that exact HAP on Mate60.

Do not uninstall or clear app data automatically.

Signing/deployment failure:

`BLOCKED — SIGNING/DEPLOYMENT`

## 7. Target and controlled fixtures

Use the real Mate60 arm64 target.

Freshly record sanitized:

- HDC version;
- architecture/API;
- bundle/version;
- launch/process result.

Freshly verify controlled fixtures:

1. H.264/AAC MP4 1280x720 ~20 s;
2. HEVC/AAC MKV 1280x720 ~20 s;
3. corrupt MP4 if still present.

Fresh hash/Range preflight is required.

If either valid controlled fixture is unavailable or changed:

`BLOCKED — TEST ENVIRONMENT`

Do not substitute an uncontrolled file.

## 8. Fresh P01 — forced System / H.264 MP4

Rerun P01 on the corrected exact source. Do not inherit the old P01 PASS.

Require:

- forced System;
- visible real frame;
- 20 s / 1280x720 plausibly correct;
- PLAYING;
- pause/resume;
- seek ~50%;
- seek ~90%;
- resume after seeks;
- COMPLETED/EOF;
- leave/release cleanly;
- no MPV fallback.

The PlayerPage surface conversion changed shared UI integration, so a fresh System smoke is mandatory even though System ignores the explicit backend surface-size property.

## 9. Fresh P02 — forced MPV / H.264 MP4

This is the correction gate.

Require all:

### Unified state

- after automatic open/play flow, UI reaches PLAYING rather than remaining READY;
- pause action is visibly available;
- pause changes to PAUSED;
- resume returns to PLAYING;
- progress continues while PLAYING.

### Surface

- real video is visible;
- video is rendered using the actual XComponent surface bounds;
- the prior small lower-left density-scaled rectangle must not recur;
- normal aspect-preserving letterbox/pillarbox is acceptable;
- do not require stretching or cropping to fill every black pixel.

### Seek

- seek ~50%;
- seek ~90%;
- seek completion is observed;
- playback resumes correctly.

### EOF

- at natural EOF UI becomes COMPLETED / 播放完成;
- keep observing long enough to prove it does not immediately regress to PAUSED due to a trailing playing=false callback;
- record final position/duration.

### Release

- leave removes surface;
- no residual audio;
- app remains responsive;
- clean release.

Any mandatory item failure => STOP with:

`FAIL — MPV PLAYBACK FOUNDATION`

Do not retry or patch.

## 10. P03 — forced MPV / HEVC MKV

Only after P02 fully passes.

Require:

- MPV first frame;
- PLAYING;
- pause/resume;
- seek 50% and 90%;
- completion;
- clean release;
- sane surface rendering.

Failure => STOP with precise MPV foundation classification.

## 11. P04 — Auto / H.264 MP4

Require current baseline commits System when System succeeds.

Validate:

- normal first frame/playback;
- pause/resume;
- seek;
- completion/release;
- no failed MPV candidate event pollution.

Do not tune selector.

## 12. P05 — Auto / HEVC MKV

Require current baseline commits MPV.

Validate:

- normal first frame/playback;
- pause/resume;
- seek;
- completion/release;
- no System candidate event pollution.

Do not tune selector.

## 13. System/MKV capability observation

Run forced System / HEVC MKV once if safe after P01-P05.

Record:

- PASS;
- UNSUPPORTED;
- stable FAIL.

Format support itself is not a Phase 8A gate.

Crash, ANR, unbounded prepare, forced-mode fallback, or unreleased state is a gate failure.

## 14. Negative path

If the controlled corrupt MP4 remains available, test forced MPV.

Require:

- bounded failure;
- no infinite loading;
- no crash/ANR;
- no repeated fallback;
- no private credential/upstream/token leakage;
- valid media can be opened afterward.

If unavailable, record NOT RUN with preflight reason. Do not synthesize a replacement.

## 15. MPV lifecycle

After P01-P05 pass, run 20 MPV open/play/leave cycles on a known-good controlled source.

Every cycle:

- visible first frame;
- PLAYING state;
- short playback;
- leave/release;
- no stale old-session events;
- no residual audio;
- no accumulating black/small surface;
- no crash/ANR.

Also perform if safe:

- one background/foreground round trip;
- one fullscreen/orientation round trip.

The fullscreen/orientation observation must confirm surface sizing remains sane after layout changes.

## 16. MediaProxy behavior

Confirm source architecture remains:

```text
REMOTE_FILE
-> NetworkDirectoryService.openSource
-> RandomAccessSource
-> NetworkFileProxy
-> localhost UUID/token URL
-> backend
```

Require source/runtime evidence for:

- localhost binding;
- no upstream credential/path encoded in proxy URL;
- playback and seek functional over remote source;
- lease released behaviorally after leave.

For exact upstream high-offset/range behavior:

- attempt only read-only evidence already available from the controlled environment;
- do not add production instrumentation;
- if no safe diagnostics surface exists, record `NOT PROVEN`;
- do not infer byte-offset behavior solely from UI seek progress.

Lack of a production diagnostics endpoint by itself is not a Phase 8A failure.

## 17. Interpretation boundaries

Do not claim:

- final Auto policy;
- System-vs-MPV performance ranking;
- broad codec/container capability;
- HDR/Dolby Vision output;
- advanced audio passthrough;
- memory/power/thermal ranking;
- Direct I/O need.

Do not start Phase 8B or the 59-case matrix.

Do not touch thumbnail research branch / Issue #17.

## 18. Security/protection

Scan all publishable evidence for:

- Authorization;
- Cookie;
- password;
- private WebDAV endpoint/server/path;
- proxy token;
- private target/device identifier;
- signing paths/material;
- SSH data;
- private media filenames/labels where they identify the user's library.

The prior independent thumbnail research publication mistake is not precedent. This Phase 8 evidence must remain sanitized.

Before commit, prove all production source/test/build/task files are byte-identical to the tested dispatch HEAD.

Do not publish HAP or private screenshots/configuration.

## 19. Authorized repository output

Codex may update only:

- `docs/PLAYBACK_PHASE8_REPORT.md`
- one new evidence directory:
  `test-lab/playback/phase8a-rerun-1-mpv-state-surface-20261007/`

The old failed evidence directory is immutable.

Suggested new evidence:

- source-state.json;
- required-reading.json;
- correction-review.json;
- dependency/EOL proof;
- fresh verify raw/provenance;
- signing/artifact provenance;
- sanitized target/fixture preflight;
- fresh P01-P05 observations;
- P02 state/EOF/surface evidence;
- optional System/MKV observation;
- negative path;
- lifecycle;
- background/fullscreen observations;
- MediaProxy behavior;
- security review;
- protected audit.

## 20. Publication

After execution:

1. restore signing overlay;
2. prove checkout has only authorized report/new evidence changes;
3. fetch remote;
4. stop on unexpected protected drift;
5. commit report + evidence only;
6. push without force;
7. fetch again;
8. prove remote containment;
9. return full 40-character remotely visible evidence SHA.

## 21. Final classification

Use exactly one primary classification:

- `PASS — PHASE 8A PLAYBACK FOUNDATION ACCEPTED`;
- `FAIL — BUILD`;
- `FAIL — SYSTEM PLAYBACK FOUNDATION`;
- `FAIL — MPV PLAYBACK FOUNDATION`;
- `FAIL — AUTO PLAYBACK FOUNDATION`;
- `FAIL — PLAYBACK LIFECYCLE`;
- `BLOCKED — SIGNING/DEPLOYMENT`;
- `BLOCKED — TEST ENVIRONMENT`;
- `BLOCKED — EVIDENCE NOT PUSHED`;
- another precise infrastructure classification when necessary.

Do not patch source.
Do not tune policy.
Do not implement Direct I/O.
Do not start Phase 8B.
