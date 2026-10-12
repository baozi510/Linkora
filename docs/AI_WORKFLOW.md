# Linkora AI Collaboration Workflow

## Purpose

## CURRENT AUTHORITY — Maximum task-scoped Codex autonomy across ALL errors (2026-10-13)

**Latest explicit user grant supersedes narrower build-only or media-harness-only repair restrictions below:** GPT owns the task goal, source baseline, hard safety boundaries and final acceptance. **Codex has full discretion to inspect, change, implement, instrument, test and independently troubleshoot ANY technically relevant failure needed to reach that goal inside a NEW isolated checkout** — production ArkTS, core playback state/races, FFmpeg/other C++ or native code, codecs, WebP encode, media analysis, System AVPlayer, HLS, release/recovery, tests, fake/media runners, diagnostics, controlled fixture/service wiring, build profile, OHPM/Hvigor/target isolation, local scripts and documentation. This includes fixing actual MEDIA FUNCTION failures, NOT just builds/installation. The earlier words "only a small harness change" and "at most two media fixes" are superseded. Codex may add truthful targeted tests and run them, not just inspect. Authorized directory read and copy of pinned inputs remains in force.

**MAXIMUM AUTHORITY DOES NOT MEAN UNBOUNDED EXECUTION OR DIRECT PRODUCTION MERGE.** Within this task's goal and approved simulator:
- Work in a fresh isolated clone/scratch, not the potentially dirty original developer worktree. Existing original FFmpeg pinned input subtree and relevant SDK/toolchain can be read; bytes may be copied outward into scratch and verified; never write/reset/stash/clean/build in the original. Don't inspect secrets, credentials, unrelated projects/private logs or old stopped checkouts.
- Any relevant source/code/config/test change in scratch is authorized, including substantial refactors if warranted by a concrete traced failure; preserve default ARM64 real MPV vs simulator x86 FFmpeg plus stub and preserve production app identity. Do not silently weaken checks, turn off guards, hard-code a mock PASS or modify an HAP to hide ABI failure. A **separate** `codex/*` candidate branch may contain tracked fixes; no direct push/merge to the protected feature branch. GPT reviews owner acceptance.
- Pure CLI only: no desktop DevEco/GUI/computer-use. User's x86_64/API26 simulator is the functional target. Controlled local fixture generation/server/reverse mapping and new instrumentation are allowed ONLY in task-owned isolated space, for approved test media, when truly necessary to test requested media functions, and must be stopped/cleaned without touching other listeners or user apps. A generated media asset never constitutes a product decoder/encoder PASS by itself.
- Installation of a new source-bound HAP needs real x86 ELF/ABI plus embedded simulator bundle identity PASS first. Only non-destructive owned simulator bundle operations; no uninstall/force-stop other user applications, wipe/reset, disabling signature validation, manual SDK sign-app, old keystore/password or global SDK/IDE reconfiguration. ARM64/device acceptance never follows from simulator.
- **Hard bounded budgets for a fresh task unless STRICTER explicit dispatch values:** up to **40 minutes active execution**, at most **5 evidenced causal repair cycles** across *all* error types, **5 scoped simulator Debug builds** total, **3 parameterized dependency installations** only when a config change requires them, **2 non-destructive source-bound simulator app installs** total only if justified by a new vetted binary, **2 attempts per independent media case** (second ONLY following a materially changed code/fixture/route with causal evidence), and **one safe retry for a genuinely transient transport/read failure**. Do not run a "full format matrix" or all-source builds just to exhaust quotas. Reuse previously verified unchanged gates and installed code whenever provenance is reliable.
- **Retry rule:** Every repair loop must log `failure/evidence → root-cause hypothesis → exact scratch diff/input change → targeted test → new observation`. No identical rerun without a meaningful change. Stop a dependent case as BLOCKED if prerequisites (fixture, signing, simulator, native ABI, SDK support) are absent and no safe grounded fix exists. If same technical failure persists after material fixes with no new hypothesis, or the fifth repair/budget limit is reached, **STOP** and hand back `NEEDS GPT DECISION — STOPPED` with partial results and a minimal safe next step. Immediate `GLOBAL_SAFETY_STOP` for actual privacy/user-workspace damage.
- All observed errors and fixes are in scope, but **NOT RUN / NOT PROVEN / UNSUPPORTED / BLOCKED / FAIL / PASS** must be separate, source-bound and traceable. No inventing decoder frame bytes, WebP output, native cleanup or System playback evidence. One compact public report and, if code changed, one separate candidate branch is the normal handoff; no report/validation/recommit loops or Codex self-dispatch.

**Updated six-step contract:** 1 GPT supplies measurable outcome & permissions → 2 Codex checks source/target/preconditions at lowest cost → 3 Codex autonomously diagnoses/modifies ANY relevant source/environment/test failure in isolated scratch → 4 Codex validates the actual end-to-end functional behavior with bounded fresh evidence → 5 stop on goal achieved, unfixable issue, safety concern or any budget limit → 6 Codex reports precise result and candidate patch to GPT, GPT accepts or decides next task. This section takes precedence over earlier lower caps and narrower definitions anywhere in older archived plan/status/task text.


## CURRENT AUTHORITY — Six-step GPT→Codex task execution workflow (2026-10-13)

**User directive:** GPT dispatches an outcome-oriented task; Codex may inspect directories, execute tests and **independently repair observed problems inside a NEW isolated checkout** without asking for permission at each normal compiler/test error. But every task has explicit budgets and deterministic STOP/escalation conditions. This section overrides older instructions that either forbid all repair or allow vague repeated attempts. **Never repeat an already completed task ID.** Bound each report, source SHA and candidate artifact to their exact provenance. Do not invent runtime PASS.

**Six steps:**

1. **GPT dispatches a measurable goal and a dependency map.** Give `TASK_ID`, `SOURCE_SHA`, terminal success evidence, exact permitted directories/actions, negative permissions, per-stage ceilings, stop/partial-result semantics, and whether install/media is allowed. Example current simulator media goal: actual FFmpeg decoded frame, supported WebP image encode, actual System AVPlayer playback. CLI ONLY, no desktop GUI, keystore/password access, app-data deletion, or changes to the user's original potentially dirty project. Media functionality is the goal; UI layout/appearance isn't.
2. **Codex performs the cheapest correct preflight once.** Confirm branch, remote parent/source/diff, user-approved x86_64/API26 emulator and owned media fixtures, source-matched installed HAP/build provenance, pinned x86 FFmpeg inputs, actual local MPV stub dependency map and ABI, plus necessary CLI tools. Reuse actual recent independently verified source-bound PASS without rerunning it solely for evidence. A dependency block stops ONLY downstream operations; safe independent paths may continue.
3. **Codex tests, diagnoses and fixes in SCRATCH.** It may read relevant user-authorized build/native directories, copy vetted pinned x86 inputs outward to an isolated ignored prefix, run tools, inspect sanitized errors, edit its isolated source/config/test code, and retry after a **specific change justified by the preceding failure**. No direct patch/checkout/build/reset of original user workspace. Production fixes go to a separate `codex/*` candidate branch for GPT review, never straight to the protected feature branch; no generated locks/binaries/logs/secrets are committed. Any source changes require fresh source-to-artifact identity.
4. **Verify the smallest real acceptance gates in order.** Source/dependency → one targeted compile only when needed → genuine x86 native ELF/ABI and embedded simulator bundle identity → one non-destructive CLI install only when required and artifact PASS → callable app/actual media behavior. Independently label each case `PASS / FAIL / BLOCKED / NOT RUN / NOT PROVEN`. A static assertion, tool exit0, decoder probe without frame data, or bare Ability start never becomes real playback PASS. Keep System x86 simulator and ARM64 hardware MPV conclusions separate.
5. **STOP instead of looping.** Default ceiling **20 minutes of active task work**, **3 scoped builds total (initial + at most 2 evidenced fixes)**, **2 parameterized dependency installs total**, **1 audited non-destructive app install/upgrade**, **1 attempt per independent media case**, and **one retry of a purely transient transport read only when safe**; a task can specify STRICTER caps. **Never retry the same error with identical inputs**, spawn parallel builds, change SDK/global settings, guess credentials, uninstall/wipe, force-stop other apps, or repeatedly generate fixtures/reports. Stop immediately on actual privacy/workspace risk. Stop the affected path upon unresolved target/toolchain/signature/ABI/fixture blocker; if 2 distinct justified repairs have failed, no supported causal fix is known, or budget/time is spent, report `NEEDS GPT DECISION — STOPPED` with evidence rather than a fourth attempt. Record unrelated safe independent outcomes before stopping only if budget/safety permits.
6. **Codex publishes once and hands back a decision.** Produce at most one small sanitized report/evidence commit (on exact authorized path and unchanged source-bound dispatch), and at most one separate candidate-code branch if modified tracked files; avoid repeated archive/manifest-helper loops. Report goal achieved or NOT, counts/versions/attempted fixes, source/candidate SHA, observed errors, stopped dependent cases and precise smallest missing input/owner decision. No new self-dispatch, no task reincarnation, no claim of execution without actual tool result. **GPT separately verifies and accepts/rejects before merging or issuing the next distinct task.**

**STOP categories:** `GOAL_PASS` means exact requested functional checkpoint genuinely observed; `CASE_FAIL` means one case failed and independent safe cases may proceed; `DEPENDENCY_BLOCKED` means only dependent stages skipped; `NEEDS GPT DECISION — STOPPED` means no known safe fix within caps; `GLOBAL_SAFETY_STOP` means actual privacy/user workspace compromise. In all non-PASS states, preserve evidence and give one actionable recommendation, not a request for permission to repeat identical work. CLI only even if older docs say use IDE Run.


## 2026-10-12 — Simulator acceptance is media-function-first, NOT UI appearance

**Owner's updated priority supersedes the immediately preceding UI-pixel/foreground-layout checklist.** The x86_64/API26 simulator is a *functional test target*: test actual decoder/media analysis, supported encoding, media playback controls, cancellation and resource recovery. There is **no UI design, layout, screenshot, visual pixel ROI or player-polish acceptance gate** for this functional checkpoint. A real installed/running Linkora app, callable feature/diagnostics route and its own functional/native observations may be necessary to execute tests; process existence or launcher state alone does not prove media correctness. First-frame events and **actual decoded frame buffers** remain valid decoder/playback functional evidence, not a screenshot or UI-design gate.

**Actual current implementation split, not guessed capability:**
- `SystemPlaybackPort` uses HarmonyOS `media.AVPlayer` for real System playback/decoder on simulator; `PlaybackEngine` / `AdaptivePlaybackPort` handle play, pause, seek, error/fallback and pending cancellation. Test H.264/AAC MP4 and HLS H.264 cancellation only when actual controlled fixtures are ready. Observe true prepare/PLAYING/position changes, native cleanup and recovery if runnable.
- `linkora_ffmpeg` x86 native analysis module probes encoded codec/container metadata, calls `avcodec_send_packet/avcodec_receive_frame`, scales frames to RGBA, and has existing simulator `FfmpegRuntimeSmoke`. Actual video **frame decoding** and metadata probe may be checked; a probe-only response is NOT decoder PASS. This FFmpeg module does **not** establish a general video/audio *encoding* feature.
- `SystemWebPEncoder` is an existing application image encoder (RGBA/PixMap -> WebP ImagePacker). This is the honest current **encoding** scope; if it can be driven through an existing safe functional route, verify actual emitted WebP bytes and re-decode/dimensions, with truthful `NOT RUN` when route unavailable. Do not claim H.264/HEVC/AAC transcoding or FFmpeg video encoder support; if owner later explicitly requests media-file transcoding, that needs a separate feature implementation.
- Simulator `MpvPlaybackPort` reaches an unavailable stub/native boundary; MPV real decoding and advanced codec/hardware coverage remain real ARM64/device gates, not simulator PASS.

**Checkpoint order:** cheap source/target/fixture preflight; one source-compatible ordinary DevEco `simulator`/`entry@simulator` Debug Run/compile only if necessary; no old manual `sign-app` or inaccessible keystore; verify the installed app or diagnostics entry is callable without UI visual acceptance; priority (1) one real x86 FFmpeg probe+decode/frame result and cancellation/cleanup if existing harness allows, (2) existing WebP encoding only if safe route, (3) actual System playback MP4 prepare/play/position/seek/pause and HLS PREPARING cancel/cleanup/recovery. Independent cases continue after unrelated failures where environment safe. If app/diagnostic route unavailable, record cases `BLOCKED/NOT RUN`; do not add a bespoke harness or modify production code just to make this validation pass. One normal Run/one necessary compilation, zero duplicate verify builds or ARM64 matrix, no per-case retry loops or 59-case corpus regeneration. Small sanitized report with independent `PASS/FAIL/UNSUPPORTED/BLOCKED/NOT RUN` by case; no video picture quality or UI screenshot tests.

**Provenance and safety still mandatory:** source identity, real x86 native artifact when used, correct fixture hashes, legal installation, privacy, user-workspace protection. A real native frame buffer, codec metadata, normal release/resources and playback progression are core assertions; do not promote static source or simulation to runtime PASS. UI layout checks were a testing distraction, not the goal.


## 2026-10-12 — Simulator first: normal DevEco Run, NO prerequisite manual keystore

**Owner correction superseding earlier signed-HAP preconditions for simulator-only work:** The actual goal is a runnable Linkora **phone/tablet simulator**. Huawei official developer guidance states emulator/previewer debugging does **not require the developer to configure signing information**, whereas actual hardware requires app signing (https://developer.huawei.com/consumer/cn/develop-novice-guide/). Current Linkora `build-profile.json5` already defines `simulator` product with `signingConfigs: []`; `entry/build-profile.json5` defines `entry@simulator`; `scripts/verify-simulator.ps1` produces/audits an x86_64 simulator Debug HAP but is not an installation, Run/Debug or manual signing contract. The previous bespoke SDK `sign-app` keystore error `11014003` was a historic **extra manually imposed test step**, not evidence that the ordinary simulator Run requires that old keystore. Do not seek, reset, rotate, guess or handle original private signing credentials for emulator verification.

**New Level1 normal path:** in an isolated source-compatible project, with a running user-authorized x86_64/API26 emulator, select the `simulator` product and `entry@simulator` target, then invoke the installed DevEco Studio's normal `Run` once, allowing its documented normal build/install/start workflow. Do not run independent `sign-app`, inspect historical keystores, alter global signing configs or invoke the old V4 credential probe. Keep at most one necessary scoped simulator Debug compilation in this checkpoint and zero ARM64/default builds; do not run an additional separate `verify-simulator.ps1` build after IDE Run. If IDE/native build fails, mark build FAIL and other gates NOT RUN, without rerunning. If installation fails on this specific emulator, preserve exact returned error and classify `DEPENDENCY_BLOCKED — ACTUAL INSTALL`; investigate that distinct simulator-specific error later, never assume keystore in advance or bypass signature validation. Do not force-remove an existing user app or wipe/emulator-reset to force a successful install.

**Runtime acceptance after genuine installed foreground window:** actual Linkora UI/layout and visible pixels first; healthy MP4 first frame/positive position; independent HLS H264 System PREPARING cancellation with same pending candidate normally released and early/>20s zero associated resources; distinct recovered MP4 only if release and cleanup proven. One attempt each, scope failures to their dependencies. A screenshot of the launcher or only process/transport exit0 is not a UI PASS. Installed simulator System playback is not real ARM64 MPV or hardware codec PASS. No unexecuted test becomes PASS. Keep privacy/original workspace protections and tiny sanitized evidence.

**Clarification:** older signed-artifact and local-keystore blocks remain immutable *historical task results*, but they must not block the new normal simulator run. Current post-Level0 source modifications invalidate naïve use of older HAP built before those changes. A new IDE Run build is permitted solely because the user explicitly prioritizes reaching a running simulator checkpoint; it is not a return to compulsory per-edit builds.


This document makes GPT and Codex conversations disposable. GitHub is the durable project memory.

Neither GPT nor Codex should depend on previous chat context to know the current architecture, branch, phase, test state, or next action.

## Durable source-of-truth order

For implementation/design work, read in this order:

1. `docs/MASTER_IMPLEMENTATION_PLAN.md`
2. later explicitly approved architecture decisions
3. `docs/ARCHITECTURE_TARGET.md`
4. `docs/ARCHITECTURE_MIGRATION.md`
5. `docs/IMPLEMENTATION_STATUS.md`
6. `docs/SESSION_HANDOFF.md` CURRENT STATE
7. current phase report / validation evidence
8. actual branch/HEAD and affected source

Repository facts and executed validation evidence override stale historical "current" statements.

## New GPT session

The user only needs to send:

> 打开 GitHub 仓库 `baozi510/Linkora`，按照 `docs/AI_WORKFLOW.md` 的 New GPT Session 流程恢复项目上下文；先审查当前状态，不要直接改代码。

The new GPT session must:

1. inspect the actual repository branch/HEAD instead of trusting chat memory;
2. read the durable documents above;
3. distinguish current state from historical sections;
4. report current branch, HEAD, phase, validation state, blockers, next action, and important architecture deviations;
5. only then begin implementation when the user asks.

If documents disagree with code/evidence, investigate and explain the conflict before changing code.

## GPT implementation ownership

GPT owns:

- architecture review and design judgment;
- production-source implementation;
- bug fixes;
- migration decisions;
- durable handoff/status updates;
- writing the next Codex validation task.

When a GPT change needs validation, GPT must not leave the validation instructions only in chat.

GPT first creates an implementation/review commit. After its SHA exists, GPT creates a separate validation-dispatch commit that updates:

`docs/CODEX_VALIDATION_TASK.md`

The separate dispatch commit is intentional: it lets the task file contain the exact implementation source SHA without a self-referential commit hash.

## Codex validation ownership

Codex owns:

- builds and tests;
- simulator/device/runtime validation;
- raw evidence collection;
- PASS / FAIL / NOT RUN / NOT APPLICABLE / BLOCKED classification;
- validation report/evidence updates.

Unless a task explicitly changes this rule, Codex must not modify production source, architecture, build/test expectations, or bypass a failed gate.

If a source change is needed, Codex stops at the task's stop condition and returns evidence to GPT.

### Validation-environment normalization

Codex may repair **non-semantic validation-environment drift inside an isolated validation checkout** only when the current task explicitly permits it.

The canonical case is a Windows package manager rewriting tracked lockfiles from LF to CRLF while their Git-normalized content remains byte-for-byte equivalent to HEAD.

Codex may self-recover from that case only when all of the following are proven:

1. every affected path is explicitly allowlisted by the current validation task;
2. each worktree file hashes to the same Git-normalized blob as `HEAD:<path>`;
3. CRLF-to-LF normalized bytes are identical to the HEAD blob;
4. no dependency entry, version, checksum, graph, comment or other semantic content changed;
5. no other tracked file changed.

When all checks pass, Codex may restore only those allowlisted files from HEAD **inside the isolated validation checkout**, confirm the checkout is clean again, record the normalization evidence, and continue testing.

That restore is validation-workspace cleanup. It is not a production-source/test change and must never be committed.

If any normalized blob differs, any semantic content differs, any extra tracked path changed, or the restore does not return the validation checkout to clean state, Codex must STOP and return evidence to GPT.

This rule never authorizes modifying the user's unrelated dirty workspace.

## Approved noncritical tooling failure rule — 2026-10-12

User decision: **When a failure is demonstrably an auxiliary/toolchain problem and the affected step is NOT a critical test or required evidence gate, record it once and DO NOT repeat the test.** Do not turn optional tooling perfection into a reason to rerun full builds or playback. This rule applies prospectively to new Codex tasks; immutable stopped tasks and historical FAIL evidence retain their original verdicts.

Before executing a new task, GPT must identify each stage as **CRITICAL** or **OPTIONAL DIAGNOSTIC**, with a finite purpose and allowed result. A Codex executor must not retrospectively call a failed CRITICAL gate OPTIONAL just to continue.

- **OPTIONAL / record only** when all hold: the command is expressly marked OPTIONAL in the current task; objective evidence (original exit/status, error, context) identifies an auxiliary tool problem; its failure cannot affect source identity, security/privacy, product execution, required test assertions, artifact validity, evidence integrity or publication; and an already completed independent required check is sufficient to support all claimed results. Record `RECORDED — NONCRITICAL TOOLING ISSUE / NO RETEST`, affected and unaffected scope, observed numeric exit, provenance limitations, and no-repeat decision. Continue only unrelated preauthorized stages if safe. Do not edit/retry the helper, rerun builds, or create a new validation task merely to turn this optional step green. When unavailable to prove harmlessness, classify UNKNOWN/BLOCKED, not optional by wish.
- **CRITICAL / never waive**: source/branch/content protections; production test/build and ABI correctness when required for a claim; signer/profile legitimacy and installed native artifact when claiming installation; actual foreground and app-visible UI when claiming playback; native frame/pixels, target media data, ordered position, pending release, early and >20s cleanup and recovery when claiming their respective PASS; privacy/no-leak checks; accurate provenance of essential evidence; correct evidence path containment, artifact hashes/serialization and remote commit/push/verification. A failing or missing critical gate remains FAIL, BLOCKED, NOT RUN or NOT PROVEN. No inherited historical PASS and no unapproved rerun under a stopped ID.
- **Infrastructure-preflight first, cost-aware:** validate cheap necessary OS/SDK availability, authorized device target, permissions and publication feasibility before expensive verification when designing future tasks. Avoid exploratory emulator setting commands, unneeded JSON introspection, nested progress shells, concurrent polling and repeatedly creating auxiliary helpers. Once an essential prerequisite is absent, BLOCK only dependent test paths with accurate NOT RUN; continue safe independent checks and reporting, not automatic whole-chain retesting.
- **Publication:** an unrelated optional audit failure cannot invalidate sound already captured evidence, but security sanitization, exact source/staged bytes, Git path authorization, readable required evidence and remote publication are CRITICAL to an independent GitHub review. An inability to publish does not require replaying playback/build tests; preserve existing data, label `BLOCKED — EVIDENCE NOT PUSHED`, and handle transfer separately if explicitly authorized.
- **Truthful boundaries:** a successful build is not simulator runtime PASS; simulator MPV stub is not real MPV; native position progress is not displayed colored pixels; a configured emulator is not a running app; resource counts not observed are NOT PROVEN. Simulator-first / targeted-build-at-functional-checkpoints / full-ARM64-at-milestones / physical-device-batched applies under the later approved feature-first execution rule.

The goal is **product progress without waiving essential acceptance**. GPT owns any reclassification and task changes in separate commits. Codex uses only the latest READY task and its explicitly marked gates, preserving the user's original workspace and private artifacts.

## Approved feature-first test path and milestone build cadence — 2026-10-12

Latest user-approved strategy **supersedes the prior every-source ARM64-build-always cadence**, without changing the architectural compatibility objective. Read the detailed replacement in docs/MASTER_IMPLEMENTATION_PLAN.md (“Feature-first / Targeted-build / Milestone-verified / Device-batched”).

**Work is classified BEFORE execution** into:

1. `LEVEL_0_FEATURE`: GPT production work, source review and optionally narrow pure/unit tests; **no mandatory build per code change**. Must report `BUILD NOT RUN`, `TEST NOT RUN` where applicable, not assume green.
2. `LEVEL_1_FUNCTIONAL`: only when a runnable feature checkpoint is planned. First cheap preflight of actual emulator/target, existing legal signing/profile/fixture and source identity. If unavailable, block dependent runtime and record `BLOCKED — ENVIRONMENT` BEFORE builds, while finishing independent safe work. Otherwise use at most **one** smallest necessary Debug simulator (or relevant target) build when no independently verified source-compatible lawful artifact exists; target feature-focused runtime checks, not full coverage. If build omitted, state why and the proven artifact provenance.
3. `LEVEL_2_MILESTONE`: after a coherent feature batch or at a risky native/build boundary, run appropriate full ARM64 Debug/Release compile/link, ABI audits, simulator build and required regressions. A three-pass `default → simulator → default` verification chain requires specific demonstrated cross-target contamination risk; it is **not the default** and never triggered by unrelated diagnostic problems.
4. `LEVEL_3_DEVICE_BATCH`: genuine ARM64 MPV/native runtime, hardware codec, HDR/advanced audio, physical resources/performance, device-only protocols. Simulator and ABI evidence cannot substitute.

**Critical assertions remain strict at the point claimed:** source integrity, secrets/privacy for anything published, real build status if claimed, source-compatible signed install for runtime, true app foreground + visible UI, actual first-frame/pixel/progress, native pending release/early+>20s cleanup and independent recovery if claiming those outcomes. Unexecuted assertions remain NOT RUN / NOT PROVEN. Historical FAILED/STOPPED tasks are never rewritten as PASS or rerun under the same ID.

**Evidence policy:** keep only sufficient sanitized text and decisive result metadata. When an accessible verified plain-text log already substantiates a claim, optional extra gzip mirrors, redundant text↔gzip pair counts or exhaustive inventory recalculations are `OPTIONAL DIAGNOSTIC`; they are not automatic gates and failure does not trigger another compile. If a compressed item is the **only** copy of an essential artifact or required to establish provenance, its readability/integrity is critical. Safe publication still needs actual candidate-wide privacy review, allowed file paths, minimal accurate provenance, and confirmed remote SHA. Unpublished historical raw evidence stays LOCAL UNREVIEWED and can be deferred safely; do not indefinitely block new feature work with redundant archive audits.

**Dispatch rule:** New Codex tasks must name one level and one concrete feature, with up-front cheap prerequisites, bounded maximum build count, explicit necessary/optional tests, NOT RUN classification and allowed small report/evidence paths. GPT alone decides whether to issue a new functional, milestone or device gate, and independently reviews published evidence. Codex never modifies production code or old stopped tasks.

## Scoped failures, independent continuation — 2026-10-12

**Failure is scoped to the smallest affected operation, not automatically the entire Codex task.** This refines older unconditional STOP phrasing in this workflow and the future task dispatcher. Preserve the original child exit/status and never turn failed checks into PASS; do NOT rerun the same failed command merely to make it green. Before execution, each stage must identify dependencies and its classification:

- `RECORD_ONLY` — Nonessential helper, progress display, optional file discovery/archival/inventory issue: record the actual failure, what is and is not affected; **continue** independent work with no retry, no extra build. The failure must not silently invalidate the provenance or result of a required test.
- `CASE_FAIL` — Actual targeted product test failed: record `FAIL`, save observed evidence, do not repeat that case; **continue other independent preauthorized cases** if the app state, fixtures, signing, test scope and safety still permit. A failed healthy control cannot itself become PASS; pending-cancel may still gather independent FAIL/PASS evidence if valid, but overall end-to-end acceptance is not PASS.
- `DEPENDENCY_BLOCKED` — A prerequisite (running emulator, valid signing, source-aligned artifact, fixture or compilable target) failed: mark only the affected dependent branch `BLOCKED / NOT RUN`. Continue unrelated offline checks, data review, safe cleanup and reporting; never start a build when its preflight is blocked. Recovery playback specifically depends on observed normal pending-cancel release/cleanup.
- `PUBLICATION_BLOCKED` — Public evidence privacy, authorized path containment, Git commit/push or remote verification fails: prohibit **unsafe publication only**, preserve trustworthy local results with `LOCAL — NOT INDEPENDENTLY REVIEWED`, and finish reporting. Do not redo playback/build to fix a publication helper. Genuine secrets/unknowns must NOT be published.
- `GLOBAL_SAFETY_STOP` — Only where continuing operations might use the wrong source, expose secrets, mutate protected workspaces/data, conceal an essential integrity failure, cause irrecoverable side effects or operate in an unsafe uncontrolled state. Immediately cease affected unsafe operations and safe cleanup/report; no claims of PASS for impacted checks.

**A nonzero process exit is evidence of a failed command, not an instruction to discard unrelated successes or automatically abort the whole run.** A CRITICAL test can fail and still permit independent tests, but cannot be waived when evaluating its own PASS or a dependent final acceptance. Every case's `PASS/FAIL/BLOCKED/NOT RUN/NOT PROVEN` survives in the task result. Final summary may be `COMPLETED WITH FAILURES / PARTIAL` rather than replacing all independent case results with a global STOP.

Predeclare a dependency map and maximum per-case attempts (default ONE), never reinterpret historical STOP/FAIL after the fact. For Phase 8F: actual emulator+signed foreground is the shared prerequisite; healthy MP4 and HLS PREPARING-cancel are independently recordable once the prerequisites hold, even if one fails; **recovered MP4 may only run after cancellation and normal resource cleanup were demonstrated**, and full targeted PASS still requires all three. An app crash or contaminated native resource state can block further opens for safety.

Protect privacy/source/authorized Git paths and truthful evidence as before. A failed publication gate prevents push but does NOT negate previously recorded local observations. Do not endlessly re-dispatch new tasks solely for auxiliary errors; next owner dispatch should be justified by a meaningful independent feature or explicitly necessary safety prerequisite.

## Fixed Codex task file

There is only one current dispatch file:

`docs/CODEX_VALIDATION_TASK.md`

It is replaced for every validation round. Git history is the archive; do not create a growing family of `CODEX_TASK_V2/V3` files for normal rounds.

The task must be self-contained and include at least:

- task state;
- task ID;
- repository;
- branch;
- exact implementation source SHA;
- permitted branch drift after that SHA;
- required reading;
- what changed;
- validation goals;
- commands/order;
- functional and regression cases;
- architecture/security invariants;
- performance exclusions;
- stop conditions;
- allowed output files;
- required final decision wording.

## Starting a new Codex conversation

The user only needs to send:

> 读取仓库 `docs/CODEX_VALIDATION_TASK.md` 并严格按其中要求执行本轮测试和取证；不要修改生产源码。

Codex must fetch the repository, read the task completely, and validate the task state and source revision before doing any test work.

The developer's existing local workspace is **not** the validation workspace requirement. If the current local checkout is on another branch or has uncommitted work, Codex must preserve it untouched and create or reuse a separate isolated validation clone/worktree. The isolated validation checkout must be clean before tests begin.

Codex must not stash, reset, clean, checkout over, or otherwise mutate an unrelated dirty user workspace merely to satisfy validation setup.

If the task is not READY, the isolated validation checkout cannot be made clean, or repository/source checks do not match the task, Codex stops and reports the mismatch.

## Source-revision safety

Because the validation-task file is committed after the implementation commit, the branch HEAD may contain docs-only workflow/dispatch commits ahead of the implementation source SHA.

The task must define the allowed drift explicitly. Normally the permitted drift is limited to operational validation documentation such as:

`docs/AI_WORKFLOW.md`

`docs/CODEX_VALIDATION_TASK.md`

The exact allowed path set for a round is always whatever the current task file declares.

If any production source, test script, build profile, lockfile, or unrelated document changed after the implementation source SHA, Codex must stop rather than silently test a different source.

The validation report records both:

- implementation source SHA;
- actual validation checkout SHA.

## Validation completion

Codex may update only the report/evidence paths authorized by the task. It does not rewrite the task file unless a future workflow explicitly permits that.

A validation round is **not complete merely because commands finished locally**.

Before telling the user that testing is complete, Codex must:

1. update the authorized validation report;
2. add the sanitized evidence required by the task;
3. commit only those authorized report/evidence changes;
4. push that commit to the exact validation branch named by the task;
5. fetch the remote branch again and verify the remote HEAD contains the pushed evidence commit;
6. report the pushed evidence commit SHA to the user.

If push is unavailable or rejected, Codex must say `BLOCKED — EVIDENCE NOT PUSHED` and provide the local evidence commit SHA. It must not say the validation is finished/handed off to GPT because GPT cannot review inaccessible local-only evidence.

After the evidence commit is visible on the remote validation branch, the user returns to GPT. GPT reviews the actual result, fixes source if needed, and updates durable project state.

### Continuous GPT ↔ Codex review loop

The preferred active-session workflow is:

1. Codex executes the current `docs/CODEX_VALIDATION_TASK.md`, commits/pushes evidence, and reports the remotely visible evidence SHA.
2. GPT independently fetches the branch and evidence; it does not rely only on Codex's prose diagnosis.
3. GPT decides whether the stop is a production defect, test-infrastructure defect, environment issue, or acceptance result.
4. GPT makes only the appropriate reviewed implementation/test-infrastructure/documentation changes.
5. If another validation round is warranted, GPT creates a new implementation/review commit first, then a docs-only validation-dispatch commit whose task file names the exact source SHA.
6. GPT replies in the conversation with the new commit SHA(s), task ID and a short READY instruction.
7. The same Codex conversation may read that reply, fetch the branch again, and treat the latest `docs/CODEX_VALIDATION_TASK.md` as the **only** execution authority for the next round.

Codex must never patch a stopped gate unless the latest task explicitly changes its role. GPT must never convert historical partial results into a new PASS.

A failed validation run remains historical evidence. A later rerun must not relabel unexecuted items from the older run as PASS.

## End-of-phase durable state

At phase acceptance, GPT updates the applicable durable state:

- `docs/IMPLEMENTATION_STATUS.md`
- `docs/SESSION_HANDOFF.md`
- phase implementation/report document
- phase validation report/evidence
- next `docs/CODEX_VALIDATION_TASK.md` only when another validation round is needed

The goal is that GPT chats and Codex chats can both be replaced at any time without losing project understanding.
