# Codex Validation Task — Phase 8F Direct Level-1 Functional Preflight and Three-Open Smoke

> STATE: READY
> TASK_ID: phase8f-level1-scoped-failure-three-open-smoke-v3
> REPOSITORY: baozi510/Linkora
> BRANCH: feat/playback-capability-phase8
> LEVEL: LEVEL_1_FUNCTIONAL
> SOURCE_SHA: 602cb10c0c346b59b6c879def7669cbaed2f2665
> ALLOWED_DRIFT: docs/CODEX_VALIDATION_TASK.md ONLY
> UNCHANGED_PRODUCTION_FIX_SHA: 8174e6e4f0214958fb83fef46e92170c4c10263a
> SUPERSEDED_READY_TASK_ID: phase8f-level1-direct-readiness-three-open-smoke-v2
> SUPERSEDED_READY_DISPATCH_SHA: 4e08263fe572ad3caf419c0be741985a2c6f262c
> HISTORICAL_STOPPED_PREDECESSOR_ID: phase8f-feature-first-targeted-simulator-cancel-smoke
> STOPPED_PREDECESSOR_DISPATCH_SHA: e605bccf1652f30b9b572e3259ec3f5b0d2c5fe9
> PRIOR_STOPPED_RERUN4_DISPATCH_SHA: f98ca3b5d61ec1cd18ee8e42d72e4718c352c5ce
> RERUN4_REMOTE_EVIDENCE_SHA: NONE
> ROLE: DIRECT SOURCE READS; CHEAP ACTUAL SIMULATOR READINESS FIRST; ONE OPTIONAL DEBUG BUILD; THREE FOCUSED FUNCTIONAL OPENS
> MILESTONE_ARM64_RELEASE_ABI: DEFERRED LEVEL_2
> REAL_DEVICE_ACCEPTANCE: DEFERRED LEVEL_3

## 0. Narrow new authorization — no tooling-test cycle

This is a NEW task, not an in-place continuation or retry of the STOPPED predecessor. The previous local-only handoff reported Python child1/outer1 while reading a nonexistent hardcoded contract path, followed later by a PowerShell staged-path helper exit1 after an apparently successful two-path git add. **Neither previous helper is to be edited or rerun.** No local or remote evidence commit was created, and the old STOP remains final. No production bug or SDK/build/signing defect was established: predecessor performed 0 builds, 0 emulator/target/UI tests, 0 official media opens. The local-only failure narrative is not independently audited remote raw evidence.

GitHub OWNER has independently verified the actual source contract **`linkora_core/src/main/ets/playback/PlaybackPort.ets`** (at old dispatch Git blob `231e49b84dce45b83c472fbed0b258711ce758d5`); **`entry/src/main/ets/playback/PlaybackPort.ets` DOES NOT EXIST.** The `linkora_core/src/main/ets/playback/PlaybackEngine.ets` imports the same-directory PlaybackPort. `entry/src/main/ets/playback/AdaptivePlaybackPort.ets` and `SystemPlaybackPort.ets` are entry adapters, not the contract location. There is no need to rediscover this with a private orchestration helper.

Under the APPROVED feature-first rules, prioritize actual functionality, not new source-read wrappers, optional progress observation, archive/gzip mirrors or extensive evidence inventory checks. Do not attempt to repair/publish the old stopped predecessor report or any Rerun4 private evidence. Prior local failures remain unreviewed and unchanged. The task may carry out the three NEW functional opens only if actual environment prerequisites pass; none of these three opens were executed by the stopped predecessor, so this is not replay of completed tests.

## 0A. Scope-based handling of errors — mandatory upfront classification

This task follows the NEW scoped-failure policy in `docs/AI_WORKFLOW.md` and `docs/MASTER_IMPLEMENTATION_PLAN.md`. The preceding `phase8f-level1-direct-readiness-three-open-smoke-v2` READY dispatch is superseded; it has not been reported executed and is not marked FAIL or PASS. No task runs concurrently. Earlier STOPPED IDs remain immutable. **The first failure must be recorded with its actual numeric process exit and semantic effect, but must NOT automatically abort unrelated safe work.** No retries of a failed test or helper to manufacture PASS.

Before commands, use this fixed dependency and classification table:

| Stage | On failure | Work that may still continue without retries |
|---|---|---|
| Optional context/read/display/diagnostic (not required for source integrity) | `RECORD_ONLY` | All independently valid stages |
| Git source identity, code drift or protected user workspace compromised | `GLOBAL_SAFETY_STOP` for unsafe operations | Only safe containment, factual reporting; no build/install/push against unknown source |
| Simulator target, signing/profile, fixture or source-compatible build prerequisite missing | `DEPENDENCY_BLOCKED` | Independent Git/code reading, small status report; no dependent build/playback |
| ONE allowed minimal Debug build fails | `CASE_FAIL` for compilation; runtime `NOT RUN` | Unrelated source review and safe reporting, no second build |
| Healthy MP4 control fails | `CASE_FAIL` | ONE independent HLS PREPARING-cancel attempt MAY continue if native/UI/app state is safe, with its own fixture and no baseline contamination; overall target PASS impossible |
| HLS PREPARING-cancel fails or normal release is unproven | `CASE_FAIL / NOT PROVEN` | Cleanup, evidence of failure, report; recovered MP4 `NOT RUN` |
| Distinct recovered MP4 fails after demonstrated clean cancel | `CASE_FAIL` | Safe cleanup and report; other recorded case outcomes preserved |
| Privacy/path containment/commit/push/remote evidence proof fails | `PUBLICATION_BLOCKED` | No unsafe push; preserve local result as `LOCAL UNREVIEWED`, finish truthful reporting, never rerun playback |

A true uncontrolled crash, native resource contamination, unsafe app state or actual secret leakage may prevent further destructive/running stages: classify `GLOBAL_SAFETY_STOP` for that unsafe branch, never continue merely to collect more PASS labels. A critical test failure still invalidates that critical claim and its dependent end-to-end acceptance; `continue` does not mean `pass`. All outcomes (PASS/FAIL/BLOCKED/NOT RUN/NOT PROVEN) are separately retained in one final partial/completed summary. No new auxiliary shells or debugging helpers to pursue noncritical failures. No quota checks, no chat polling, no forced background tasks.

## 1. Required source/read-only review and workspace safety

1. Fresh-fetch `baozi510/Linkora` branch, read this entire latest Task, `docs/AI_WORKFLOW.md`, current `docs/MASTER_IMPLEMENTATION_PLAN.md`, `docs/ARCHITECTURE_TARGET.md`, `docs/ARCHITECTURE_MIGRATION.md`, CURRENT `docs/IMPLEMENTATION_STATUS.md` and `docs/SESSION_HANDOFF.md`. Read original preceding STOP as historic, not task authority. Confirm READY/latest ID; SOURCE_SHA `602cb10c0c346b59b6c879def7669cbaed2f2665` is direct parent of current dispatch; SOURCE_SHA..dispatch changes **only** `docs/CODEX_VALIDATION_TASK.md`. Previous dispatch `4e08263fe572ad3caf419c0be741985a2c6f262c`→SOURCE_SHA changes exactly `docs/AI_WORKFLOW.md`, `docs/MASTER_IMPLEMENTATION_PLAN.md`, `docs/IMPLEMENTATION_STATUS.md` and `docs/SESSION_HANDOFF.md`. All SHAs in results full 40 hex.
2. Use a new clean isolated validation checkout, never the user's original potentially dirty workspace or any stopped historical isolated worktree. Do NOT reset/stash/clean/checkout/modify those protected originals. Verify `AdaptivePlaybackPort.ets` and `SystemPlaybackPort.ets` current blobs equal production fix `8174e6e4f0214958fb83fef46e92170c4c10263a`. No changes to source/test/scripts/build profile/SDK/signing/fixtures, no pin/TLS bypass.
3. **Use direct Git tree/list and actual existing source files, not a new private hardcoded-path verifier**. Required production contract paths:
   - `linkora_core/src/main/ets/playback/PlaybackPort.ets`
   - `linkora_core/src/main/ets/playback/PlaybackEngine.ets`
   - `linkora_core/src/main/ets/playback/PlaybackModels.ets`
   - `entry/src/main/ets/playback/AdaptivePlaybackPort.ets`
   - `entry/src/main/ets/playback/SystemPlaybackPort.ets`
   - `entry/src/main/ets/pages/PlayerPage.ets`, `entry/src/main/ets/entryability/EntryAbility.ets`.
   If an OPTIONAL additional file name is uncertain, use a single native Git file inventory to locate it or omit the optional read; do NOT fabricate paths or run a new failing standalone path-check script. STOP only on a real mandatory source/identity mismatch, not an exploratory path assumption.

## 2. Cheap READY checks BEFORE building anything

**CRITICAL for attempting runtime:**
- First query actual HDC connected targets using installed documented safe read-only syntax and capture semantic output + exit. A configured or installed API26 emulator is not a running target. If target is empty, you may perform at most ONE normal supported, non-destructive start of the preexisting user-authorized compatible simulator instance using **documented** installed CLI syntax; do not run `-config`, parse SDK `emulator.json`, change settings/profile/instance/image, reset or wipe. If target remains absent: scope `DEPENDENCY_BLOCKED — SIMULATOR ENVIRONMENT` to dependent build/signing/media (`NOT RUN`); finish safe independent code reading and small report; no optional discovery helpers, compilation or repeated starts.
- Only with an actual compatible running target, check existing valid legal signing/profile membership with correctly parsed live `bm get -u` output and installed signing profile, no credentials/IDs published and no edits. If membership cannot be proved: `BLOCKED — SIGNING PREFLIGHT`, no build/media.
- Check that the existing healthy MP4 + separate HLS H264 PREPARING-cancel fixture already exists and one owned host/target route can be used without any extra fixture generation. If missing: `BLOCKED — FIXTURE ENVIRONMENT`, no build/media. Respect user secrets and unrelated services.
- Decide whether a source-compatible, x86 simulator-native-audited, *legally signed* existing HAP can actually be proved for the current source; if yes, use it and explicitly record `BUILD NOT RUN`. Otherwise ONLY after prerequisites pass, allow one scoped simulator Debug build in Section 3. An arbitrary old HAP or ARM64 build is not simulator runtime proof.

These small readiness commands should be direct native invocations; no new multi-layer PowerShell/Python controller, separate process watcher, status-tail, hidden retries or extra JSON metadata helpers. Capture real native return code and meaningful result, do not equate transport0 with semantic success. Cheap STOP is an authorized honest result, not an instruction to loop.

## 3. At most ONE simulator Debug build; no full build cycle

If no valid existing signed x86 artifact and Section 2 passed, perform **ONCE** the current scoped simulator Debug build using existing `scripts/verify-simulator.ps1 -BuildMode debug` and only necessary normal dependency setup. No `scripts/verify.ps1`, no default ARM64 Debug/Release, no triple `default→simulator→default` cycle, no unnecessary unit/format matrix rerun. If required, normalize ONLY existing allowlisted four lockfile EOL drifts with byte/Git-blob identical proof inside new isolated clone; never change semantics. Confirm actual x86 FFmpeg-only native whitelist, code/child exit and source-matched signed installed artifact. A real build error is `FAIL — MINIMAL DEBUG BUILD` and runtime `NOT RUN`; do not patch and rerun tests. Full ARM64 compiler/linker/native artifact validation is `DEFERRED — LEVEL_2 MILESTONE`, not silently PASS.

## 4. Actual foreground and precisely THREE feature opens

Before any media, require actual app Ability foreground, a Linkora-owned nonempty layout/window and matching private screenshot metadata; no launcher-only state. Signed HAP must be genuinely installed (not merely `hdc` exit0). If UI fails, mark `DEPENDENCY_BLOCKED — APP FOREGROUND`; all media NOT RUN; complete safe offline review/report. If app/native state is unsafe, stop risky operations.

Use already approved owned HTTP/WebDAV fixture route only if essential, verify target-side GET where needed. Never modify other user services/ports/account/preference or publish credentials/host address. Use one attempt per case, with dependency-aware continuation rather than unconditional STOP: healthy MP4 and pending HLS cancellation are independently recordable when real shared prerequisites hold and app/native state is safe. If healthy MP4 FAILS, record FAIL and continue the HLS cancellation case only when a new safe independent session can be established without restarting/repeating the failed control. If cancellation fails/unproven, recovered MP4 is NOT RUN. Never restart an unsafe app to manufacture PASS:

1. **Healthy MP4 control:** actual System AVPlayer prepared/play, submitted video frame with observable nonblack meaningful colored pixels, strictly >0ms position delta and actual source fetch if networked. Position movement without pixels is not PASS.
2. **Separate HLS H264 native PREPARING cancellation:** leave while the same candidate is initialized/preparing but BEFORE prepared, correlate normal System AVPlayer candidate release with no stale play/prepared/fallback. Sample app-associated surfaces/service records/audio renderers at ~3–5s and >20s after normal leave (all observed zero, no force-stop); failures and sample limitations honest. If candidate already prepared or correlation unavailable, FAIL/NOT PROVEN and #3 NOT RUN.
3. **Distinct recovered healthy MP4:** only after #2 true normal native release+resource cleanup; new prepared/playing/real frame+colored pixel/positive progress and clean leave. No app reset/wipe/force-stop to fake recovery.

Ordinary HLS, HLS HEVC, FFV1, HDR/DV, advanced audio, real ARM64 MPV/native loading/device hardware all DEFERRED/NOT RUN. Simulator System play is not physical device PASS. No production/test code changes by Codex.

## 5. Minimal TWO-file publication only; no PowerShell staging helper

ONLY NEW authorized public outputs:
```text
docs/PLAYBACK_PHASE8F_LEVEL1_SCOPED_SMOKE_REPORT.md
test-lab/playback/phase8f-level1-scoped-smoke-20261012/result.json
```
A small report and one JSON with honest actual observed status/exit/NOT RUN for unattempted cases are sufficient. If STOP occurs before runtime, this same two-file summary is sufficient; no log bundles needed. Preserve private details and exact raw streams privately when captured; public text must be sanitized. Do not copy unreviewed old Rerun4/predecessor report and evidence files; no new .gz, inventory, progress scripts, timeout observers or helper source required.

**CRITICAL: privacy and Git containment** must be checked on the actual candidate two small files, excluding credentials, signing profiles, emulator/device/instance IDs, PIDs, local private machine paths, native HAP, private network URLs, screenshots/media/full hilog. Do not use broad unproven regex as an automatic PASS/FAIL; inspect actual content semantics. If unsafe/unknown, classify `PUBLICATION_BLOCKED — PRIVACY REVIEW` and do not push; preserve trustworthy local runtime results and report the uncertainty without new tests. Filename and result JSON must truly exist before staging.

Stage the two paths **explicitly** using `git add -- <the-exact-report-path> <the-exact-result-json-path>`, then directly inspect `git diff --cached --name-only` (and modes) before commit. It must contain **exactly two lines matching the two authorized full paths**, with no preexisting tracked staged mutations or other paths. No new PowerShell array-comparison validator, no interpretive regex/pipeline wrapper, no second shell progress observer. If the actual Git output disagrees, classify `PUBLICATION_BLOCKED — PATH CONTAINMENT`, forbid commit/push and retain the REAL output privately; do not assume a wrapper's `Unauthorized staged paths` assertion establishes a Git violation. Do not silently bypass actual unauthorized staged changes. Preserve the final report/result content versions: if updated after staging, re-stage only these SAME two authorized files BEFORE final commit (this is not a rerun of a failed test/helper). Check staged blobs match reviewed worktree public files.

Before one normal commit/push, fresh-fetch remote HEAD EXACT new dispatch and confirm no drift. One ordinary commit of exactly the two paths, one normal push to `feat/playback-capability-phase8`, no force/merge/rebase. Fresh-fetch GitHub and confirm remote HEAD is new evidence full40 SHA, parent exact dispatch, diff exactly two paths and remote text safely readable. If necessary publication operation fails, record actual exit and classify `PUBLICATION_BLOCKED — EVIDENCE NOT PUSHED`, preserving local observed case statuses without rerunning any build, playback or failed helper. A publication FAIL does not convert already locally observed player result into PASS or alter historical tasks; no new infinite evidence-only loop is authorized automatically.

## 6. Final truth, clean owned resources and exact status

Cleanup only routes/resources created by this task; no process force-stop used to claim normal cancel PASS, no unapproved app/wipe/profile changes. Do not claim original workspace bytewise preserved unless final snapshot was genuinely run; otherwise report observed nonmutation limited to known activity.

Final report/chat fields, SHA full 40 hex:
`REVIEW_RESULT; STATE; TASK_ID; LEVEL; REPOSITORY; BRANCH; SOURCE_SHA; TESTED_DISPATCH_SHA; PRODUCTION_BLOBS; SIMULATOR_TARGET; SIGNING_AND_FIXTURES; BUILD_STATUS (NOT RUN or ONE MINIMAL DEBUG); ARM64_MILESTONE (DEFERRED); FOREGROUND_UI; HEALTHY_MP4; PENDING_HLS_CANCEL_RELEASE_AND_CLEANUP; RECOVERED_MP4; DEFERRED_FORMATS; AUTHORISED_PUBLIC_PATHS; EVIDENCE_COMMIT_SHA or NONE; PRIVACY_AND_GIT_PATH_AUDIT; ORIGINAL_WORKSPACE_UNCHANGED/NOT FULLY RECHECKED; FIRST_FAILURE; NEXT_ACTION`.

Only claim `PASS — TARGETED SIMULATOR PENDING CANCELLATION AND RECOVERY` if all three required runtime opens actually pass. Otherwise finish as `COMPLETED WITH FAILURES / PARTIAL` where safe, retaining each case verdict; a publication-blocked outcome must say `LOCAL UNREVIEWED`, not globally erase the observations. No old local build claim is independently accepted absent published evidence. Do not ask about quotas, poll chat or schedule future activity. GPT alone reviews actual remote evidence and decides the next feature/phase milestone plan.
