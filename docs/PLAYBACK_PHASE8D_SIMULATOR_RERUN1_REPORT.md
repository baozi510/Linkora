# Phase 8D-SIM Rerun 1 — Focused System Investigation

> Classification: PASS — FOCUSED SYSTEM SIMULATOR INVESTIGATION COLLECTED
> Task: phase8d-sim-rerun1-hdc-rport-six-case
> Branch: feat/playback-capability-phase8
> Date: 2026-10-08 (Asia/Shanghai)

Validation source: `c0d37ef9aaeba31c512743fe704e8d91ba1c0c48`.
Actual tested dispatch: `a8ad55081c54630e3602b71f9fe9415cc092e1ab`.
Unchanged production playback baseline: `99ab47020f81391b7640d44c58ccb719491b4106`.
Prior stopped evidence: `391d56e4c0b36f19d4a52f8d77a4adab2db87b8b`.
New evidence: `test-lab/playback/phase8d-system-simulator-rport-rerun1-20261008/`.

This classification accepts **collection**, not six-format playback success. The healthy control passed; all six historical targets were freshly attempted exactly once and remain new bounded FAIL/UNRESOLVED observations. Historical Phase 8B FAIL and Phase 8D first-round NOT RUN/BLOCKED are untouched. Final source-vs-native attribution and any production fix belong to GPT.

## Source, fresh builds and exact deployment

A distinct clean isolated checkout matched repository/branch/READY/task/HEAD, prior-evidence/source ancestry and task-only source-to-dispatch drift. Pinned submodules matched exact committed revisions. An extra recursive origin fetch encountered a framework TLS handshake error; the mainline ref was freshly fetched successfully. Trusted local Git source repositories at verified pins were explicitly cloned and absorbed as normal submodules, then origin URLs synchronized to committed upstream URLs. No TLS/file-transport security policy was weakened, no source pin changed and no application artifact or old PASS inherited.

Current task/review sections and previous stopped report/diagnoses were read. Previously fully read unchanged documentation/source was revalidated against exact current bytes; required-reading provenance distinguishes this from new reads. All eight pinned FFmpeg dependency archives were freshly hash/manifest/member-ABI checked as dependency inputs only.

One normal initial ohpm install passed. Four allowlisted locks received fresh Git-normalized blob/exact CRLF-to-LF byte/semantic-content/all-other-tracked-byte proof before isolated restore. The simulator finally install received its separate proof/restore. No repair reinstall occurred.

| Fresh stage | Actual result |
| --- | --- |
| First default verify.ps1 | PASS; Hypium 210 PASS / 0 Failure / 0 Error / 0 Ignore |
| Simulator verifier | PASS; parity/isolation, audio metadata static guard, sole x86 liblinkora_ffmpeg.so native whitelist |
| Immediate final default verifier | PASS; separate Hypium 210 PASS / 0 Failure / 0 Error / 0 Ignore |
| Each default invocation | Architecture fixtures 5; FFmpeg pure 15/15; analysis pure 46/46; artifact fixtures 17; MPV mapping 7; Debug/Release HAR/HAP; two exact-nine AArch64 audits |
| Dependency restoration | Normal simulator finally restore and final production/default native dependency/build gates passed |

Both actual Hypium originals were separately preserved before overwrite. Sanitized readable/gzip gate copies include original local hashes and exact decompression/hash checks, without removing warnings or results.

Target: x86_64, API26, system parameter firmware OpenHarmony-7.0.0.105, HDC3.2.0f, bundle com.linkora.player debug0.1.0. HTTP native user-agent separately reports emulator7.0.0.107; these distinct identities are recorded, not silently reconciled or used to infer an image upgrade. No physical ARM64 runtime occurred.

Fresh unsigned HAP SHA-256: `9E0CF4165B4FF41DF65A4E080F5CA2F3E7DB42705B6AB19D34DE23581C1073DF`, 25,087,238 bytes. Normal replace-install rejected its signature with9568332 despite transport exit0. Existing legal profile membership was freshly checked. The unchanged SDK signing procedure signed that exact artifact; source/profile/permission/signature settings were not modified.

Explicitly installed signed HAP SHA-256: `2142E30932BE7F67E5E534796E83FA5E02454CAD6D6C2357E1CA6249F8899BE0`, 25,281,137 bytes. Exact signed whitelist/ABI audit, replace-install and ordinary cold launch passed; app data was retained.

## Correct reverse mapping, inputs and control

Fresh owned input proof covers seven planned fixtures and thirteen retained files, including both HLS manifests and all six segments. Local hash/size, authenticated TLS WebDAV whole-GET/Range206 and host ffprobe matched committed Phase 8B truth. Nothing was regenerated, reencoded or substituted.

Installed HDC help and [official OpenHarmony HDC documentation](https://github.com/openharmony/docs/blob/master/zh-cn/application-dev/dfx/hdc.md) were checked. Host19084 was initially unoccupied; mapping list had no conflict. The designated retained-fixture server was started on host loopback19084, and its exact owned listener/process was verified. Thirteen whole-GET responses matched truth, **host-only input checks, not target-route proof**.

Exactly one `rport tcp:19084 tcp:19084` was created while the server remained running. Its explicit OK and actual `[Reverse]` list entry were captured. No fport creation, alternate port, direct-WebDAV playback, URI rewrite, code hook or decoder/configuration change was used.

The installed target shell had no curl/wget. The task-authorized first unchanged app healthy System MP4 served as **both its one official control execution and the genuine target-route proof**. Its validated literal StreamPage URI correlated with two native AVPlayer GET/Range206 requests (0-8191, then8192-end), prepared/playing native events, size320x180, first-frame submission callback, actual expected multicolor XComponent pixels and position144→977ms. Leave sampling was zero. This was not an extra anonymous PASS or a host-only request. Native SDK user-agent activity and actual frame support target consumption; an independent app wire-byte digest is not exposed.

Read-only native screenshot/layout collection was preflighted before any media opening. Original Auto was observed and forced System verified. The same source kind, literal loopback19084 route, controlled server and retained relative paths were used for all seven executions.

## Actual seven executions

One explicit attempt per fixture is recorded in the independent ledger; seven complete result rows, six exact target IDs, no retry or replacement result. Source/HTTP traces, native after-minus-before event logs, UI timeline, captured surface/ROI/RGB/image digests and sampled cleanup are retained separately.

| Fixture | Fresh observation | Position samples, ms | Native video-size callback | Native first-frame callback | Scoped disposition |
| --- | --- | --- | --- | --- | --- |
| Healthy MP4/H.264/AAC | Prepared, PLAYING, expected colored video, correlated GET | 144→977 | 320x180 | Observed | PASS control/route |
| hls-h264-aac | Manifest +3 segments GET200; play rejected in initialized; LNK-PLAY-006 | 0,0,0 | Not observed | Not observed | Bounded FAIL; readiness mismatch, attribution unresolved |
| hls-hevc-aac | Independently same response/state pattern; LNK-PLAY-006 | 0,0,0 | Not observed | Not observed | Bounded FAIL; readiness mismatch, attribution unresolved |
| mkv-ffv1-flac | Native prepared/PLAYING; sampled ROI black, no expected pattern | 269→970 | 0x0 | Not observed | Bounded FAIL; no proven video output |
| mov-prores-pcm | Native prepared/PLAYING; sampled ROI black, no expected pattern | 315→991 | 0x0 | Not observed | Bounded FAIL; no proven video output |
| ogv-theora-vorbis | Native prepared/PLAYING; sampled ROI black, no expected pattern | 253→1003 | 0x0 | Not observed | Bounded FAIL; no proven video output |
| wmv-wmv2-wma | Native prepared/PLAYING; sampled ROI black, no expected pattern | 414→1138 | 0x0 | Not observed | Bounded FAIL; no proven video output |

All seven leaves sampled zero surface nodes, app player service entries and app audio renderers. These are scoped samples, not comprehensive leak or physical audio-output proof.

Raw host harness used a >=800ms progress predicate. The four legacy positive deltas701/676/750/724ms are below that predicate, so their original raw `positionAdvanced=false` is preserved. Independently derived monotonic-positive advance is true from the actual samples, with its distinct meaning and explicit threshold recorded. No raw metric/result was rewritten, and neither predicate turns the black-frame results into PASS.

Native first-frame evidence means an actual `OnStartRenderFrameCb is called` event, not callback registration. Size evidence is actual `OnVideoSizeChangedCb` numeric data, not expected fixture metadata. UI omission alone was not substituted for a0x0 callback. The [AVPlayer API documentation](https://raw.githubusercontent.com/openharmony/docs/master/en/application-dev/reference/apis-media-kit/arkts-apis-media-AVPlayer.md) separates frame submission from visible output; actual pixels are independently sampled.

## Narrow cause assessment and owner decisions

**HLS:** both exact manifests and all segments were requested successfully; no recorded404/auth/route failure explains the rejection. Native logs independently show initialized, surface assignment, prepare invocation, a roughly2s native prepare-wait sequence, then JsPlay while still initialized and a native invalid-state rejection. There is no prepared notification before that play attempt. Numeric native rejection code is not separately exposed in these captured lines; UI codeLNK-PLAY-006 and exact native message are retained without fabricating a measured code.

Read-only source tracing confirms SystemPlaybackPort awaits initialization and the native prepare promise; AdaptivePlaybackPort then commits/emits PREPARED, and PlaybackEngine invokes play. Native state and that promise/contract assumption diverge in the exercised HLS cases. Official docs restrict play to prepared/paused/completed and describe state-change observation; they also contain ordinary await-prepare/await-play examples. Therefore this run does **not** claim the cause is proven portable production code rather than native simulator completion behavior. GPT should review the actual native readiness/prepare completion boundary and whether a state-confirmed, bounded readiness contract is needed. No source fix or policy change was made; these observations are not decoder UNSUPPORTED verdicts.

**Four video-output cases:** correctly routed identical inputs contain320x180 video according to independent ffprobe. Unchanged AVPlayer reaches prepared/playing and reports0x0, without a captured first-frame callback. Concurrent native surface captures show black content throughout the sampled playing window after the initial opening overlay; the healthy control proves capture/viewport alignment and expected-frame detection. This narrows the prior observation gap to actual **simulator-native video output not established** in these samples, rather than unavailable screenshots or a demonstrated layout defect. Native decoder-selection/unsupported-track internals and permanent/all-device black behavior are not proven. Audio decoding/audibility is not inferred merely from timeline progress.

No platform-independent production defect requiring a source patch was conclusively isolated. Owner attribution remains scoped/unresolved where native internals are missing. Historical two HLS +four first-frame FAIL remain unchanged; new evidence is independent. This is investigation collection PASS, **not** System compatibility acceptance, a codec ranking or device acceptance.

## Cleanup, integrity and publication

Original Auto was restored and verified, the one owned temporary HTTP row removed, and original local page restored. All owned WebDAV media/profile and unrelated data remain. Only this run's exact reverse task was removed using installed `fport rm` removal syntax; explicit removal success and empty final forward/reverse list were verified. Only the owned host fixture-server process was stopped; host19084 listener is absent. Final app surface/player/audio samples were zero. No quota query occurred.

Original dirty D:/Linkora and all2686 pre-existing tracked files/old evidence are protected. Only this new report and authorized new directory may be published. Credentials/private endpoints/identifiers/port-owner PIDs/signing/SDK or checkout absolute paths, HAP/media and private screenshots remain outside Git. Native/build readable and compressed logs are explicitly sanitized with original local hashes; raw screenshots/hilog remain private. Publication requires normal push, fresh fetch and verification of the final evidence SHA, all authorized remote blobs, unchanged protected blobs and gzip integrity; no force/merge.

Real MPV, ARM64 FFmpeg runtime, Mate60 codec behavior, HDR/DV, advanced audio/output, hardware decode and performance remain DEVICE REQUIRED/NOT PROVEN. No Auto tuning, display-mode/UI implementation, Direct I/O, thumbnail research or broader59-case rerun occurred.
