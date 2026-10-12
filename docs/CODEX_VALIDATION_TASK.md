# Codex Validation Task — Level 0 PlaybackEngine Stale Async Session Review

> STATE: READY
> TASK_ID: phase8f-level0-playback-engine-stale-async-review
> REPOSITORY: baozi510/Linkora
> BRANCH: feat/playback-capability-phase8
> LEVEL: LEVEL_0_FEATURE — READ-ONLY STATIC REVIEW
> SOURCE_SHA: 96a6b802a4a2796f9ffefca74f80541a0ce9fcb9
> ALLOWED_DRIFT: docs/CODEX_VALIDATION_TASK.md ONLY
> BASE_SHA: 61494cda50fae092647db5133e781d2105063d52
> PREVIOUS_KEYSTORE_TASK: phase8f-level1-keystore-access-reuse-unsigned-smoke-v4 (CLOSED)
> PRIOR_VALIDATION_EVIDENCE_SHA: 2763174a67da32332754d745a0de174328c7128f
> KEYSTORE_STATUS: USER-REPORTED UNAVAILABLE — DEFERRED
> BUILD_COUNT_ALLOWED: 0
> SIGNING_AND_KEYSTORE_PROBE_ALLOWED: 0
> SIMULATOR_AND_MEDIA_OPENS_ALLOWED: 0
> ROLE: INDEPENDENT SOURCE-LEVEL CORRECTNESS REVIEW OF NEW SESSION-RACE FIX AND AUTHORED REGRESSION CASES

## 0. Purpose, priority and hard scope

This is a new, meaningful **Level 0 feature review task**, not a retry of stopped V4 signing or Phase8F runtime. GPT owns production code and created SOURCE_SHA with a narrow change to `PlaybackEngine` and its four deferred-async regression tests. Keystore is unavailable, so all installation, signed simulator runtime and actual picture/position/native release acceptance are still blocked. No new build is required after every source edit.

**Prohibited entirely:** `ohpm install`, Hvigor/Hypium execution requiring SDK build, `verify.ps1`, `verify-simulator.ps1`, ARM64/Release/HAP/native rebuild, keystore/password/profile/keytool/sign-app inspection or probing, DevEco/SDK settings, HDC/emulator/device commands, signed/unsigned HAP, fixtures, media/HTTP/rport, UI tests, original STOP helper, private historical logs or old 110-file evidence. No password question, credential guesses, private environment changes, timers/chat polling or repeated diagnostic shell wrappers. Do not modify production source, tests, dependencies, scripts, configs, CURRENT state docs or old task evidence. Do not touch the user's original potentially dirty workspace or a stopped checkout; use a fresh isolated read-only clone.

Read latest `docs/AI_WORKFLOW.md` (scoped errors and feature-first), `docs/MASTER_IMPLEMENTATION_PLAN.md`, `docs/ARCHITECTURE_TARGET.md`, `docs/ARCHITECTURE_MIGRATION.md`, current `docs/IMPLEMENTATION_STATUS.md`, `docs/SESSION_HANDOFF.md`, and this entire task. Any optional unavailable read that is not needed to establish source or review case must be RECORD_ONLY, not a global STOP.

## 1. Git provenance — CRITICAL if claiming THIS source was reviewed

Fresh-fetch exact remote branch. Verify READY/current ID, dispatch full40 SHA, SOURCE_SHA `96a6b802a4a2796f9ffefca74f80541a0ce9fcb9` is its **direct parent**, and SOURCE..dispatch changed path is EXACTLY `docs/CODEX_VALIDATION_TASK.md`. The previous head BASE_SHA `61494cda50fae092647db5133e781d2105063d52`→SOURCE diff MUST be EXACTLY:
```text
linkora_core/src/main/ets/playback/PlaybackEngine.ets
entry/src/test/PlaybackEngine.test.ets
docs/IMPLEMENTATION_STATUS.md
docs/SESSION_HANDOFF.md
```
Confirm the prior fixed entry native adapters' Git blobs remain `1050012dbef214efba5ebccb5571cc9174345c08` (Adaptive) and `cc78c2611e8582633f2a67cb323f3072f5d8a31f` (System), equal to historical production fix SHA `8174e6e4f0214958fb83fef46e92170c4c10263a`. Source mismatch is GLOBAL_SAFETY_STOP for source-specific approval, not permission to test a different SHA. No guesswork about `PlaybackPort.ets`: actual contract is `linkora_core/src/main/ets/playback/PlaybackPort.ets`.

## 2. Independent static functional review (no execution claims)

Read complete old/new `linkora_core/src/main/ets/playback/PlaybackEngine.ets`, `linkora_core/src/main/ets/playback/PlaybackPort.ets`, complete old/new `entry/src/test/PlaybackEngine.test.ets`. Review actual code and reason through these scenarios as distinct cases:

1. Old active port's `togglePlayback()` has in-flight `pause()` or `play()`; after a newer `open()` or `release()`, old Promise rejects. Verify old failure cannot mark new session ERROR, increment the NEW session ID or release a new active port. A failure for the *same* currently active port must still yield a genuine ERROR and release.
2. Old active port raises `onInterruptionPause`; its Promise rejects after new playback has been selected. Verify the old async catch is gated by BOTH old session identity and same port. No swallowed error for the still-active port.
3. A replacement `open()` awaits slow previous-port `release()`; a later `release()` wins meanwhile. Verify stale open cannot reset snapshot, show PREPARING, create new native port or autoplay after the newer release.
4. An earlier `release()` awaits slow port disposal; a newer `open()` successfully enters PLAYING. Verify old completion cannot turn current snapshot to RELEASED.
5. Inspect existing asynchronous observer/session ID handling, `failActivePort`, double-release and late callback implications for correct unrelated behavior. Flag any **specific** remaining race or missing owner check (with exact paths/functions and a safe reasoned trace), but don't claim that a behavior has been reproduced experimentally.
6. Review four newly authored Fake/DeferredPause/DeferredRelease Hypium cases: whether they deterministically stage the intended race and assert the **right observable state and port identity**, whether they would fail before the fix, whether ArkTS typing/library idioms are plausible, and whether they cause unresolved Promises or cleanup hangs. Do not run Hypium or compiler; if static uncertainty remains, `REVIEW UNKNOWN — COMPILATION NOT RUN`, not PASS.

**Sufficient review evidence:** exact SHA, diff path list, risk matrix and concise code-level reasoning for each case. No need for screenshot, native logs, simulator, gzip archives, 33-pair inventories, hash chains or custom Python/PowerShell helper. Optional metadata read failure is RECORD_ONLY; continue independent checks. An actual source/test semantic gap is `SOURCE REVIEW FINDING`, not an automatic global task abort. Do not make any production fix (GPT owns implementation).

## 3. Report and remote review handoff

Allowed ONE new public file ONLY, if ordinary publication remains safe:
```text
docs/PLAYBACK_PHASE8F_LEVEL0_STALE_ASYNC_STATIC_REVIEW.md
```
Brief Markdown report:
- exact task/source/dispatch full40 SHAs and audited paths;
- each of four race scenarios `STATIC OK / STATIC FINDING / UNKNOWN`;
- test source inspection verdict (authored, not executed);
- any concrete issue with file/function/causal trace;
- `BUILD NOT RUN / TESTS NOT RUN / SIGN NOT RUN / RUNTIME NOT PROVEN`;
- privacy/path/write-protection status, final `READY FOR NEXT LEVEL0 FEATURE WORK` or `NEEDS GPT SOURCE FIX`;
- no inherited historical playback/native release PASS.

Before publication inspect actual candidate whole text for secrets/private machine or device IDs/paths/host URLs/credential/profile material. Stage explicitly this ONE path, inspect raw `git diff --cached --name-only` and mode/blob, ensure EXACTLY this file is staged. Confirm remote head still dispatch, one normal no-force commit/push, fresh remote fetch and report readback; return true 40-digit remote evidence SHA. If Git publication fails, `PUBLICATION_BLOCKED`; retain local review status, do not redo source review, compile or retry failed wrappers. No new result JSON needed.

This is a **source review only**; even `STATIC OK` is not a successful build or actual simulator/native test. If the task is blocked by genuinely unsafe source identity or privacy, protect the repository and report honestly. No repeated autonomous dispatch to turn optional helper errors green.

## 4. Final response requirements

`REVIEW_RESULT / STATE / TASK_ID / LEVEL / REPOSITORY / BRANCH / SOURCE_SHA / DISPATCH_SHA / PRODUCTION_DIFF / ADAPTER_BLOBS_UNCHANGED / FOUR_STATIC_RACE_VERDICTS / REGRESSION_TESTS_AUTHORED_NOT_RUN / BUILD_STATUS=NOT RUN / SIGNING_STATUS=NOT RUN / SIMULATOR_MEDIA_STATUS=NOT RUN / KEYSTORE=DEFERRED / SOURCE_FINDINGS / REPORT_PATH / REMOTE_EVIDENCE_SHA_OR_NONE / ORIGINAL_WORKSPACE_NONMUTATION_LIMITS / NEXT_ACTION`.

If all source checks pass, conclude `STATIC REVIEW COMPLETE — NOT RUNTIME VALIDATION`. Do not invoke SDK, install HAP or claim cancellation/recovery native PASS. After receipt GPT independently reviews GitHub source/evidence and decides the next meaningful source feature or (later) milestone testing step.
