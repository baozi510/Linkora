# Codex Validation Task

> State: READY
> Task ID: phase8a-rerun-2-fullscreen-viewport-boundary
> Repository: `baozi510/Linkora`
> Branch: `feat/playback-capability-phase8`
> Prior rerun-1 evidence: `e894775c0bc81b39a6217a0a0516cec46158b82b`
> Corrected source: `02e724e16a57b680add342d1b01c886279ab5377`
> Role: BUILD / FOCUSED RUNTIME TEST / EVIDENCE / REPORT ONLY

## 1. Purpose

Validate only the shared PlayerPage fullscreen/orientation correction that stopped Phase 8A rerun 1.

Rerun 1 already produced fresh accepted historical evidence on source `5146ff923900fd73ff25769783fb2d9732cfad5c` for:

- P01-P05;
- forced System/HEVC MKV capability observation;
- corrupt-MPV failure/recovery;
- 20/20 MPV lifecycle;
- background/foreground;
- MPV PLAYING/PAUSED/EOF correction;
- portrait surface sizing.

Do **not** relabel that evidence as if it came from the new source.

The new source changes the shared PlayerPage layout boundary, so this task requires a fresh build/deployment plus focused System and MPV portrait/fullscreen/orientation checks.

If the focused correction passes, GPT may combine rerun-1 functional evidence with rerun-2 layout regression evidence to accept Phase 8A.

Do not run Phase 8B or the 59-case matrix.

## 2. Source safety

Use a new isolated checkout, for example:

`D:\Linkora-playback-phase8a-rerun2`

Do not mutate the user's existing workspace.

Before execution:

1. fetch `feat/playback-capability-phase8`;
2. checkout current remote HEAD;
3. initialize/verify pinned submodules;
4. prove tracked checkout clean;
5. prove rerun-1 evidence `e894775c0bc81b39a6217a0a0516cec46158b82b` is an ancestor of corrected source;
6. prove corrected source `02e724e16a57b680add342d1b01c886279ab5377` is an ancestor of HEAD;
7. run:

```powershell
git diff --name-only 02e724e16a57b680add342d1b01c886279ab5377..HEAD
```

The only permitted result is:

```text
docs/CODEX_VALIDATION_TASK.md
```

Anything else => STOP.

Record actual tested checkout SHA.

## 3. Required reading

Read completely:

1. `docs/AI_WORKFLOW.md`
2. `docs/MASTER_IMPLEMENTATION_PLAN.md`
3. `docs/IMPLEMENTATION_STATUS.md`
4. `docs/SESSION_HANDOFF.md` — CURRENT STATE first
5. `docs/CODEX_VALIDATION_TASK.md`
6. `docs/PLAYBACK_PHASE8_MATE60_RUNBOOK.md`
7. `docs/PLAYBACK_PHASE8_REPORT.md`
8. rerun-1 `fullscreen-geometry.json`
9. rerun-1 published fullscreen screenshot/reference image metadata
10. `entry/src/main/ets/pages/PlayerPage.ets`
11. `scripts/check-player-page-layout.cjs`

Do not treat rerun-1 fullscreen as PASS.

## 4. Read-only correction review

Verify the corrected source before building.

Required structure:

### Shared video surface

`videoSurface()` itself must:

- fill its containing frame with `width('100%')`;
- fill its containing frame with `height('100%')`;
- not own `aspectRatio(16 / 9)`.

### Fullscreen

When `fullScreen=true`:

- PlayerPage renders `videoSurface()` directly inside the full-page Column;
- the surface is therefore constrained by the actual viewport;
- no trailing non-fullscreen `Blank()` participates in the fullscreen layout.

### Non-fullscreen

When `fullScreen=false`:

- PlayerPage retains the existing top bar;
- an outer Stack owns `width('100%').aspectRatio(16 / 9)`;
- `videoSurface()` fills that 16:9 wrapper;
- normal controls/status/Blank remain.

### Surface units

The existing geometry rule must remain:

- ArkUI/gesture geometry stored in vp;
- only values sent through playback `setSurfaceSize` are converted through active `UIContext.vp2px`;
- gesture coordinates remain vp.

### Static regression

`scripts/check-player-page-layout.cjs` must enforce that:

- fullscreen surface does not own the 16:9 ratio;
- non-fullscreen wrapper does;
- surface fills its container.

`verify.ps1` must execute this guard.

No MPV adapter state logic, Auto selector, MediaProxy strategy, Direct I/O or capability policy change is authorized in this correction.

Contradiction => STOP. Do not patch.

## 5. Fresh build gate

Run exactly one normal:

```powershell
ohpm install
```

Use the established strict four-lock EOL-only proof/restore only if the known Windows normalization occurs.

Then run one fresh:

```powershell
./scripts/verify.ps1
```

Required fresh evidence includes:

- architecture fixtures;
- FFmpeg pure;
- analysis pure;
- artifact fixtures;
- MPV mapping 7/7 if inventory is unchanged;
- **Player layout guard PASS marker**;
- actual Hypium count;
- Debug/Release HAR/HAP;
- two exact-nine AArch64 audits;
- final verifier marker.

Any failure => STOP:

`FAIL — BUILD`

Do not patch or rerun after a source/test failure.

## 6. Fresh exact-source signed HAP

After build PASS:

- use the accepted signing-only root overlay procedure;
- do not change SDK/module/dependencies/ABI/source/build options;
- create one fresh signed default/debug arm64 HAP;
- run the existing exact artifact audit against that HAP;
- record SHA-256 and byte size;
- restore signing overlay to HEAD and prove clean;
- explicitly install that exact HAP on Mate60.

Do not uninstall or clear app data automatically.

Failure => `BLOCKED — SIGNING/DEPLOYMENT`.

## 7. Target and fixture

Use the real Mate60 arm64 target and the same controlled H.264/AAC MP4 used by rerun 1.

Freshly verify the controlled source hash before runtime.

Record sanitized target/build information only.

If the controlled source changed/unavailable:

`BLOCKED — TEST ENVIRONMENT`

## 8. MPV focused portrait preflight

Use forced MPV.

Open the controlled H.264/AAC MP4 fresh.

Before fullscreen, require:

- real first frame;
- PLAYING state;
- normal portrait surface;
- approximately 1216x684 portrait XComponent behavior or current-device equivalent;
- no recurrence of the old density-scaled lower-left rectangle;
- pause/resume works.

This is a smoke regression only; full P02 seek/EOF does not need repetition unless the focused layout flow naturally exercises it.

Failure => `FAIL — MPV PLAYBACK FOUNDATION`.

## 9. MPV fullscreen correction gate

Enter fullscreen/orientation using the production UI.

### Scope clarification: viewport vs MPV scaling policy

This gate validates the **PlayerPage viewport boundary**, not a permanent video scaling policy.

PlayerPage owns only the render viewport. MPV owns how the source image is transformed inside that viewport.

The current production configuration does not expose user-selectable Original / Fit / Fill / Stretch modes in Linkora yet. Therefore this task validates only the **current default MPV display behavior** after the viewport is corrected.

Do not implement or tune mpv `keepaspect`, `video-unscaled`, `panscan`, `video-zoom`, or equivalent display-mode controls in this task.

A future playback UX/capability task may define explicit display modes such as:

- Fit / contain;
- Fill / crop;
- Stretch;
- Original / 1:1.

Those modes must operate inside the correctly sized viewport established here.

This task must not infer that a full-frame default-Fit result means Fill/Stretch/Original are unsupported.



Once stable in landscape, collect fresh raw geometry.

Require:

### Viewport constraint

- record physical landscape screen/viewport dimensions;
- record XComponent original bounds;
- record XComponent visible bounds;
- original XComponent bounds must not exceed the viewport on either axis;
- visible bounds must not indicate bottom/right clipping caused by layout overflow.

For the same class of Mate60 orientation seen in rerun 1, a correct result should be approximately:

```text
viewport: 2688 x 1216
surface:  <= 2688 x 1216
```

Do not hard-code those exact numbers if device/window metrics differ during the fresh run; compare against the actual fresh viewport.

### Visual frame under current default MPV behavior

Using the controlled owned fixture:

- rerun-1 **external layout crop** must not recur;
- with the current default MPV behavior, the full controlled frame should remain visible inside the correctly bounded viewport;
- normal aspect-preserving pillarbox/letterbox is expected and allowed;
- do not require stretching or intentional fill/crop;
- do not interpret this result as a test of future Original / Fill / Stretch modes.

The critical distinction is:

```text
invalid:
MPV renders into an oversized XComponent
-> ArkUI clips the XComponent

valid:
XComponent == actual viewport
-> MPV decides fit/crop/stretch inside that viewport
```


A new sanitized screenshot may be published only if it contains no private source/server/device information.

If visual proof is published, preserve the raw image byte-for-byte and record SHA-256.

### Surface size handoff

Confirm the production layout reports the new fullscreen dimensions through the existing vp->px surface-size path.

Do not add instrumentation.

### Controls / gestures

While fullscreen:

- controls overlay can be shown/hidden;
- pause/resume works;
- at least one production seek gesture/control action works without obviously incorrect horizontal hit geometry;
- no crash/ANR.

Any crop/overflow or broken fullscreen interaction =>

`FAIL — FULLSCREEN LAYOUT`

and STOP.

Do not patch.

## 10. Return to portrait

Exit fullscreen through production UI.

Require:

- orientation returns;
- portrait/non-fullscreen video frame returns to the 16:9 presentation frame;
- no persistent stretched/cropped surface;
- PLAYING/PAUSED state remains coherent;
- controls remain usable.

Then leave player.

Require:

- surface disappears;
- app remains responsive;
- no residual app audio renderer.

## 11. System shared-layout smoke

Because the corrected boundary is shared PlayerPage UI, perform one fresh forced-System fullscreen smoke on the same H.264/AAC MP4.

Minimum required:

- portrait real frame;
- enter fullscreen;
- XComponent bounds do not exceed fresh viewport;
- complete source frame is visible without the same layout crop;
- exit fullscreen;
- leave/release cleanly.

This is not a replay of full P01 and does not require repeating both seeks/EOF unless naturally convenient.

Failure of the shared layout in System mode =>

`FAIL — FULLSCREEN LAYOUT`

## 12. What does not need repetition

If Sections 8-11 pass, do not rerun solely for this task:

- P03 HEVC/MKV full flow;
- P04/P05 Auto;
- O01 System/MKV;
- corrupt MPV;
- 20-cycle lifecycle;
- background/foreground;
- full seek/EOF matrix.

Those results remain separately attributable to rerun-1 source/evidence and are unchanged by this focused PlayerPage layout correction.

If fresh focused behavior contradicts any earlier foundation evidence, stop and report the contradiction.

## 13. MediaProxy

No new MediaProxy proof is required in this focused rerun beyond confirming the same controlled remote media opens and plays.

Exact upstream high-offset/token invalidation remains `NOT PROVEN` unless already safely observable without source changes.

Do not add diagnostics.

## 14. Security

Scan all new publishable evidence for:

- Authorization/Cookie/password;
- private server endpoint/path/alias;
- concrete proxy token;
- private device identifier;
- signing/SSH material;
- private media labels outside the owned controlled fixture.

Do not publish private runtime screenshots.

## 15. Authorized output

Codex may update only:

- `docs/PLAYBACK_PHASE8_REPORT.md`
- one new evidence directory:
  `test-lab/playback/phase8a-rerun-2-fullscreen-viewport-20261007/`

All previous evidence directories are immutable.

Suggested files:

- source-state.json;
- required-reading.json;
- correction-review.json;
- fresh build/provenance;
- signing/artifact provenance;
- target/fixture preflight;
- mpv-portrait-smoke.json;
- mpv-fullscreen-geometry.json;
- mpv-fullscreen-observation.json;
- mpv-return-portrait.json;
- system-fullscreen-smoke.json;
- security-review.json;
- protected-audit.json;
- sanitized raw screenshot(s) only if safe.

## 16. Publication

After completion:

1. restore signing overlay;
2. prove only authorized report/new evidence changes exist;
3. fetch remote;
4. stop on unexpected protected drift;
5. commit report + evidence only;
6. push without force;
7. fetch again;
8. prove remote containment;
9. return the full 40-character remote evidence SHA.

## 17. Final classification

Use exactly one primary classification:

- `PASS — PHASE 8A FULLSCREEN CORRECTION VERIFIED`;
- `FAIL — BUILD`;
- `FAIL — MPV PLAYBACK FOUNDATION`;
- `FAIL — FULLSCREEN LAYOUT`;
- `BLOCKED — SIGNING/DEPLOYMENT`;
- `BLOCKED — TEST ENVIRONMENT`;
- `BLOCKED — EVIDENCE NOT PUSHED`;
- another precise infrastructure classification if necessary.

Do not patch source.
Do not tune Auto.
Do not implement Direct I/O.
Do not start Phase 8B.
Do not touch thumbnail research / Issue #17.
