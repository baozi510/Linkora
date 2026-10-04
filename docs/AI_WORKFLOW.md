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

If the task is not READY, or repository/source checks do not match the task, Codex stops and reports the mismatch.

## Source-revision safety

Because the validation-task file is committed after the implementation commit, the branch HEAD may be one docs-only dispatch commit ahead of the implementation source SHA.

The task must define the allowed drift. Normally the only allowed path between the implementation source SHA and dispatch HEAD is:

`docs/CODEX_VALIDATION_TASK.md`

If any production source, test script, build profile, lockfile, or unrelated document changed after the implementation source SHA, Codex must stop rather than silently test a different source.

The validation report records both:

- implementation source SHA;
- actual validation checkout SHA.

## Validation completion

Codex may update only the report/evidence paths authorized by the task. It does not rewrite the task file unless a future workflow explicitly permits that.

After Codex commits evidence, the user returns to GPT. GPT reviews the actual result, fixes source if needed, and updates durable project state.

A failed validation run remains historical evidence. A later rerun must not relabel unexecuted items from the older run as PASS.

## End-of-phase durable state

At phase acceptance, GPT updates the applicable durable state:

- `docs/IMPLEMENTATION_STATUS.md`
- `docs/SESSION_HANDOFF.md`
- phase implementation/report document
- phase validation report/evidence
- next `docs/CODEX_VALIDATION_TASK.md` only when another validation round is needed

The goal is that GPT chats and Codex chats can both be replaced at any time without losing project understanding.
