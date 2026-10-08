# Phase 8D-SIM System Investigation Report

> Classification: BLOCKED — SIMULATOR ENVIRONMENT
> Task: phase8d-sim-system-hls-first-frame-root-cause
> Branch: feat/playback-capability-phase8
> Date: 2026-10-08 (Asia/Shanghai)

Validation source: `e19123a0e110cebb479d24dbdf72d6d3c9169a5b`.
Actual tested dispatch: `0a5e1af4be94a2528dcbc968f42f1883d9c22c3b`.
Unchanged production playback baseline: `99ab47020f81391b7640d44c58ccb719491b4106`.
Accepted Phase 8C evidence: `9cd0db4b4719409de942892790de71f0ae015823`.
New evidence: `test-lab/playback/phase8d-system-simulator-investigation-20261008/`.

## Outcome and exact stop

The fresh build chain and exact signed simulator deployment passed. Runtime investigation stopped during controlled HTTP forwarding preflight, **before the healthy control or any of the six fixtures was opened**.

The retained corpus's historical literal StreamPage input uses target loopback port 19084, forwarded to the owned host fixture server. This round's normal HDC forward creation returned:

```text
[Fail]TCP Port listen failed at 19084
```

The target's forward list was `[Empty]` before the operation and remained `[Empty]` afterward. HDC's native message establishes the failed listen operation; it does not identify the conflicting owner or prove its precise cause. No unrelated port/process/service was stopped, no alternate URL/port/route was used to force success, and the failed preflight was not retried. The owned host fixture server was stopped. This is a simulator/transport environment blocker, **not** an established player, decoder, format, media or ARM64 build defect.

## Read-only setup diagnosis after stop

Installed HDC3.2.0f help states `fport localnode remotenode` forwards local traffic to the device, while `rport remotenode localnode` reverses device traffic to the host. The host fixture server was already listening on port19084 before the recorded `fport` attempt. **The orchestration chose the wrong forwarding direction for device-to-host fixture access**, explaining the host listen collision. This is a local validation setup error, not a newly identified production defect. `preflight-command-diagnosis.json` preserves the exact installed-help lines and hash. No corrective reverse mapping or media execution was attempted after STOP; the original stopped observations remain immutable.

## Fresh source, dependencies and builds

A new isolated clone matched repository/branch/READY/task/source/dispatch. Accepted evidence is an ancestor of validation source, source is an ancestor of dispatch, and source-to-dispatch drift is exactly `docs/CODEX_VALIDATION_TASK.md`. All three committed submodules were initialized and matched their pins. The source/reading/protected audit records cover the current task and required documentation, affected playback source, retained corpus truth and historical failure attribution.

Only pinned FFmpeg dependency inputs were reused. All eight static archives were freshly hashed, their manifest constraints checked and every ELF member audited for its ABI. No old application artifact or old test PASS was reused.

Exactly one normal initial `ohpm install` passed. Its four allowlisted EOL-only lock changes were freshly proven Git-normalized blob/exact CRLF-to-LF byte/line-content equivalent with no other tracked-byte changes, then restored in this isolated checkout. The simulator verifier's normal finally install received a separate fresh proof and restore. No dependency/version/checksum/graph/comment semantics changed; no repair reinstall was performed.

| Fresh gate | Actual result |
| --- | --- |
| Initial default verify.ps1 | PASS; Hypium 210/0 Failure/0 Error/0 Ignore |
| verify-simulator.ps1 | PASS; parity, audio metadata static guard, only real x86_64 liblinkora_ffmpeg.so |
| Immediate final default verify.ps1 | PASS; independent Hypium 210/0 Failure/0 Error/0 Ignore |
| Each default run | Architecture fixtures 5; FFmpeg pure 15/15; analysis pure 46/46; artifact fixtures 17; MPV mapping 7; Debug/Release HAR/HAP builds; two exact-nine AArch64 audits |
| Default dependency restoration | Normal simulator finally install plus final default real-MPV/native artifact and build gates passed |

Both default Hypium raw outputs were preserved separately before overwrite. Published build logs are explicitly sanitized copies, with original local hashes and exact gzip-decompression proof; no warning/result was removed.

## Exact simulator artifact and deployment

Target: x86_64 / API26 / OpenHarmony 7.0.0.105 / HDC3.2.0f; bundle `com.linkora.player` debug0.1.0. No physical ARM64 runtime was attempted.

Fresh unsigned HAP SHA-256: `E5D29D40AE724F3D914391A57C40D03DE611E157388074C475337C0E0A868642` (25,087,238 bytes).

Normal replace-install of the unsigned exact artifact was rejected solely by signature enforcement code9568332 despite transport exit0. The existing legal profile was checked to include this simulator. The previously authorized unchanged SDK signing procedure signed that exact input without modifying source/profile/dependency/ABI or disabling signature/permission checks.

Installed signed HAP SHA-256: `0004679B25960C6F1A1C0787A58D189F705A166332C9EFCF4B00F70554C95340` (25,281,137 bytes).

The signed artifact passed the repository exact x86 native whitelist/ABI auditor, then explicit replace-install and ordinary cold launch passed. App data was retained. No diagnostic or target fixture playback had been dispatched at the stop.

## Fresh controlled inputs and execution coverage

The six target fixtures and healthy H.264/AAC MP4 were independently verified against committed Phase 8B truth. Thirteen retained files, including both HLS manifests and all six segments, matched local SHA-256/size and authenticated TLS WebDAV whole-GET bytes and Range206 prefixes. Fresh host ffprobe confirmed the expected codecs and 320x180 video. Media was not regenerated, re-encoded or modified. This proves input preflight only; it does not prove the blocked target HTTP route or any playback result.

| Case | Official new executions | Result / historical diagnosis |
| --- | ---: | --- |
| Healthy forced-System H.264/AAC control | 0 | NOT RUN |
| hls-h264-aac | 0 | NOT RUN; historical initialization cause UNRESOLVED |
| hls-hevc-aac | 0 | NOT RUN; historical initialization cause UNRESOLVED |
| mkv-ffv1-flac | 0 | NOT RUN; visible-frame evidence NOT PROVEN |
| mov-prores-pcm | 0 | NOT RUN; visible-frame evidence NOT PROVEN |
| ogv-theora-vorbis | 0 | NOT RUN; visible-frame evidence NOT PROVEN |
| wmv-wmv2-wma | 0 | NOT RUN; visible-frame evidence NOT PROVEN |

No native first-frame signal, per-case PLAYING/progress/video-size timeline, capture ROI or video pixel verdict is invented. The screenshot taken after STOP is a cleanup observation, not fixture/frame evidence. The two historical HLS FAIL and four first-frame-evidence FAIL remain unchanged. Source-only potential semantic issues are not promoted to a newly reproduced defect.

## Cleanup, security and owner action

The owned host server is stopped, the failed forward left no new mapping, and backend/app preferences were not changed. Owned corpus/WebDAV profile and unrelated data/services are preserved. Post-stop sampling showed zero XComponent nodes, zero app player service entries and zero app audio renderers; this is sampled cleanup, not comprehensive leak freedom. Private layout/screenshot/device logs, device identifiers, endpoint/credential/signing data and HAP/media are excluded from publication.

Ignored host helpers encountered argument/encoding/quoting errors before any fixture dispatch; these are local procedural observations, not media executions or source changes. They did not repeat a completed case or replace a FAIL verdict. No production source, test/script expectation, task, profile, manifest, CMake, semantic lockfile or historical evidence was changed. Original dirty `D:/Linkora` is preserved.

GPT should review the actual failed preflight and decide an explicitly scoped environment/route recovery and distinct future task. A future fresh task must not inherit these build PASS results or retroactively reclassify Phase 8B. Real MPV, ARM64 runtime, hardware/output, HDR/DV/advanced audio/performance remain DEVICE REQUIRED/NOT PROVEN; Direct I/O/UI/thumbnail research were not started.

Publication is report/new-evidence only, normal push without force/merge, followed by fresh remote containment/blob verification. Until that verification succeeds, this report is not an external handoff.
