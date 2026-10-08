# Phase 8E — System prepared-state guard validation

> Primary: **FAIL — SYSTEM PREPARED-STATE GUARD REGRESSION**
> Task: `phase8e-sim-system-prepared-state-gate`
> Branch: `feat/playback-capability-phase8`
> Date: 2026-10-08 (Asia/Shanghai)

Source: `68452df5486cf568da66a5c52352841cb7e64c5f`.
Tested dispatch: `ff5917e912c310d52fda747b2a8089109a170954`.
Accepted prior collection: `9c4f6ded7cc86afad1052eb448ce3172b3232db6`.
New evidence: `test-lab/playback/phase8e-system-prepared-readiness-sim-20261008/`.

Fresh builds and the healthy control passed. Captured HLS native play ordering improved, but **leaving while preparation was pending did not release the observed app resources**. The cancellation guard was held, sampled cleanup failed, and retained player service/audio records remained beyond the configured20s bound. Strict STOP was honored; the planned subsequent healthy recovery open was NOT RUN. Final resources were zero only after force-stopping the owned test application and an ordinary cold launch. This forced cleanup does not make cancellation PASS.

No production source, test expectation, policy, media, profile, task or historical evidence was changed. Previous failures remain immutable. Direct JavaScript Promise fulfillment, app synthetic PREPARED and reject/timer-clear callback telemetry remain NOT PROVEN where the unchanged app exposes no event.

## Source and fresh gate evidence

Fresh remote fetch, exact repository/branch/READY/task/source/dispatch, ancestry through prior evidence, and source-to-dispatch Task-only drift passed. A distinct clean isolated checkout was created with three exact committed submodule pins. Trusted local Git source repositories were explicitly cloned and absorbed, origins synchronized, and mainline fetched normally; no TLS/file-protocol policy was weakened and no old app artifact or PASS was reused. Required-reading metadata records fresh current sections/new source/diff and byte revalidation of previously fully read unchanged history. The installed API26 declarations and current official primary documentation were checked.

Eight pinned FFmpeg archives were freshly checked for manifest/hash/member ABI as dependency inputs. One initial normal ohpm install passed. Both initial and simulator-finally installs had independent proof of allowlist, normalized Git blob, exact CRLF-to-LF bytes, unchanged semantics and all-other-tracked-byte protection for the four authorized locks; only proven locks were restored. A preflight proof command initially ran before the asynchronous baseline file finished writing and failed with FileNotFoundError. The clean pre-install snapshot process completed normally; the non-test proof was then executed successfully. This invalid orchestration invocation is separately recorded; no second install, test retry or media retry occurred.

| Fresh invocation | Actual result |
| --- | --- |
| First default verifier | PASS; independently saved Hypium210/210, zero failure/error/ignore |
| Simulator verifier | PASS; parity/isolation/audio-only metadata static guard, sole x86 FFmpeg whitelist/ABI |
| Immediate final default verifier | PASS; separately saved Hypium210/210, zero failure/error/ignore |
| Each default verifier | Architecture fixtures5, FFmpeg pure15, analysis pure46, artifact fixtures17, MPV mapping7, Debug/Release HAR/HAP, two exact-nine AArch64 audits |
| Default graph restoration | Simulator finally install/restoration and final production native builds passed |

Build warnings are preserved in sanitized readable/gzip outputs with original private hashes and exact decompression/hash proof. Build PASS is separate from the failed runtime cancellation requirement.

Fresh unsigned simulator HAP SHA256: `803C4EEB225BD63F2047D8B62A16ECF0C4C30DBBDABDCAA4FC1916A6E388F17E`, 25,094,175 bytes. Normal replace-install rejected its signature with9568332 despite transport exit0. Existing legal profile membership was freshly verified. The unchanged installed SDK signing method signed this exact artifact.

Explicitly installed signed HAP SHA256: `44BCF250B2EB605B4DEC3357B394E9F8199B281B307813AE1479ABB421498117`, 25,289,424 bytes. Exact signed x86 whitelist/ABI audit and explicit install/normal cold launch passed. App data, profile and permissions were retained.

## Controlled route and five distinct opens

Four selected fixtures and ten retained files were freshly verified against committed truth by local hash/ffprobe, authenticated TLS WebDAV whole GET/Range206, and owned host served bytes. Both HLS manifests and all six segments were included. No regeneration, reencoding or manifest change occurred.

Host loopback19084 was unoccupied and mapping list had no conflict. The owned fixture server's listener/process was verified; exactly one `rport tcp:19084 tcp:19084` was created and actual `[Reverse]` captured. Installed HDC3.2.0f help and [official HDC documentation](https://github.com/openharmony/docs/blob/master/zh-cn/application-dev/dfx/hdc.md) support this creation direction and exact `fport rm` removal. The target had no shell curl/wget. The one official healthy app open proved real target requests with native AVPlayer GET/Range206 and independent visible frame/progress, rather than relying on host-only GET.

Target remains x86_64/API26, system firmware parameter OpenHarmony-7.0.0.105; native HTTP user-agent separately reports emulator7.0.0.107. Neither identity proves an upgrade or device equivalence. Read-only screenshot/layout capture was preflighted. Original Auto was observed and forced System selected, with the same literal loopback19084 input route throughout.

| Scenario, one open each | Fresh observations | Scoped outcome |
| --- | --- | --- |
| Healthy MP4/H.264/AAC control | Native prepared before play, playing, size320x180, actual first-frame submission callback and separate colored pixels; position185→985ms; clean leave | Healthy/route PASS |
| HLS H.264/AAC official attempt | Manifest+three segments GET200; captured prepared precedes JsPlay, size320x180 and first-frame callback/playing observed; positive335ms delta; raw>=800ms Boolean remains false | Native ordering observed; actual visible output NOT PROVEN in early capture windows; raw bounded result unchanged |
| HLS HEVC/AAC official attempt | Manifest+three segments GET200; native5400106 with `VID_DEC_ERR` and video/hevc decoder-type text; UI LNK-PLAY-003; no captured prepared/play, explicit release | Bounded native failure, no observed premature play; scoped error is not platform-wide codec certification |
| FFV1/FLAC legacy representative | Native prepared precedes play/playing; actual size0x0, no captured frame submission, sampled black ROI; positive768ms delta below raw800 predicate | Bounded video-output FAIL/UNRESOLVED; no playable-video claim |
| Separately labeled HLS cancellation | Initialized and prepare invocation observed at leave, no prior prepared; leave requested2.344s after scenario start; subsequent sampled player records nonzero | **FAIL: pending preparation release/cleanup** |

There were four official control/format opens plus one separately labeled cancellation open, total5. No fixture was retried or old PASS inherited. The cancellation HLS input is not a second format verdict. The planned cancellation-follow-up healthy open is NOT RUN after STOP.

Native prepared notifications, play calls and actual frame callbacks are distinguished from callback registration, UI controls and pixel samples. HLS H.264's captured native callback occurred after early screenshot sampling; those samples do not establish late visible video. Neither335ms nor768ms advances were rewritten to satisfy the old>=800ms raw helper predicate. Both raw results and separately derived positive deltas remain readable.

[AVPlayer primary documentation](https://raw.githubusercontent.com/openharmony/docs/master/en/application-dev/reference/apis-media-kit/arkts-apis-media-AVPlayer.md) and installed declarations distinguish native state notification, prepare Promise and permitted play states. Native Wait Prepare Task End is not relabeled as direct JavaScript `.then` fulfillment. There is no direct unchanged-app CandidateObserver.commit/Adaptive synthetic-PREPARED event log. Discrete UI snapshots cannot prove complete event absence/order; these app-contract telemetry requirements are NOT PROVEN, without adding hooks.

## Cancellation failure and owner review boundary

The separate at-leave capture confirms initialized and JsPrepare with no native prepared notification. Leave was requested at14:56:36.777UTC,2.344s after the scenario start. At approximately3.406s after that request, the sampled surface count was0 and app audio count0, but **PlayerDistributedService app-matching entries were2**. This metric counts service entries, not proven native player instances.

At14:57:47.375UTC and14:58:03.386UTC, well beyond20s after leave, player service entries were still2 and an app audio renderer record existed in state1. This is retained resource evidence; it is not proof of audible output. Later native transition/callback identity is NOT PROVEN from available post-stop logs. No late prepared event or exact object identity is fabricated.

Static source exposes a relevant ownership boundary: `AdaptivePlaybackPort.prepare()` assigns `this.backend` only after `await this.prepareBackend(...)`. During that wait the candidate lives in a local variable in prepareBackend; release reads only `this.backend`, which is still null. The candidate may then commit/return without checking the adapter's released flag. The new SystemPlaybackPort reject-on-release guard requires its release method actually to be reached. GPT should independently review pending candidate ownership, release propagation and stale commit prevention across Adaptive/System/PlaybackEngine. This source observation and retained resource samples warrant owner review; they do not establish exact leaked object identities or all-platform behavior. Codex made no patch.

## STOP, cleanup and integrity

No further playback or compatibility rerun occurred after the failed cancellation sample. Only the owned HTTP row was deleted, original Auto verified/restored, original local page restored, owned reverse removed using its exact supported removal syntax and owned server stopped; mapping list was empty and host19084 listener absent. WebDAV profile/media and unrelated data were retained.

Resource samples still failed after that normal cleanup. Only the owned com.linkora.player debug test process was force-stopped; app data was neither wiped nor uninstalled. An ordinary cold launch opened no fixture. Final surface/player service/audio counts were0. This is **forced cleanup**, explicitly separate from the failed normal cancellation release; next-session recovery safety remains NOT RUN/NOT PROVEN.

Publication is limited to this new report and authorized new evidence directory. All2773 pre-existing regular tracked blobs/work bytes and original user workspace are audited. Private full hilog/screenshots/HAP/media/signing/credentials/identifiers remain local. Native excerpts are explicitly selected after-minus-before subsets; cancellation at-leave uses a separate capture window, not merged invented events. Every compressed public log has exact SHA256/decompression proof. Normal push/fresh fetch/full remote inventory verification is required before reporting delivery.

Real MPV, physical ARM64/Mate60, audio audibility, HDR/DV/hardware output and exhaustive leak freedom were not checked or accepted. No quota query, Auto tuning, Direct I/O change, broader codec matrix or production implementation was performed.
