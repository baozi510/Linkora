# Codex Validation Task

> STATE: READY
> TASK_ID: phase8f-rerun4-evidence-publication-recovery-only
> REPOSITORY: baozi510/Linkora
> BRANCH: feat/playback-capability-phase8
> SOURCE_SHA: adef77219cebe347382fd172a6b615780517f402
> ORIGIN_STOPPED_TASK_ID: phase8f-sim-rerun4-single-controller-ui-cancel
> ORIGINAL_TESTED_SOURCE_SHA: a9312a86a5104e46847f1087af52e7de8b1c2fab
> ORIGINAL_TESTED_DISPATCH_SHA: f98ca3b5d61ec1cd18ee8e42d72e4718c352c5ce
> PRIOR_REMOTE_EVIDENCE_SHA: 4ef43b09a4e8a05e7021b7734fdfd2ab767bb138
> UNCHANGED_PRODUCTION_FIX: 8174e6e4f0214958fb83fef46e92170c4c10263a
> ORIGINAL_RERUN4_LOCAL_EVIDENCE_SHA: NONE
> ORIGINAL_RERUN4_REMOTE_EVIDENCE_SHA: NONE
> ROLE: EXISTING SANITIZED EVIDENCE PRESERVATION, INDEPENDENT PUBLICATION AUDIT, ONE NORMAL COMMIT/PUSH ONLY
> ALLOWED_DRIFT: docs/CODEX_VALIDATION_TASK.md ONLY (relative to SOURCE_SHA)

## 0. Scope and historical STOP

This is a NEW DISTINCT TASK solely for restoring GitHub publication of EXISTING Phase 8F Rerun 4 evidence. It is NOT Rerun 4 validation, not a rerun of its failed emulator inspector, controller, staged audit, commit helper, builds or media. The original Rerun4 run remains STOPPED; its LOCAL verdict is FAIL — REQUIRED TEST GATE and its publication result was BLOCKED — EVIDENCE NOT PUSHED. The previous task forbade continuation after the failure. This task newly authorizes publication **only**, using existing already-collected artifacts and a separate clean isolated checkout; it does not retroactively authorize any old failed helper, device step or test. Never turn any local PASS claim into independently reviewed PASS merely by transferring files.

Original local handoff asserts: controller five synthetic selfchecks; fresh serial default→simulator→default verifier child0, two independent Hypium210/210 and exact ARM64 audits; first live HDC target list [Empty]; installed emulator listed a configured API26/x86_64 instance not running; a NEW PRIVATE emulator metadata inspector child1 threw AttributeError because emulator.json root was a list, not a dict, on data.keys(). No emulator boot, legal signing/install, app UI, fixture route, or six official media opens. The no-argument emulator -config command may have settings side effects that are NOT PROVEN absent. Outer helper byte-identical stdout/stderr and exact start/end were not independently captured. No production/codec/signature defect established. The later evidence-staged-audit failed child1 on private controller-state.json os.replace PermissionError [WinError 5]; commit helper child1; cause unresolved, no local evidence commit or push. The report was later amended but not staged. This paragraph is local handoff, not GitHub-confirmed Rerun4 evidence.

Never check quota, set a task timer, poll chats, do background polling, reinterpret missing records, redo failed helpers or manufacture evidence. Original failed gates are immutable.

## 1. Exact identity and source safety

1. Fresh-fetch the specified repository/branch and inspect HEAD and entire current Task. Confirm exact READY ID. Confirm SOURCE_SHA adef77219cebe347382fd172a6b615780517f402 is immediate parent of this dispatch, and diff SOURCE_SHA..dispatch is EXACTLY docs/CODEX_VALIDATION_TASK.md. The review commit SOURCE_SHA must have exactly docs/IMPLEMENTATION_STATUS.md and docs/SESSION_HANDOFF.md relative to old Rerun4 dispatch f98ca3b5d61ec1cd18ee8e42d72e4718c352c5ce. Confirm ancestry original tested source→original dispatch→review→new dispatch, and prior remote Rerun3 evidence is ancestor. Reject any other drift with BLOCKED — SOURCE DRIFT.
2. Verify production AdaptivePlaybackPort.ets and SystemPlaybackPort.ets Git blobs at new dispatch exactly match production fix 8174e6e4f0214958fb83fef46e92170c4c10263a. No other production/build/test/media/config/profile/source changes authorized. Existing historical reports, evidence, task files, old branch commits and submodule pointers MUST be unmodified.
3. The original Rerun4 stopped isolated checkout's HEAD is f98ca3b5d61ec1cd18ee8e42d72e4718c352c5ce. Read-only inspect it; it is NOT the user's original workspace. It reportedly contains one staged report plus 109 authorized staged evidence files, followed by an unstaged report amendment. Do NOT clean/reset/stash/checkout/rebase/reinstall in this original checkout or touch the user's original potentially dirty workspace. Do not change Git index or staged content there. If origin checkout cannot be safely accessed without mutations, STOP BLOCKED — LOCAL SOURCE UNAVAILABLE.
4. Use a NEW separate clean isolated clone/worktree freshly checked out at THIS publication dispatch only as the destination. Never attempt to push original detached/staged checkout directly or force/rebase its old branch. No build, ohpm install, HAP creation or simulator/host fixture activity is permitted.

## 2. Required reading and materials

Read docs/AI_WORKFLOW.md, docs/MASTER_IMPLEMENTATION_PLAN.md, docs/ARCHITECTURE_TARGET.md, docs/ARCHITECTURE_MIGRATION.md, new CURRENT docs/IMPLEMENTATION_STATUS.md and docs/SESSION_HANDOFF.md, whole latest Task, old Rerun4 task from original dispatch, old Rerun3 report and task-result/progress-monitor-stop/build-results, and actual original Rerun4 stopped local report and PUBLIC sanitized evidence if present. Record origin checkout full commit, branch, Git status and staged and worktree differences without modifying them. Make clear which facts are only from this chat/local files and which are remotely verifiable.

These are the ONLY Rerun4 publication output paths, identical to the earlier task:
~~~
docs/PLAYBACK_PHASE8F_RERUN4_SINGLE_CONTROLLER_UI_CANCELLATION_REPORT.md
test-lab/playback/phase8f-rerun4-single-controller-ui-cancel-20261011/
~~~
The handoff claims exactly 110 new paths: one report and 109 evidence files. Determine actual names/count from the original staged index and worktree, NEVER invent missing files, and STOP on unexplained discrepancy, missing report, inaccessible bytes, extra paths or a claimed evidence item absent. No separate task report, helper, manifest, script or extra file may be committed. Evidence recovery is a publication operation, not new measurements.

## 3. Preserve ORIGINAL source material without rerunning

1. On stopped Rerun4 isolated checkout, run only read-only Git status, index pathname/mode/blob discovery, staging diff, normal file reads/hash and privacy checks. Keep an exact private immutable byte/hash/mode ledger of all source files, staged report version AND later worktree report version, and a distinct ledger for their intended public copies. Source of the 109 evidence files is the prior staged index **only**, verifying the corresponding worktree files are not silently substituted; report source is the last amended existing worktree report, whose header says BLOCKED — EVIDENCE NOT PUSHED. Explicitly document staged-vs-worktree report difference privately. Do not claim the report revision was staged when it was not.
2. Do not modify any original source file, private failed audit/controller or failed helper. Do not rerun old original inspector/data.keys(), controller, audit, commit helper, old PowerShell observer, old sign preflight or original 800ms progress helper. Do not run installed emulator -config, emulator -list, device bm/aa/hdc, live profile, signing, install, foreground/layout, native player telemetry, host server, reverse port, fixture or official media. These already NOT RUN gates must remain NOT RUN.
3. Transfer ONLY the existing sanitized/public intended file bytes into the new isolated clone, without following symlinks, copying private files, or touching the original working tree/index. The 109 evidence files should reproduce the original staging blobs exactly; if byte-normalization on Windows/checkout changes a blob, STOP unless independently proved a harmless newline presentation artifact while published blob remains identical. The amended report may differ from the original staged report, preserving the historical fail and publication blocker; do not rewrite its findings to PASS or insert an invented local or remote SHA.
4. Never copy or publish signing credentials/profile, device IDs, instance IDs, PIDs, original private paths, developer workspace IDs, complete HAP, private raw stdout/stderr/hilog, original screenshots/media, server credentials/URLs, private environment documents or nonredacted identifiers. If an approved public file is not safe for publication, STOP BLOCKED — PRIVACY REVIEW; do NOT silently omit a required file, edit original private evidence or fabricate hashes. No uploading local-only private raw files through chat or web.

## 4. NEW publication-only independent audit (not the failed controller)

Use a NEW separately owned, finite, read-only publication audit over the copied candidate tree, NOT the historical failed staged-audit or controller. The new audit must not call old controller-state.json, os.replace on old state, or any old failed helper. Do not infer the cause of WinError 5, attempt AV/lock/permission workarounds, run with elevated privileges, force-delete files, or change machine-wide settings. Use direct completed read-only Git/plumbing, Python filesystem reads/checks or equivalent. Each actual command has a distinct observed numeric exit (including wrappers where used) and semantic interpretation. If a NEW command fails, STOP; do not patch it and continue in this task.

Before staging/commit require:
- Exact origin HEAD, staged pathname count 110 and report/evidence path containment; names UTF-8 clean, modes regular, no symlink, unexpected directory, replacement or duplicate; actual SOURCE ledger matches intended copied public bytes except identified amended report.
- Evidence files honest: Rerun4 STOP and inspector child1, configured-not-running vs live-target [Empty], no device sign/install/UI/open, historical local build child0 only as CLAIM until independently audited, unresolved original controller audit WinError5/commit-helper child1 and missing outer-helper original bytes/precise times explicitly documented. Do not reconstruct raw stderr or timestamps. No post-STOP retry or extra media attempt. Official ledger empty; all six NOT RUN/NOT PROVEN. No resource0, signed HAP, real MPV/ARM64 runtime, HEVC/HDR/audio-format PASS invented.
- Independent privacy sweep on EVERY candidate public file including decompressed .gz, JSON/string fields and any report text. No secret, live credential, unredacted 64-hex device/instance ID, private local path, private media/HAP, image or full hilog. Do not print private matches publicly. Remember some hashes are intentional: differentiate SHA256 evidence hashes from device-ID fields by schema/context; do not silently drop valid hashes.
- Verify every actual sanitized text/gzip pair (handoff claims 33), decompress and hash/compare byte exact sanitized text; cross-check actual report log-integrity and protected source inventory with published files, while clearly distinguishing PRIVATE-original SHA claims from independently readable sanitized-byte hashes. Unavailable original private bytes remain NOT INDEPENDENTLY VERIFIED, not falsely replayed.
- On destination clone initial clean HEAD, original SOURCE_SHA→dispatch drift exact task only, destination staged changed set EXACTLY report+109 authorized files, no protected tracked modifications. Verify all new paths are regular files and published public bytes match audited candidate. Ensure no generated HAP or tool state accidentally staged.
- Do not use a progress observer process while another child is running. No waiting loops/chat polling. Capture actual numerical exit codes and STOP at any required audit or privacy gate failure. Do not hide errors with outer shell success. No testing is part of this task.

The prior private controller-state.json atomic-write failure remains an original failed audit, never treated as PASS because this NEW and DIFFERENT publication audit uses read-only checks and a new checkout. A successful NEW publication audit does NOT erase either Rerun4 failure; it only authorizes an evidence push.

## 5. One ordinary publication commit and verification

After the NEW publication audit and privacy check succeed, fresh-fetch the remote again. Remote HEAD must EXACTLY equal this NEW dispatch SHA and all protected paths remain unchanged. Any unexpected advancement: STOP BLOCKED — SOURCE DRIFT; no merge, rebase, force, cherry-pick across ambiguous remote history or retry of failed publication helpers.

Create EXACTLY ONE NEW normal evidence commit on destination isolated clone containing ONLY the two allowed path prefixes. Normal push once to feat/playback-capability-phase8, no force. If git add/commit/push fails, STOP with real numeric codes and commit SHA if one exists; do not patch and re-run failed command in this task. No local evidence SHA exists until commit succeeds; do not report original dispatch or new dispatch as an evidence SHA.

After push fresh-fetch GitHub remote branch, require remote HEAD equal the new evidence commit full40 SHA, parent equal this new dispatch and tree diff exactly the authorized report/evidence paths. Re-read remote report, actual evidence paths, metadata and relevant sanitized files; check count/modes and gzip/hash integrity on the remotely published bytes, and protected history unchanged. If any remote content mismatch or inaccessible evidence, STOP BLOCKED — EVIDENCE NOT VERIFIED. If push/HEAD not confirmed, BLOCKED — EVIDENCE NOT PUSHED, and do not claim delivered evidence. Preserve original source checkout and user original workspace exactly as before. Local private originals never published.

Historical Rerun4 report header can remain BLOCKED — EVIDENCE NOT PUSHED because that describes the ORIGINAL execution. The result of THIS new separate publication-only task can be PASS — EVIDENCE PUBLISHED AND REMOTELY VERIFIED. These are not contradictory, and that publication PASS must never be labelled a playback/validation PASS.

## 6. Final outputs and handoff

Report in chat (do not edit the old report to invent self-referential SHA):
REVIEW_RESULT / PUBLICATION_RESULT / ORIGINAL_VALIDATION_RESULT / STATE / TASK_ID / REPOSITORY / BRANCH / SOURCE_SHA / TESTED_DISPATCH_SHA / NEW_DISPATCH_SHA / ORIGINAL_LOCAL_EVIDENCE_SHA / NEW_REMOTE_EVIDENCE_SHA / ORIGINAL_REPORT+EVIDENCE_PATH_COUNT / NEW_AUDIT_VERDICT / FIRST_FAILURE_EXITS / BUILD_GATE_STATUS_AS_EVIDENCE_ONLY / ALL_SIX_MEDIA_SCENARIOS / PRIVACY_AND_GZIP_AUDIT / CLEAN_CHECKOUT+USER_WORKSPACE / NEXT_ACTION.
Every commit SHA printed must be complete 40 hex; NONE means no commit exists. Preserve missing originals and unverified facts explicitly.

Successful publication next action: GPT independently review remotely pushed Rerun4 evidence first, then alone decide a future distinct runtime validation/task correction; no self-dispatch by Codex. Any STOP: no further work or old task replay. No quota checks.

Primary result for this task is strictly publication state, never cancellation acceptance.