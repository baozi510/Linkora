# Codex Validation Task — Phase 8F Rerun 4 Evidence Publication

> STATE: READY
> TASK_ID: phase8f-rerun4-evidence-publish-no-retest-v2
> REPOSITORY: baozi510/Linkora
> BRANCH: feat/playback-capability-phase8
> SOURCE_SHA: e71d4d7e5eeb75fa85f7b9b7f6e3ca6a472e3323
> ALLOWED_DRIFT: docs/CODEX_VALIDATION_TASK.md ONLY
> ORIGINAL_STOPPED_TASK_ID: phase8f-sim-rerun4-single-controller-ui-cancel
> ORIGINAL_TESTED_SOURCE_SHA: a9312a86a5104e46847f1087af52e7de8b1c2fab
> ORIGINAL_TESTED_DISPATCH_SHA: f98ca3b5d61ec1cd18ee8e42d72e4718c352c5ce
> SUPERSEDED_PUBLICATION_TASK_ID: phase8f-rerun4-evidence-publication-recovery-only
> SUPERSEDED_DISPATCH_SHA: 135b3b0e6819548ed449a719289b2281b3f07c1a
> PRIOR_REMOTE_RERUN3_EVIDENCE_SHA: 4ef43b09a4e8a05e7021b7734fdfd2ab767bb138
> UNCHANGED_PRODUCTION_FIX_SHA: 8174e6e4f0214958fb83fef46e92170c4c10263a
> ORIGINAL_RERUN4_EVIDENCE_SHA: NONE
> ROLE: EXISTING EVIDENCE READ-ONLY RECOVERY, ESSENTIAL PUBLICATION CHECKS AND ORDINARY COMMIT/PUSH ONLY

## 0. Authorization and priority

The user has APPROVED the new prospective rule in docs/AI_WORKFLOW.md: **if a demonstrably noncritical, PRECLASSIFIED OPTIONAL tooling step fails without compromising required test/evidence correctness, record its failure and DO NOT repeat the test or build**. Critical verification, source protection, required provenance, privacy and evidence publication still cannot be waived. Do not retroactively change previous STOP. Use the labels RECORDED — NONCRITICAL TOOLING ISSUE / NO RETEST, FAIL, BLOCKED, NOT RUN and NOT PROVEN precisely.

THIS task is NEW, replacing and superseding the unexecuted previous publication-only READY task phase8f-rerun4-evidence-publication-recovery-only. It is NOT permission to restart, retry, modify or continue the STOPPED Rerun4 validation or its original failed tools. Execute exactly this latest task only; if any older task is executing in a local session, stop initiating its work, retain its existing evidence, and do not run two tasks in parallel. No quota/remaining-usage or chat polling, future timer scheduling or background waits. No test-environment changes.

**Single goal: make Rerun4's ALREADY RECORDED, safely sanitized local evidence visible as a fresh GitHub evidence commit.** Do not spend time making harmless optional diagnostics green; do not replay any ARM64/Hypium/simulator build or native playback. GPT must first review the new remote evidence SHA before any future runtime test is authorized.

## 1. Historical truth; never rewrite results

Original Rerun4 local handoff claims: original new single-controller five synthetic PASS; real serial install/EOL proofs/default→simulator→default builds numeric0; fresh independent Hypium210/210 each and native ABI/whitelist checks. These are **LOCAL REPORTS, NOT INDEPENDENT GPT-ACCEPTED RESULTS** until publication and remote audit.

First actual test STOP (claimed child exit1) was a private emulator metadata-inspection helper that treated the JSON root list as a dictionary when calling data.keys(). HDC target list was [Empty]; an emulator configuration was listed but was not running. A no-argument emulator -config query's read-only effect was not proved. Real device ID/profile, signing/HAP install, Linkora foreground/window/layout, media fixture route, all six official media opens, pending native release, early/>20s normal cleanup and recovery were **NOT RUN / NOT PROVEN**. Reported emulator inspector full outer stdout/stderr original bytes and exact process timestamps were not independently retained; do not invent them. No production/decoder/signature defect established.

After STOP, the original evidence-staged-audit failed child1 with PermissionError [WinError 5] during private controller-state.json os.replace; the original commit helper then failed child1. Cause is UNKNOWN, no local evidence commit and no remote push. The amended report was reportedly not staged. Preserve these failures and limitations in the published report/evidence; do not try to repair/re-run the failed helper/controller/audit/commit helper. Historical Rerun1/2/3/other FAILs are immutable; do not invoke them. Neither a successful evidence push nor a previously green individual build retroactively makes original Rerun4 PASS.

## 2. Mandatory reading and exact source/drift

Fresh-fetch remote baozi510/Linkora branch feat/playback-capability-phase8; read entire current docs/CODEX_VALIDATION_TASK.md, docs/AI_WORKFLOW.md including the approved noncritical-tooling rule, docs/MASTER_IMPLEMENTATION_PLAN.md, docs/ARCHITECTURE_TARGET.md, docs/ARCHITECTURE_MIGRATION.md, latest CURRENT docs/IMPLEMENTATION_STATUS.md and docs/SESSION_HANDOFF.md. Read old Rerun4 task at f98ca3b5d61ec1cd18ee8e42d72e4718c352c5ce and Rerun3 report/STOP for background, not execution authority.

Require new SOURCE_SHA e71d4d7e5eeb75fa85f7b9b7f6e3ca6a472e3323 to be direct parent of current dispatch; SOURCE_SHA..dispatch changed paths EXACTLY docs/CODEX_VALIDATION_TASK.md. Require old source a9312a86a5104e46847f1087af52e7de8b1c2fab ancestor of original dispatch f98ca3b5d61ec1cd18ee8e42d72e4718c352c5ce; original dispatch→first review adef77219cebe347382fd172a6b615780517f402→superseded publication dispatch 135b3b0e6819548ed449a719289b2281b3f07c1a→new SOURCE_SHA→current dispatch strictly linear, no unexpected protected modifications. New review commit relative to superseded publication dispatch must touch ONLY docs/AI_WORKFLOW.md, docs/IMPLEMENTATION_STATUS.md, docs/SESSION_HANDOFF.md. Production AdaptivePlaybackPort.ets and SystemPlaybackPort.ets blobs at new dispatch must equal those at 8174e6e4f0214958fb83fef46e92170c4c10263a.

STOP BLOCKED — SOURCE DRIFT if identities, ancestry, blobs or path drift fail. Never change the user's original D:/Linkora workspace, its dirty state or any unrelated repositories. Use the original stopped **isolated Rerun4 evidence worktree** for read-only source discovery; use a separate NEW clean isolated checkout based exactly on this dispatch for the publication commit. No reset/stash/clean/checkout/rebase in old checkout. No force-push anywhere.

## 3. Allowed material and simple provenance

The ONLY authorized new Rerun4 GitHub paths remain:
~~~
docs/PLAYBACK_PHASE8F_RERUN4_SINGLE_CONTROLLER_UI_CANCELLATION_REPORT.md
test-lab/playback/phase8f-rerun4-single-controller-ui-cancel-20261011/
~~~
The handoff reports one local report +109 existing evidence files =110 paths, 33 sanitized text/gzip pairs. Determine actual file list, regular-file modes, and staged Git blob IDs from a **single read-only inspection** of the original stopped Rerun4 isolated checkout at HEAD f98ca3b5d61ec1cd18ee8e42d72e4718c352c5ce. Original evidence files should come from the existing staged index only; extract/read/copy their byte-identical existing content, without changing old index or files. For the report use its latest already-present worktree version (which says BLOCKED — EVIDENCE NOT PUSHED); record its difference versus staged report, preserving historical facts. Read only existing bytes; no new test logs, measurements, report claims or simulated results. Source checkout remains untouched.

All 110 claimed paths must be accounted for; require the actual number and names be proven, not hardcoded or invented. If any supposedly required file is missing, inaccessible, not regular, has an unexpected public path/mode, or staged/new-byte mismatch is unexplained, STOP BLOCKED — REQUIRED EVIDENCE INCOMPLETE. A publication cannot legitimately certify absent original private outputs; distinguish unavailable full private originals from the already recorded sanitized subset and label NOT INDEPENDENTLY VERIFIED. Do not create extra report, manifest, scripts or fixtures under the repo; use private temporary bookkeeping only outside the repo. A new report version must not be composed from memory or edited to hide FAILURE, or fabricate SHA.

## 4. Essential publication gates versus optional diagnostics

**CRITICAL, must PASS before committing:**
A. Fresh checkout/source protection and allowed-path proof, no old workspace mutation.
B. Existing staged report/evidence provenance and exact audited public candidate bytes; all new files regular and path-contained.
C. Security/privacy review of EVERY publication candidate, including decompressed .gz: no private signing material, credentials, device/emulator identifiers, PIDs, local user paths, host URLs, complete private hilogs, screenshots, media, HAPs or confidential source. Do not print matches publicly. Treat legitimate SHA256 evidence hashes as hashes, not automatic device IDs; inspect semantic context.
D. Every existing sanitized text/gzip pair must decompress and match its claimed sanitized source bytes and hashes, and report integrity inventory must reconcile as far as the published evidence allows. Actual private-original bytes unavailable remain NOT VERIFIED, never secretly claimed replayed.
E. Destination clean checkout and final commit diff exactly the one report + its original 109 allowed evidence files with no changes to historical blobs, scripts, tests, source, config, manifests or submodule pins.
F. Normal commit, normal push to precise branch, fresh-fetch remote HEAD equal newly created evidence full40 SHA, parent equal THIS dispatch, exact diff and remotely readable, sanitized authorized contents.

**OPTIONAL DIAGNOSTICS, DO NOT RUN if unnecessary:** extra progress-shell polling, separate emulator/SDK config introspection, additional metadata-probing helpers, redundant staging re-audits, repeated original data hashing beyond the necessary A–F assurance, wrappers whose only purpose is progress display, speculative filesystem/AV root-cause probes. Do not generate them. If an explicitly optional existing one nevertheless failed historically, RECORD the observed error and mark NO RETEST; it is NOT a new critical gate. If an optional step is attempted in this task and fails, preserve actual numeric child exit/error and declare RECORDED — NONCRITICAL TOOLING ISSUE / NO RETEST **only when A–F are independently still provably unaffected**. Never replay, edit or retry it, and do not rerun any expensive build/playback. If harmlessness cannot be established, STOP BLOCKED/NOT PROVEN, not PASS. An unclassified failed operation cannot be retroactively waived.

**The old inspector AttributeError and original private state WinError5 are historical recorded FAILs, not new gates to rerun.** Their documented cause and uncertainty remain part of evidence; do not guess AV, race, permissions or SDK effects. Do not use old os.replace controller-state mechanism, old failed audit code or any old helper. Favor the smallest direct read-only file/Git operations; no auxiliary preflight scaffolding for publication. A new essential publication command that exits nonzero is a real STOP; never hide it by a later successful wrapper. If command/outer-helper timing or raw output is unavailable, document exact limit, not invented certainty.

## 5. Explicitly forbidden operations

NO `ohpm install`, `verify.ps1`, `verify-simulator.ps1`, Hvigor, tests/Hypium reruns, FFmpeg/submodule rebuilds, rerun5, emulator CLI (including -config, -list and start), HDC, device boot/reset/wipe, signer/profile queries, HAP build/sign/install, app launch/foreground/UI, media server/WebDAV/rport, fixture or playback opens, native release checks, app force-stop/uninstall, old private controller/inspector/staging audit, changes to existing code/tests/scripts/build profiles/task/historical evidence. No private logs/profiles/device IDs/HAP/screenshot/media copied into repo or user-facing chat. Do not query quotas, start chat polling or timers.

## 6. One normal evidence publication and independent verification

After A–E PASS, fresh fetch branch once more to confirm actual remote HEAD EXACTLY this new dispatch. If branch advanced unexpectedly, STOP BLOCKED — SOURCE DRIFT; do not merge/rebase/force to salvage. Git add ONLY allowed paths in the new clean isolated checkout, verify index's actual paths/blobs, create exactly ONE normal evidence commit, push once normally without force. Capture each command's REAL numeric exit and save privately original output as appropriate; no self-referential fake evidence SHA in report. If commit/push fails, STOP BLOCKED — EVIDENCE NOT PUSHED with local SHA if one exists; do not rerun any Rerun4 test. Follow-up publication repair requires a new separate owner decision, not a hidden retry.

Fresh-fetch GitHub after the push; require remote branch HEAD matches exact new 40-digit evidence commit, parent equals new dispatch, diff contains only authorized paths, all 110 claimed new files or accurate actual count, all protected source/history unmodified, privacy and gzip/hash consistency of published bytes. An unavailable/nonmatching remote file => BLOCKED — EVIDENCE NOT VERIFIED, not success. The old report header describing its own publication BLOCKED may remain unchanged; successful publication in THIS task is not original validation PASS.

## 7. Required final response (all SHA values full 40 hex)

REVIEW_RESULT; STATE; TASK_ID; REPOSITORY; BRANCH; SOURCE_SHA; DISPATCH_SHA; ORIGINAL_STOPPED_TASK_ID; ORIGINAL_TESTED_DISPATCH_SHA; NEW_LOCAL_EVIDENCE_SHA (or NONE); NEW_REMOTE_EVIDENCE_SHA (or NONE); PUBLICATION_RESULT; ORIGINAL_VALIDATION_RESULT (LOCAL, UNREVIEWED); NONCRITICAL_TOOLING_RECORDED; REQUIRED_AUDIT_RESULT; ACTUAL_AUTHORIZED_FILE_COUNT; ALL_SIX_OFFICIAL_OPENS=NOT RUN; CANCELLATION_AND_RECOVERY=NOT PROVEN; PRIVACY_AND_INTEGRITY; USER_ORIGINAL_WORKSPACE_UNCHANGED; NEXT_ACTION.

Publication PASS only means EVIDENCE PUBLISHED AND REMOTELY VERIFIED, not source fix, product PASS, physical device PASS, or the cancellation/recovery gate. If remote evidence is truly published, return its SHA and STOP; GPT will independently review and design a small, cost-effective next runtime-validation task if needed. If a critical publication gate cannot pass, report the original observed blocker without executing another expensive validation or rerunning a noncritical diagnostic.
