# Codex Validation Task

> State: READY
> Task ID: phase8d-sim-rerun1-hdc-rport-six-case
> Repository: `baozi510/Linkora`
> Branch: `feat/playback-capability-phase8`
> Validation source SHA: `c0d37ef9aaeba31c512743fe704e8d91ba1c0c48`
> Unchanged production playback baseline: `99ab47020f81391b7640d44c58ccb719491b4106`
> Prior blocked Phase 8D evidence: `391d56e4c0b36f19d4a52f8d77a4adab2db87b8b`
> Role: BUILD / VALIDATION ENVIRONMENT PREFLIGHT / SYSTEM SIMULATOR FUNCTIONAL INVESTIGATION / EVIDENCE / REPORT ONLY

## 0. Scope and operating authority

This is a **new, distinct rerun-1 task** correcting the **validation-environment setup** that stopped the prior Phase 8D task. The previous task `phase8d-sim-system-hls-first-frame-root-cause` has been executed, published and independently reviewed as `BLOCKED — SIMULATOR ENVIRONMENT`. Its original logs/FAIL/NOT RUN are immutable. **Do not re-run the previous task ID, repeat Phase 8C's 39-feature audit, or relabel historical Phase 8B observations.**

No physical ARM64 device is available; run Simulator-first and ARM64-build-always. MPV simulator is stub, x86 FFmpeg does not prove ARM64 runtime, and System simulator results do not prove Mate60. Real MPV, HDR, Dolby Vision, passthrough, native storage runtime and device output remain separate batched gates. This task is a focused investigation of two historical HLS initialization FAIL and four historical first-frame-evidence FAIL using unchanged System playback.

Neither chat messages nor prior evidence authorize deviation from this exact committed task. Codex is test/report-only: **do not change production source, tests/scripts, runtime logging hooks, native packages, fixtures, signing/profile settings, player policy, Auto, Direct I/O, UI/display modes or thumbnail research / Issue #17**.

## 1. Repository/source gate — before any install/build

1. Fresh fetch branch `feat/playback-capability-phase8`, initialize/check all pinned submodules, verify repository, task ID, READY, source SHA and clean isolated validation checkout.
2. Leave the user's existing dirty `D:/Linkora` untouched: no stash/checkout/reset/clean in that workspace. Use a distinct isolated clone/worktree.
3. Verify blocked evidence `391d56e4c0b36f19d4a52f8d77a4adab2db87b8b` is ancestor of exact source `c0d37ef9aaeba31c512743fe704e8d91ba1c0c48`, and source is ancestor of actual fetched HEAD.
4. Record and inspect `git diff --name-only c0d37ef9aaeba31c512743fe704e8d91ba1c0c48..HEAD`. The **only permitted drift** is `docs/CODEX_VALIDATION_TASK.md`. Anything else, including a report or old evidence change, => STOP with source-drift evidence.
5. Record full implementation source SHA and actual dispatch HEAD SHA separately. Do not substitute any prior run's build/test results.

## 2. Mandatory complete reading

Read these files and current portions fully (with required-reading provenance):

1. `docs/AI_WORKFLOW.md`
2. `docs/MASTER_IMPLEMENTATION_PLAN.md`
3. `docs/ARCHITECTURE_TARGET.md`
4. `docs/ARCHITECTURE_MIGRATION.md`
5. `docs/IMPLEMENTATION_STATUS.md` latest CURRENT EXECUTION SUMMARY, distinguish historical summaries
6. `docs/SESSION_HANDOFF.md` latest CURRENT STATE, distinguish history
7. `docs/CODEX_VALIDATION_TASK.md` (this task)
8. `docs/PLAYBACK_PHASE8D_SIMULATOR_INVESTIGATION_REPORT.md`
9. `test-lab/playback/phase8d-system-simulator-investigation-20261008/preflight-command-diagnosis.json`, `root-cause-assessment.json`, `six-case-observations.json`, `source-state.json`
10. `docs/PLAYBACK_PHASE8B_REPORT.md` and `docs/PLAYBACK_PHASE8B_SIMULATOR_RUNBOOK.md`
11. `docs/PLAYBACK_NATIVE_CAPABILITY_AUDIT_REPORT.md` (boundaries only; no Phase 8C rerun)
12. `test-lab/media-compatibility/` manifest / fixture truth for six IDs + healthy System MP4, the original Phase 8B simulator matrix/evidence and its input routing
13. `entry/src/main/ets/playback/SystemPlaybackPort.ets`, `entry/src/main/ets/pages/PlayerPage.ets`
14. `linkora_core/src/main/ets/playback/PlaybackPort.ets`, `PlaybackBackend.ets`, `PlaybackEngine.ets`, `AdaptivePlaybackPort.ets` if present
15. Actual installed HDC help for `fport`, `rport` and forwarding list/removal syntax.

If the exact historical file naming differs, locate actual tracked files before continuing. Do not invent a path or invoke the wrong API based on memory.

## 3. Initial installation and EOL-only normalization

Execute **exactly one initial normal** `ohpm install`; simulator verify's standard internal dependency-restore install is permitted later.

Only these tracked paths may be restored to HEAD for **freshly proven, semantically identical Windows EOL-only drift in the isolated checkout**:

```text
entry/oh-package-lock.json5
linkora_ffmpeg/oh-package-lock.json5
linkora_proxy/oh-package-lock.json5
oh-package-lock.json5
```

For each affected path prove (a) allowlisted; (b) Git-normalized worktree blob == exact checkout HEAD blob; (c) CRLF→LF normalized bytes == exact HEAD bytes; (d) no dependency/version/checksum/graph/comment change; (e) no other tracked-byte/path change. Restore only those proven EOL-only files from checkout HEAD and verify clean. Independently repeat the same proof after the simulator verifier's own dependency restoration. Failed proof / any semantic or other drift / dirty checkout after restore => `BLOCKED — VALIDATION ENVIRONMENT`, STOP. Never normalize the developer's unrelated workspace.

## 4. Fresh build, artifact and simulator install gates

Execute in this exact order **fresh for this new task**:

```powershell
./scripts/verify.ps1
./scripts/verify-simulator.ps1
./scripts/verify.ps1
```

Require independent actual outputs for both default runs: architecture-boundary fixtures, FFmpeg/analysis pure suites, MPV mapping, Hypium original files/counters, Debug/Release HAR/HAP, two exact-nine AArch64 native artifact/ABI audits in **each** default run. Require simulator parity/isolation, audio-metadata static guard, exact x86_64 FFmpeg-only native library whitelist; final default restores production MPV/native dependencies.

Audit the freshly built simulator HAP. Use only the existing legitimate SDK signing tool and existing profile to sign the exact artifact if the normal unsigned install is rejected by signature enforcement. Never bypass signature/permission checks, alter sign profiles or accept HDC transport exit0 as install proof. Independently audit signed artifact native ABI/whitelist, explicitly replace-install without clearing app data, and cold launch. Save hashes and private signing provenance only, never publish secrets/HAP.

On any failed build/Hypium/native whitelist/artifact/install gate: STOP before fixture or route runtime tests and publish accurate FAIL/BLOCKED with evidence. Previous Phase 8D passes are historical, not this round's substitutes.

## 5. Mandatory corrected HDC reverse-port setup — before official media opens

**This round fixes validation setup, not playback.** Keep the same owned controlled fixture media, same host fixture server, same intended HTTP fixture URI on simulator loopback, and same port 19084. Do not change server/path/manifest/segments or use a different port, direct WebDAV playback, rewriting the URL, or a temporary application hook to force a PASS.

Run the following ordered preflight, with sanitized command/status/time evidence:

1. Independently inspect installed HDC version/help. Confirm `fport localnode remotenode` is **host→device** and `rport remotenode localnode` is **device→host**. The intended fixture path is **device→host**. **Do not issue `fport` for this route.**
2. Inspect host TCP19084 listener ownership and HDC forward/reverse lists **before** starting services or mapping. Do not close or replace unrelated listeners/mappings. If TCP19084 is unexpectedly occupied by a different process or a conflicting mapping exists, STOP as `BLOCKED — SIMULATOR ENVIRONMENT`; record nonprivate bounded evidence.
3. Start only the designated owned fixture server on host 127.0.0.1:19084, verify it is this owned process and actually serves expected controlled manifest/bytes. Preserve the expected server and retained media.
4. Create a single **reverse** mapping, verified against installed HDC syntax, exactly:

```powershell
hdc rport tcp:19084 tcp:19084
```

Here `remotenode=tcp:19084` is the simulator's listening endpoint and `localnode=tcp:19084` is the already-running host fixture server. The host server **must stay running**. Confirm command-level result and the **actual reverse mapping** list. Ignore neither a rejected command nor a stale/unrelated mapping. Never treat an empty fport list alone as proof of an active rport mapping.
5. Establish an actual **simulator/device→host** HTTP request against the unchanged controlled server, observe matching host access trace/status/body/hash or controlled nonsecret probe. A host-only curl/whole-GET is **not** target-route proof. If the installed target shell has no HTTP client, the first **unchanged app's healthy forced-System MP4 open** may serve as the target-route proof: require correlated target/app activity and host GET on the exact route; count it as the healthy-control official execution, not an extra anonymous PASS.
6. If reverse mapping creation or the genuine target HTTP route fails, STOP: capture exact command/error/host-listener evidence, **do not retry using fport**, change ports, kill unrelated services, alter URI/route, or start the six-case matrix. No source patch.

Record host/server side and target side provenance without publishing endpoints, process identifiers or private paths. A successful `rport` status alone is not sufficient if no device-side HTTP request is demonstrated.

## 6. Seven actual scoped executions — only after the route is proven

Use only the retained owned corpus. Freshly hash all seven fixture inputs (including six HLS segments/manifests: 13 files total) against committed truth, TLS-verify owned authenticated WebDAV whole-GET and Range206 where supported, check host ffprobe truth. Do not regenerate/change media, reencode or change decoder settings. Source/type/URI must match the original Phase 8B System path.

After successful preflight execute **one healthy forced-System H.264/AAC MP4 control**, proving true visible native XComponent pixel samples, PLAYING/position progress and one leave cleanup, and then independently execute **exactly six** targeted historical cases via unchanged forced System:

| Case | Historical Phase 8B observation | New investigation objective |
| --- | --- | --- |
| `hls-h264-aac` | `LNK-PLAY-006` during initialize | correlate URL, HLS manifest/segments, native state/prepare/error and server request trace |
| `hls-hevc-aac` | `LNK-PLAY-006` during initialize | same independently; don't infer H.264 result |
| `mkv-ffv1-flac` | PLAYING and progressing, no proven visible frame | distinguish frame-submission signal, video size, ROI/pixels, black/unchanged vs visible content |
| `mov-prores-pcm` | PLAYING and progressing, no proven visible frame | independent same |
| `ogv-theora-vorbis` | PLAYING and progressing, no proven visible frame | independent same |
| `wmv-wmv2-wma` | PLAYING and progressing, no proven visible frame | independent same |

Record actual official attempts separately. Per HLS fixture capture sanitized URI/source type, host GET/Range/manifest/segment response trace if requested, elapsed prepare/state/error/native log details and whether error originates before AVPlayer. Do not attribute a 404/route failure to decoder unsupported. HLS/DASH remain System-only; no backend policy changes.

Per frame fixture capture unchanged source's native `startRenderFrame` indication if observable, PLAYING/status and monotonic position, videoSizeChange, actual XComponent surface bounds, pixel ROI and real expected color samples/verified digest if feasible, and resource cleanup. A callback or progress without actual pixels remains **NOT PROVEN**. If capture inaccessible, record exact instrument limit rather than call it black video. Avoid injecting temporary code or tweaking layout to improve screenshots.

A valid completed failed run remains a new, separate FAIL/UNRESOLVED record. Do not automatically retry or overwrite a completed failed case. A procedural invalid-input event before the official case may be documented separately and corrected without relabeling the original failed execution. If valid input is lost, STOP and report NOT RUN/BLOCKED. If a genuine production/test-code defect is identified, STOP and report details to GPT; Codex must not patch.

## 7. Diagnosis and immutable history

Classify each historical cause narrowly as supported: reproducible adapter/UI defect, native simulator System limitation, source/manifest/route issue, observation gap or unresolved. Keep history untouched:

- Phase 8B: two HLS initialization **FAIL**, four first-frame-evidence **FAIL**.
- Phase 8D first attempt: `BLOCKED — SIMULATOR ENVIRONMENT`, seven runtime checks **NOT RUN**, `fport` wrong direction, original evidence preserved.
- Phase 8C: accepted *static* native-first audit; no new full-matrix research.
- MPV simulator is stub, no real MPV device result; no Mate60 capability, encoded passthrough, HDR/DV, or ARM64 FFmpeg runtime inference.
- Do not use x86 results for System/MPV performance ranking, Auto changes or global codec policy.

Fresh new results live only in the new task's own report/new directory. Distinguish evidence of native frame submission from visible output; keep telemetry precise. Diagnostic analysis should not silently turn a historical FAIL into a PASS or reuse old screenshot/hilog/build PASS.

## 8. Stop conditions, cleanup, security

STOP on branch/source mismatch or protected drift, build gate failure, semantic EOL difference, incorrect port listener owner, failed `rport`, target-route proof failure, unexpected authentication/fixture hashes, inability to keep source and expected path intact, test instrumentation requiring code modifications, observed user-secret exposure, or a reproducible production defect requiring GPT fix. Report all actions already done before STOP honestly, without calling omitted stages PASS.

After normal completion or stop, remove **only the reverse mapping created in this run** using installed HDC removal syntax, verify forward and reverse lists, and stop only the host server created by this run. Do not modify unrelated host listeners/forwards, user services, dirty worktree, stored passwords or data. Restore original backend selection/app preferences if changed; retain user-owned controlled WebDAV media and other fixtures. Sample post-leave surface/player/audio counts, without claiming exhaustive leak freedom.

Do not publish credentials, private URLs/hostnames, IDs/port-owner PIDs, absolute SDK/checkout paths, local host shell transcripts with secrets, signing/profile files, private images/video/screenshots/HAP, generated/owned media or unsanitized logs. Retain accurate SHA/byte provenance and explicitly label sanitized readable and compressed logs; no false original-byte identity claim. No test result/metric rewriting.

## 9. Authorized report/evidence output

Codex may add/update **only**:

```text
docs/PLAYBACK_PHASE8D_SIMULATOR_RERUN1_REPORT.md
test-lab/playback/phase8d-system-simulator-rport-rerun1-20261008/
```

Suggested new evidence: `source-state.json`, `required-reading.json`, `initial-eol-proof.json`, `post-simulator-eol-proof.json`, `build-results.json`, separately preserved sanitized original-gate logs/Hypium, `artifact-install-proof.json`, `fixture-proof.json`, `hdc-command-help.json`, `host-listener-preflight.json`, `reverse-mapping-proof.json`, `target-route-proof.json`, `healthy-control.json`, `six-case-observations.json`, `root-cause-assessment.json`, `cleanup.json`, `protected-audit.json`, `security-review.json`.

Never alter `docs/CODEX_VALIDATION_TASK.md` after dispatch; don't touch Phase 8B/C/D old report/evidence. Raw private files remain outside Git.

## 10. Publish/fresh remote verification

1. Ensure changed tracked paths are only new authorized report/new directory, no old tracked source/report/test/config/lock drift.
2. Fresh fetch remote; if unrelated protected remote drift appears, STOP rather than merging or replacing it.
3. Commit only allowed outputs and normal push (no force/merge).
4. Fresh fetch again; verify remote HEAD contains new evidence commit SHA, all pushed report/evidence blobs remotely accessible and exact allowed-diff containment; output full 40-character evidence SHA.
5. If push failed, report `BLOCKED — EVIDENCE NOT PUSHED` and local commit SHA; don't claim completed handoff.

Exactly one final primary classification:

- `PASS — FOCUSED SYSTEM SIMULATOR INVESTIGATION COLLECTED` only if all six were freshly attempted with bounded evidence and the healthy control plus valid target route were established (some cases may remain FAIL/UNRESOLVED, explicitly);
- `FAIL — PLAYBACK FUNCTIONAL DEFECT IDENTIFIED`;
- `FAIL — ARM64 BUILD GATE`;
- `FAIL — SIMULATOR BUILD`;
- `FAIL — INVESTIGATION EVIDENCE INCOMPLETE`;
- `BLOCKED — VALIDATION ENVIRONMENT`;
- `BLOCKED — SIMULATOR ENVIRONMENT`;
- `BLOCKED — EVIDENCE NOT PUSHED`;
- another precise observed infrastructure classification if required.

Do not query Codex usage/remaining quota. No quota check is a test or dispatch precondition. If interrupted, retain exact completed/NOT RUN state without fabricating work; the repository and final evidence, not conversation cadence, are the source of truth.
