# CODEX READY — One-Shot Batch of ALL Core Wrapper Contract Tests T00–T09

> STATE: READY
> TASK_ID: phase8f-level1-cli-all-wrapper-contracts-batch-t00-t09-v1
> REPOSITORY: baozi510/Linkora
> BRANCH: feat/playback-capability-phase8
> SOURCE_SHA: 7a13dc55dbf0f5f830b47aa5d0b3f316f0ef17f8
> ALLOWED_DISPATCH_DRIFT: docs/CODEX_VALIDATION_TASK.md ONLY
> BATCH_MODE: ALL TEN TASKS DISPATCHED NOW — CONTINUE WITHOUT INTERMEDIATE GPT REVIEW
> SINGLE_FINAL_REVIEW: YES — ONE CODE CANDIDATE + ONE FINAL CONSOLIDATED EVIDENCE REPORT
> SUPERSEDED_UNEXECUTED_HLS_ONLY_TASK_ID: phase8f-level1-cli-hls-resource-attribution-recovery-v1
> TASK_SPEC: docs/CONTRACT_TEST_BATCH_T00_T09.md
> TASKS: T00 #21; T01 #20; T02 #22; T03 #23; T04 #24; T05 #25; T06 #26; T07 #27; T08 #28; T09 #29
> TARGET: CLI-ONLY HARMONYOS X86_64/API26 SIMULATOR; DETERMINISTIC CONTRACTS SYSTEM/MPV
> ACTIVE_WORK_CEILING: 40 MIN PER CHECKPOINT AND 360 MIN GLOBAL MAX
> REPAIR_CEILING: 5 CAUSAL FIXES PER CHECKPOINT AND 25 GLOBAL
> BUILD_CEILING: 12 SCOPED X86 DEBUG BUILDS TOTAL, ONLY WHEN SOURCE CHANGE REQUIRES IT
> OHPM_CEILING: 8 EXPLICIT TARGET-PARAMETERIZED DEPENDENCY INSTALLS MAX, ONLY WHEN NEEDED
> SIMULATOR_INSTALL_CEILING: 6 NONDESTRUCTIVE OWNED-BUNDLE INSTALLS TOTAL AFTER ABI/BUNDLE AUDIT
> CASE_RETRY_CEILING: INITIAL + ONE ONLY AFTER A MEANINGFUL CODE/INPUT CHANGE
> ALL_PRODUCTION_CODE_EDITS: SCRATCH AND SEPARATE codex/* CANDIDATE BRANCH ONLY
> ORIGINAL_WORKSPACE_WRITES: ZERO; DESKTOP_GUI/IDE_LAUNCH: ZERO
> OLD_KEYSTORE/MANUAL_SIGN_APP/PASSWORD_OR_SECRETS: ZERO; OTHER_APP_UNINSTALL/WIPE/RESET: ZERO
> MPV_REAL_NATIVE_ON_SIMULATOR: UNSUPPORTED — MOCKED CONTRACT ONLY; ARM64 DEVICE DEFERRED
> REQUIRED_STOP: UNSOLVABLE DEPENDENCY/BUDGET/SAFETY -> STOP AFFECTED PATH, CONTINUE INDEPENDENT TASKS
> FINAL_PUBLIC_REPORT: docs/PLAYBACK_CONTRACT_BATCH_T00_T09_FINAL_REPORT.md
> FINAL_CANDIDATE_BRANCH: codex/linkora-contract-batch-t00-t09-v1

## 0. THIS IS THE SINGLE OWNER DISPATCH FOR THE WHOLE BATCH

User has explicitly approved **dispatching all related tests at once and reviewing after the full batch only**. Execute T00→T09 as one cohesive Codex engagement. DO NOT ask GPT to review, merge, issue a new TASK_ID or open ten new READY dispatches between checkpoints. Do not wait for user approval for an ordinary relevant source/test/native bug fix. A finished checkpoint can be locally recorded and the next one begun. If context/tool quota interruption forces a pause, preserve a private checkpoint journal and source SHA so the SAME batch can be resumed under explicit later user instruction; this is not permission for asynchronous execution, self-rescheduling, concealed background work or resetting already used budgets. The existing old HLS-only READY was superseded by the owner policy commit, **not relabeled as a runtime FAIL or PASS**.

Read entire `docs/CONTRACT_TEST_BATCH_T00_T09.md`, current top `docs/AI_WORKFLOW.md`, architecture `docs/ARCHITECTURE_TARGET.md` if present, this task, relevant source and exact per-issue acceptance text. The ten GitHub issues are SCOPED specifications, **not separately running workflows**. All test paths must identify actual source/build/candidate SHAs. Never inherit native PASS from an older installed HAP without matching identity. These tasks test functional behavior and abstractions, **NOT UI layout or screenshots**.

## 1. One cheap source-target preparation

1. Fresh fetch branch at this DISPATCH SHA; verify immediate parent equals SOURCE_SHA `7a13dc55dbf0f5f830b47aa5d0b3f316f0ef17f8`, diff is exactly `docs/CODEX_VALIDATION_TASK.md`. SOURCE's predecessor was prior HLS-only dispatch `caf7f874b53c94736bcf164d06dc588dd88a36d7`, followed only by docs workflow/status/handoff/batch plan/task supersession; no new product code.
2. Work in a NEW isolated clone and **one** isolated candidate branch `codex/linkora-contract-batch-t00-t09-v1` based on DISPATCH. The user's original possibly dirty `D:/Linkora` is immutable: only the previously authorized `third_party/ffmpeg/prebuilt/x86_64` read/hash/copy-OUT of its pinned n8.1.3 manifest/four headers/four archives is permitted when required. Never copy old HAPs/logs/hidden credentials/stopped private worktrees. Any generated dependency lock, test fixture, HAP and private logs stay untracked/unstaged. Candidate commits MAY be made as checkpoints, but no branch force push or owner review until final; ensure final tested SHA bound to tests.
3. Check approved already-running x86_64/API26 emulator through CLI. At most one ordinary existing simulator CLI start if needed; no GUI/IDE/desktop computer use. Reuse genuine already proved x86-only System app/open when source-bound; no unnecessary redundant build/upgrade. Generated new HAP requires effective local MPV Stub dependency via `ohpm install --pf oh-package-simulator-params.json5` if needed, direct parameterized CLI Hvigor `simulator`/`entry@simulator` Debug, package identifier `com.linkora.player.simulator`, strict existing x86 ELF audit exit0 (only machine62 `liblinkora_ffmpeg.so`; no ARM64 MPV/AKI/CXX) BEFORE any legal nondestructive install. No `devecocli run` with unverified param forwarding.
4. Existing meaningful native evidence to avoid redundant green tests: first earlier candidate `928fe777869a8fefbdacad26c52d1d2f91835452` proved actual FFmpeg RGBA 320×180 decoded frame, WebP encode/redecode and System AVPlayer MP4 play/pause/seek. Second candidate `fd8bae5ab1e52c45c8a2e0848156879c66278b40` proved independent FFmpeg proxy cancel and narrow HLS PREPARING release, NOT complete native app-associated audio/surface/service zeros or post-HLS recovery, and did not rerun earlier core suite. Both candidate changes were merged via `abe78f52c3340e56d5f34814072178b516c3fd0d`. These historic claims are **not** replacements for NEW contract tests or final code SHA regression.

## 2. Execute ALL TEN checkpoint specifications, in this exact order

Each issue URL is part of this one dispatch. Read its complete acceptance details and test existing authored tests before adding new ones. Record per case `PASS / FAIL / PARTIAL / BLOCKED / UNSUPPORTED / NOT RUN / NOT PROVEN`, with native/host/mock type, tested SHA, attempt count and precise error/release semantics.

- **T00 / P0 / Issue #21:** HLS pending cancel, own native AVPlayer and ImageReceiver release BEFORE 3–5s and >20s snapshots, attributable audio/surface/media service metrics only where supported, conditional distinct MP4 recovery. If service ownership cannot be safely attributed, mark UNKNOWN/NOT PROVEN and STOP that dependent recovery path; **CONTINUE T01** without guessing. No app force-stop or global service count reinterpretation.
- **T01 / P0 / Issue #20:** unified `PlaybackPort`/`PlaybackPortObserver`/`PlaybackEngine` controls, errors, state events, seek/time units, first frame/tracks/duration/buffering/interruption, idempotent release and stale event isolation. Shared deterministic contract scenarios for System/MPV adapters, actual System native runtime where meaningful. MPV x86 Stub/mock DOES NOT prove real native MPV; ARM64 device acceptance deferred, label explicitly.
- **T02 / P0 / Issue #22:** `AdaptivePlaybackPort`, `PlaybackBackendSelector` candidate prepare/commit/fallback, preference/capability policy, old port disposal, duplicate/backend-change event filtering and safe recovery. Don't assume an unavailable route supports automatic fallback.
- **T03 / P0 / Issue #23:** `StorageProvider`/`RandomAccessSource`/adapters, exact readAt offsets/ranges/EOF, stat/list/open, concurrency, cancellation, close and implemented local/remote protocol parity.
- **T04 / P0 / Issue #24:** `NetworkFileProxy`/HTTP ByteRange/lease and progressive download, 200/206/416, seek, concurrent client/isolation, abort and attributable zero active clients/sources upon normal cancellation.
- **T05 / P1 / Issue #25:** `IMediaProbe` System vs FFmpeg normalized metadata/field provenance/completeness, cancel/timeout and `PolicyMediaProbe` fallback. Do not confuse native probe with actual decoded-frame success.
- **T06 / P1 / Issue #26:** `IThumbnailExtractor`/`IThumbnailProcessor`/`IThumbnailEncoder` System/FFmpeg/WebP pixel/size/mutation/release contract and actual image encode/decode where callable. Don't claim lossy pixel equality.
- **T07 / P1 / Issue #27:** `FailureCatalog`/PlaybackEngine async lifecycle, error normalization, stale callbacks, prepare cancellation, terminal events, duplicate close/release and no fake native cleanup.
- **T08 / P1 / Issue #28:** scanner/source identity/local network cache/bookmarks/recent-media database, duplicate/refresh/delete/corruption/partial write/resume source isolation, using task-only data not real user data. Mark unfinished protocol support honestly.
- **T09 / P2 / Issue #29:** media/thumbnail/backend policy and benchmark rules, reproducible sample/cost and deterministic fallback/capability selection; real hardware perf not inferred from simulator.

For each checkpoint make the **smallest effective changes** to real sources/tests/owned fixtures needed to fulfill declared behavior. Codex is authorized to fix ANY relevant ArkTS/native/C++/CMake/SDK/test issue in its isolated scratch; never create a fake MPV implementation, two competing long-term architectures or extra GUI testing. Keep tests composable and reuse existing `PlaybackEngine.test.ets`, `NetworkFileProxy.test.ets`, `MediaAnalysisAdapters.test.ets`, `ThumbnailPolicy.test.ets` etc. A safe blocked independent subcase is **not** a reason to stop the entire batch.

## 3. Bounded autonomy and explicit partial-results policy

Each subtask is limited to **40 ACTIVE minutes** and **5 evidence-backed causal fix cycles**; global cap across T00–T09 is **360 active minutes**, **25 repair cycles**, **12 total necessary scoped simulator x86 Debug builds**, **8 explicit target-param ohpm install invocations** and **6 actual audited nondestructive owned-bundle installs**. A non-native/unit-only checkpoint should have ZERO builds/installs. Two attempts per independent functional case only when second follows a real causal code/fixture/source change. Never retry a failed unchanged command simply to use budget. No simultaneous heavy builds, no auto-generated 59-case matrix, no repeated historical full codec/playback smoke to fill a table. One genuinely transient fetch can be retried once safely with unchanged worktrees.

On any failure: write `observed failure → causal fix hypothesis → exact isolated diff/input → targeted check → new result`; after real supported fixes fail and no new hypothesis, STOP THAT PATH and move to the next independent checkpoint. If resources or global caps exhausted, global unsafe condition arises, or no independent safe checkpoint remains, STOP BATCH, preserve partial evidence and deliver consolidated `NEEDS GPT DECISION — STOPPED`. Do not wait for owner's interim review, do not self-dispatch, do not weaken guards to force all-green reports.

Hard safety: never edit/build/reset/clean/stash original developer workspace; do not access secrets/keystores/other projects/user application data, invoke manual sign-app, bypass signing, uninstall or wipe apps/emulator, alter global SDK/device settings, use unapproved private media or scrape endpoints, open desktop DevEco UI. Owned local test servers and fixtures may be created/cleaned in scratch only, with exact port ownership and no other listener stopped.

## 4. Only ONE final GitHub code+evidence review

Maintain task-local checkpoint ledger privately with **T00–T09 status, exact tested candidate SHA and native/host/mock evidence**. After ALL ten checkpoints have been attempted or safely classified blocked, run a focused relevant regression on FINAL candidate SHA (the final combined source code). If full native regression is impossible, record prior-SHA PASS + FINAL-SHA `NOT RUN/NOT PROVEN`, not unearned parity. Do not change default-target ARM64 native MPV functionality without explicit milestone scope.

At final handoff:
- Push ONE separate code candidate branch `codex/linkora-contract-batch-t00-t09-v1` (with logically labeled commits), after reviewing all changed paths, no generated lock/prebuilts/HAP/media/raw log/private data. Do NOT directly push candidate source to `feat/playback-capability-phase8`, merge, force-push or auto approve a PR.
- Commit ONE new sanitized consolidated final evidence file `docs/PLAYBACK_CONTRACT_BATCH_T00_T09_FINAL_REPORT.md` into the exact original-dispatch feature branch only if its HEAD remains this DISPATCH. Normal no-force single report-only commit, verify remote one parent and one path/mode/blob/readback. If remote moved or evidence publication blocked, do not retry execution; report with `EVIDENCE_SHA NONE` and candidate SHA.
- Include one clear status row for every T00–T09 with native vs mock/host status, success criterion, tests/attempts/run SHAs, fixes, unsupported / device-only claims, total budget use, candidate final SHA, first unresolved blockers and per-category STOP reason. If any case failed/unproven, overall result must be `PARTIAL` or `STOPPED`, NEVER `ALL PASS`.
- Ask for ONE GPT owner review of the final code candidate + consolidated evidence, not a review after each checkpoint. Do not claim unexecuted work complete.

**Final response fields:** `STATE / BATCH_TASK_ID / SOURCE_SHA / DISPATCH_SHA / T00..T09_OUTCOMES / CANDIDATE_BRANCH_SHA / FINAL_COMBINED_REGRESSION / BUILD/OHPM/INSTALL/REPAIR_COUNTS / GUI0 / SIGN_APP0 / USER_ORIGINAL_UNCHANGED_TO_OBSERVED_SCOPE / DEVICES_AND_UNSUPPORTED_GAPS / REPORT_SHA_OR_NONE / FIRST_OPEN_BLOCKER / FINAL_OWNER_DECISION_NEEDED`.
