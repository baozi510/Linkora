# Linkora AI Collaboration Workflow

## Purpose

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
- **Infrastructure-preflight first, cost-aware:** validate cheap necessary OS/SDK availability, authorized device target, permissions and publication feasibility before expensive verification when designing future tasks. Avoid exploratory emulator setting commands, unneeded JSON introspection, nested progress shells, concurrent polling and repeatedly creating auxiliary helpers. Once an essential prerequisite is absent, STOP that task with accurate NOT RUN; schedule any separately authorized fix at the smallest meaningful scope, not automatic whole-chain retesting.
- **Publication:** an unrelated optional audit failure cannot invalidate sound already captured evidence, but security sanitization, exact source/staged bytes, Git path authorization, readable required evidence and remote publication are CRITICAL to an independent GitHub review. An inability to publish does not require replaying playback/build tests; preserve existing data, label `BLOCKED — EVIDENCE NOT PUSHED`, and handle transfer separately if explicitly authorized.
- **Truthful boundaries:** a successful build is not simulator runtime PASS; simulator MPV stub is not real MPV; native position progress is not displayed colored pixels; a configured emulator is not a running app; resource counts not observed are NOT PROVEN. Simulator-first / targeted-build-at-functional-checkpoints / full-ARM64-at-milestones / physical-device-batched applies under the later approved feature-first execution rule.

The goal is **product progress without waiving essential acceptance**. GPT owns any reclassification and task changes in separate commits. Codex uses only the latest READY task and its explicitly marked gates, preserving the user's original workspace and private artifacts.

## Approved feature-first test path and milestone build cadence — 2026-10-12

Latest user-approved strategy **supersedes the prior every-source ARM64-build-always cadence**, without changing the architectural compatibility objective. Read the detailed replacement in docs/MASTER_IMPLEMENTATION_PLAN.md (“Feature-first / Targeted-build / Milestone-verified / Device-batched”).

**Work is classified BEFORE execution** into:

1. `LEVEL_0_FEATURE`: GPT production work, source review and optionally narrow pure/unit tests; **no mandatory build per code change**. Must report `BUILD NOT RUN`, `TEST NOT RUN` where applicable, not assume green.
2. `LEVEL_1_FUNCTIONAL`: only when a runnable feature checkpoint is planned. First cheap preflight of actual emulator/target, existing legal signing/profile/fixture and source identity. If unavailable, STOP/record `BLOCKED — ENVIRONMENT` BEFORE builds. Otherwise use at most **one** smallest necessary Debug simulator (or relevant target) build when no independently verified source-compatible lawful artifact exists; target feature-focused runtime checks, not full coverage. If build omitted, state why and the proven artifact provenance.
3. `LEVEL_2_MILESTONE`: after a coherent feature batch or at a risky native/build boundary, run appropriate full ARM64 Debug/Release compile/link, ABI audits, simulator build and required regressions. A three-pass `default → simulator → default` verification chain requires specific demonstrated cross-target contamination risk; it is **not the default** and never triggered by unrelated diagnostic problems.
4. `LEVEL_3_DEVICE_BATCH`: genuine ARM64 MPV/native runtime, hardware codec, HDR/advanced audio, physical resources/performance, device-only protocols. Simulator and ABI evidence cannot substitute.

**Critical assertions remain strict at the point claimed:** source integrity, secrets/privacy for anything published, real build status if claimed, source-compatible signed install for runtime, true app foreground + visible UI, actual first-frame/pixel/progress, native pending release/early+>20s cleanup and independent recovery if claiming those outcomes. Unexecuted assertions remain NOT RUN / NOT PROVEN. Historical FAILED/STOPPED tasks are never rewritten as PASS or rerun under the same ID.

**Evidence policy:** keep only sufficient sanitized text and decisive result metadata. When an accessible verified plain-text log already substantiates a claim, optional extra gzip mirrors, redundant text↔gzip pair counts or exhaustive inventory recalculations are `OPTIONAL DIAGNOSTIC`; they are not automatic gates and failure does not trigger another compile. If a compressed item is the **only** copy of an essential artifact or required to establish provenance, its readability/integrity is critical. Safe publication still needs actual candidate-wide privacy review, allowed file paths, minimal accurate provenance, and confirmed remote SHA. Unpublished historical raw evidence stays LOCAL UNREVIEWED and can be deferred safely; do not indefinitely block new feature work with redundant archive audits.

**Dispatch rule:** New Codex tasks must name one level and one concrete feature, with up-front cheap prerequisites, bounded maximum build count, explicit necessary/optional tests, NOT RUN classification and allowed small report/evidence paths. GPT alone decides whether to issue a new functional, milestone or device gate, and independently reviews published evidence. Codex never modifies production code or old stopped tasks.

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
