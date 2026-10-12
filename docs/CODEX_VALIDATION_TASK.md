# Codex Task — Phase 8F Level-0 Narrow Stale-Open Error Closure Review

> STATE: READY
> TASK_ID: phase8f-level0-stale-open-catch-barrier-review-v2
> REPOSITORY: baozi510/Linkora
> BRANCH: feat/playback-capability-phase8
> LEVEL: LEVEL_0_FEATURE — SOURCE/TEST STATIC REVIEW ONLY
> SOURCE_SHA: b5fb32b5aaacfa46f092a02238790832b2c31273
> ALLOWED_DRIFT: docs/CODEX_VALIDATION_TASK.md ONLY
> FIX_BASE_SHA: 279fb2216de0e97abec684d82476840826efd05d
> PRIOR_COMPLETED_TASK_ID: phase8f-level0-playback-engine-stale-async-review
> PRIOR_COMPLETED_REPORT_SHA: 279fb2216de0e97abec684d82476840826efd05d
> PREVIOUS_KEYSTORE_TASK: phase8f-level1-keystore-access-reuse-unsigned-smoke-v4 — CLOSED
> KEYSTORE: USER-REPORTED UNAVAILABLE; SIGNING/RUNTIME DEFERRED
> MAX_BUILDS: 0
> MAX_HYPIUM_EXECUTIONS: 0
> MAX_SIGNING_PROBES_OR_ATTEMPTS: 0
> MAX_SIMULATOR_DEVICE_MEDIA_OPENS: 0

## 0. Why this new task exists

The prior `phase8f-level0-playback-engine-stale-async-review` was COMPLETED WITH FINDINGS, not runtime PASS. It produced one independently reviewed GitHub report at `279fb2216de0e97abec684d82476840826efd05d`. **Do not execute or amend the completed prior ID, and do not rerun earlier sign/build/SDK helper failures.** GPT independently reviewed its two findings and authored the smallest source/test correction in SOURCE_SHA.

This is a **single narrow follow-up static review**, not a restart of the earlier four-case survey and not another gratuitous compilation. No new code changes are permitted to Codex; report concrete remaining findings to GPT. If these exact concerns are statically addressed, record source review closure and return to meaningful Level0 product development, **not an endless repeat review cycle**.

## 1. Bound actual source (critical)

Fetch the exact remote branch, verify current task READY and its actual full40 dispatch SHA. SOURCE_SHA `b5fb32b5aaacfa46f092a02238790832b2c31273` must be the dispatch's immediate parent, and SOURCE..dispatch must change **only** `docs/CODEX_VALIDATION_TASK.md`. FIX_BASE_SHA `279fb2216de0e97abec684d82476840826efd05d`→SOURCE must change **exactly**:
```text
linkora_core/src/main/ets/playback/PlaybackEngine.ets
entry/src/test/PlaybackEngine.test.ets
docs/IMPLEMENTATION_STATUS.md
docs/SESSION_HANDOFF.md
```
Check entry native Adapter blobs remain Adaptive `1050012dbef214efba5ebccb5571cc9174345c08`, System `cc78c2611e8582633f2a67cb323f3072f5d8a31f`, unchanged since production fix `8174e6e4f0214958fb83fef46e92170c4c10263a`. Read the current workflow/feature-first/scoped-error policy and latest current status/handoff. Use clean NEW isolated read-only checkout and actual Git file tree; original possibly dirty user workspace, stopped worktrees and private unsigned HAP must not be touched.

## 2. Review exactly the two prior findings and their regression protection

Read entire SOURCE `linkora_core/src/main/ets/playback/PlaybackEngine.ets`, `entry/src/test/PlaybackEngine.test.ets` and corresponding FIX_BASE old versions, plus `linkora_core/src/main/ets/playback/PlaybackPort.ets`. Then judge with actual path/function and causal trace:

1. **Must-fix stale open catch:** Original `open()` catches prepare/play error, checks session once, awaits `releaseCurrentPort()` and then publishes `fail`. New source must check captured session **again after await and before fail**. Reason through A rejected prepare without observer error → A disposal begins and clears slot → B `open()` succeeds to PLAYING → A finishes disposal; B port and snapshot must survive. Also consider newer release's RELEASED snapshot; and same-current genuine prepare failure must still report ERROR.
2. **New deferred failed-open regression:** `ignoresLateFailedOpenAfterDisposalWhenNewSessionIsPlaying` must deterministically observe A release is already entered (do not rely on an arbitrary microtask tick), get B into PLAYING, finish A release, await A open, then assert B active/PLAYING and no old failure. Check Promise settlement, no fake deadlock and expected test would FAIL on FIX_BASE source. Also inspect existing `preservesSpecificPrepareFailure` as same-current error protection.
3. **Should-fix audio interruption test ordering:** fake `DeferredPausePort.pause()` must return the **actual original deferred promise** (no async adoption), and test must await a handler-completion barrier where the engine's existing rejection handler was attached BEFORE the barrier subscriber. Evaluate `failPendingPause()` return/await and the engine interruption .catch job order to ensure assertions cannot run before old unguarded engine failure would mutate current state. Check old toggle pause test remains properly awaited.
4. State any concrete source/test flaw with exact file/function and conditions. Report `STATIC OK / STATIC FINDING / UNKNOWN` for each. No compiler execution: ArkTS/Hypium compatibility remains UNKNOWN until milestone/authorized checkpoint. Don't invent native AVPlayer lifecycle/physical resource proof.

**No tests, compilation or expensive environment activity**: prohibit `ohpm install`, dependency restore, `verify.ps1`, `verify-simulator.ps1`, Hvigor/Hypium, signing/keystore tooling, HDC/emulator/devices, HAP, host media, HTTP/network fixtures, native rebuild, archival compression, old controller, user workspace updates. Read-only Git/file/semantic inspection suffices. Optional missing file lookup is RECORD_ONLY; required source identity mismatch is genuine safety STOP for source approval only. A review finding does not erase independent static checks or trigger a build.

## 3. One short report if safe; no evidence-archiving loop

Only allowed NEW public output:
```text
docs/PLAYBACK_PHASE8F_LEVEL0_STALE_OPEN_CATCH_CLOSURE_REVIEW.md
```

Produce concise source+dispatch IDs, old/new specific code traces, verdict for each of 3 narrow checks, any source finding, `CODE AUTHORED / TESTS AUTHORED BUT NOT RUN`, `BUILD NOT RUN`, `KEYSTORE DEFERRED`, `SIMULATOR/RUNTIME NOT PROVEN`, and a crisp next action. No screenshots, raw logs, local machine/credential/device identifiers or copies of old evidence. Optional tools/extra JSON/gzip/manifest inventories are not required.

If publishing: inspect all candidate public text for secrets/privacy; stage ONLY this one exact file, inspect actual Git staged name/mode/blob, fresh-fetch remote head equal task dispatch before one normal nonforce commit/push, and independently fresh-fetch same evidence full40 SHA, one-parent dispatch ancestry, one changed path and remote readback. If unavailable, `PUBLICATION_BLOCKED` with local static result preserved; no repetitive helpers, no retest.

Final reply: `STATE; TASK_ID; SOURCE_SHA; DISPATCH_SHA; PREVIOUS_EVIDENCE_SHA; THREE_STATIC_VERDICTS; TESTS_RUN=NO; BUILDS=0; SIGNING=0; RUNTIME=NOT PROVEN; GITHUB_REPORT_SHA_OR_NONE; ACTUAL_SOURCE_FINDINGS; NEXT_ACTION`.

A clean review concludes `STATIC REVIEW COMPLETE — PRIOR TWO FINDINGS ADDRESSED (NOT RUNTIME PASS)`. If a specific issue remains, `NEEDS GPT MINIMAL SOURCE FIX`; Codex must not modify source/tests. Do not autonomously issue another validation dispatch or recheck the deferred keystore.
