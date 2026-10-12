# Codex Task — CLI Simulator Media Features with Bounded Autonomous Repair

> STATE: SUPERSEDED — USER EXPANDED ALL-ERROR AUTONOMY; NEVER EXECUTED AS THIS ID
> SUPERSEDED_REASON: max task-scoped permission for ALL media/runtime/build/test errors; distinct successor task required
> TASK_ID: phase8f-level1-cli-media-function-bounded-autorepair-v1
> REPOSITORY: baozi510/Linkora
> BRANCH: feat/playback-capability-phase8
> LEVEL: LEVEL_1_FUNCTIONAL — X86 SIMULATOR MEDIA
> SOURCE_SHA: 8089b19ce2d932f070b4be6661e6317e204277ee
> ALLOWED_DISPATCH_DRIFT: docs/CODEX_VALIDATION_TASK.md ONLY
> PREVIOUS_TASK: phase8f-level1-cli-har-stub-prebuild-and-app-open-v1 — CLOSED, NOT TO BE REPEATED
> APP_OPEN_EVIDENCE: 4eeeb8de4ee6c18794bd8145b1ab1ba051cdfb88
> MODE: CLI ONLY; NO GUI/IDE WINDOW/COMPUTER USE
> GOAL: REAL FFMPEG DECODED FRAME + WEBP OUTPUT IF REACHABLE + SYSTEM MP4 PLAYBACK; HLS CANCEL IF INDEPENDENTLY SAFE
> MAX_ACTIVE_TASK_MINUTES: 20
> MAX_SCOPED_X86_DEBUG_BUILDS: 3 = INITIAL ONLY IF NEEDED + MAX 2 DISTINCT REPAIRS
> MAX_PARAMETERIZED_OHPM_INSTALLS: 2 = INITIAL ONLY IF NEEDED + MAX 1 FIX-NECESSARY REINSTALL
> MAX_NONDESTRUCTIVE_SIMULATOR_APP_INSTALLS: 1, ONLY IF NEEDED AND NEW HAP PASSES ABI/IDENTITY AUDIT
> MAX_MEDIA_CASE_ATTEMPTS: 1 PER INDEPENDENT CASE; NO IDENTICAL RETRIES
> MAX_TRANSPORT_FETCH_RETRY: 1, ONLY TRANSIENT AND SAFE
> MAX_MEDIA_FIX_CYCLES: 2 EVIDENCED CAUSAL FIXES IN ISOLATED CHECKOUT TOTAL
> NO_MANUAL_SIGN_APP/OLD_KEYSTORE/GUI/APP_UNINSTALL/WIPE/RESET/USER_WORKSPACE_WRITE: ZERO
> NO_DEFAULT_ARM64/RELEASE_BUILD; NO FULL 59-CASE MATRIX
> STOP_ON_UNSOLVABLE: NEEDS GPT DECISION — STOPPED WITH GROUNDED ERROR AND NEXT SMALLEST ACTION

## Supersession notice — no reported execution under this ID

**This task ID is SUPERSEDED (not executed, not failed, and not runtime PASS).** The user granted Codex broader autonomy to change **all task-relevant code/tests/runtime/media**, not only build/installation or two narrow media fixes. The successor is a DIFFERENT source-bound READY task issued after the policy update. Do not replay this ID or claim its lack of report is evidence that media passed/failed.

Latest official owner authority: top of `docs/AI_WORKFLOW.md` ("Maximum task-scoped Codex autonomy across ALL errors"), bounded to isolated scratch, real media evidence, a non-destructive CLI-only simulator, a separate candidate branch for tracked source modifications, and explicit STOP.

## 0. Follow the NEW canonical six-step workflow, not repeated one-off audit loops

Read `docs/AI_WORKFLOW.md` top "Six-step GPT→Codex task execution workflow", current `docs/MASTER_IMPLEMENTATION_PLAN.md`, `docs/IMPLEMENTATION_STATUS.md`, `docs/SESSION_HANDOFF.md`. This task gives Codex **real autonomy**: inspect required directories, run media checks, edit config/ArkTS/native/diagnostic source within a NEW isolated scratch checkout and validate justified fixes. Codex does NOT have to ask GPT before an ordinary fixable compiler or test error. It MUST stop if no supported causal fix is known, the identical failure persists without materially changed inputs, two justified fix cycles fail, the total active task exceeds 20 min, or any hard safety boundary is reached; report the observed error and one clear recommendation rather than re-dispatching or looping.

**History:** The immediately preceding completed evidence commit `4eeeb8de4ee6c18794bd8145b1ab1ba051cdfb88` contains one report `docs/PLAYBACK_PHASE8F_CLI_HAR_STUB_PREBUILD_APP_OPEN_REPORT.md`. It independently reports source-compatible simulator x86_64/API26 Hvigor build exit0, LOCAL MPV stub, x86 HAP native ABI audit exit0 (only ELF machine62 `liblinkora_ffmpeg.so`), embedded bundle `com.linkora.player.simulator`, native CLI install exit0, EntryAbility start exit0/foreground and bounded no-fatal log. No source code repair was needed. The successful new HAP SHA256 reported privately is `992749423D5CBE34179D5E4B9C7BB0A9FDD3AD368E16B762C8FAB368AAD2752C`. **This is app-open PASS, NOT FFmpeg/WebP/System MP4/HLS PASS.** Do not rebuild or reinstall just to reprove prior case.

One source tree, two native sets: simulator x86 FFmpeg analyzer + System AVPlayer + fail-closed local MPV Stub; default ARM64 real MPV and FFmpeg. User priority is MEDIA functionality, not UI look. H.264/HEVC/AAC video/audio encoding is NOT an existing feature; `SystemWebPEncoder` implements image/WebP encoding.

## 1. Low-cost preflight and reuse already installed app WHEN genuinely source-bound

- Fresh-fetch exact dispatch, verify direct SOURCE_SHA parent, task-only diff; SOURCE is previous evidence followed by only the five docs workflow/closure changes, no production code changes. Keep original potentially dirty `D:/Linkora` untouched except already user-approved **read-only** inspection of pinned x86 FFmpeg prebuilt `third_party/ffmpeg/prebuilt/x86_64` and copy-out of validated manifest/headers/four static libs to isolated scratch ONLY if necessary. No access to old stopped private checkout, keystore/signing profiles or unrelated user data. No resetting/checkouts/builds in the original.
- Confirm authorized connected emulator x86_64/API26 and normal currently installed `com.linkora.player.simulator` Ability/functional entry with bounded CLI native status. If the current installed version is provably source-compatible with unchanged production blobs and reported app-open SHA/provenance, **reuse it** without ohpm install, rebuild or application reinstall. If provenance is UNKNOWN, do not inherit runtime PASS; choose ONE source-aligned scratch build within budget only if necessary and legal. Keep original app and its data.
- Read only current `entry/src/simulator/RuntimeDiagnostics.ets`, `entry/src/simulator/ets/diagnostics/FfmpegRuntimeSmoke.ets`, `AnalyzerIntegrationSmoke.ets`, `entry/src/main/ets/services/SystemWebPEncoder.ets`, `SystemPlaybackPort.ets`, `PlaybackEngine.ets`, approved simulator fixture runbook/manifest and safe CLI diagnostics. `RuntimeDiagnostics` uses explicit `Want` parameters `linkoraFfmpegSmoke` or `linkoraAnalyzerSmoke`, and approved **controlled** local endpoint; do not print private endpoint or regenerate all 59 fixtures. FfmpegRuntimeSmoke expects its specific MP4/MKV input; a different old MP4 does not prove that harness PASS. If fixture-specific bytes truly absent, the case is `DEPENDENCY_BLOCKED — FIXTURE`; do not download arbitrary samples, access other users' endpoints or invent a fixture PASS. Independent runnable cases can continue.
- No UI layout/pixel/screenshot/visual review. CLI actions that launch Linkora's Ability solely to invoke genuine media functionality are allowed, but a running process alone is NOT decoder or playback PASS. Avoid repeated app starts when onCreate-only diagnostics cannot reinitialize cleanly.

## 2. Genuine one-attempt media cases with priority and independence

**A — Actual x86 FFmpeg decoder:** If approved existing diagnostic route and exact fixture are available, invoke one bounded native `FfmpegRuntimeSmoke` operation (its one existing run may internally have multiple named cases; keep original per-case results). Record probe/container/video/audio codec metadata separately from REAL frame extraction: width>0, height>0, RGBA bytes equal width×height×4, actual frame timestamp and hash/fresh buffer. Probe PASS without a decoded frame is NOT DECODER PASS. Existing cancellation/timeout/source-client cleanup cases may be observed from same invocation without rerunning. Don't attempt to pass unavailable native MPV Stub.
 
**B — Real supported encoding:** Prefer the existing `AnalyzerIntegrationSmoke` feature path for `SystemWebPEncoder`; when its approved endpoint/fixture route is available, record actual encoded WebP bytes, supported format/signature and image dimensions if a real decode/recheck is implemented. If the harness only confirms a signature, say `WEBP_SIGNATURE PASS; ROUNDTRIP NOT PROVEN`. If no callable route, `NOT RUN — HARNESS/ROUTE UNAVAILABLE`, not `ENCODER FAIL`. There is no actual H.264/HEVC/AAC video/audio transcoder; do not fabricate one.

**C — Real System AVPlayer playback:** With an approved existing H.264/AAC MP4, test one actual System backend prepare/PLAYING, first-frame/native event if available, positive position, pause, seek and normal bounded release using an existing safe functional route. Do not substitute Play() invocation, mock or UI appearance for native playback. Media case remains `NOT RUN` if no reliable route/controlled fixture exists. If a **small simulator-only test harness change** is necessary and a proven fix is possible within remaining budget, Codex may implement it in scratch and verify; if requiring new signing/deleting apps/unbounded infrastructure, STOP case and hand off recommendation.

**D — Conditional HLS cancel and recovery:** Only if app/native state remains safe and an existing authorized HLS H264 fixture/route is available: one real PREPARING cancellation before prepared with native candidate release and stale callback isolation, early ~3–5 s and >20 s app resource observations, then one distinct recovered MP4 only after release and cleanup positively demonstrated. Without native release proof, record `NOT PROVEN` and skip dependent recovery. No force-stopping app or server to manufacture clean results.

Cases are independent where safety permits. Each receives `PASS / FAIL / BLOCKED / NOT RUN / NOT PROVEN` with attempt count and minimal causal evidence. Real ARM64 MPV, advanced hardware codec/HDR/DV and whole matrix remain device/milestone work.

## 3. Autonomous SCRATCH fixes — with explicit budget and STOP

- Codex MAY inspect authorized CLI/native tools, build/package caches and source and edit relevant scratch-only scripts, diagnostics, ArkTS code, CMake or target/config when the real error justifies a specific fix. **At most two distinct fixes** within this task; for each, write down `observed error → causal hypothesis → exact diff → targeted verification → new result`. Never retry an identical failed command with identical state. Stop early if tool capability, fixture, ABI, native API support or signature failure has no supported safe fix in scope.
- If a scratch fix needs to change runtime code, put patch on separate `codex/phase8f-media-bounded-repair-v1` candidate branch from this exact dispatch; code branch MAY be committed/pushed once after reviewing exact changed paths/secret safety. **No production/config edits directly to `feat/playback-capability-phase8`; no merges/force pushes/auto PR.** Bind any new build/HAP/runtime claims to the actual code candidate SHA, not the older SOURCE_SHA. Do not stage ohpm generated lock files, x86 prebuilts, private media/logs or secrets.
- Only build if required by a concrete scratch change or unprovable prior artifact identity, using existing official parameterized CLI `ohpm install --pf oh-package-simulator-params.json5` and direct Hvigor `-p parameterFile=oh-package-simulator-params.json5`, simulator product/entry target. Up to 3 **total** actual scoped Debug build attempts, with second/third only after **different** grounded repairs; up to 2 parameterized installs if a dependency repair requires it. Each freshly built HAP must pass existing x86 native ABI audit (only x86 liblinkora_ffmpeg, no foreign ARM64 libraries), actual `com.linkora.player.simulator` embedded ID, and source/commit binding BEFORE any installation. One nondestructive CLI install/upgrade at most, only for safe owned simulator identity and verified artifact; no old keystore, manual SDK sign-app, uninstall, clear data, reset/wipe or GUI.
- **STOP conditions (mandatory):** 20-minute active work budget; two attempted independent justified patches do not make progress; repeated same error after no grounded change; required fixture or CLI harness unavailable with no safe one-step remedy; unsigned/signature or HAP ABI failure without proven repair; exceeding build/install attempt caps; any privacy or original-workspace mutation risk. On stop set `NEEDS GPT DECISION — STOPPED` (or `GLOBAL_SAFETY_STOP` for actual compromise), leave unresolved dependent cases NOT RUN, identify EXACT first blocker and next smallest owner decision. It is correct to stop with partial useful results rather than blindly try more.

## 4. One concise outcome report, separate candidate code

Only authorized new PUBLIC evidence file in the feature branch (if remote unchanged from dispatch):
`docs/PLAYBACK_PHASE8F_CLI_MEDIA_BOUNDED_AUTOREPAIR_REPORT.md`.

Stage only this single report from a separate clean evidence checkout, one ordinary nonforce push after HEAD check; exact parent dispatch, file diff/mode/blob and remote full-text fresh readback. Separate `codex/*` candidate branch for code fixes only if real code changed. Report task/dispatch/source/candidate SHA, effective installed artifact provenance, actual case attempts/results, root causes and repair diffs, build/dependency install counts, simulator HAP ABI/install statuses if relevant, exact stop reason and smallest owner decision; private raw process logs, paths, device/user IDs, local approved endpoint/token, HAP/media, screenshots, keystore/sign cert/key fingerprints remain PRIVATE. Do not regenerate archives/reports to green publication; if publication blocked, preserve the local observed result.

**Mandatory final:** `TASK_ID; SOURCE_SHA; DISPATCH_SHA; RESULT GOAL/PARTIAL/STOP; ACTUAL DECODED FRAME; WEBP IMAGE ENCODE; SYSTEM MP4 PLAY/PAUSE/SEEK; HLS CANCEL/RESOURCE/RECOVERY; FIX COUNT; BUILD COUNT; OHPM COUNT; INSTALL COUNT; CANDIDATE CODE SHA OR NONE; GUI=0; KEYSTORE/MANUAL_SIGN=0; ORIGINAL WORKSPACE READ-ONLY; EXACT FIRST BLOCKER; NEXT OWNER ACTION; EVIDENCE_SHA OR NONE`. Never self-dispatch another task; GPT independently reviews this result before new execution.
