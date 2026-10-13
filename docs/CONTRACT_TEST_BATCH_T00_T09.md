# Linkora — One-shot Unified Interface Contract Test Batch (T00–T09)

> STATUS: DISPATCH PREPARATION — ten scoped checkpoints queued together; actual test outcomes NOT RUN until Codex executes
> USER_DECISION: DISPATCH ALL UP FRONT; NO INTERMEDIATE GPT/OWNER REVIEWS; ONE FINAL CODE+EVIDENCE REVIEW
> BRANCH: feat/playback-capability-phase8
> TEST_TARGET: CLI-only simulator x86_64/API26 for actual System/media runtime; deterministic contract tests for System+MPV adapters
> EXCLUSIONS: desktop DevEco GUI, old keystore/manual signer, editing original user worktree, app uninstall/wipe/reset, fabricated MPV native PASS
> PRIOR_SOURCE: caf7f874b53c94736bcf164d06dc588dd88a36d7 (single HLS-only READY, superseded at batch dispatch)
> FINAL_ACCEPTANCE: each checkpoint one of PASS / PARTIAL / FAIL / BLOCKED / UNSUPPORTED / NOT RUN with source-bound proof; no interim merge or owner signoff

## Execution order — all ten tasks now assigned

| ID | Priority | GitHub task | Actual functional contract / completion boundary |
| --- | --- | --- | --- |
| T00 | P0 | [#21 HLS cancellation and resources](https://github.com/baozi510/Linkora/issues/21) | Native pending release, receiver released BEFORE early and >20s sampling; supported per-app audio/surface/service attribution, then conditional distinct MP4 recovery |
| T01 | P0 | [#20 Unified playback control/events](https://github.com/baozi510/Linkora/issues/20) | Shared PlaybackPort/Observer/Engine public control and event semantics for System and controlled MPV; distinguish real System from stub/mock MPV |
| T02 | P0 | [#22 Adaptive backend/fallback](https://github.com/baozi510/Linkora/issues/22) | Candidate event gate, selection/fallback capability matrix, old session disposal, no precommit/stale callback leakage |
| T03 | P0 | [#23 Storage and RandomAccess](https://github.com/baozi510/Linkora/issues/23) | readAt offset/bytes/EOF, stat/list/open, pending cancel/close, concurrency and supported concrete providers |
| T04 | P0 | [#24 Proxy and HTTP Range](https://github.com/baozi510/Linkora/issues/24) | 206/416/200, byte-exact ranges, seek/client/lease races, task-owned proxy/client zero cleanup |
| T05 | P1 | [#25 System/FFmpeg MediaProbe](https://github.com/baozi510/Linkora/issues/25) | IMediaProbe normalized semantics, provenance/completeness, cancellation and policy fallback |
| T06 | P1 | [#26 Thumbnail/WebP pipeline](https://github.com/baozi510/Linkora/issues/26) | IThumbnailExtractor/Processor/Encoder, bounds and format, real WebP roundtrip where supported, resource release |
| T07 | P1 | [#27 Error & lifecycle](https://github.com/baozi510/Linkora/issues/27) | FailureCatalog and PlaybackEngine timeout/cancel/release, duplicate errors, stale open callbacks, no leaked state |
| T08 | P1 | [#28 Scan/identity/persistence](https://github.com/baozi510/Linkora/issues/28) | scanner, database/store, bookmark/cache source identity, delete/corrupt/retry without user-data mutation |
| T09 | P2 | [#29 Policy and benchmarks](https://github.com/baozi510/Linkora/issues/29) | backend selection/probe/thumbnail policy, evidence-driven benchmark and cache, performance only if reproducible |

## Test sequencing rules

1. Execute T00 first; then T01 → T09. No GPT review or additional task dispatch between checkpoints. At every checkpoint: reuse current source/tests, identify coverage gaps, run focused tests, fix actual bugs in isolated worktree, and capture only legitimate PASS evidence; **do not manufacture coverage by copying a pre-existing PASS for an untested candidate**.
2. Subtasks are independently completable: if an HLS service ownership API is unavailable, record T00 conditional branch NOT PROVEN/NOT RUN, do not rerun unsupported commands, **continue T01–T09**. If one named network protocol or ARM64 native MPV isn't runnable, mark that implementation UNSUPPORTED/BLOCKED; continue all testable contracts.
3. For dual-backend control/event tests, assert what interfaces actually expose (PlaybackPortObserver exposes state/error/duration/position/buffering/first-frame/video-size/interruption/seek/tracks/video-info/backend-change). A mock MPV trace proves a CONTRACT, NOT native MPV playback on x86; real ARM64 libmpv parity is explicitly DEFERRED to the proper device-level gate.
4. Reuse existing authored tests: PlaybackEngine, NetworkFileProxy, MediaAnalysisAdapters, ThumbnailPolicy, etc. Make one shared scenario fixture per abstraction instead of inventing a second architecture. Tests must include actual error/cancel/release semantics, not only successful return values.
5. Product code, test harness, ArkTS/native adapters and controlled fixture are all repairable by Codex within the task; no approval request per ordinary defect. Track precise source SHA/test runner, causal diff and evidence; multiple checkpoint patches live in **one** isolated candidate branch. A final focused regression of changed contracts must bind to final candidate SHA; historical results remain tied to the SHA at which they actually ran.
6. Device-only H.265/HDR/DV/MPV hardware codec, full SMB/NFS server connectivity, broad format catalog and UI appearance are not hidden prerequisites. No false PASS if the supported fixture/device environment isn't available.

## Budget and STOP (finite across all 10)

The one-shot dispatch is a batch exception to the usual single-checkpoint review workflow. Default maximum **40 active minutes and 5 causal changes per checkpoint**, but an overall ceiling of **360 active minutes, 25 causal changes, 12 scoped x86 simulator Debug builds, 8 explicit targeted dependency installations, and 6 non-destructive simulator-owned HAP installs**; a stricter simulator safety cap wins. At most **2 attempts per independent case**, with second ONLY after an evidence-backed meaningful code/input change; no identical retries. These are maximum ceilings, not targets. Reuse existing correctly installed/source-compatible code where possible.

If a subtask has no supported safe fix, STOP only its dependent path and mark PARTIAL/BLOCKED, continue independent work. Immediate **GLOBAL SAFETY STOP** on original-workspace/privacy/destructive-risk breach. Stop the entire batch if globally exhausted or no safe further tasks remain, consolidate observed results with status `PARTIAL / NEEDS GPT DECISION — STOPPED`. Never mutate production feature branch source or claim all tasks PASS merely because the final report was published.

## Final handoff only

- One *source-bound* code candidate branch `codex/linkora-contract-batch-t00-t09-v1` with checkpoint-labeled commits, reviewed changed paths, no private media/logs/keys/generated lockfiles; no force push, no autonomous merge/PR.
- One sanitized consolidated final report `docs/PLAYBACK_CONTRACT_BATCH_T00_T09_FINAL_REPORT.md` on the unchanged exact batch dispatch if publication is safe, with one ordinary commit. Separate report checkout, parent/diff/blob/fresh remote readback; if feature HEAD moved, do not overwrite and report without fabricating SHA.
- Provide per-task contract matrix and independent real native observations by SHA, candidate final SHA, build/ohpm/install/repair budgets, unsupported/device-only limits, original-workspace untouched declaration based on actual observed checks, privacy scrub, exact STOP/recommendation. No intermediate owner acceptances. GPT performs **ONE final comprehensive review** and decides all candidate source changes together.
