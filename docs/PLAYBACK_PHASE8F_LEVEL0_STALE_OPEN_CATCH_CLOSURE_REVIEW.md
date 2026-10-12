# Phase 8F narrow stale-open catch closure review

What this change does: The failed-open catch now rechecks session ownership after asynchronous disposal. The deferred pause fake exposes its original Promise and an ordered rejection barrier; a new regression waits for actual disposal entry before starting replacement playback.

REVIEW_RESULT: STATIC REVIEW COMPLETE — PRIOR TWO FINDINGS ADDRESSED (NOT RUNTIME PASS).
STATE: COMPLETED — STATIC REVIEW ONLY.
NEXT_ACTION: READY FOR NEXT LEVEL0 FEATURE WORK.

- TASK_ID: phase8f-level0-stale-open-catch-barrier-review-v2
- REPOSITORY / BRANCH: baozi510/Linkora / feat/playback-capability-phase8
- LEVEL: LEVEL_0_FEATURE — SOURCE/TEST STATIC REVIEW ONLY
- SOURCE_SHA: b5fb32b5aaacfa46f092a02238790832b2c31273
- DISPATCH_SHA: a0f6dfb0b07333222ba9826acf56d0dad6854c8b
- FIX_BASE_SHA / PREVIOUS_EVIDENCE_SHA: 279fb2216de0e97abec684d82476840826efd05d

## Source binding

Fresh isolated clone and fresh fetch matched exact dispatch; SOURCE is its direct parent, and SOURCE-to-dispatch changed only `docs/CODEX_VALIDATION_TASK.md`. Initial clone was clean. FIX_BASE-to-SOURCE changed exactly `linkora_core/src/main/ets/playback/PlaybackEngine.ets`, `entry/src/test/PlaybackEngine.test.ets`, `docs/IMPLEMENTATION_STATUS.md` and `docs/SESSION_HANDOFF.md`.

Adaptive/System blobs are unchanged at `1050012dbef214efba5ebccb5571cc9174345c08` / `cc78c2611e8582633f2a67cb323f3072f5d8a31f`, compared with production fix `8174e6e4f0214958fb83fef46e92170c4c10263a`. Current workflow and latest CURRENT status/handoff were read. Master Plan and architecture documents were revalidated against same-session readings: no changes from the previous reviewed evidence. Complete old/new engine and tests plus actual PlaybackPort were read. The completed earlier four-case survey was not rerun or amended.

## Three narrow checks

| Check | Verdict | Static causal evidence |
| --- | --- | --- |
| 1. Failed-open post-disposal ownership | STATIC OK | `PlaybackEngine.open` lines 75–83 checks captured session both before disposal and again after await/before `fail`. `releaseCurrentPort` clears the captured old slot before awaiting its release. A rejected prepare/play enters disposal; B open obtains a greater ID and reaches PLAYING; A completion now skips failure. A newer release likewise retains RELEASED. With no newer operation, the ID remains equal, so genuine same-current prepare failure still reaches ERROR with the original error mapping. The old code lacked the second check and would overwrite the newer snapshot. |
| 2. Deferred failed-open regression | STATIC OK | `ignoresLateFailedOpenAfterDisposalWhenNewSessionIsPlaying` at test lines 452–491 awaits `firstPortCreated`, then `oldPort.releaseStarted`, not an arbitrary tick. The failing fake throws without observer error, so this signal comes from open's catch disposal after its port slot was cleared. Release stores its finish resolver synchronously before the awaiting test can resume. B open then reaches PLAYING; the test finishes A release and awaits `failedOpen` before checking two ports, old released/new unreleased, PLAYING and null failure. Normal-path deferred promises settle; new current-port release is also awaited. On FIX_BASE engine, A would publish ERROR/non-null failure before `failedOpen` completes, failing the final assertions. This is a static counterfactual, not an executed old/new test. |
| 3. Interruption rejection completion barrier | STATIC OK | `DeferredPausePort.pause` lines 95–101 returns the actual stored deferred Promise without async adoption. `pauseForInterruption` attaches its synchronous rejection handler to that Promise during the interruption call. Later `failPendingPause` lines 103–112 rejects it and attaches a second catch to the identical Promise; the earlier engine reaction precedes this later barrier reaction. Awaiting the returned barrier means engine state mutation would have occurred before test assertions, including with the older unguarded interruption catch. The changed test no longer depends on a single unrelated `Promise.resolve()` tick. The toggle case awaits both this barrier and its original `stalePause` operation. |

The existing `preservesSpecificPrepareFailure` (lines 516 onward) still uses a prepare rejection without observer error and asserts ERROR, mapped original failure and old-port release. The new guard preserves that same-current path. The newer-release variant is source-reasoned, not a newly executed or separately authored variant. Fake single-pending-operation usage matches these cases; no normal-path circular Promise wait or fake deadlock is apparent. Runner timeout/cleanup behavior after an assertion failure was not exercised.

ACTUAL_SOURCE_FINDINGS: NONE within the two prior findings and three explicitly scoped checks. Prior report findings remain historical; this review does not certify every unrelated engine path or restart the earlier survey.

## Acceptance and publication boundaries

CODE AUTHORED / TESTS AUTHORED BUT NOT RUN. ArkTS/Hypium compilation and execution compatibility is UNKNOWN — COMPILATION NOT RUN; interface signatures and typed deferred callbacks look plausible by inspection only. TESTS_RUN=NO; BUILDS=0; SIGNING_PROBES=0; SIGNING_ATTEMPTS=0; SIMULATOR/DEVICE/MEDIA_OPENS=0; KEYSTORE=UNAVAILABLE — DEFERRED; RUNTIME=NOT PROVEN. No SDK, dependency install/restore, compiler, Hypium, signing/keytool, HDC/emulator, HAP, fixture, media/HTTP, native rebuild, historical private-log/helper or archival operation was performed. No native AVPlayer release, resource-zero, recovered playback, ARM64 or hardware PASS is claimed.

Only this new report is authorized. Whole candidate text was directly inspected: repository-relative paths, public commit/blob IDs and authored reasoning only; no private machine/device/user identifiers, local paths, credentials, profiles, media or raw logs. Exact stage name/mode/blob and remote dispatch are required before ordinary commit/push; final remotely verified evidence SHA is supplied externally after publication/readback. No production/test/config/current-state/previous-evidence file is changed by this executor.

Original user workspace and stopped checkouts were not operated on; source review and report use only the new isolated clone. Exhaustive final bytewise preservation comparison NOT RUN; the claim is limited to observed operations. No runtime resources were created.

Verdict: Looks good for this narrow source closure; resume meaningful Level0 feature development. Later authorized checkpoint/milestone must establish actual compilation/tests; signing-dependent runtime remains deferred.
Not checked: compilation, Hypium execution, simulator/native lifecycle/resources, physical devices or complete product acceptance.
