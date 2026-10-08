# Codex Validation Task

> State: READY
> Task ID: phase8f-sim-adaptive-pending-candidate-cancel-recovery
> Repository: `baozi510/Linkora`
> Branch: `feat/playback-capability-phase8`
> Validation source SHA: `8174e6e4f0214958fb83fef46e92170c4c10263a`
> Prior Phase 8E failed evidence: `e99ad8928811d394e65efb1ca31d77fb1c885c72`
> Role: BUILD / SIMULATOR RUNTIME / CANCELLATION AND RECOVERY EVIDENCE / REPORT ONLY

## 0. New task, owner correction, and scope

**This is a new validation task; do NOT execute any old READY ID.** The previous `phase8e-sim-system-prepared-state-gate` has been executed, independently reviewed, and **ACCEPTED AS FAIL — SYSTEM PREPARED-STATE GUARD REGRESSION**, not a pending test. Its documented five fresh opens/builds/FAIL remain immutable. The Phase 8D first attempt BLOCKED and Phase 8D rerun 1 collection PASS (six bounded playback FAIL) are also historical. Phase 8C native-first static audit acceptance does not imply hardware playback capability.

**GPT source correction at this exact validation source:** in `entry/src/main/ets/playback/AdaptivePlaybackPort.ets` the pending backend candidate is now owned from factory creation, through asynchronous prepare, until synchronous handoff to `this.backend`. On leave it is released before the resolved network lease; stale factory/prepare/lease results do not emit PREPARED or commit, and cancelled Auto never falls back to another backend. Double release is guarded by ownership-slot transfer. `SystemPlaybackPort.ets` now also rejects pending initialization on release and avoids late initialized-surface assignment. Previously introduced 20s explicit native prepared-state gate remains. No decoder/format/Auto routing/engine/UI/fixture/test policy was changed. **NONE of this new source has passed a fresh test yet.**

Your task: fresh build and inspect this lifecycle correction, then reproduce **one controlled cancellation while native System HLS is still preparing**, require timely normal release without a force-stop, and verify a distinct healthy recovery session afterward. Include ordinary healthy and bounded HLS/legacy regression evidence. Failure to prove normal cancellation is a FAIL/NOT PROVEN, not PASS. Never force-stop to claim an ordinary release result.

No physical ARM64 target is available. Required: simulator first **and full ARM64 build**. MPV simulator uses stub; x86 native FFmpeg is not real ARM64 runtime and none of these results proves Mate60 codec/device capability. No Direct I/O, media-session overhaul, Auto/codec policy, UI layout, display sizing, thumbnail Issue#17, advanced audio/HDR/performance work.

## 1. Fresh source and exact ancestry gate

1. Fresh-fetch `baozi510/Linkora` on `feat/playback-capability-phase8`, record actual full dispatch HEAD SHA. Verify READY/task ID/repo/branch, exact source SHA `8174e6e4f0214958fb83fef46e92170c4c10263a`, source ancestor of fetched HEAD, evidence `e99ad8928811d394e65efb1ca31d77fb1c885c72` ancestor of source.
2. `git diff --name-only 8174e6e4f0214958fb83fef46e92170c4c10263a..HEAD` must list **only** `docs/CODEX_VALIDATION_TASK.md`. Any other drift: STOP `BLOCKED — SOURCE DRIFT`.
3. Use a distinct clean isolated worktree/clone; do not modify/stash/reset/clean/check out over the user's dirty `D:/Linkora`. Verify all three committed submodule pins, origin provenance, hashes/ABI. If extra remote recursive fetch fails, no TLS disabling or unsafe Git file transport; exact trusted pinned local Git submodules may be used only with checked object/pin identity and normal clone/absorb/origin sync, documented. Never reuse any old HAP, PASS or install artifacts.
4. Codex role: **tests and evidence only**. No production code/test expectation/script/profile/config/dependency/native package/fixture/manifest/lock semantics/task change; suspected defect returns to GPT. No quota query or quota gate.

## 2. Mandatory reading and traceability

Read and capture exact source SHA/reading provenance for:
- `docs/AI_WORKFLOW.md`, `docs/MASTER_IMPLEMENTATION_PLAN.md`, `docs/ARCHITECTURE_TARGET.md`, `docs/ARCHITECTURE_MIGRATION.md`.
- `docs/IMPLEMENTATION_STATUS.md` most recent CURRENT execution summary; `docs/SESSION_HANDOFF.md` most recent CURRENT state; **entire** `docs/CODEX_VALIDATION_TASK.md`.
- `docs/PLAYBACK_PHASE8E_SYSTEM_READINESS_VALIDATION_REPORT.md` and `test-lab/playback/phase8e-system-prepared-readiness-sim-20261008/leave-during-prepare.json`, `native-readiness-timeline.json`, `source-lifecycle-assessment.json`, `task-result.json` (historical failure reference only).
- `docs/PLAYBACK_PHASE8D_SIMULATOR_RERUN1_REPORT.md`, `docs/PLAYBACK_PHASE8D_SIMULATOR_INVESTIGATION_REPORT.md`, `docs/PLAYBACK_PHASE8B_REPORT.md`, actual Phase 8B simulator runbook and fixture corpus truth. Phase 8C native capability audit boundaries.
- Exact `entry/src/main/ets/playback/AdaptivePlaybackPort.ets` and `SystemPlaybackPort.ets` at source and diff vs `68452df5486cf568da66a5c52352841cb7e64c5f`; `NetworkPlaybackSourceResolver.ets`, `MpvPlaybackPort.ets`, `entry/src/main/ets/pages/PlayerPage.ets`.
- `linkora_core/src/main/ets/playback/PlaybackEngine.ets`, `PlaybackPort.ets`, `PlaybackModels.ets`, `PlaybackBackend.ets`; any existing relevant test files and simulator commands.
- Installed API26 AVPlayer prepare/state/stateChange/release declarations and installed HDC fport/rport/list/remove help; current official docs as secondary cross-check.
- Four exact retained controlled media fixtures plus both HLS manifests and all segments (10 files) from the committed corpus, same literal simulator loopback 19084 source path.

**Lifecycle review checklist**: candidacy owned before awaiting `backend.prepare()`; `release()` claims `pendingCandidate`; System release rejects pending preparation AND initialization; no release→fallback; no late candidate.commit/Adaptive synthetic PREPARED after release; no double native release on concurrent error/cancel; no late resolver lease retention, late factory backend creation, or stale source surface binding. If a compile/type/API issue appears, STOP; Codex must NOT edit the patch. Native direct JS Promise/commit/identity observations not exposed by unchanged app are `NOT PROVEN`, not invented.

## 3. One install, EOL proof and fresh build chain

Run exactly one initial normal `ohpm install`. Simulator verifier's own standard finally dependency install is permitted. Only the following four tracked lock files may be restored from isolated checkout HEAD, **after separately proven fresh exact Windows EOL-only drift for each relevant phase**:

```text
entry/oh-package-lock.json5
linkora_ffmpeg/oh-package-lock.json5
linkora_proxy/oh-package-lock.json5
oh-package-lock.json5
```

Prove path allowlist, normalised Git blob equality, CRLF→LF byte equality to HEAD, unchanged dependency checksum/version/graph/comments, no other tracked byte changes, and fully clean isolated checkout after restore. Separate proofs after initial and simulator finally install. Any other drift, semantic change or unclean checkout => STOP `BLOCKED — VALIDATION ENVIRONMENT`. Do not repeat install to repair.

Run **fresh**, exact order:

```powershell
./scripts/verify.ps1
./scripts/verify-simulator.ps1
./scripts/verify.ps1
```

Preserve both actual Hypium raw output captures before overwrite, counters and exit codes. Require all existing architecture fixtures, FFmpeg/analysis pure tests, artifact fixtures, MPV mapping, Debug/Release HAR+HAP, **two exact-nine ARM64 ABI/native audits on each default invocation**, x86 simulator FFmpeg-only whitelist, parity/isolation and audio metadata static guard, final restoration to default real production MPV packaging. Any build/gate FAIL => STOP before runtime; report `FAIL — ARM64 BUILD GATE`, `FAIL — SIMULATOR BUILD` or exact failing gate, **do not call it cancellation failure without execution**.

For simulator deployment build a **new exact signed HAP**; use existing legal SDK signing/profile only, never disable signature/permission checks. Verify exact signed native x86 whitelist/ABI, hash and bytes; explicit replace-install and normal coldlaunch with no app data wipe. HDC exit0 alone is not install success. Keep HAP and credentials PRIVATE.

## 4. Fresh controlled HTTP route and input gate

Same authorized owned fixture server, host loopback19084, literal simulator `NETWORK_LINK` StreamPage URL, unchanged media bytes as Phase 8E. Check host listener owner/no unrelated occupancy and pre-mapping lists. Start only own host fixture server, authenticate inputs via fresh local SHA/size/ffprobe against committed truth; owned TLS WebDAV wholeGET/Range206, host 200/206 actual served-body proof. All ten selected media files including two HLS manifests and six segments must match committed truth.

Create **one** `hdc rport tcp:19084 tcp:19084` (device→host), check explicit success and actual `[Reverse]` mapping. Do not use fport to create this route. Prove actual target→host GET/Range via one official healthy System MP4 open and correlation to native AVPlayer user-agent, not host-only curl. No alternate port/media/route/URL/forced backend fallback/policy/config changes.

If route cannot be proven STOP `BLOCKED — SIMULATOR ENVIRONMENT` before HLS cases. The healthy route control counts once only, no duplicate anonymous PASS.

## 5. Runtime coverage and strict stop order

**A — baseline healthy System control**: fresh official MP4 H.264/AAC one open, native initialized→prepared→play→playing; actual native first-frame callback separately from expected-colored pixels on real XComponent ROI; 320×180; positive elapsed position; sampled clean leave. Fail/STOP on a newly broken baseline; never inherit previous healthy PASS.

**B — two HLS contract checks, independently once each**: `hls-h264-aac` and `hls-hevc-aac`. Manifest+three segments GET200 evidence; native prepare/promise-vs-state timeline, measured play and errors, current `player.state` if observable, synthetic PREPARED direct telemetry if available. `play()` while native initialized or app synthetic PREPARED before true native readiness is regression FAIL. A bounded prepare timeout or HEVC decoder error can remain scoped FAIL without invalidating a safety guard, but never claim HLS codec/visible-frame PASS without pixels. No automatic retry, no relabel of Phase 8D/8E results.

**C — one legacy representative**: `mkv-ffv1-flac` or same prior FFV1 controlled case, exactly one new open; preserve actual prepared/playing, 0×0 or genuine size, first-frame callback vs registration, black/pixel ROI and position deltas. If old raw helper uses >=800ms, retain raw Boolean and separately report positive delta; no black-to-PASS conversion, no audio audibility claims.

**D — single independent cancellation reproduction**: `cancel-hls-h264-aac` using exact controlled HLS input, deliberately leave **while initialized/preparing and before native prepared**. Must prove at-leave native timeline rather than guess. This is a cancellation test, not a second format verdict. Do not issue other fixture opens if the cancellation cleanup fails.

Require:
1. `AdaptivePlaybackPort.release()` reaches **the in-flight candidate's** `SystemPlaybackPort.release()` (native release/notify released where observable), not only after 20s timeout or force-stop.
2. There is no stale candidate commit, synthetic PREPARED/play or changed Auto selection after leave; any missing direct telemetry is clearly `NOT PROVEN`.
3. Bounded post-leave release and clean sampled surface count, app-matching PlayerDistributedService entries, audio renderer entries **zero without force-stop**, measured at comparable early and follow-up checkpoints (including >20s when justified), with honest semantics that service entries are not proven player object counts.
4. One clean teardown of the owned playback session, no application data wipe/uninstall. If native/player service/audio records persist beyond the practical bounded cleanup window, **FAIL — CANCELLATION CLEANUP REGRESSION**, preserve normal FAIL, STOP.

**E — healthy new-session recovery**: only after (D) clean without force-stop, open one **distinct** healthy controlled MP4 session (new official recovery execution), verify real prepared→play, fresh colored pixel frame callback/ROI, positive progress and sampled clean leave. This proves no stale candidate/observer poisoning of a subsequent session. If (D) FAIL, mark E `NOT RUN`; do not force-stop then claim recovery PASS.

Run exactly these scoped scenarios, not the old 39-feature, 59-case or six-video matrix. Differentiate setup errors from actual official runtime; don't conceal duplicate attempts or modify old results. Any necessary production hook/test fixture change stops and goes to GPT. Native MPV on simulator is stub; ARM64/Mate60/HDR/DV/passthrough/performance NOT PROVEN.

## 6. Cleanup and private-data guarantees

On normal completion or STOP: remove only this run's reverse HDC mapping using documented installed `fport rm` for exact task, verify list empty/own absent; stop only owned host fixture server and verify host listener gone; restore original Auto/backend preference and original app UI/layout, delete only owned temporary HTTP row. Retain owned media, WebDAV settings and all unrelated services. Sample surface/service/audio entries; avoid exhaustive leak claims. If abnormal cleanup truly requires force-stop, do **not** turn D/E to PASS: report it separately after recording repeated failure samples. Never wipe/uninstall user data.

Do not publish private URLs, endpoint, account credentials, IDs/PIDs, exact signing artifacts/certificates/profile, original dirty workspace/SDK paths, HAP/media, raw screenshots/video or full private hilog. Build and native logs are SANITIZED readable/gzip with original local SHA provenance; selected native logs explicitly `subset after-minus-before`, not false full original. Preserve warnings/error codes/results, exact gzip/hash checks, protected file counts.

No quota/remaining usage queries. If interrupted, report actual partial state, no background assertions.

## 7. Only authorized evidence/report output

Codex may create/update **only**:

```text
docs/PLAYBACK_PHASE8F_PENDING_CANDIDATE_CANCELLATION_REPORT.md
test-lab/playback/phase8f-adaptive-candidate-cancel-recovery-sim-20261008/
```

Suggested: source-state/reading/protected-audit, dependency-inputs, initial/post-sim EOL proofs, build-results, two original independently captured Hypium files, artifact/signing whitelist/install provenance, fixture truth, HDC reverse/target-route proof, fresh case ledger, healthy-control, two-HLS-case, legacy representative, pending-cancel timeline, cancellation-resource checkpoints, native-release evidence, next-session healthy recovery, cleanup, security-review, log-integrity with sanitized text/gzip.

Old Phase 8E report/cancelled attempt/evidence, Phase 8D reports and older fixture truth are immutable. Do not edit `docs/CODEX_VALIDATION_TASK.md` or production source while validating.

## 8. Publication and verdict

1. Audit tracked diff: only report and new evidence directory, no modified production/test/old evidence/config/semantic lock files. Verify original dirty workspace unchanged.
2. Fresh-fetch branch before push, STOP on protected advanced HEAD. Commit+normal push only; no force/merge.
3. Fresh-fetch after push; confirm final remote evidence SHA, ancestry, every promised remote blob availability, exact allowed-diff containment, old blobs unchanged and gzip integrity, checkout clean. If not remotely verified: `BLOCKED — EVIDENCE NOT PUSHED` and local SHA only.
4. One **primary** result:
  - `PASS — ADAPTIVE PENDING-CANDIDATE CANCELLATION VALIDATED` only after all fresh gates, healthy control, safe HLS native-state boundary, clean normal pending cancellation **without force-stop**, and distinct subsequent healthy recovery with independent pixels/cleanup. Legacy FFV1 may remain scoped output FAIL, explicitly.
  - `FAIL — CANCELLATION CLEANUP REGRESSION` (persistent app records, no normal native release).
  - `FAIL — PLAYBACK SOURCE REGRESSION` (stale commit, early play, late synthetic PREPARED, unhealthy control or broken recovery).
  - `FAIL — ARM64 BUILD GATE`, `FAIL — SIMULATOR BUILD`, `FAIL — REQUIRED TEST GATE`, `FAIL — EVIDENCE INCOMPLETE`.
  - `BLOCKED — SOURCE DRIFT`, `BLOCKED — VALIDATION ENVIRONMENT`, `BLOCKED — SIMULATOR ENVIRONMENT`, `BLOCKED — EVIDENCE NOT PUSHED`.
  - `PENDING — INTERRUPTED` if incompletely run; no fabricated PASS.
5. Share exact full source/dispatch/evidence SHAs, ordinary plain Markdown text, precise PASS/FAIL/NOT RUN, and owner next step. No more old tasks or quota checks.

GPT independently reviews any new evidence and owns any next source change.
