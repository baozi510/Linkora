# Codex Task — Normal DevEco Simulator Run, No Manual Keystore Gate

> STATE: READY
> TASK_ID: phase8f-level1-normal-deveco-simulator-run-v1
> REPOSITORY: baozi510/Linkora
> BRANCH: feat/playback-capability-phase8
> LEVEL: LEVEL_1_FUNCTIONAL — NORMAL SIMULATOR RUN
> SOURCE_SHA: b51d0be18f8e5ed31e9b8f1ed7893846aacad9b3
> ALLOWED_DRIFT: docs/CODEX_VALIDATION_TASK.md ONLY
> PREVIOUS_COMPLETED_TASK: phase8f-level0-stale-open-catch-barrier-review-v2 — CLOSED
> HISTORICAL_SIGN_FAILURE_EVIDENCE_SHA: d4905fe4b00f74681e9ff44e0a3102b9679e7ad6
> HISTORICAL_V4_KEYSTORE_EVIDENCE_SHA: 2763174a67da32332754d745a0de174328c7128f
> USER_GOAL: ACTUAL LINKORA APP RUNNING IN X86_64/API26 SIMULATOR
> NORMAL_ENTRY: DEVECO STUDIO RUN / simulator PRODUCT / entry@simulator TARGET
> MANUAL_SIGN_APP_ATTEMPTS: ZERO
> OLD_KEYSTORE_PROBES_OR_PASSWORD_READS: ZERO
> MAX_SCOPED_SIMULATOR_DEBUG_COMPILES: ONE
> FULL_ARM64_DEFAULT_BUILDS: ZERO
> RELEASE_AND_PHYSICAL_DEVICE: DEFERRED

## 0. Correction: simulator does NOT require our old manual keystore gate

The user explains that ordinary DevEco Studio simulator Run used to work without a complicated keystore process. GPT checked Huawei's official developer guide at https://developer.huawei.com/consumer/cn/develop-novice-guide/ and normal simulator Run instructions at https://developer.huawei.com/consumer/cn/doc/doccenter-deveco-studio/ide-emulator-create : simulator/previewer debug does NOT require configured signing information, unlike physical-device deployment. Existing repository `build-profile.json5` has `app.signingConfigs: []`, product `simulator`; `entry/build-profile.json5` has `entry@simulator` x86 entry target. Existing `scripts/verify-simulator.ps1` builds/audits but does not install/start; the earlier extra standalone SDK `sign-app` command failed on the old keystore. That outcome is historical and **must not be repeated or promoted to an actual simulator-install failure**.

**Primary instruction:** use the *normal DevEco Studio Run* flow on the actual current isolated project with selected simulator product/entry target; do **NOT** add any standalone manual SDK `sign-app`, ask for passwords, restore old keystore, generate new signing profiles, force an insecure install or modify global IDE/SDK settings. If a real IDE/installer failure occurs, report its true code; never automatically assume it is 11014003. App running means installed current-source code, foreground Linkora-owned visible pixels, not a compiler exit0 or an empty launcher.

## 1. Source and safety baseline

1. Fresh-fetch latest remote GitHub branch; require this READY task's dispatch full40 SHA directly descends from SOURCE_SHA `b51d0be18f8e5ed31e9b8f1ed7893846aacad9b3` with EXACT `docs/CODEX_VALIDATION_TASK.md` as its sole changed path. The preceding `49292ecd90659c3ac318f9067b4cd6e64ed9b1c6`→SOURCE changes exactly `docs/AI_WORKFLOW.md`, `docs/MASTER_IMPLEMENTATION_PLAN.md`, `docs/IMPLEMENTATION_STATUS.md`, `docs/SESSION_HANDOFF.md`. Read those latest docs and SOURCE's app and entry build profiles, existing simulator run/build docs, actual `linkora_core` contracts, and current entry app ability. Verify fresh isolated source checkout clean. Adaptive and System production Git blobs should still be `1050012dbef214efba5ebccb5571cc9174345c08`, `cc78c2611e8582633f2a67cb323f3072f5d8a31f`; PlaybackEngine source is NEWER than original unsigned artifact.
2. **Protect original possibly dirty `D:/Linkora` and any previously stopped private evidence checkout.** No reset, clean, stash, checkout, build, signer or IDE project writes there; open ONLY a fresh isolated checkout in IDE. No system-level emulator wipe/reset/reconfiguration, removal of existing user app, stopped task modifications, key/profile changes, unauthorized shared dependency installs. IDE may create its ordinary isolated-clone build outputs only.
3. Treat source identity and user-workspace safety as CRITICAL. An absent optional file/metadata is RECORD_ONLY and must not abort independent stages. No old auxiliary Python/PowerShell wrapper, controller, progress monitor, hash inventory loops or reporter scripts.

## 2. Cheap readiness, then ONE NORMAL IDE RUN

1. Query actual emulator state (HDC read-only) and ensure a running user-authorized target with **x86_64 / API26**. Prior V3/V4 recorded a running target, but do not inherit PASS. No `-config`, undocumented emulator JSON parsing, instance/profile changes, or wipe; if absent, allow at most one normal non-destructive documented IDE start of existing simulator; if still unavailable `DEPENDENCY_BLOCKED — SIMULATOR`; compile/install/opens NOT RUN, continue safe source/report.
2. Before building check source identity, installed IDE Run configuration and actual selected **product `simulator` / target `entry@simulator`**, and existence of only already-approved MP4 and HLS H264 fixtures without regeneration. Do not preflight previous certificate/password/profile; these are NOT gates for normal simulator Run. If normal IDE GUI access/Run config cannot be driven safely, `DEPENDENCY_BLOCKED — IDE RUN CONTROL` with build0, no invented fallback signer or exploratory setup scripts.
3. Invoke normal DevEco Studio `Run` **ONCE** for the current isolated checkout, selected simulator target and currently running simulator. Permit at most **ONE** ordinary scoped x86 simulator Debug compilation as part of this Run; do NOT separately run `scripts/verify-simulator.ps1` or `scripts/verify.ps1` after Run, no default ARM64/triple build, no extra ohpm install unless IDE's ordinary Run intrinsically performs its normal dependency resolution. IDE Run may handle its own development deployment automatically, but DO NOT call standalone manual `sign-app` with old credential-bearing argv, and do not add a new keystore.
4. Capture real IDE/child compile result, generated package source/provenance, product x86 Native whitelist from read-only HAP inspection when feasible, genuine deployment/install result and Ability foreground. If build FAIL, runtime NOT RUN; if install FAIL, preserve actual distinct native error and leave UI/media NOT RUN; **do not repeat build, change signing or uninstall other user app**. If ordinary Run says signing is required on this specific image, record that factual prompt/error and STOP only dependent install/runtime; report actual circumstance and proposed smallest next change. Do not infer the old manual keystore is mandatory in general.
5. Require actual Linkora application foreground Ability, Linkora-owned visible non-empty layout/window and private screenshot/pixel evidence. A package listed as installed or a launcher alone is not PASS; installed no UI means `BLOCKED — APP FOREGROUND`. Do not publish screenshots/device IDs.

## 3. Only after actual Linkora UI — three focused opens, dependency scoped

Use the already user-owned MP4/HLS H264 approved fixture route and the smallest necessary user-owned temporary local server/reverse mapping (only if the UI is genuinely ready and existing approved route isn't active; do not touch unrelated listeners/settings). No other format matrix.

- **Healthy MP4**: one actual System backend open, first frame/pixel/color change, positive playback position and target-side media GET when relevant. Record PASS/FAIL independently.
- **HLS H264 PREPARING cancellation**: one independent normal native System AVPlayer prepare-start then leave strictly before prepared, correlated actual pending candidate release, suppressed stale callbacks/Auto fallback, early ~3–5s and >20s app-associated audio/surface/resource zeros without force-stop. May run even if MP4 FAIL if app/native state is safe; do not retry it to green the result.
- **Distinct MP4 recovery**: ONLY if prior HLS normal pending native release/cleanup positively proven. New real playback frames/color and position required; otherwise NOT RUN/NOT PROVEN.

If actual UI is installed but required fixture route unavailable, record UI PASS and media `DEPENDENCY_BLOCKED — FIXTURE ROUTE` (not global STOP). Unknown native counters/possible session contamination cannot become a release PASS. Cleanup only temporary task-owned server/mappings, not simulator/other user's configuration or app via force stop. All real ARM64 MPV/native/DV/HDR/HEVC/FFV1/audio/hardware/performance are DEFERRED Level2/Level3.

## 4. One concise sanitized evidence report, no publication loops

Only NEW public file permitted:
```text
docs/PLAYBACK_PHASE8F_NORMAL_IDE_SIMULATOR_RUN_REPORT.md
```
Write what happened: SHA, running-target read-only result, IDE/product/entry target selection, number of actual x86 Debug compilations and exit(s), real install/native result, actual Linkora UI foreground & visible pixel determination, each media case attempts/status, no manual signing, resource observations or NOT PROVEN, privacy/original workspace limits, and next smallest action. Never include keystore/password/secret, private device IDs or full URLs, private paths, HAP, screenshots, media, raw logs, PIDs, other user process info. Keep raw logs private.

Privacy and path containment are publication-only CRITICAL gates. Stage ONLY the exact public report path, directly check actual `git diff --cached --name-only` and modes, no brittle custom wrapper; one ordinary non-force commit/push if candidate is safe, fresh-fetch remote HEAD, exact one-parent task SHA and one-file diff, remote readback. If publication fails keep local observations `LOCAL UNREVIEWED`, do not rerun IDE build/playback just for evidence. Previous stopped evidence and private historical records untouched.

## 5. Final truthful result and closure

Fields: `REVIEW_RESULT / STATE / TASK_ID / SOURCE_SHA / DISPATCH_SHA / IDE_RUN_INVOCATIONS / X86_DEBUG_BUILD_COUNT / MANUAL_SIGN_COUNT=0 / OLD_KEYSTORE_PROBE_COUNT=0 / SIMULATOR_ACTUAL_TARGET / INSTALL_RESULT / FOREGROUND_LINKORA_PIXELS / HEALTHY_MP4 / HLS_PREPARING_CANCEL_NORMAL_RELEASE_EARLY_20S / RECOVERED_MP4 / OTHER_FORMATS_DEFERRED / ORIGINAL_WORKSPACE_LIMITS / PUBLIC_REPORT_SHA_OR_NONE / FIRST_REAL_BLOCKER / NEXT_ACTION`.

A legitimate narrow result can be `UI PASS, MEDIA NOT RUN` (fixture route blocked), `BUILD PASS, INSTALL FAIL` (actual simulator install denied) or `DEPENDENCY_BLOCKED — IDE CONTROL`; do not turn them into global product failure, keystore failure or fabricated runtime PASS. User goal is actual running simulator app, not optional tooling perfection. This is ONE authorized meaningful simulator Run attempt, not an unlimited test loop.
