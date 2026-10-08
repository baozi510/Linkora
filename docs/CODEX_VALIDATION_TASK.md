# Codex Validation Task

> State: READY
> Task ID: phase8e-sim-system-prepared-state-gate
> Repository: `baozi510/Linkora`
> Branch: `feat/playback-capability-phase8`
> Validation source SHA: `68452df5486cf568da66a5c52352841cb7e64c5f`
> Pre-fix production baseline: `99ab47020f81391b7640d44c58ccb719491b4106`
> Accepted investigation evidence (collection only): `9c4f6ded7cc86afad1052eb448ce3172b3232db6`
> Role: Codex BUILD/TEST/EVIDENCE/REPORT ONLY; GPT owns production changes

## 0. New task and exact owner change

This is a **new Phase 8E simulator validation of a GPT-owned System playback readiness safety correction**, not a rerun of any previous task ID.

Prior completed tasks: `phase8c-sim-native-first-capability-audit`, `phase8d-sim-system-hls-first-frame-root-cause`, `phase8d-sim-rerun1-hdc-rport-six-case`. Do **not** execute them again.

GPT independently accepted Phase 8D-SIM Rerun 1 as `PASS — FOCUSED SYSTEM SIMULATOR INVESTIGATION COLLECTED` **only for bounded investigation scope**. Healthy MP4 passed; two HLS remained native `initialized` when Linkora called play, despite HLS manifest/segments GET200; four legacy System videos showed native size0x0, no frame callback and black sampled ROI with positive position deltas. Historical Phase 8B six FAIL, prior Phase 8D BLOCKED/NOT RUN and Phase 8D rerun bounded FAIL remain immutable. No codec, hardware, audio output or Mate60 support was accepted.

**Changed source:** `entry/src/main/ets/playback/SystemPlaybackPort.ets` now requires ALL THREE before `prepare()` fulfills its app-level contract: successful underlying `AVPlayer.prepare()` Promise, explicit native `stateChange('prepared')` notification, and current native `AVPlayer.state === 'prepared'`. The new wait is bounded by `PREPARATION_TIMEOUT = 20000` ms. Timeout/native error/release rejects the pending preparation, clears the timer and prevents `AdaptivePlaybackPort` from committing/emitting its synthetic PREPARED early. Native play should **never** occur in `initialized` just because a native Promise returned. Source may still fail HLS with a bounded timeout; **HLS format playback is not an expected PASS gate**.

Source is **NOT YET COMPILED/VALIDATED** by GPT; your full fresh builds and target checks are mandatory. Native-first SDK contract research remains the scope; don't add workarounds/format blacklists, change System-only HLS routing, or claim device runtime.

## 1. Fresh source/checkout isolation

1. Fresh-fetch `baozi510/Linkora` branch `feat/playback-capability-phase8`. Validate current task state=READY, task ID and exact implementation SOURCE_SHA `68452df5486cf568da66a5c52352841cb7e64c5f`; save actual fetched dispatch HEAD and branch metadata.
2. Verify source SHA is an ancestor of the actual dispatch HEAD. Run `git diff --name-only 68452df5486cf568da66a5c52352841cb7e64c5f..HEAD`: the ONLY ALLOWED DRIFT is **`docs/CODEX_VALIDATION_TASK.md`**. An extra tracked path => STOP with exact evidence, no run.
3. Check complete ancestry back to accepted Phase 8D evidence `9c4f6ded7cc86afad1052eb448ce3172b3232db6`; pin three native submodules to committed SHA. Clean isolated checkout/worktree only; do not stash/reset/clean/checkout the user's dirty `D:/Linkora`.
4. If an **optional extra recursive remote submodule fetch** hits TLS errors, do not disable certificate verification, change Git file protocol security rules or accept unverified pins. Existing trusted local Git repositories may be used for explicit normal clones only after fresh pin/hash provenance and exact Git object verification, followed by normal submodule absorption and origin URL synchronization; record truthfully or STOP if unprovable.
5. No old app artifact, test result, signed HAP, historical PASS or previous evidence may replace a new invocation.

## 2. Required reading — actual current source and history

Read and record complete relevant content:
- `docs/AI_WORKFLOW.md`
- `docs/MASTER_IMPLEMENTATION_PLAN.md`
- `docs/ARCHITECTURE_TARGET.md`, `docs/ARCHITECTURE_MIGRATION.md`
- latest CURRENT EXECUTION SUMMARY of `docs/IMPLEMENTATION_STATUS.md`
- latest CURRENT STATE of `docs/SESSION_HANDOFF.md`; distinguish historical snapshots
- entire `docs/CODEX_VALIDATION_TASK.md` (this task)
- `docs/PLAYBACK_PHASE8D_SIMULATOR_RERUN1_REPORT.md`, `docs/PLAYBACK_PHASE8D_SIMULATOR_INVESTIGATION_REPORT.md`, `docs/PLAYBACK_PHASE8B_REPORT.md` and `docs/PLAYBACK_PHASE8B_SIMULATOR_RUNBOOK.md`
- `test-lab/playback/phase8d-system-simulator-rport-rerun1-20261008/native-event-analysis.json`, `official-attempt-ledger.ndjson`, `root-cause-assessment.json`, `target-route-proof.json` and `six-case-observations.json`; read bounded prior source and observed differences, DO NOT inherit as new PASS
- `docs/PLAYBACK_NATIVE_CAPABILITY_AUDIT_REPORT.md` for installed SDK/native-first limitations
- `entry/src/main/ets/playback/SystemPlaybackPort.ets` at SOURCE and pre-fix revision (diff)
- `entry/src/main/ets/playback/AdaptivePlaybackPort.ets`, `entry/src/main/ets/playback/NetworkPlaybackSourceResolver.ets`, `entry/src/main/ets/pages/PlayerPage.ets`
- `linkora_core/src/main/ets/playback/PlaybackPort.ets`, `PlaybackEngine.ets`, `PlaybackModels.ets`, `PlaybackBackend.ets`
- controlled Phase 8B fixture manifest/truth in `test-lab/media-compatibility/` for MP4 healthy control, both HLS cases and one selected legacy video, including exact HLS segment payloads
- installed API26 MediaKit `AVPlayer.prepare()/play()`, `state` and `stateChange` declarations, and installed HDC 3.2.0f `rport` and removal syntax, cross-check current official primary docs.

Keep accurate per-file SHA/provenance. If a named historical path differs in actual repository, locate the exact tracked file rather than inventing it.

## 3. Normal ohpm, EOL-only recovery and strict source protection

Run one normal initial `ohpm install` and do not attempt a second repair install.

The only tracked paths permitted for **freshly proven Windows EOL-only temporary restore inside the isolated validation checkout**:

```text
entry/oh-package-lock.json5
linkora_ffmpeg/oh-package-lock.json5
linkora_proxy/oh-package-lock.json5
oh-package-lock.json5
```

For each affected path prove exact allowlist, Git-normalized blob equality to the checkout HEAD, CRLF→LF exact HEAD-byte equality, unchanged dependency/version/graph/checksum/comment semantics, and no other tracked byte change. Only then restore those exact files to HEAD in isolated checkout; verify fully clean. Repeat independent fresh proof after simulator verifier's normal dependency-restore install. Any other worktree drift or semantic discrepancy => STOP `BLOCKED — VALIDATION ENVIRONMENT`.

Do not edit production/test scripts, profiles, lockfile semantics, dependency versions, simulator stubs, package/native source, fixture bytes or test thresholds. All source fixes return to GPT for a new source/review commit.

## 4. Fresh non-negotiable build gates

In exact order:

```powershell
./scripts/verify.ps1
./scripts/verify-simulator.ps1
./scripts/verify.ps1
```

Preserve both actual Hypium originals before overwrite and separately record each command exit status. Require architecture fixtures, FFmpeg and analysis pure tests, artifact fixtures, MPV mapping, Debug/Release HAR/HAP for four modules, each default's two exact-nine AArch64 native library/ABI audits, simulator parity/isolation/audio-only metadata static guard, x86 simulator FFmpeg-only native whitelist and final restored production native deps. STOP on ANY compile failure or required failed gate: no target runtime after failed build. Classify `FAIL — ARM64 BUILD GATE`, `FAIL — SIMULATOR BUILD` or exact test failure truthfully.

Use only an unchanged legal SDK signing mechanism and existing appropriate simulator profile if normal unsigned HAP install is rejected by signature enforcement. Audit exact fresh signed x86_64 native whitelist/ABI after signing; explicitly replace-install the exact signed artifact and cold-launch, recording actual status beyond HDC exit0. Do not disable signing/permission checks, edit profiles or wipe application data. Never publish signing secret/HAP/device IDs.

## 5. Controlled reverse mapping and native route proof

Keep the **same controlled owned fixture server, same literal simulator loopback HTTP URI/port19084 and same retained exact fixture media** as Phase 8D rerun. The previous fix was environment setup, not a license to bypass production route.

- Check installed HDC help: `fport` host→device; `rport` device→host. Inspect host19084 listener ownership and existing reverse/forward list before touching anything; don't disturb unrelated services. Start only the owned fixture server listening 127.0.0.1:19084; verify actual owner/bytes.
- Create exactly one `hdc rport tcp:19084 tcp:19084`, confirm actual `[Reverse]` list and status while server stays running. Never use `fport` to create this device→host route; don't change port/URI/host.
- Demonstrate actual simulator→host request, correlated to one official healthy unchanged app MP4 open and native AVPlayer GET/Range events (not just host curl). The healthy case counts once. If target route cannot be shown, STOP `BLOCKED — SIMULATOR ENVIRONMENT`; do not proceed using host-only GET as a substitute.
- Freshly prove controlled inputs and HLS manifest/three segments for BOTH targets by local and authenticated TLS WebDAV hash/wholeGET/Range206 plus owned host served-byte proof against committed truth. No reencoding, regeneration, manifest rewrite, mixed media or fake codec fields.

## 6. Scoped runtime contract regression (not codec certification)

**Contract invariants under test:**

A. A healthy System MP4 control must still play: native initialization → actual prepared notification, underlying Promise fulfillment, app PREPARED only after native prepared confirmation, native play then playing, video320×180, actual first-frame submission callback and separately observed colored XComponent pixels, positive position progress, sampled clean leave.

B. Two HLS cases independently: `hls-h264-aac` and `hls-hevc-aac` (exact HLS input/route as original). Each gets **one distinct official prepared/playback attempt**; don't retry a completed failed case. Record controlled manifest+segments GET200 and actual native event timeline. The expected owner **safety** verdict is either:
  - native genuinely transitions to `prepared`, only THEN a play occurs, and actual output (if any) is judged independently, OR
  - native remains `initialized` and the app **does not** issue play/emit false PREPARED; preparation terminates on the explicitly bounded 20s timeout/error with concrete mapped failure and sampled release.
Do not call an HLS timeout a format PASS, do not infer a decoder unsupported verdict. `JsPlay` while native still initialized **or** synthetic PREPARED emitted without native prepared is a **production regression FAIL**, even if no crash. An unbounded hang beyond the configured bounded gate is FAIL/STOP.

C. Cancellation/leave scenario distinct from official HLS format attempts: open one controlled HLS input and intentionally leave **while preparing**, before native `prepared`; record it as a separately labeled cancellation test, not a second format verdict or replacement run. Require timely release of pending preparation without stale PREPARED/play/error leaking into next controlled healthy session, with sampled surface/player/audio/forward cleanup. If native preparation cannot be held open reproducibly, report this exact guard as NOT PROVEN, do not synthesize PASS.

D. One separate legacy video **representative** from the four Phase 8D samples (suggest `mkv-ffv1-flac`), one official fresh System attempt after the change to establish no new app synthetic-ready regression. Record native prepared and native play ordering, size callback, actual first-frame callback vs registration, ROI pixels, duration/position samples and raw helper Boolean. This case is **not expected to show playable video**; preserve any new black result and distinguish positive delta from >=800ms helper predicate. Do not re-run all six legacy issues as a hidden compatibility ranking.

E. Preserve existing forced System / Auto decision policy. No MPV real runtime claim: simulator has only a stub. Any observed Auto fallback is recorded as software control flow only, never real MPV codec success. No new fatal error after release; restore original Auto user selection.

All new verdicts must distinguish:
- compile/test gates versus runtime functional results;
- native Promise resolution versus `stateChange('prepared')` and `player.state`;
- app synthetic PREPARED versus true native readiness;
- first-frame callback versus actual visible frame;
- raw >=800ms progress predicate versus strictly positive deltas;
- simulator System versus Mate60 real ARM64;
- scoped native failure versus proven codec/system-wide support.

No implicit retry, no changing verdict/threshold/fixture midrun. If orchestration itself fails before the official run, record invalid setup separately; only clean, documented preflight correction is allowed. If a production or test-instrumentation change is needed, STOP with exact proof, never patch code from Codex.

## 7. Review and root-cause decision limits

The initial Phase 8D evidence already exposed HLS prepare Promise-vs-state mismatch. The GPT fix is a **defensive app-contract correction only**. The fact that an HLS clip still fails to play is not enough to fail this fix if it is **bounded and cannot call play in initialized**. Conversely, if native prepared never arrives, do not pretend the codec or hardware works.

Record the SDK `stateChange` correlation and any timer/release races with timestamps (e.g. native prepare Task In/Out, prepared notification, app onStateChange, JsPlay, async reject). If app contract telemetry cannot be observed without code changes, report NOT PROVEN instead of relying only on UI.

Do not promote System simulator HLS/legacy findings to real-device acceptance. Do not modify System-only HLS/DASH routing, Auto, Direct I/O, playback speed, buffer contract, seek UI, display fit, tracks, HDR/DV or advanced audio output. Their Phase 8C native-first owner backlog remains separate.

## 8. Mandatory cleanup and confidentiality

Remove **only this task's** reverse mapping using installed HDC removal syntax (e.g. supported `fport rm` with exact owned mapping), prove no owned reverse remains; do not remove unrelated mapping. Stop only the owned fixture server, verify host listener cleanup and leave other services/media intact. Remove only owned temporary HTTP UI row, restore saved Auto preference/layout, check sampled surface, app player service entries, app audio renderer count zero after each leave (not proof of leak freedom). Preserve user dirty D:/Linkora, retained WebDAV profile, media corpus and all historical evidence.

Never publish private endpoint/host identifiers/PIDs, credentials, tokens, device IDs, signing/profile secrets, HAPs, raw screenshots/hilog or absolute SDK/checkout paths. Redacted native log excerpts must state actual selection/subset method and distinguish from private complete native hilog. Publish sanitized build logs with original local file hash, gzip exact decompression/hash proof, and preserve every warning and test verdict. Do not query Codex quota/usage and do not add quota checks as a gate.

## 9. Authorized new outputs ONLY

Codex may create/update **only** the following two paths:

```text
docs/PLAYBACK_PHASE8E_SYSTEM_READINESS_VALIDATION_REPORT.md
test-lab/playback/phase8e-system-prepared-readiness-sim-20261008/
```

Suggested evidence within the new directory: `source-state.json`, `required-reading.json`, `protected-audit.json`, `security-review.json`, `initial-eol-proof.json`, `post-simulator-eol-proof.json`, fresh independent Hypium/build logs/results, `signed-artifact-install.json`, `fixture-truth.json`, `reverse-mapping-proof.json`, `target-route-proof.json`, `native-readiness-timeline.json`, `healthy-control.json`, `hls-two-case-results.json`, `leave-during-prepare.json`, `legacy-representative.json`, `cleanup.json`, `log-integrity.json`.

Never rewrite `docs/CODEX_VALIDATION_TASK.md` after dispatch; never touch old report/evidence or test assertions.

## 10. Exact publication and primary classification

1. Before push, verify tracked diff contains **only** new allowed report/new evidence directory; do not commit source/tests/scripts/lock/profile/old evidence.
2. Fetch remote branch fresh and stop on unexpected protected advancement.
3. Commit allowed outputs and normal push only (no force/no merge).
4. Fetch remote again; prove exact evidence SHA is remotely contained, all promised new blobs available, historical tracked blobs unchanged, sanitized gzip integrity, checkout clean. Report 40-char evidence SHA.
5. If push not confirmed, report `BLOCKED — EVIDENCE NOT PUSHED` with local SHA; do not claim delivery.

Choose exactly one truthful primary result:
- `PASS — SYSTEM NATIVE PREPARED-STATE GUARD VALIDATED` **only** when fresh builds pass, healthy control PASS, both HLS show no premature native play/synthetic PREPARED and bounded resolution, and required leave/cancellation safety is actually verified. Legacy case may remain bounded video-output FAIL, explicitly.
- `FAIL — SYSTEM PREPARED-STATE GUARD REGRESSION` for early play/synthetic ready, unbounded wait, incorrect error/cancellation or severe functional regression.
- `FAIL — ARM64 BUILD GATE` / `FAIL — SIMULATOR BUILD` / `FAIL — REQUIRED TEST GATE`.
- `FAIL — INVESTIGATION EVIDENCE INCOMPLETE` when required observability is absent despite executed runtime.
- `BLOCKED — VALIDATION ENVIRONMENT` / `BLOCKED — SIMULATOR ENVIRONMENT` / `BLOCKED — EVIDENCE NOT PUSHED`.
- `PENDING — INTERRUPTED` for honestly incomplete work, no quota inference or query.

No old task rerun. No old FAIL/NOT RUN reclassification. GPT independently reviews remote evidence after publication.
