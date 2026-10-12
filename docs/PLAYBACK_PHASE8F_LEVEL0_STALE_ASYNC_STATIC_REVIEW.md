# Phase 8F Level-0 stale async static review

What this change does: Captured session and port identity keep replaced pause/play failures from failing current playback. New checks after previous-port disposal prevent stale open/release success paths from overwriting a newer snapshot. This is a source review, not an executed regression or native acceptance.

REVIEW_RESULT: STATIC REVIEW COMPLETE — NOT RUNTIME VALIDATION; SOURCE REVIEW FINDINGS.
STATE: COMPLETED WITH FINDINGS.
NEXT_ACTION: NEEDS GPT SOURCE FIX.

## Identity and scope

- TASK_ID: phase8f-level0-playback-engine-stale-async-review
- LEVEL: LEVEL_0_FEATURE — READ-ONLY STATIC REVIEW
- REPOSITORY / BRANCH: baozi510/Linkora / feat/playback-capability-phase8
- SOURCE_SHA: 96a6b802a4a2796f9ffefca74f80541a0ce9fcb9
- DISPATCH_SHA: 78ba2a3d9017d0c32198437a52d192c3aafeb58a
- BASE_SHA: 61494cda50fae092647db5133e781d2105063d52
- PRIOR_VALIDATION_EVIDENCE_SHA: 2763174a67da32332754d745a0de174328c7128f

Fresh clone and fresh fetch returned exact dispatch; clean worktree, SOURCE direct parent, and SOURCE-to-dispatch difference exactly `docs/CODEX_VALIDATION_TASK.md`. BASE-to-SOURCE contains exactly:

```text
docs/IMPLEMENTATION_STATUS.md
docs/SESSION_HANDOFF.md
entry/src/test/PlaybackEngine.test.ets
linkora_core/src/main/ets/playback/PlaybackEngine.ets
```

Production diff is only PlaybackEngine; the second code path contains authored tests. Adaptive/System blobs remain `1050012dbef214efba5ebccb5571cc9174345c08` / `cc78c2611e8582633f2a67cb323f3072f5d8a31f`, independently compared with fix `8174e6e4f0214958fb83fef46e92170c4c10263a`.

Read workflow, Master Plan, target/migration, latest CURRENT status/handoff, full task, complete old/new engine and tests, actual PlaybackPort/PlaybackModels, and connected PlayerFeatureController/composition/adapter source. Scope assumes one engine owns one current port, with overlapping asynchronous user operations and backend callbacks. No production/test/config/script/old evidence edits or execution.

## Four required race scenarios

| Case | Source verdict | Reasoned ownership trace | Authored regression inspection |
| --- | --- | --- | --- |
| 1. Old toggle pause/play rejection after open or release | STATIC OK | `togglePlayback` captures session and port (lines 94–118); catch requires both current ID and identical current port. Replacement/release invalidates ID; stale failure cannot call `failActivePort`, change the new ID or dispose the new port. Still-current rejection remains ERROR and captures/releases its own port. | Late pause case awaits the complete `stalePause` operation and checks old released/new unreleased/PLAYING. Before fix, unguarded failure would fail these assertions. Play rejection, intervening release and same-current-port failure are reasoned branches, not newly authored test coverage. |
| 2. Old interruption pause rejection after replacement | STATIC OK | Observer initially gates session, and `pauseForInterruption` catch additionally checks captured session plus port (lines 252–269). Same-current-port rejection still enters genuine failure/disposal. | STATIC FINDING: the test's single microtask wait is not a barrier for this deferred async wrapper; see finding 2. |
| 3. Replacement open awaits old release; newer release wins | STATIC OK | `releaseCurrentPort` clears its slot before awaiting. Newer release increments ID; stale open checks after disposal at lines 46–49 and returns before reset/PREPARING/factory/prepare/play. Old RELEASED callback is stale. | Deferred release is explicitly completed before awaiting `staleOpen`; port count stays one and final RELEASED is asserted. Before fix it would create another port and overwrite the snapshot. No successful-path unresolved deferred promise is apparent. |
| 4. Old release completes after newer open is PLAYING | STATIC OK | Newer open has a greater ID and owns a new port. Old release's final check at lines 168–172 suppresses its RELEASED write; old observer is also stale. | Test completes old disposal, awaits `staleRelease`, then checks two ports/new unreleased/PLAYING. Before fix the unconditional RELEASED write would fail. New current port cleanup is awaited. |

These four STATIC OK code verdicts are limited to the stated traces; they do not approve all engine error continuations. Existing observer callbacks are session-gated. `failActivePort` increments ID and clears/captures the old slot before notifying and releases only that captured port; competing late errors then fail the session gate. Disposal exceptions are swallowed by existing policy, so this cannot prove successful native release or zero resources.

## Must fix

1. **Old open error can overwrite a newer playback after awaited disposal** — `linkora_core/src/main/ets/playback/PlaybackEngine.ets:75–78`, `open` catch; also `releaseCurrentPort:364–374`.

   This existing error path checks session only before an await. Safe reasoned counterexample: open A's prepare/play rejects without a preceding observer error (permitted by PlaybackPort); the catch sees current A, clears A's slot and waits for slow A.release. Open B then finds an empty slot, obtains a higher session ID and reaches PLAYING. When A disposal completes, A unconditionally calls `fail`, so B's snapshot becomes ERROR with A's failure while B's port remains live. A concurrent newer release can likewise have RELEASED overwritten. PlayerFeatureController retry/surface requests can overlap engine operations; its active flag does not filter old engine snapshots while still active.

   This was present at BASE and remains after the narrow fix; it is not claimed to be introduced or experimentally reproduced. Minimal owner correction: recheck captured session after the catch's disposal await before publishing failure, retaining genuine same-session error behavior. Add a deferred-disposal failing-open regression for this trace. Otherwise the main stale-snapshot problem remains on the error branch.

## Should fix

2. **Interruption regression can assert before its failure handler runs** — `entry/src/test/PlaybackEngine.test.ets:93–98,364–383`, `DeferredPausePort.pause` and `ignoresLateInterruptionPauseFailureFromReplacedPort`.

   The async fake returns an inner pending Promise, so its outer Promise adopts the inner result. Rejecting the inner Promise queues adoption propagation; the single `await Promise.resolve()` separately queues the test continuation. That continuation can inspect PLAYING/new-unreleased before the outer rejection's engine catch runs. Under ordinary Promise job order, even the old unguarded catch can pass these assertions, then fail after cleanup begins; there is no post-cleanup assertion. This is a static inference from the code and [ECMAScript Promise job/adoption semantics](https://tc39.es/ecma262/multipage/control-abstraction-objects.html#sec-newpromiseresolvethenablejob), not an ArkTS/Hypium execution result.

   Minimal owner correction: remove the unnecessary async wrapper from this fake so it returns the actual deferred Promise directly, or introduce an explicit handled-operation completion barrier before assertions. Verify that the regression fails with the old catch when test execution is later authorized. Also cover same-current interruption/toggle failure and stale play/release variants at an appropriate checkpoint; the existing observer-error test is a different entry path. Otherwise the interruption isolation regression is not established by the authored test.

## Test and evidence boundaries

Four cases are authored and registered through the existing PlaybackEngine test suite. Promise signatures, typed callback fields and Fake port overrides look consistent with the existing contract; compiler/Hypium acceptance is **UNKNOWN — COMPILATION NOT RUN**. Deferred pause/release operations are explicitly settled on normal paths for cases 1/3/4; case 2 has the completion-order problem above. Assertions throwing before manual settlement may leave local deferred operations unresolved; no native process/timer is created by these fakes, and actual runner cleanup/hang behavior was not exercised.

BUILD NOT RUN / TESTS NOT RUN / SIGN NOT RUN / SIMULATOR AND MEDIA NOT RUN / RUNTIME NOT PROVEN. Keystore UNAVAILABLE — DEFERRED. No SDK, signing/keytool, device, artifact, fixture, media, HTTP, UI, old failed helper or historical private-log operation was performed. Native cancellation, cleanup and recovered playback have no new PASS.

One optional caller-discovery lookup named a nonexistent PlaybackService path; its enclosing command returned1 (native rg exit not separately captured), classified RECORD_ONLY. It did not affect Git identity or required source reads. The failed lookup was not retried; actual repository inventory independently located PlayerFeatureController/composition and those callers were read directly. Oversized read output was truncated; bounded read segments/full source reads supplied the review text, with no test rerun/helper/controller added.

Only this new report is authorized for publication. The whole candidate was directly reviewed for private paths, device/user identifiers, credentials, signing material and raw logs; it contains repository paths, public commit/blob IDs and authored static reasoning only. Stage names/mode/blob and current remote dispatch must be checked before ordinary commit/push; final publication SHA is supplied externally after fresh fetch/readback. No prior report is changed.

Original user workspace and stopped checkouts were not read or mutated for this task; only the new isolated clone was used. Exhaustive final bytewise user-workspace comparison NOT RUN, so preservation is limited to observed operations. No new runtime resources required cleanup.

Verdict: fix 1 and 2 first; NEEDS GPT SOURCE FIX.
Not checked: compilation, Hypium execution, native/resource behavior, ARM64/real device or complete format acceptance.
