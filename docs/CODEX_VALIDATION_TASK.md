# Codex Validation Task

> State: READY
> Task ID: phase8f-sim-rerun1-positive-progress-cancel-recovery
> Repository: `baozi510/Linkora`
> Branch: `feat/playback-capability-phase8`
> Validation SOURCE_SHA (exact reviewed tree): `50eaf6da48f6d0e445676050bde362adfd0b36b6`
> Unchanged implemented playback fix: `8174e6e4f0214958fb83fef46e92170c4c10263a`
> Prior stopped Phase 8F evidence: `202fdab4f77365bd62ec60fe5af2c2fb9cc9364c`
> Role: TEST / BUILD / SIMULATOR RUNTIME / REPORT / EVIDENCE ONLY

## 0. New and distinct task — no previous task replay

This is a **new authorized investigation/validation task**, NOT a restart of the previous `phase8f-sim-adaptive-pending-candidate-cancel-recovery` ID. The previous task executed and was independently accepted as `FAIL — REQUIRED TEST GATE` after a private helper's `>=800ms` progress assertion failed on a healthy MP4 with 161→927ms = **positive +766ms**. Its original helper exit1, AssertionError, `positionAdvanced=false` and bounded FAIL are final historical evidence and may **never** be reclassified or overwritten. The full Phase8F cancellation and recovery were NOT RUN. No player regression or cancellation-fix PASS was established.

**GPT review decision:** The Phase8F task's healthy progress contract was *strictly positive monotonic playback position*, whereas the reused PRIVATE `focus-run.PRIVATE.py` asserted `>=800ms`. This mismatch is **test orchestration semantics**, not a product defect established by the +766ms sample. This new task explicitly defines an independent acceptance method so it does not depend on or secretly loosen the old private helper. **Do not invoke the old >=800ms-asserting focus runner as a required healthy gate or patch/comment out its assertion.** If you nevertheless invoke any existing helper and it fails, record its exit/failure and STRICT STOP; do not ignore a failed gate.

No new production change has been made in the GPT review commit. The **only production change under test** is the previously committed Adaptive pending-candidate lifecycle repair at `8174e6e4f0214958fb83fef46e92170c4c10263a`. Its correct asynchronous cancellation and next-session recovery are **UNVALIDATED**. Keep current System 20s native prepared-state gate, forced System-only HLS routing, original Auto preference behavior, and all historic outcomes unchanged.

No physical ARM64 device currently available: **simulator tests plus fresh ARM64 builds**. Real MPV simulator stub, hardware/HEVC codec/HDR/Dolby Vision/advanced audio/encoded passthrough/device output/performance are NOT PROVEN. Do not implement Auto tuning, Direct I/O, Issue#17 thumbnails, display UI, native features, or any code/policy changes.

## 1. Exact source checkout and permission boundary

1. Fresh-fetch `feat/playback-capability-phase8` from `baozi510/Linkora`, confirm this task's READY and exact ID, repository/branch, full validation SOURCE_SHA `50eaf6da48f6d0e445676050bde362adfd0b36b6`, and actual full dispatch HEAD. Verify Phase8F evidence `202fdab4f77365bd62ec60fe5af2c2fb9cc9364c` is an ancestor of SOURCE_SHA; SOURCE_SHA must be an ancestor of dispatch HEAD.
2. `git diff --name-only 50eaf6da48f6d0e445676050bde362adfd0b36b6..HEAD` must show **exactly `docs/CODEX_VALIDATION_TASK.md`**. Any other tracked drift => STOP `BLOCKED — SOURCE DRIFT`. The production `AdaptivePlaybackPort.ets` / `SystemPlaybackPort.ets` blobs must match the previous implemented source `8174e6e4f0214958fb83fef46e92170c4c10263a`.
3. Use a new distinct clean isolated clone/worktree, **never alter, stash, reset, clean or switch the user's dirty `D:/Linkora`**. Pin and verify three committed native submodules' Git object identity and origin. Fresh mainline ref, do not bypass TLS or relax Git local file transport rules; exactly verified trusted local pinned Git repositories may be normal-cloned/absorbed with provenance if recursive fetch unavailable, otherwise STOP. No old HAP/build/test PASS/media regeneration.
4. Codex is test/evidence only. No edits to production, existing test expectations, tracked scripts, deps/lockfile semantics, build profiles, native packages, simulator stubs, playback source, manifest, fixture, privacy settings, task file or previous report/evidence. GPT owns any necessary fix. No quota/usage query.

## 2. Required complete reading and fixed provenance

Read as source of truth:
- `docs/AI_WORKFLOW.md`, `docs/MASTER_IMPLEMENTATION_PLAN.md`, `docs/ARCHITECTURE_TARGET.md`, `docs/ARCHITECTURE_MIGRATION.md`.
- `docs/IMPLEMENTATION_STATUS.md` newest CURRENT EXECUTION SUMMARY, `docs/SESSION_HANDOFF.md` newest CURRENT STATE, and **entire** `docs/CODEX_VALIDATION_TASK.md` (this file).
- `docs/PLAYBACK_PHASE8F_PENDING_CANDIDATE_CANCELLATION_REPORT.md` and `test-lab/playback/phase8f-adaptive-candidate-cancel-recovery-sim-20261008/{healthy-control.json,healthy-run.stderr.sanitized.txt,native-readiness-timeline.json,task-result.json,remaining-scenarios.json}`. Specifically inspect literal +766ms and the old raw >=800ms predicate/AssertionError. Do not reuse prior results.
- `docs/PLAYBACK_PHASE8E_SYSTEM_READINESS_VALIDATION_REPORT.md`, the Phase8E `leave-during-prepare.json`, `native-readiness-timeline.json`, `source-lifecycle-assessment.json` and `task-result.json`. This documents the prior cancellation failure and forced cleanup, not a result for this run.
- `docs/PLAYBACK_PHASE8D_SIMULATOR_RERUN1_REPORT.md`, `docs/PLAYBACK_PHASE8D_SIMULATOR_INVESTIGATION_REPORT.md`, `docs/PLAYBACK_PHASE8B_REPORT.md`, actual Phase8B simulator runbook, historical fixture truth, and `docs/PLAYBACK_NATIVE_CAPABILITY_AUDIT_REPORT.md` (native-first static scope).
- `entry/src/main/ets/playback/{AdaptivePlaybackPort,SystemPlaybackPort,NetworkPlaybackSourceResolver,MpvPlaybackPort}.ets`, `entry/src/main/ets/pages/PlayerPage.ets`, `linkora_core/src/main/ets/playback/{PlaybackEngine,PlaybackPort,PlaybackModels,PlaybackBackend}.ets`, existing relevant tests and scripts.
- The exact source diff `68452df5486cf568da66a5c52352841cb7e64c5f..8174e6e4f0214958fb83fef46e92170c4c10263a` for ownership/release behavior. Check actual installed API26 AVPlayer prepare/release/stateChange and HDC3.2.0f rport/list/remove help; official primary docs for reference.
- Retained four fixture classes/ten files in committed owned corpus: healthy H.264/AAC MP4, HLS H.264/AAC, HLS HEVC/AAC (both manifest and all three segments), MKV FFV1/FLAC; actual manifest/test-source truth.

Preserve sha/provenance; if a named historical path is absent, find the actual tracked repository path rather than fabricating it.

## 3. One normal install, fresh lock proof, full build before runtime

Execute exactly **one initial ordinary** `ohpm install`. A later install as the simulator verifier's ordinary `finally` dependency restore is permitted.

After initial and again after simulator-verifier finally install, prove fresh EOL-only modification and only then locally restore to HEAD these four allowlisted lockfiles:

```text
entry/oh-package-lock.json5
linkora_ffmpeg/oh-package-lock.json5
linkora_proxy/oh-package-lock.json5
oh-package-lock.json5
```

For each: exact allowlist, Git-normalized blob == HEAD blob, CRLF→LF byte equality == HEAD, unchanged versions/checksums/graph/comments, no other tracked path or semantic change; clean isolated checkout after restore. Never restore user workspace. Semantic difference or unclean checkout => STOP `BLOCKED — VALIDATION ENVIRONMENT`.

**Fresh required command order** (never inherit Phase8F/8E outputs):

```powershell
./scripts/verify.ps1
./scripts/verify-simulator.ps1
./scripts/verify.ps1
```

Capture both independent raw Hypium original outputs before overwrite, exact counts/exits, architecture fixtures, FFmpeg+analysis pure tests, artifact fixtures, MPV mapping, Debug/Release HAR/HAP and two separate exact-nine AArch64 artifact/ABI audits **in each default invocation**. Simulator requires parity/isolation, metadata static guard, exact sole x86 FFmpeg-native whitelist, final default production MPV/native re-restoration. Any gate failure STOP before runtime; classify actual ARM64/simulator/test failure.

Use a freshly produced simulator HAP. If necessary sign only the exact new HAP via unchanged legal installed SDK sign tool and existing simulator-permitted profile. **Signed x86 ABI auditor CLI uses positional argument `x86_64`, not `--abi=x86_64`**; first inspect the actual script syntax and run the valid invocation. Do not repeat previously observed bad setup argument. Preserve legal permission/signature checks; signed HAP exact hash/bytes/native whitelist, explicit replace-install success, ordinary coldlaunch without data wipe. HDC exit0 alone is not proof.

## 4. Controlled inputs, forward preflight and host

Reuse only the exact owned fixture server and same target loopback HTTP route/port 19084. Check host TCP19084 ownership and mapping lists before activity; do not stop unrelated listeners/services. Verify local all ten retained files, exact SHA/size, ffprobe, authenticated TLS WebDAV whole GET and Range206 against committed truth, and owned host's served bytes; don't regenerate/modify media.

Start only owned fixture server bound to host127.0.0.1:19084; ensure verified matching server owner. Use exactly **one `hdc rport tcp:19084 tcp:19084`** for simulator→host direction. Confirm explicit success and actual `[Reverse]` mapping, server remains listening. Do not create fport forward or switch ports/path/URI to force success. A genuine simulator/native AVPlayer GET or Range206 correlated to the **one official healthy System MP4 open** must prove target HTTP route. Host-only curl is not target-route evidence. Stop on missing owned route or byte truth.

## 5. Mandatory task-specific progress semantics and collector

**Preselect and document a fresh, PRIVATE, task-specific non-invasive runtime collection method BEFORE first official open.** It can use approved HDC UI automation, timestamped UI hierarchy reads, controlled screenshots + pixel samples, native selected hilog excerpts, fixture-server access records and fixed outside-repo scripts. It must NOT modify tracked source/test scripts/test assertions/HAP or runtime hooks and must NOT patch the old private `focus-run.PRIVATE.py`. Do not run the previously >=800ms-asserting focus helper as a required gate; use an independent, non-asserting collector or freshly authored private runner that implements this task's explicit contract, and preserve its command/source hash + execution provenance in the new sanitized evidence.

**Healthy acceptance MUST meet each invariant independently:**
- Exact unchanged forced System H.264/AAC MP4 opened once; owned actual native target GET/Range206 and correct source URI;
- Native `initialized → prepared → JsPlay → playing`, actual `OnStartRenderFrameCb` event (not registration), native `videoSizeChange(320,180)`, and independently sampled genuine multicolor testsrc pixels from correct XComponent bounds;
- At least TWO valid timestamped UI playback-position samples taken in the same valid playback window (ideally between 0.3 and 1.5 seconds apart), sampled promptly after PLAYING. **Measured later sample > earlier sample; positive delta strictly >0ms**. Bounded capture window no more than 5 seconds from first PLAYING (or actual natural completion, whichever comes first). Do not wait/retry until an arbitrary >=800ms difference is reached, artificially set position, change seek/decoder, or change values. If credible pair cannot be sampled within the window, outcome FAIL/NOT PROVEN, stop. Record raw samples/times and independently derived delta.
- Normal leave, with sampled app-associated surface/PlayerDistributedService/audio-entries all zero; not a native-object-count or exhaustive leak claim.
- The old `>=800ms` predicate is **historical only**, its Phase8F `false` and AssertionError remain untouched. You MAY publish a separately labeled `diagnosticAtLeast800ms` computed from this round's new independent samples, but it is NOT the healthy gate, NOT a rewrite of the old helper's raw `positionAdvanced`, and must never be named original raw output. If the old helper is invoked and returns failure, STOP without disregarding its failed gate.

**Never claim old Phase8F health helper PASSED**. This new test task authorizes different independent observation logic, not retrospective reclassification of a failed test.

## 6. Runtime execution order, no retries, strict stop

A. **New healthy forced-System MP4 control**: once, per Section 5. Require real pixels, native callback and strictly positive progress, actual target GET, no error and clean leave. This case is route proof and healthy gate in **one** official open. Fail => STOP, no further fixture.

B. **Two HLS cases** (`hls-h264-aac`, `hls-hevc-aac`), independently exactly one official open each. Require same source/URI, manifest+3 segments GET200 when fetched, timestamped native prepare-state/promise/JsPlay, actual errors. Never call play in initialized or synthesize PREPARED without native-ready confirmation if observable. A native HEVC decoder-type failure is simulator-scoped; no device/global codec inference. H264 native first-frame callback alone is not pixel proof: include actual later ROI/color if observed, otherwise `NOT PROVEN`. A bounded error/timeout can be a scoped format FAIL yet the safety contract may pass; don't change old results. If a new source safety regression or leak occurs, STOP.

C. **One FFV1/FLAC representative** (`mkv-ffv1-flac`), once; preserve native prepared/play ordering, 0x0 or actual size callbacks, callback event vs registration, sampled true ROI colors/black, monotonic delta and distinct optional >=800 diagnostic. Black/0x0 and positive time are not video PASS or audio audibility.

D. **Separate pending-candidate cancellation**: once with unchanged HLS H.264 controlled input. Deliberately leave while native `initialized` / `JsPrepare` **before `prepared`**, with at-leave native timeline and source/route evidence. Not a second HLS format verdict. Prove **actual candidate release was reached** (correlated native release/released notification when exposed) and sampled normally released surfaces, app-associated PlayerDistributedService entries and app audio-renderers are all zero WITHOUT force-stop or app uninstall/wipe. Capture early checkpoints after leave and a follow-up **after >20 seconds** verifying zero and absence of late play/stale commit as far as unchanged observable signals support. A service entry metric is not a count of unique AVPlayer instances, nor is audio renderer state proof of audibility.
  - If native release identity cannot be demonstrated, report exact telemetry limitation, and **do not claim cancellation repair fully validated** solely from transient zero counts.
  - If any app resources remain past bounded normal cleanup, or synthetic ready/play occurs after leave, STOP `FAIL — CANCELLATION CLEANUP REGRESSION` / `FAIL — PLAYBACK SOURCE REGRESSION`. Do not run E; do not use force-stop as a repair-PASS.
  - No direct JavaScript promise/candidate.commit/timer telemetry without hooks is `NOT PROVEN`, not fabricated.

E. **Distinct fresh healthy recovery MP4**: only after D passed ordinary cleanup without force-stop. A separately counted official open with genuine server GET/Range, native prepared→play, actual first frame+color pixels, fresh positive position pair using the same Section 5 contract, normal zero-resource leave. This verifies practical next-session safety, not absence of every theoretical async race.

Every case attempted **exactly once** and all actions/negative observations retained; no repeated official fixture after fail, no hidden retry to meet progression threshold. A setup-only invocation before any official fixture may be diagnosed/rectified without mislabeling it a media execution, but record it. STOP whenever new script itself asserts unexpectedly/nonzero, environment/resource/provenance fails, or code/test hooks would be needed. No production patch by Codex.

## 7. Cleanup, privacy and immutable results

Restore original Auto/backend preference and UI/layout; delete only this task's temporary HTTP media row; stop only owned fixture-server process, check host19084 no listener; remove only this task's reverse mapping via installed supported `fport rm` syntax, check forward+reverse list. Keep all other user data, owned media, WebDAV profile, unrelated mappings/services intact. Sample surface/app-service/audio after each leave and final cleanup. A later owned-app force-stop **only for containment after documented FAIL** is allowed; never credit it as normal cancellation/recovery PASS or silently run E afterward.

Never publish endpoint URLs, tokens, passwords, signing material, device identifiers, port-owner PIDs, SDK/user paths, raw screenshots/media/HAP/full hilog. Selected native logs must identify after-minus-before or other actual selection method and be labeled subset/redacted, not original. Public build logs sanitized with original private SHA, complete errors/warnings/actual exit status; gzip decompression/SHA256 provenance. Protect the original dirty `D:/Linkora` unchanged. No quota queries or polling requirements.

## 8. Only authorized new outputs and publication

May create/update ONLY:

```text
docs/PLAYBACK_PHASE8F_RERUN1_POSITIVE_PROGRESS_CANCELLATION_REPORT.md
test-lab/playback/phase8f-rerun1-positive-progress-cancel-recovery-20261008/
```

Suggested: `source-state.json`, `required-reading.json`, `protected-audit.json`, `build-results.json`, two fresh actual Hypium files and sanitized logs/gzip, `eol-initial.json`, `eol-post-simulator.json`, `signed-artifact-install.json`, `fixture-byte-proof.json`, `native-route-proof.json`, `independent-collector-provenance.json`, `healthy-positive-progress.json`, `hls-case-observations.json`, `ffv1-case.json`, `pending-cancel-timeline.json`, `release-cleanup-checkpoints.json`, `recovery-healthy.json`, `attempt-ledger.ndjson`, `security-review.json`, `log-integrity.json`.

No modifications to `docs/CODEX_VALIDATION_TASK.md`, old evidence/report, production/tests/profile/media/lock semantics. Remote evidence must be append-only in new paths.

After tests: audit exact changed paths and old blobs, fresh fetch remote branch, STOP on unrelated protected advancement, commit only authorized files and normal push (no force/no merge). Fresh fetch again and prove final remote HEAD contains pushed evidence SHA, every declared blob readable/hash-matched, old tracked files unchanged, sanitized gzip integrity, checkout clean; otherwise `BLOCKED — EVIDENCE NOT PUSHED` with truthful local SHA.

Choose one primary verdict:
- `PASS — ADAPTIVE PENDING-CANDIDATE CANCELLATION VALIDATED` only when all fresh build gates pass, independent A healthy **positive-progress** gate PASS, B scoped native-ready checks evidence collected, C one FFV1 sample collected, D native release + zero normal resource cleanup before/after >20s without force-stop, and E independent healthy recovery control PASS. B/C may retain bounded format FAIL, explicitly; no codec certification.
- `FAIL — REQUIRED TEST GATE` for a newly invoked real test/helper assertion, valid health gate/collector failure, or other mandatory gate; preserve raw nonzero and STOP.
- `FAIL — CANCELLATION CLEANUP REGRESSION` / `FAIL — PLAYBACK SOURCE REGRESSION` when actually reproduced.
- `FAIL — ARM64 BUILD GATE` / `FAIL — SIMULATOR BUILD` / `FAIL — EVIDENCE INCOMPLETE`.
- `BLOCKED — SOURCE DRIFT`, `BLOCKED — VALIDATION ENVIRONMENT`, `BLOCKED — SIMULATOR ENVIRONMENT`, `BLOCKED — EVIDENCE NOT PUSHED`, or `PENDING — INTERRUPTED` with exact scope.

At handoff include exact full 40-char source, dispatch, remote evidence SHA, verdict, actual cases attempted and NOT RUN. Future GPT decides further repair; Codex never uses this task to modify playback code.
