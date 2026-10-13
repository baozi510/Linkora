# Codex Task — CLI HLS Resource Ownership and Conditional Recovery

> STATE: READY
> TASK_ID: phase8f-level1-cli-hls-resource-attribution-recovery-v1
> REPOSITORY: baozi510/Linkora
> BRANCH: feat/playback-capability-phase8
> LEVEL: LEVEL_1_FUNCTIONAL — HLS RESOURCE OWNERSHIP / CONDITIONAL MP4 RECOVERY
> SOURCE_SHA: a678ab5c9c2282dd42448dd658bad9cec0760dd9
> ALLOWED_DISPATCH_DRIFT: docs/CODEX_VALIDATION_TASK.md ONLY
> PRIOR_COMPLETED_TASK: phase8f-level1-cli-media-all-error-autonomous-repair-v2 — CLOSED PARTIAL
> PRIOR_REPORT_SHA: 61e18de5e7f80a6f8f94469ef530b30d8eac5d92
> PRIOR_MERGED_CODE_SHA: abe78f52c3340e56d5f34814072178b516c3fd0d
> MODE: CLI ONLY — NO DESKTOP GUI / IDE / SCREENSHOT / COMPUTER USE
> GOAL: REAL HLS PENDING CANCEL + APP-OWNED PLAYER/SURFACE AND SUPPORTED SERVICE ATTRIBUTION + CONDITIONAL DISTINCT MP4 RECOVERY
> MAX_ACTIVE_MINUTES: 40
> MAX_CAUSAL_REPAIRS: 5; MAX_X86_BUILDS: 5; MAX_OHPM_INSTALLS: 3; MAX_NONDSTRUCTIVE_HAP_INSTALLS: 2
> MAX_HLS_ATTEMPTS: 2 WITH ACTUAL CHANGE BEFORE SECOND; MAX_RECOVERY_ATTEMPTS: 1 AFTER CLEANUP GATE
> GUI/SIGN_APP/OLD_KEYSTORE/USER_ORIGINAL_WORKSPACE_WRITES/APP_UNINSTALL/WIPE/RESET: ZERO
> TRACKED_CHANGES: SEPARATE codex/phase8f-hls-resource-recovery-v1 CANDIDATE BRANCH ONLY
> NO_IDENTICAL_RETRIES; STOP_UNSUPPORTED: NEEDS GPT DECISION — STOPPED WITH HONEST PARTIAL EVIDENCE

## 0. Distinct narrow objective, not redoing completed media tests

GPT independently read the old 64-line report and all six reviewed candidate files, verified evidence commit 61e18de5e7f80a6f8f94469ef530b30d8eac5d92 has only a one-file report addition, and merged final code candidate fd8bae5ab1e52c45c8a2e0848156879c66278b40 via two-parent merge abe78f52c3340e56d5f34814072178b516c3fd0d. The closure commit adds status/handoff docs only. Completed V2 must not be rerun.

Native H264/AAC FFmpeg RGBA decode, WebP encode/redecode and System MP4 play/pause/seek were actually tested at FIRST candidate 928fe777869a8fefbdacad26c52d1d2f91835452. The final candidate added separately tested FFmpeg active cancel and HLS PREPARING native release; final candidate did NOT rerun complete core cases. These are not new HLS audio/surface/service zero-resource evidence. No distinct post-HLS MP4 recovery has been run.

Specific owner source finding in CURRENT entry/src/simulator/ets/diagnostics/MediaFunctionSmoke.ets, method hls(): the test creates an ImageReceiver; it awaits native backend.release while HLS is pending and performs early ~3.5s / late >20s observations; however the receiver is released only in finally AFTER those observations. Thus the old test itself still owned a surface-related receiver during its claimed observation windows. Also SystemPlaybackPort.release catches native release errors internally, so higher-level release resolution alone does not establish complete kernel media-service cleanup.

## 1. Source and safety preflight

Verify latest dispatch direct parent SOURCE SHA and task-only diff, preserve old report/history; SOURCE consists of reviewed code merge and closure docs, not another untested production change. New isolated scratch checkout; inspect actual MediaFunctionSmoke.hls, SystemPlaybackPort.prepare/release/registerEvents, PlaybackPort and simulator RuntimeDiagnostics and prior task-owned fixture script. Do not open stopped private checkout or mutate original user worktree. May read ONLY user-authorized existing pinned x86 FFmpeg input directory and copy verified manifest/headers/four static libs outward into new ignored scratch prefix IF necessary for a new build. Pure CLI. Confirm existing x86_64/API26 simulator without reset or wipe.

Current code already has a task-owned HTTP delayed HLS segment recipe and real System AVPlayer pending-cancel test; source-aligned current installed simulator HAP may be reused only if exact provenance is known. Any changed code must be rebuilt and HAP provenance bound to actual code candidate. No default ARM64/Release build, old keystore or manual sign-app.

## 2. Concrete resource ownership acceptance

A. Fix the HLS harness ownership gap in scratch: release both native backend and the test-created ImageReceiver BEFORE early 3–5s and later >20s sampling, with guaranteed exactly-once cleanup even if an error occurs. Capture actual release completion, errors and expected native released state separately, plus actual prepare Promise settlement/late events. Do not swallow an AVPlayer native release failure as PASS; if necessary and causally grounded, modify SystemPlaybackPort implementation and verify. Record pending pre-cancel state and ensure no late prepared/error/fallback confusion.

B. Independently classify five separate evidence types at baseline, pending, after release, early and >20s: owned AVPlayer handle/state, owned receiver/surface handle, app-attributable audio session(s), app-attributable graphic/surface service resources, and app-attributable media service resources. Actual client-managed handles can establish only APP_OWNED_HANDLE_CLEANUP, not zero global native kernel/service allocations. Read-only documented CLI Hidumper process FD/memory or service help is permitted where available, but total FD/PSS and global service counters are not per-player leak proof. Do not invent a per-app metric; if service counters are unavailable/denied, label UNKNOWN/NOT PROVEN and explain the missing supported ownership interface. Use no privilege escalation, global settings changes, app force-stop, unsanitized private service dumps or evidence manufacturing. Reference capability help for documented API26 hidumper process FD/memory where applicable; use only real supported commands on this image.

C. DISTINCT MP4 recovery is a conditional NEW test: only after real native player release and receiver release plus every necessary supported app-attributable resource guard have passed without unexplained native errors, create a NEW System backend+surface and prove independent H264/AAC MP4 prepared/playing/first-frame/positive position/normal release. Never recycle the old standalone MP4 PASS as a post-HLS recovery PASS. If essential audio/surface/service attribution remains UNKNOWN or suspicious, recovery is NOT RUN — GATE UNPROVEN. Do not weaken the gate to green the result.

D. Full task-scoped autonomy applies to native ArkTS/C++ player, resource cleanup implementation, HLS harness and controlled task-owned fixture, but only in isolated scratch. Track actual failure → specific causal patch → focused test. Maximum FIVE meaningful repairs, FIVE necessary x86 simulator builds, THREE needed parameterized OHPM installs, TWO ABI/source/bundle-audited nondestructive installs, TWO HLS attempts (second after real change) and ONE conditional recovery attempt. 40 active minutes maximum. Never rerun passed FFmpeg/WebP/standalone MP4 case merely to green the summary, no 59-case format matrix. Stop unresolvable paths, return truthful partial evidence and smallest owner action. Do not retry an identical failure unchanged.

Before any new install, require generated local MPV stub, strict x86 ELF native HAP audit with only machine62 liblinkora_ffmpeg.so (no arm64/MPV/AKI/CXX), embedded com.linkora.player.simulator, and actual source-bound test candidate SHA. Pure CLI; no GUI or signing credential work, uninstall/wipe/reset. Do not change original project or other user's apps/processes.

## 3. Publication and final contract

Any tracked code fix is committed only to separate branch codex/phase8f-hls-resource-recovery-v1 based on this task dispatch, after exact diff/secret review; never directly to feature branch. One concise sanitized public report may be written only to docs/PLAYBACK_PHASE8F_HLS_RESOURCE_OWNERSHIP_RECOVERY_REPORT.md from a separate clean report checkout at unchanged task dispatch, with one normal push, freshfetch parent/diff/blob/readback. Keep all raw logs, HAP/media, private endpoints, user/device IDs, local paths, tokens and credentials private. No rebuild/media retry just for publication.

Final fields: TASK_ID; SOURCE_SHA; DISPATCH_SHA; CANDIDATE_SHA_OR_NONE; HLS_PENDING_STATE_AND_NATIVE_RELEASE; EARLY_AND_20S_RECEIVER_RELEASE; AUDIO_ATTRIBUTION; SURFACE_ATTRIBUTION; MEDIA_SERVICE_ATTRIBUTION; CONDITIONAL_DISTINCT_MP4_RECOVERY; REPAIR/BUILD/OHPM/INSTALL_COUNTS; GUI0/SIGN_APP0; ORIGINAL_WORKSPACE_READ_ONLY; FIRST_UNRESOLVED_BLOCKER; STOP_REASON_IF_ANY; NEXT_GPT_ACTION; EVIDENCE_SHA_OR_NONE. Only actual evidence can be PASS. Codex must stop when attribution is unsupported, no safe fix is known or any quota reached; do not self-dispatch or redo old task IDs.
