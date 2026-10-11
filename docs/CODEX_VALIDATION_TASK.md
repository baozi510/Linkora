# Codex Validation Task — Phase 8F Feature-first Targeted Simulator Smoke

> STATE: READY
> TASK_ID: phase8f-feature-first-targeted-simulator-cancel-smoke
> REPOSITORY: baozi510/Linkora
> BRANCH: feat/playback-capability-phase8
> LEVEL: LEVEL_1_FUNCTIONAL
> SOURCE_SHA: f9fd23c66e5fc9f70a3ccfd4c4b3ba0d0d443e03
> ALLOWED_DRIFT: docs/CODEX_VALIDATION_TASK.md ONLY
> UNCHANGED_PRODUCTION_FIX: 8174e6e4f0214958fb83fef46e92170c4c10263a
> SUPERSEDED_READY_TASK_ID: phase8f-rerun4-evidence-privacy-semantic-publish-v3
> SUPERSEDED_READY_DISPATCH_SHA: eee759ffe99c52dd139b20d4261275f22c23a6f0
> ORIGINAL_STOPPED_VALIDATION_TASK_ID: phase8f-sim-rerun4-single-controller-ui-cancel
> ORIGINAL_TESTED_DISPATCH_SHA: f98ca3b5d61ec1cd18ee8e42d72e4718c352c5ce
> ORIGINAL_RERUN4_REMOTE_EVIDENCE_SHA: NONE
> ROLE: TARGETED FUNCTIONAL SIMULATOR RUNTIME; MAX ONE NECESSARY DEBUG SIMULATOR BUILD; MINIMAL SAFE REPORT
> FULL_ARM64_RELEASE_ABI_GATE: DEFERRED TO LEVEL_2_MILESTONE

## 0. New user-approved execution strategy (read first)

This is a **new distinct authorized task** after a separately committed GPT review. Its sole priority is to establish actual Phase 8F functionality with the cheapest valid simulator path, following the 2026-10-12 feature-first execution rule in `docs/MASTER_IMPLEMENTATION_PLAN.md` and `docs/AI_WORKFLOW.md`.

The earlier publication-only task `phase8f-rerun4-evidence-privacy-semantic-publish-v3` was READY but has no remotely published result at dispatch time. It is **SUPERSEDED**, not falsely marked executed, PASS or FAIL. Do **NOT** run it alongside this task. Original Rerun4, Rerun3 and publication-v2 historical failed tasks remain CLOSED/STOPPED; never rerun their specific failed helper, original controller, PowerShell observer, original privacy classifier or old build gates. Their local-only Rerun4 report +109 evidence files are preserved privately, NOT magically certified or safe to publish. This task NEVER copies or publishes those old 110 files, never ignores unresolved historical privacy concerns, and does NOT claim prior Rerun4 evidence was reviewed.

Core rule: daily modifications need NO compulsory compilation; only one source-compatible minimal **simulator Debug** build at most if required for a real smoke test, after cheap prerequisites are ready. Full default ARM64/Release/native ABI/build suite is **NOT RUN, intentionally deferred** to a coherent milestone. Do not run `scripts/verify.ps1`, the old full default→simulator→default triple cycle, or full six-case media matrix. Do not use a passing old build to assert a new runtime PASS.

## 1. Required reading, exact remote source and protected workspace

Fresh-fetch repository and branch; verify actual full HEAD dispatch SHA, `STATE: READY`, this TASK_ID, SOURCE_SHA immediate parent of dispatch and diff SOURCE_SHA..dispatch EXACTLY `docs/CODEX_VALIDATION_TASK.md`. Verify previous policy review `eee759ffe99c52dd139b20d4261275f22c23a6f0`→SOURCE_SHA touched ONLY `docs/MASTER_IMPLEMENTATION_PLAN.md`, `docs/AI_WORKFLOW.md`, `docs/IMPLEMENTATION_STATUS.md` and `docs/SESSION_HANDOFF.md`. Stop on source/branch drift.

Read FULL latest task, current `docs/AI_WORKFLOW.md`, `docs/MASTER_IMPLEMENTATION_PLAN.md`, `docs/ARCHITECTURE_TARGET.md`, `docs/ARCHITECTURE_MIGRATION.md`, latest CURRENT `docs/IMPLEMENTATION_STATUS.md` and `docs/SESSION_HANDOFF.md`. Read recent historical Phase8F Rerun4 STOP handoff, Rerun3 remote failure report, and original relevant `AdaptivePlaybackPort.ets` / `SystemPlaybackPort.ets` and actual production UI/playback port contracts. Verify these two production files' Git blobs still equal `8174e6e4f0214958fb83fef46e92170c4c10263a`; no source/test/profile/fixture/build config changes.

Use a separate clean isolated source checkout, not the user's original potentially dirty `D:/Linkora` workspace and not the old stopped Rerun4 evidence checkout. Do not reset/stash/clean/checkout/modify either protected workspace or another task's index. Authentic dependency pins only; do not alter checksums or TLS/security/SDK configuration.

## 2. CRITICAL CHEAP readiness BEFORE ANY BUILD

1. Record original authorized emulator/SDK availability with **documented read-only commands** only; first query actual running HDC target list and confirm a simulator target is really running. `[Empty]` means **no target**, regardless of a configured API26 x86_64 instance. Do NOT inspect SDK emulator.json or run `-config` without arguments or invent undocumented emulator command switches. If a compatible user-authorized installed API26 emulator is not running, ONE normal supported non-destructive start of that existing instance is allowed **only** when the installed tool's documented start syntax is verified and no profile/image/settings changes occur. No reset, wipe, reinstall or force-stop. If no legally usable documented start is available, STOP `BLOCKED — SIMULATOR ENVIRONMENT`, with build/sign/install/media `NOT RUN`; do not start a full build.
2. Only after the target really appears: establish legal existing simulator signing/profile membership by correct separately checked interpretation of the installed HDC/`bm get -u` output (no guessing labeled output). No modifying profile, keys, credentials, SDK preference or device IDs. If signing cannot be proved, STOP `BLOCKED — SIGNING PREFLIGHT`; build and media NOT RUN.
3. Check that the minimal healthy MP4 and separate HLS H264 cancellation fixture specified by previous authoritative Phase8F corpus exist as lawful **already prepared** local/media assets and that a safe, ownable host/target route is possible. No remote secrets/private paths published. If not ready, STOP `BLOCKED — FIXTURE ENVIRONMENT` before building. No broad media corpus recreation or six-format sweep.
4. Before building, check if an existing already installed/signed x86 simulator artifact can be independently tied to EXACT current production blobs/source, simulator product, legal profile and x86 native isolation. If and only if all match, record proven provenance and **BUILD NOT RUN**; otherwise it is not reusable, proceed to one minimal build only. HAP presence alone is not proof. Do not reuse an old unsigned HAP, old PASS label or ARM64 artifact as x86 runtime proof.

No helper/extra PowerShell progress observations, polling while a child is running, gratuitous meta-inspection, or mid-stage reads of completion-only files. A blocking invocation captures direct numeric exit and original private stdout/stderr; actual faults remain honest, not repaired and secretly rerun.

## 3. At most ONE necessary minimal simulator Debug build

Only if all Section 2 prerequisites pass and no valid source-matched signed artifact exists:

- Run ONCE the existing scoped simulator `debug` build path (e.g., `scripts/verify-simulator.ps1 -BuildMode debug`, which includes its own scoped checks and built-in dependency restore). Do NOT run `scripts/verify.ps1`, full ARM64 default Debug/Release build or any second simulator build as ritual. No new release HAP, no copy-forward of old test PASS. Any initial dependency setup strictly required for this build may be done ONCE; allow only the previously authorized exact EOL-equivalent four-lock normalization in isolated checkout if actually necessary and proven identical to Git blobs. No script edits, retry installation loops or changes to dependency versions.
- One explicit child returncode plus meaningful semantic build result, emulator x86 native library isolation/ABI guard and signed-installable artifact identity must be reported before attempting runtime. A real build failure is `FAIL — MINIMAL DEBUG BUILD`; do not assert compilation PASS or bypass critical ABI/security checks. Runtime NOT RUN.
- `DEFAULT_ARM64_DEBUG`, `DEFAULT_ARM64_RELEASE`, full `HAR/HAP` ARM64 native audit, cross-product triple cycle and physical-device tests remain deliberately `DEFERRED — LEVEL_2/LEVEL_3`. This is not a product release acceptance.

## 4. Targeted FUNCTIONAL runtime only; three media opens maximum

After valid x86 product, original legal signed profile and installed HAP verified (actual installation success, not transport exit0), require actual Linkora UIAbility foreground, an app-owned visible window, nonempty Linkora UI hierarchy and one matching private screenshot **metadata** check. Reject launcher-only/empty UI. If UI fails, STOP `BLOCKED — APP FOREGROUND` and do no media tests. Do not publish raw screenshots.

Use the previously approved controlled host fixture WebDAV/target reverse only when needed, with actual target HTTP GET evidence; create only OWN route/service and clean it after, never touch unrelated mapping, user account, profile, application preferences or state. Do not fake WebDAV success from host-only fetch. Use existing healthy official MP4 and HLS H264 fixtures from the documented corpus.

Exactly these THREE opens in this order; STOP on first essential failure. Never replay a failed scenario within this task:

1. **Healthy System MP4 (control):** actual native prepared→playing state, genuinely submitted first frame, observed app screenshot/pixel ROI with >1 meaningful color, real actual HTTP target fetch if using a network source, and a positive strictly >0ms playback position delta. Position advancement alone is NOT a visible frame. If absent, `FAIL — HEALTHY CONTROL`; later two NOT RUN.
2. **Independent System HLS H264 PREPARING cancellation:** one new fixture open; leave while the same native candidate is still preparing (actual native prepare-in and before prepared), require evidence of pending candidate ownership to its normal native AVPlayer release, no stale prepared/late play/fallback, bounded release without force-stop. Inspect early about 3–5 seconds and again after >20 seconds: app-associated surfaces, services and audio renderer samples must be zero during normal cleanup, with semantic limitations honestly recorded. Never force-stop to claim PASS; if cannot capture true PREPARING or correlate release, or resource state is nonzero/unknown, `FAIL/NOT PROVEN — PENDING CANCELLATION`; third NOT RUN.
3. **Distinct recovered healthy MP4:** only if #2 normal native cleanup is independently supported; new open and real prepared/play, submitted colored frame, positive position, target GET and normal leave. No app wipe/restart/force-stop to manufacture recovery. Otherwise NOT RUN.

No fresh HLS HEVC, ordinary HLS playback, FFV1, advanced codec or six-format suite here; classify `DEFERRED/NOT RUN`, not PASS. Simulator System backend only; MPV stub is not ARM64 libmpv or hardware/codec/HDR/advanced-audio acceptance.

## 5. Lean evidence, optional archive packaging, real security gates

Permitted NEW outputs ONLY:
```text
docs/PLAYBACK_PHASE8F_FEATURE_FIRST_TARGETED_SIMULATOR_SMOKE_REPORT.md
test-lab/playback/phase8f-feature-first-targeted-smoke-20261012/
```

Keep a concise sanitized result report and the **minimum small** decisive text/JSON evidence that actually exists: exact source/dispatch identity, cheap readiness statuses, zero-or-one build command and real numeric result, actual app foreground proof if attempted, three-scenario attempt ledger with original observed behavior/times, cancellation/release correlation and cleanup bounds, private original output hashes where available, cause/limits/next action. If failure occurs before build, an honest short `BLOCKED — ENVIRONMENT` report is sufficient. No invented output files, no copy of unreviewed Rerun4 110 files.

**CRITICAL publication checks:** inspect EVERY actual proposed public text/JSON file for secrets, signing material, credentials, personal/device/instance identifiers, private host paths/URLs, full private stdout/stderr/hilog, screenshots/HAP/media; strip prohibited sensitive content from **new** sanitized report/evidence before publishing without altering native observed facts. Verify only authorized Git paths, source and actual remote evidence commit SHA after one normal push. Privacy cannot be optional or inferred from a broad regex false positive; suspect matches need semantic inspection and STOP if genuinely sensitive or unresolved. Exact commit parent and remote HEAD must match new dispatch; no force/merge, no unrelated edits.

**OPTIONAL and NOT REQUIRED:** duplicate `.gz` files, exact 33 compressed text pairs, exhaustive evidence-inventory lists, elaborate controller-state files, supplementary progress-shell observers, cosmetic dashboard scripts. Do not create them merely for accounting. If a redundant optional package/diagnostic fails and all critical facts remain independently supported, record `RECORDED — NONCRITICAL TOOLING ISSUE / NO RETEST`; do NOT retry, rebuild or loop through another complete test. If the **sole** required source is an archive and unreadable, that essential evidence stays NOT PROVEN. Private original raw evidence/hashes unavailable are NOT INDEPENDENTLY VERIFIED, not guessed.

The historical original Rerun4 publication and v2 privacy gate failures remain unchanged; this new sanitized report must never suggest that historical private material was cleared or pushed.

## 6. STOP rules, cleanup and completion

Critical STOP includes source drift, no usable emulator after safe preflight, illegal/unknown signing, incompatible required fixture route, actual minimal build failure, no real Linkora foreground/UI, unhealthy MP4, unproven pending native release/normal cleanup, or any public evidence privacy failure. A nonessential optional metadata/archive operation must NOT launch an expensive retest. No force-stop of application to claim normal cancellation; if needed only for safety after recorded failure, mark the scenario FAIL first and do NOT run recovery. Restore only resources created by this task; do not touch user original workspace, existing old evidence checkout, unrelated processes or profiles.

After a bounded attempt, publish ONLY safe authorized short report/evidence via one ordinary commit/push to exact branch if required publication checks pass; fresh-fetch exact remote HEAD, parent, changed paths and inspect report contents. If push fails, report `BLOCKED — EVIDENCE NOT PUSHED`, local SHA if it exists, NO automatic further rebuild or new helper to force publication. Codex does not modify production code, tests, build profiles, thresholds, requirements, source, old evidence or task file.

Final chat response must include:
`REVIEW_RESULT / STATE / TASK_ID / LEVEL / REPOSITORY / BRANCH / SOURCE_SHA / TESTED_DISPATCH_SHA / BUILD_STATUS (RUN_ONCE PASS/FAIL or NOT RUN with reason) / ARM64_MILESTONE_STATUS (DEFERRED) / SIMULATOR_TARGET / SIGNING_AND_UI / HEALTHY_MP4 / HLS_PREPARING_CANCEL_AND_RELEASE / RECOVERED_MP4 / DEFERRED_FORMATS / MINIMAL_PUBLIC_EVIDENCE_PATHS / REMOTE_EVIDENCE_SHA (40-digit or NONE) / PRIVACY_AND_WORKSPACE_SAFETY / NEXT_ACTION`.

Only claim `PASS — TARGETED SIMULATOR PENDING CANCELLATION AND RECOVERY` if every required runtime assertion is actually evidenced; otherwise accurate FAIL/BLOCKED/NOT RUN/NOT PROVEN, and full milestone/device release claims still deferred. GPT independently reviews any remotely published report, prioritizes feature implementation and schedules the next milestone compile only at the stage boundary. No quota queries, no chat polling, no background task scheduling.
