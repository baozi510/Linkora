# Codex Validation Task — Rerun 4 Existing-Evidence Privacy Resolution and Publication

> STATE: READY
> TASK_ID: phase8f-rerun4-evidence-privacy-semantic-publish-v3
> REPOSITORY: baozi510/Linkora
> BRANCH: feat/playback-capability-phase8
> SOURCE_SHA: 7ec13641b432d40cfdb4a44e2666efb23a810441
> ALLOWED_DRIFT: docs/CODEX_VALIDATION_TASK.md ONLY
> ORIGINAL_STOPPED_VALIDATION: phase8f-sim-rerun4-single-controller-ui-cancel
> ORIGINAL_TESTED_SOURCE_SHA: a9312a86a5104e46847f1087af52e7de8b1c2fab
> ORIGINAL_TESTED_DISPATCH_SHA: f98ca3b5d61ec1cd18ee8e42d72e4718c352c5ce
> STOPPED_PUBLICATION_V2: phase8f-rerun4-evidence-publish-no-retest-v2
> STOPPED_PUBLICATION_V2_DISPATCH: 5d66330f5939480e9ae60988742dd300f60003be
> UNCHANGED_PRODUCTION_FIX: 8174e6e4f0214958fb83fef46e92170c4c10263a
> ORIGINAL_LOCAL_EVIDENCE_SHA: NONE
> ORIGINAL_REMOTE_EVIDENCE_SHA: NONE
> ROLE: FRESH MINIMAL PRIVACY SEMANTIC AUDIT OF EXISTING SANITIZED EVIDENCE, NORMAL PUBLICATION ONLY

## 0. Purpose and permission boundary

This is a NEW DISTINCT task for ONE narrowly scoped evidence publication attempt. Rerun4 validation and publication v2 remain STOPPED, immutable and NOT to be rerun. An earlier publication-only task phase8f-rerun4-evidence-publication-recovery-only is also superseded; use ONLY this committed READY task and no concurrent task. GPT has not independently accepted any local claims, and publication PASS is not playback PASS.

The user-approved docs/AI_WORKFLOW.md rule is binding: optional and demonstrably harmless tooling failures are recorded without retesting, but **privacy and source/evidence integrity remain CRITICAL**. The failed v2 privacy scanner was REQUIRED and exited Python1 / outer PowerShell1; NEVER relabel its result optional/PASS, rerun it, patch it, or continue its stopped execution. New task may inspect the same ORIGINAL existing file bytes with a NEW, independently defined correctly scoped semantic check, expressly authorized by this distinct task. This is not a repeat of Rerun4 builds, media or stopped helpers.

Current local handoff says v2 read-only source/inventory gate found exactly 110 entries (one report and109 evidence files, regular mode100644) and a different amended worktree report; v2 privacy checker then raised AssertionError based on nine suspect matches. Its regex `(?i)[a-z]:[\\/]` can match `s:/` inside `https://`; **this fact alone does NOT classify any of the nine matches as benign**. Original exact match contexts are still private and unreviewed by GPT. Integrity/gzip gate, transfer, commit/push and final original checkout audit NOT RUN. Preserve v2 failure and original Rerun4 local STOP. No evidence SHA yet.

All private personal IDs, device/emulator IDs, signing material, credentials, private file paths, private stdout/stderr, HAP/media/screenshots/full hilog must stay LOCAL PRIVATE and never be shown in chat, tool public output or pushed repository. No quota checks, autonomous timers/chat polling, unseen background tasks or private environment alteration.

## 1. Source and required reading

Fresh fetch `baozi510/Linkora`, exact branch, record actual new full dispatch SHA. Verify READY and this ID; SOURCE_SHA `7ec13641b432d40cfdb4a44e2666efb23a810441` is immediate parent of dispatch and diff SOURCE_SHA..dispatch is **EXACTLY `docs/CODEX_VALIDATION_TASK.md`**. The prior v2 dispatch `5d66330f5939480e9ae60988742dd300f60003be`→SOURCE_SHA diff is exactly `docs/IMPLEMENTATION_STATUS.md` and `docs/SESSION_HANDOFF.md`. Earlier repository lineage includes original Rerun4 source, original dispatch, reviews and v2 dispatch. Compare production AdaptivePlaybackPort.ets and SystemPlaybackPort.ets Git blobs against `8174e6e4f0214958fb83fef46e92170c4c10263a`; no source/test/profile/fixture/script/old-task/evidence changed.

Read whole latest task, docs/AI_WORKFLOW.md including noncritical NO RETEST rule, docs/MASTER_IMPLEMENTATION_PLAN.md, docs/ARCHITECTURE_TARGET.md, docs/ARCHITECTURE_MIGRATION.md, latest CURRENT docs/IMPLEMENTATION_STATUS.md and docs/SESSION_HANDOFF.md, Rerun4 original task at `f98ca3b5d61ec1cd18ee8e42d72e4718c352c5ce`, v2 task at `5d66330f5939480e9ae60988742dd300f60003be`, and remotely published Rerun3 historical STOP report. Old tasks/readings are context only, never execution permission.

Never touch the user's original potentially dirty `D:/Linkora`, private installed profile/SDK state, original Rerun4 stopped isolated checkout's index/files, or any unrelated service. Inspect the original stopped isolated checkout read-only (HEAD `f98ca3b5d61ec1cd18ee8e42d72e4718c352c5ce`); use a **NEW separate clean isolated clone** at this NEW dispatch for publication. If either origin or candidate cannot be used safely, STOP.

## 2. Only authorized content; preserve original failed evidence

Exactly the existing originally approved new paths, and NO OTHER outputs:
```text
docs/PLAYBACK_PHASE8F_RERUN4_SINGLE_CONTROLLER_UI_CANCELLATION_REPORT.md
test-lab/playback/phase8f-rerun4-single-controller-ui-cancel-20261011/
```

Read-only inspect origin Git staged entries (claimed one report +109 evidence =110, all regular modes100644), existing blob IDs and bytes; preserve private ledger of observed actual counts/hashes. Use **staged byte-exact 109 evidence files**, not unproven worktree substitutions. Use **already amended worktree report** (preserving BLOCKED EVIDENCE NOT PUSHED and full historical FAIL) and record its difference from staged report; do not silently edit it to invent Rerun4 PASS, proof, evidence SHA, hashes or timestamps. Confirm path containment; no symlinks/extra staging paths. The older original helper/WinError5 and the v2 required privacy scanner child1 and reported contexts remain FAIL historical records. No new measurements or source/test modifications. Missing/unreadable/unsafe material => STOP, no invented files.

Before any transfer, independently examine already captured v2 local scanner result metadata PRIVATELY to recover the **nine original match source files and exact local offsets/contexts** if retained. Do not invent or replay v2 scanner. If original hit offsets/contexts are unavailable, a new independent whole-candidate semantic audit must still establish safe classification; uncertainty is BLOCKED, not blanket false-positive dismissal. Keep private original snippets/context and decisions in PRIVATE audit notes, not in Git or chat. If actual sensitive data is found, STOP `BLOCKED — PRIVACY REVIEW`; do NOT publish it, silently omit it, rewrite the immutable originals or bypass the gate.

## 3. One NEW independent, tightly delimited REQUIRED privacy review

This is not an optional helper and MUST PASS. Define a **NEW** minimal PRIVATE privacy-audit implementation or direct read-only semantic inspection outside all Git checkouts. Do NOT modify/reinvoke the failed v2 script. First test *this new detector only* on synthetic nonprivate text (no SDK/device/build/fixture):
- `https://github.com/...`, `http://host/...`, `ssh://...` and `s:/` inside a scheme must **NOT** be treated as absolute Windows drive paths merely due to the last scheme character.
- Actual `C:\\Users\\private\\file` and `D:/private/file` (synthetic examples) MUST be detected as drive paths; quoted paths and drive paths after benign separators also need detection. Reject drive-relative `C:relative` as an absolute drive claim. This is a syntax test, not evidence privacy PASS.
- A context-aware detector can use an explicit boundary such as `(?<![A-Za-z0-9.+-])[A-Za-z]:[\\/](?!/)` for **one** Windows-drive indicator, while separately covering UNC `\\\\server\\share`, Linux/WSL home paths, quoted/escaped strings, secrets, credential-containing URLs, private host endpoints, private instance/device identifiers and nontext binary files. The example is not a comprehensive privacy classifier; validate boundaries and semantic context instead of blindly trusting regex counts.
- Legitimate public upstream URLs and SHA256 content hashes are not automatically private paths or device IDs. Conversely, a clean drive-path regex does **not** prove the overall file safe.

Read every candidate public file (including JSON and decompressed all .gz) with a single bounded, read-only, privately recorded audit. Precisely classify the nine previously recorded source locations across:
1. controller-source plain and its sanitized gzip;
2. fresh-fetch stderr plain/gzip;
3. fresh-submodules stderr plain/gzip;
4. simulator stdout plain/gzip;
5. submodules.json.

For each, privately record file/offset, short private context, semantic category (public URL/benign artifact versus real private path/token/identifier versus UNKNOWN), and independent rationale with observed bytes. Compare plain and decompressed gzip without counting the same logical occurrence as multiple independent leaks. No raw match fragments/identifiers/URLs sent to chat or Git; public outcome can report aggregate counts by harmless/sensitive/unknown only. Privately verify no overlooked real drive/home/UNC paths, credentials, private URLs, device/emulator IDs, PIDs, HAP, media, screenshots, raw complete hilogs or original full unredacted subprocess output across **all 110 candidate files**, not only the nine matches. Context-dependent 64-hex strings must be classified by schema/use (SHA256 fingerprints versus actual device IDs); never simply publish ambiguous 64-hex strings. Any match TRUE SECRET/UNKNOWN, inaccessible content, unsupported gzip, or helper exit nonzero => STOP `BLOCKED — PRIVACY REVIEW`; no successful publication. Capture the actual new helper numeric child exit, wrapper exit and private exact stdout/stderr/timestamps where practicable; do not pretend unknown timing or byte-for-byte original streams were retained.

No optional progress observers, exploratory OS/AV/permission probes, SDK JSON introspection, extra shell polling or duplicate scanners. If a genuinely noncritical *preclassified* optional diagnostic fails and A–F required proofs are unaffected, record `RECORDED — NONCRITICAL TOOLING ISSUE / NO RETEST`; never conflate this with the required privacy gate or rescue an earlier failed scanner.

## 4. Required integrity, origin, publication proofs AFTER PRIVACY PASS

**CRITICAL A — Source:** documented origin read-only HEAD, current isolated clean HEAD, ancestry/task-only drift, production blob equality and original user checkout preservation.

**CRITICAL B — Provenance:** all 110 claimed new paths, actual names/modes/staged blob hashes, 109 original staged evidence bytes and existing latest report version; accurate report-vs-index amendment and provenance limitations. No unauthorized path; no manufacture of missing original raw helper output.

**CRITICAL C — Privacy:** Section 3 classification and all-candidate semantic audit PASS, all nine recorded match contexts resolved on original existing bytes. No private content or true sensitive/unknown match silently overlooked.

**CRITICAL D — Integrity:** complete sanitized text/gzip pair verification (historical claim 33 pairs, verify actual count), matching decompressed bytes and hashes; audit evidence-inventory.json without treating it as an extra staged file, report log-integrity/attempt ledger/task result consistency to the extent readable. Any claimed private ORIGINAL raw-byte SHA is historic, not independently recreated from inaccessible originals; mark NOT INDEPENDENTLY VERIFIED. Preserve original failure exits/timestamp caveats. Official six media opens all NOT RUN, cancellation and recovery NOT PROVEN; reported three fresh verifiers are LOCAL assertions pending remote evidence.

**CRITICAL E — Exact isolated candidate:** Only after A–D pass, transfer audited regular public bytes to clean NEW publication checkout. Inspect exact 110 permitted stage files and their hashes, no source/test/task/old-report/config/lock/submodule drift, no additional files. No modifying original Rerun4 checkout or user original workspace.

**CRITICAL F — Normal evidence push:** Fresh-check remote HEAD exactly equals this new dispatch, STOP on unexpected change. Do exactly one normal new evidence commit of authorized report+original evidence, ordinary no-force push to feat/playback-capability-phase8, then fresh-fetch verify remote HEAD equals evidence full40 SHA, one-parent ancestry, exact allowed changed files and remotely readable sanitized contents/hash/gzip match. A failed essential commit/push must STOP with numeric exit and local SHA if created. Do not rerun stopped v2 or Rerun4 tests for missing evidence.

If A–F PASS: publication verdict `PASS — EVIDENCE PUBLISHED AND REMOTELY VERIFIED` **for this v3 publication task only**; original Rerun4 verdict remains LOCAL FAIL until GPT independent review. If any required stage fails: keep `BLOCKED`, preserve original unchanged bytes, STOP and describe precise first failure; do not relabel a required stage optional or automatically issue another retry.

## 5. HARD prohibitions, privacy and final handoff

NO new `ohpm install`, `verify.ps1`, `verify-simulator.ps1`, Hvigor/Hypium, FFmpeg/MPV/native rebuild, simulator/emulator/HDC (including `-config`), SDK settings/profiles, signing/HAP install, local/WebDAV/fixture/host rport, playback, cancellation/recovery tests, media opens, process force-stop, reset/wipe, old inspector, old failed controller/audit, v2 failed scanner, chat polling, timers or quota inquiry. Do not commit new task docs, extra notes, independent scan script, private notes, amended failure evidence or unrelated artifacts; only the two authorized report/evidence prefixes already existing. User original workspace and old staged origin must remain untouched.

Report in chat with ALL commit SHAs as 40 hex:
REVIEW_RESULT; STATE; TASK_ID; REPOSITORY; BRANCH; SOURCE_SHA; DISPATCH_SHA; ORIGINAL_STOPPED_TASK_ID; V2_STOPPED_TASK_ID; NEW_LOCAL_EVIDENCE_SHA (or NONE); NEW_REMOTE_EVIDENCE_SHA (or NONE); PUBLICATION_RESULT; ORIGINAL_RERUN4_VALIDATION_RESULT (LOCAL UNREVIEWED FAIL); V2_REQUIRED_PRIVACY_SCAN (FAIL, historic); NINE_RECORDED_CONTEXTS (resolved benign/sensitive/unknown aggregates, private snippets never shared); REQUIRED_PRIVACY_AND_GZIP_AUDITS; ACTUAL_AUTHORIZED_FILE_COUNT; ALL_SIX_OFFICIAL_OPENS=NOT RUN; CANCELLATION_AND_RECOVERY=NOT PROVEN; ORIGINAL_WORKSPACE_PRESERVATION (report actual final state check, do not claim if not run); NEXT_ACTION.

If push succeeds, stop and deliver verified new evidence SHA for GPT independent review; Codex must not self-dispatch Rerun5 or mark cancelled lifecycle PASS. If privacy cannot be established, no push and no test rerun. This is the one current READY authority.
