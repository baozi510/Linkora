# Codex Validation Task

> State: READY
> Task ID: phase8d-sim-system-hls-first-frame-root-cause
> Repository: `baozi510/Linkora`
> Branch: `feat/playback-capability-phase8`
> Validation source SHA (reviewed tree, exact): `e19123a0e110cebb479d24dbdf72d6d3c9169a5b`
> Unchanged production playback source baseline: `99ab47020f81391b7640d44c58ccb719491b4106`
> Accepted Phase 8C evidence: `9cd0db4b4719409de942892790de71f0ae015823`
> Role: BUILD / FOCUSED SIMULATOR INVESTIGATION / RESEARCH / EVIDENCE / REPORT ONLY

## 0. Do not re-execute an old task

Phase 8C task `phase8c-sim-native-first-capability-audit` is **already executed and GPT-accepted for audit/evidence scope**; its historical READY marker is not an instruction to rerun it.

This is a **new distinct Phase 8D-SIM root-cause investigation of the six outstanding Phase 8B System simulator FAIL observations**. It is not another 39-feature capability audit and is not a rerun of the whole 59-case matrix. The original Phase 8B records MUST remain unchanged.

No physical ARM64 target is available. Do not wait for one. Real MPV simulator is a stub; do not claim real MPV tests. No feature/policy/display/UI implementation is authorized.

## 1. Source and checkout safety — do this first

1. Fetch remote `feat/playback-capability-phase8` fresh, including submodules. Work in a clean **isolated clone/worktree**, not the user's dirty `D:/Linkora`.
2. Verify repository, branch, task ID, READY, the exact validation source SHA above, pinned submodule revisions and clean tracked checkout.
3. Verify `9cd0db4b4719409de942892790de71f0ae015823` is an ancestor of `e19123a0e110cebb479d24dbdf72d6d3c9169a5b`, and `e19123a0e110cebb479d24dbdf72d6d3c9169a5b` is an ancestor of the freshly fetched validation HEAD.
4. Run `git diff --name-only e19123a0e110cebb479d24dbdf72d6d3c9169a5b..HEAD`. The **only** permitted path drift is `docs/CODEX_VALIDATION_TASK.md`. Any other path => STOP, even a report/evidence update.
5. Record both immutable source SHA and actual dispatched checkout HEAD. Do not infer either from this chat.

## 2. Read completely before execution

- `docs/AI_WORKFLOW.md`
- `docs/MASTER_IMPLEMENTATION_PLAN.md`
- `docs/ARCHITECTURE_TARGET.md` and `docs/ARCHITECTURE_MIGRATION.md`
- `docs/IMPLEMENTATION_STATUS.md` current summary
- `docs/SESSION_HANDOFF.md` latest CURRENT STATE, distinguishing old snapshots
- `docs/CODEX_VALIDATION_TASK.md`
- `docs/PLAYBACK_PHASE8B_REPORT.md` (including the historical six observations and their 59-case attribution)
- `docs/PLAYBACK_PHASE8B_SIMULATOR_RUNBOOK.md`
- `docs/PLAYBACK_NATIVE_CAPABILITY_AUDIT_REPORT.md` and Phase 8C matrix (for evidence boundary only)
- original 59-case simulator evidence: `test-lab/playback/phase8b-simulator-functional-preflight-rerun1-20261007/` and its 59-case records
- `test-lab/media-compatibility/` manifest / generator / fixture provenance relevant to the six cases
- `entry/src/main/ets/playback/SystemPlaybackPort.ets`
- `entry/src/main/ets/pages/PlayerPage.ets`
- `linkora_core/src/main/ets/playback/PlaybackEngine.ets`
- `linkora_core/src/main/ets/playback/PlaybackPort.ets`, `PlaybackBackend.ets`, `AdaptivePlaybackPort.ets` where present.

If a referenced historical evidence filename is not obvious, inspect the repository directory and record the actual path; do not invent historical evidence.

## 3. Installation and authorized Windows EOL-only recovery

Run **one normal** `ohpm install`. Do not reinstall to repair semantic failure.

Only these paths may be restored from HEAD in the isolated checkout for **proven EOL-only drift**:

```text
entry/oh-package-lock.json5
linkora_ffmpeg/oh-package-lock.json5
linkora_proxy/oh-package-lock.json5
oh-package-lock.json5
```

For each affected file freshly prove allowlisting, Git-normalized worktree blob equals the HEAD blob, exact CRLF-to-LF byte equality, unchanged dependency/version/checksum/graph/comment semantics, and no other tracked changes. Restore only these files in the isolated checkout; prove clean again. Apply the **same fresh proof** after simulator verifier's normal dependency-restoration step.

Any extra changed path, changed semantic byte, unmatched blob or failed restoration => `BLOCKED — VALIDATION ENVIRONMENT`. Never touch the user's original dirty checkout.

## 4. Fresh build/isolation gates (mandatory before runtime)

Execute in order:

```powershell
./scripts/verify.ps1
./scripts/verify-simulator.ps1
./scripts/verify.ps1
```

Keep separate actual raw outputs and test results for both default runs (do not allow the second Hypium result to overwrite the first without preserving it). Require two clean Hypium suites, architecture/pure checks, Debug/Release HAR/HAP, exact ARM64 native library/ABI audits; simulator parity, audio metadata static guard, x86 FFmpeg-only artifact whitelist, and default dependency restoration.

No production package, source, build profile, lockfile, test expectation, signing settings or simulator stub may be edited. If a compile/artifact/test gate fails, STOP with its precise result and evidence. Do not continue simulator runtime on a failed gate.

The signed simulator HAP must derive from the freshly built exact artifact using the previously authorized unchanged SDK signing procedure/profile, if signature enforcement requires it. Check installed ABI and explicit install status (HDC exit0 alone is not proof). Do not bypass permissions/signing or publish HAP/signing inputs.

## 5. Exact fresh focused functional investigation

Use the already controlled and user-owned corpus; preserve fixture media. Verify actual fixture hashes/manifests and served HTTP bytes against committed truth. Reject changed/unavailable fixtures; never fake codec metadata, re-encode to make a failing file pass, or alter player configuration/route to force success.

One **healthy control**: ordinary forced-System H.264/AAC MP4 with actual visible video pixels, progress and sampled leave cleanup. This validates the observation and capture method; it is not a seventh previously failed case.

Then investigate the **six historical failures**, each through unchanged product System playback:

| Case ID | Original Phase 8B observation | Investigation goal |
| --- | --- | --- |
| `hls-h264-aac` | `LNK-PLAY-006` before prepare/play | distinguish input/URI/manifest/segment request error, actual AVPlayer prepare error, SDK simulator limitation, and policy/adapter route |
| `hls-hevc-aac` | `LNK-PLAY-006` before prepare/play | same, separately; avoid inference from H.264 HLS |
| `mkv-ffv1-flac` | PLAYING + progress; visible frame not proven | event versus actual output/pixel, surface geometry and expected frame |
| `mov-prores-pcm` | PLAYING + progress; visible frame not proven | same, independently |
| `ogv-theora-vorbis` | PLAYING + progress; visible frame not proven | same, independently |
| `wmv-wmv2-wma` | PLAYING + progress; visible frame not proven | same, independently |

For HLS: record exact nonsecret source type, literal URL/routing, content type as available, controlled server GET/Range/manifest+segment evidence, timing/state/error and native hilog evidence. Do not automatically treat `LNK-PLAY-006` as a decoder/format verdict, and do not change HLS/DASH System-only production policy. Inability to exercise an identical owned fixture is NOT RUN/BLOCKED, not success.

For the four frame-evidence cases: separately record `startRenderFrame` signal if observable via unchanged product, PLAYING, monotonic position, videoSizeChange, native XComponent surface bounds, capture ROI coordinates and real RGB/frame-image digest where permitted, frame-visibility verdict, black/unchanged/misaligned versus genuine colored image, and error/resource cleanup. Native frame-submission callback alone is **not** visible-frame proof. Do not attribute an unavailable screenshot to proof of black video or codec failure. Keep user-private screenshots and raw device identifiers local.

**Exactly one planned new execution per fixture after input and UI instrumentation preflight**. A procedural invalid input/setup attempt may be separately documented and corrected before the official valid attempt; never silently repeat a completed FAIL to replace its result. Every case must have explicit attempted/not attempted and independent evidence.

## 6. Causality, limits and disposition

For each original FAIL, distinguish where evidence permits:

- reproducible product/adapter or UI source defect (return to GPT with exact source/stack);
- simulator System native/API limitation;
- media input / route / manifest / controlled fixture defect;
- observation/instrumentation gap (position alone not frame proof);
- unresolved, with missing proof named.

Produce a fresh scoped diagnosis, not a global codec/output support ranking. Historical two HLS + four first-frame Phase 8B **FAIL stay untouched**; any new observed PASS is a separate Phase 8D result with its own source and timestamp, not a retrospective overwrite.

No device conclusion for Mate60, real MPV, HDR/DV, advanced audio/passthrough, ARM64 FFmpeg runtime or power/performance. No Auto/backend routing tuning, Direct I/O, display-mode UI, standalone feature implementation or thumbnail research / Issue #17.

## 7. Stop conditions / work ownership

Codex is **test-only**. If solving an issue requires modifying `SystemPlaybackPort`, `PlaybackEngine`, `PlayerPage`, test scripts, fixtures, build profiles or native package: STOP and return a concrete report; GPT performs the source/test-infrastructure change and dispatches a different future task.

STOP immediately on source/branch drift, failed required gate, semantic lockfile drift, unauthorized signing/workspace mutation, missing controlled input required for the scoped functional verdict, leaked secret or evidence contamination.

If Codex 5-hour quota remaining drops below 10%, preserve a truthful `PENDING` handoff without claiming completion; resume after reset, and never synthesize omitted checks.

## 8. Security, cleanup and provenance

- Preserve old failures, reports, old evidence, owned test media and unrelated user data.
- Preserve original `D:/Linkora` dirty state unchanged; isolated checkout only.
- Restore original Auto selection and modified app preferences; clean only resources created by this round.
- Never push credentials, signing data, private SDK/checkout absolute paths, device identifiers, real endpoints/tokens, generated media, HAPs, screenshots or unsanitized logs.
- Sanitized logs must remain accurately labeled; preserve original log hashes and avoid claiming sanitized copies are byte-identical originals.
- Record precise execution timestamps, source/dispatch SHA, package/SDK/ABI, fresh fixture provenance, tests attempted, controlled observations and limits.

## 9. Authorized report/evidence output ONLY

Codex may create/update **only**:

```text
docs/PLAYBACK_PHASE8D_SIMULATOR_INVESTIGATION_REPORT.md
test-lab/playback/phase8d-system-simulator-investigation-20261008/
```

This is one new evidence directory. Suggested files:

- `source-state.json`, `required-reading.json`, `protected-audit.json`, `security-review.json`;
- `install-eol-proof.json`, `post-simulator-eol-proof.json`, `build-results.json`, sanitized build/Hypium logs;
- `signed-simulator-provenance.json`, `fixture-input-proof.json`;
- `healthy-system-control.json`, `six-case-observations.json` (exact six IDs), sanitized event/network timelines, frame-capture evidence metadata;
- `root-cause-assessment.json`, `cleanup.json`.

Never edit Phase 8B/8C evidence or `docs/CODEX_VALIDATION_TASK.md` itself.

## 10. Publication & final classification

Before handoff:

1. prove only the report and new directory differ from the fetched branch;
2. fresh fetch, stop if protected remote drift;
3. commit only authorized new report/evidence;
4. normal push to the exact task branch, no force, no merge;
5. fetch remote again, prove pushed evidence commit reachable/contained, and report its full 40-character SHA;
6. if push unavailable, say `BLOCKED — EVIDENCE NOT PUSHED` with local SHA; never claim GPT handoff.

Use one primary classification:

- `PASS — FOCUSED SYSTEM SIMULATOR INVESTIGATION COLLECTED` (all six independently attempted and fully characterized, even if one remains native FAIL/UNRESOLVED);
- `FAIL — PLAYBACK FUNCTIONAL DEFECT IDENTIFIED` (reproducible source defect; no patch);
- `FAIL — ARM64 BUILD GATE`;
- `FAIL — SIMULATOR BUILD`;
- `FAIL — INVESTIGATION EVIDENCE INCOMPLETE`;
- `BLOCKED — VALIDATION ENVIRONMENT`;
- `BLOCKED — SIMULATOR ENVIRONMENT`;
- `BLOCKED — EVIDENCE NOT PUSHED`;
- `PENDING — CODEX QUOTA` (truthful incomplete checkpoint).

No retroactive Phase 8B PASS. Do not repeat Phase 8C native audit. Do not begin device testing.
