# Codex Task — Full Autonomous Media Runtime Repair on CLI Simulator, with Hard Stop

> STATE: READY
> TASK_ID: phase8f-level1-cli-media-all-error-autonomous-repair-v2
> REPOSITORY: baozi510/Linkora
> BRANCH: feat/playback-capability-phase8
> LEVEL: LEVEL_1_FUNCTIONAL — FULL TASK-SCOPED AUTONOMY
> SOURCE_SHA: 7f94e2deabe6372c05d46e10883b82e0d3f386b8
> ALLOWED_DISPATCH_DRIFT: docs/CODEX_VALIDATION_TASK.md ONLY
> SUPERSEDED_UNEXECUTED_ID: phase8f-level1-cli-media-function-bounded-autorepair-v1
> PREVIOUS_COMPLETED_APP_OPEN_EVIDENCE: 4eeeb8de4ee6c18794bd8145b1ab1ba051cdfb88
> MODE: CLI ONLY — NO IDE/DESKTOP GUI/COMPUTER USE
> GOAL: REAL X86 FFMPEG DECODE + SUPPORTED WEBP ENCODE + SYSTEM MP4 PLAYBACK, HLS CANCEL/RECOVERY IF SAFE
> AUTONOMY: MAY CHANGE AND TEST ALL TASK-RELEVANT SOURCE, NATIVE, MEDIA LOGIC, HARNESS, FIXTURE, BUILD/ENVIRONMENT ERRORS IN ISOLATED SCRATCH
> MAX_ACTIVE_MINUTES: 40
> MAX_CAUSALLY_JUSTIFIED_REPAIR_CYCLES: 5 ACROSS ALL ERROR TYPES
> MAX_SCOPED_X86_SIM_DEBUG_BUILDS: 5, ONLY IF NEEDED
> MAX_PARAMETERIZED_OHPM_INSTALLS: 3, ONLY IF NEEDED
> MAX_NONDESTRUCTIVE_OWNED_APP_INSTALLS: 2, ABI/SOURCE/IDENTITY GATED
> MAX_PER_INDEPENDENT_MEDIA_CASE: 2, SECOND ONLY AFTER A REAL CAUSAL CHANGE
> MAX_SAFE_TRANSIENT_READ_RETRY: 1
> STOP_IF_UNSOLVABLE_OR_BUDGET: NEEDS GPT DECISION — STOPPED; NO IDENTICAL RETRIES
> DO_NOT_TOUCH: ORIGINAL WORKSPACE WRITES / OLD STOPPED CHECKOUTS / KEYSTORE / SIGNING SECRETS / OTHER USER APPS
> NO_GUI / NO_MANUAL_SIGN_APP / NO_OLD_KEYSTORE_PROBES / NO_UNINSTALL_WIPE_RESET_OR_SIGNATURE_BYPASS: ZERO
> DEFAULT_ARM64_RELEASE_DEVICE_TESTS: OUT OF SCOPE
> TRACKED_CODE_CHANGES: SEPARATE codex/* CANDIDATE BRANCH ONLY; GPT REVIEWS BEFORE MERGE

## 0. The user's newest grant expands ALL fixes, not just compile and install

The user explicitly says Codex should have **maximum autonomy to modify and fix errors of every relevant type**, not just build/install. Treat this as task-scoped implementation and testing authority, NOT a read-only/static job and NOT a restriction to "small harness" edits. The top `docs/AI_WORKFLOW.md` section `Maximum task-scoped Codex autonomy across ALL errors` is canonical; it overrides archived narrower limits. Codex does **not** need to request approval for each normal compiler failure, ArkTS/C++ bug, playback race, FFmpeg decoder issue, WebP encoder bug, HLS cancellation leak, test harness bug or relevant local fixture/route issue. Implement the correction, run targeted tests and collect real evidence while within caps and safe boundaries. Do not claim PASS from a stub/mock or static review.

The previously published `phase8f-level1-cli-har-stub-prebuild-and-app-open-v1` report (evidence SHA `4eeeb8de4ee6c18794bd8145b1ab1ba051cdfb88`) states actual local MPV Stub resolution, one valid x86_64 `liblinkora_ffmpeg.so` HAP audited with ELF machine62, embedded `com.linkora.player.simulator`, native install PASS and EntryAbility foreground PASS. This is **basic app-open only**, not decoder/encoder/player PASS. Production source/MPV Stub unchanged since that app-open report except documentation and task dispatch updates. New task ID replaces prior media v1 (SUPERSEDED without execution evidence), not a rerun.

## 1. Stage 1 — source binding and minimal real prerequisites

1. Fresh-fetch exact dispatch, confirm direct parent SOURCE_SHA and only `docs/CODEX_VALIDATION_TASK.md` drift. Prior media v1 dispatch `8ceb7d6505f23f84605379188d88fb3db950ec4c` → SOURCE must be only `docs/AI_WORKFLOW.md`, `docs/MASTER_IMPLEMENTATION_PLAN.md`, `docs/IMPLEMENTATION_STATUS.md`, `docs/SESSION_HANDOFF.md`, `docs/CODEX_VALIDATION_TASK.md`, with no product source changes. Read current workflow, architecture, current task, status/handoff, actual simulator source/test functions. Keep original maybe-dirty developer worktree immutable; use a new isolated checkout. Read original `third_party/ffmpeg/prebuilt/x86_64` manifest, known four headers and four archives ONLY as already authorized, copy their verified bytes OUTWARD to isolated ignored prebuilt prefix if a build requires it; no original builds/writes.
2. CLI check approved current simulator x86_64/API26. One normal simulator CLI start only if absent; no GUI or emulator reset/wipe. Prefer reusing currently installed same-source `com.linkora.player.simulator` if actual package/Ability/source provenance is known (including reported HAP SHA256 `992749423D5CBE34179D5E4B9C7BB0A9FDD3AD368E16B762C8FAB368AAD2752C`); do not duplicate builds/installs merely for repeated proof. If provenance unprovable and runtime needs changed code, use genuinely source-bound audited new HAP under budgets.
3. Inspect existing `entry/src/simulator/RuntimeDiagnostics.ets`, `FfmpegRuntimeSmoke.ets`, `AnalyzerIntegrationSmoke.ets`, `SystemWebPEncoder.ets`, `SystemPlaybackPort.ets`, `PlaybackEngine.ets`, `AdaptivePlaybackPort.ets`, existing approved fixture corpus, simulator runbooks/controlled local services and actual CLI calls. Read relevant source fully enough to identify correct functional entry points. No broad recursive private disk scan, no old stopped private log or artifact excavation. At most one safe transport read retry, no infinite env preflights.

## 2. Stage 2–4 — act on any function/test/native error; real acceptance

**A. FFmpeg actual decode:** Run the existing callable x86 native diagnostics with exact approved MP4/MKV inputs where available. Distinguish metadata probe vs `extractFrame` decoded RGBA width, height, `width*height*4` buffer length, valid time/content, and real cancellation/timeouts/resource cleanup. A probe never counts as decoder PASS. If C++/ArkTS binding, native decode, codec dispatch, memory lifetime or fixture endpoint fails, Codex CAN MODIFY its actual implementation and tests in isolated scratch and retry once with a justified changed version; do not stop merely because it's not a build issue.

**B. Real WebP encoding:** Use existing `AnalyzerIntegrationSmoke` and `SystemWebPEncoder` to verify actual encoded `image/webp` data/signature and, if implementable within budget, round-trip real decoder size/data. If ImagePacker, memory/format conversion or harness bugs occur, Codex can fix them; do NOT conflate WebP image encoding with nonexistent FFmpeg H.264/HEVC/AAC video/audio transcoding.

**C. System AVPlayer playback:** On user-approved controlled H.264/AAC MP4, verify native prepared/start/PLAYING and independently positive progress; pause/resume/seek and error handling/normal resource release. If a true System AVPlayer call, session race, ArkTS type, source resolver, URI/proxy mapping, controlled fixture or diagnostic invocation is wrong, fix the relevant code/tests/controlled task-owned media harness and actually revalidate. Mock state-only tests are supplementary, NOT actual native player PASS.

**D. HLS H264 pending cancellation / recovery:** If legally approved fixture route and safe current native state allow, start a PREPARING HLS, cancel while pending before prepared, verify normal native release and suppressed stale callbacks, early 3–5 s and later >20 s app-associated audio/surface/service resources, then one distinct MP4 recovery only after cleanup proven. If leaking resources, stale error, wrong session, server/proxy or decoder integration causes an actual failure, Codex may modify source/test/controlled fixtures in scratch to repair and retest under caps. Never use force-stop, simulator wipe, fraudulent counters or auto-fallback to claim cleanup PASS.

**Scope of autonomous change: FULL task-relevant code and test path.** Codex may create targeted ArkTS/Hypium tests, C++ unit/native checks, correct source interface contracts, fix FFmpeg/CMake, build task args, native package binding, System WebP/AVPlayer code, playback engine async resource races, diagnostic instrumentation, controlled task-owned media server/fixture plumbing, without preapproval per issue. For needed fixture generation use a fully approved task-owned local test source only; do not download arbitrary copyrighted/private samples or overwrite approved fixtures. Stop/clean task-owned servers without affecting other listeners. **No UI layout/pixel beauty tests; CLI-only.**

Use these outcome labels for EACH independent case with counts: `PASS`, `FAIL`, `BLOCKED`, `NOT RUN`, `NOT PROVEN`, `UNSUPPORTED`. A case may be retried at most ONCE after a meaningful evidenced code or input change. Real simulator System codec limits and x86 MPV Stub are distinct from real ARM64 MPV/hardware codec capability.

## 3. Stage 3/5 — repair loop and hard STOP

For every repair: `actual failure / private reproducible observation → causal hypothesis → exact source or fixture/config diff in scratch → targeted verification → new status`. **Up to 5 such cycles ACROSS ALL types**, not 5 per class. Do NOT retry same command with same input to hope for different result. At most 40 minutes of actual active work; at most 5 simulator Debug Hvigor builds (only if necessary), 3 parameterized ohpm dependency installations (only for a real graph change), 2 nondestructive new HAP installs when genuinely needed, 2 real attempts per independent media case (second after a proved meaningful change). No serial loop to exhaust time or budgets; a correct first result should terminate that case.

Builds require actual `ohpm install --pf oh-package-simulator-params.json5` target context if needed and direct CLI Hvigor with `-p parameterFile=oh-package-simulator-params.json5` for `simulator`/`entry@simulator`. Before any install verify real local MPV Stub lock, actual simulator package ID `com.linkora.player.simulator`, and strict x86 ELF ABI HAP audit exit0 (ONLY approved `liblinkora_ffmpeg.so` machine62; zero ARM64 MPV/AKI/C++). Never reuse old ABI-invalid package, rebuild ARM64/default/Release in this checkpoint, perform manual SDK sign-app/keystore/password probes, uninstall any app, clear/reset/wipe target or bypass signature verification. Never edit user's original worktree or global SDK/IDE.

**STOP MUST HAPPEN** if any of: (i) no safe supported root-cause fix or necessary fixture/SDK/feature is unavailable, (ii) same error repeats without fresh evidence/new hypothesis, (iii) five causal repairs attempted without satisfying goal, (iv) 40 active minutes or any build/install/case ceiling reached, (v) actual privacy/original-workspace/other-app safety risk. Stop affected dependent operations, preserve already proven independent results, and return `NEEDS GPT DECISION — STOPPED` with exact first blocker and smallest owner action; `GLOBAL_SAFETY_STOP` for actual damaging safety incident. Do not begin another equivalent task, retry indefinitely, or substitute a static green report for runtime evidence.

## 4. Stage 6 — candidate production changes and one honest report

Any tracked source/build/test changes stay ONLY inside isolated scratch until reviewed; if material, Codex may commit/push one `codex/phase8f-media-all-error-repair-v2` **separate candidate branch** from this dispatch, after reviewing exact paths/diff, excluding generated lock/prebuilts/media, with real tested candidate SHA. Do NOT push changes or merge directly into `feat/playback-capability-phase8`; GPT owner reviews and decides. A runtime PASS of a patched candidate must identify its exact compiled candidate SHA, not the unmodified original SHA.

Only one NEW sanitized public report at:
`docs/PLAYBACK_PHASE8F_CLI_MEDIA_ALL_ERROR_AUTONOMOUS_REPORT.md`
may be committed on original feature branch from a **separate clean report checkout** if remote is still exact dispatch. One ordinary no-force push then fresh-fetch confirm parent=dispatch and only that report path changed. If branch HEAD moved or publication blocked, report results and any candidate SHA without retrying builds/media to package evidence. No secret/private credentials, user path/target ID, private media/endpoint, raw logs/HAP/screenshot/certificate data or unauthorized project inventory in public report.

Final summary must include: `TASK_ID; SOURCE_SHA; DISPATCH_SHA; RESULT=GOAL_PASS/PARTIAL/STOPPED; ACTUAL_FFMPEG_DECODE; WEBP_ENCODER; MP4_PLAY_PAUSE_SEEK; HLS_CANCEL_NATIVE_RELEASE_EARLY_20S_RECOVERY; ALL_ERROR_REPAIR_COUNT; EACH_PATCH_CAUSE; BUILDS; OHPM; INSTALLS; CODE_CANDIDATE_SHA_OR_NONE; GUI=0; SIGN_APP=0; USER_ORIGINAL_READ_ONLY; FIRST_REAL_BLOCKER; STOP_REASON_IF_ANY; NEXT_OWNER_DECISION; REMOTE_EVIDENCE_SHA_OR_NONE`. Submit outcomes to GPT; do not self-dispatch new IDs. The goal is genuine decoder/encoder/player behavior, not only successful packaging.
