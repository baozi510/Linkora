# Playback Phase 8 Report

> Status: FAIL — MPV PLAYBACK FOUNDATION. Fresh rerun passes P01–P05 and lifecycle, but fullscreen clips the video; independent review pending.
> Branch: `feat/playback-capability-phase8`
> Validation date: 2026-10-07 (Asia/Shanghai)

## Fresh rerun 1 — state/EOF/portrait correction passes; fullscreen overflow fails

Task: `phase8a-rerun-1-mpv-state-eof-surface`.

- Corrected source: `5146ff923900fd73ff25769783fb2d9732cfad5c`.
- Actual tested dispatch HEAD: `53d37b5caf1b80e88ccce92d7756009878fe7106`.
- Prior failed evidence: `08852ccc0ae1806b8270f2a248113eeedd61b5f9`, verified ancestor of corrected source.
- Corrected source is an ancestor of tested HEAD; the only source-to-HEAD change is `docs/CODEX_VALIDATION_TASK.md`.
- New isolated clone and pinned submodules; original workspace preserved. All prior failed evidence remains byte-identical.
- New evidence: [phase8a-rerun-1-mpv-state-surface-20261007](../test-lab/playback/phase8a-rerun-1-mpv-state-surface-20261007/).

### Fresh build and exact artifact

Exactly one normal install and one full default verifier passed. Strict normalization proved all four affected lockfiles identical to HEAD after CRLF-to-LF conversion; only those files were restored in the isolated clone.

Fresh counts: architecture fixtures **5/5**, FFmpeg pure **15/15**, analysis pure **46/46**, artifact fixtures **17/17**, MPV mapping **7/7**, Hypium **210 PASS / 0 Failure / 0 Error / 0 Ignore**. Debug/Release HAR/HAP, two exact-nine AArch64 audits and final verifier marker passed. The two new MPV event-order regressions passed. No earlier PASS was reused.

One fresh signed default/debug arm64 HAP was built, audited and explicitly installed, without uninstalling or clearing data. The root signing-only overlay was restored and clean checkout proven before installation.

- HAP SHA-256: `AA79CD5F08E4136361C47543E13C027CEF82179F78A44D3895A48D38430567DA`.
- HAP size: **64,545,852 bytes**.
- Signing-only overlay SHA-256: `5143AE29AFDA4A20ECECCDD7495E1B1759FD40A77A0312BBCFD63F97E04E9F6C`.
- Target: real Mate60, aarch64/API 26, `com.linkora.player` / `0.1.0`, debug; launch successful.

The same existing private signing material was checked afresh; only signing fields changed temporarily. Fresh controlled MP4/MKV/corrupt hashes and TLS-verified Range/206 checks passed.

### Fresh runtime outcomes

| Item | Result | Observed behavior |
| --- | --- | --- |
| P01 forced System / H.264 MP4 | PASS | Real frame; PLAYING; pause/resume; ~50%/~90% seek; COMPLETED; clean leave. |
| P02 forced MPV / H.264 MP4 | PASS | PLAYING and real pause action; PAUSED/resume; both seeks; correct portrait surface; stable COMPLETED; clean leave. |
| P03 forced MPV / HEVC MKV | PASS | Real frame; PLAYING; pause/resume; both seeks; COMPLETED; clean leave. |
| P04 Auto / H.264 MP4 | PASS | System baseline corroborated by AVPlayer callbacks/instances; controls, seeks, EOF and release passed. |
| P05 Auto / HEVC MKV | PASS | MPV baseline corroborated by forced/Auto factory selection, real video/audio and no AVPlayer instance; controls, seeks, EOF and release passed. |
| O01 forced System / HEVC MKV | PASS observation | This controlled file reached first frame/PLAYING and EOF on this target; clean release. No broad format or policy inference. |
| Corrupt forced MPV | PASS functional failure/recovery | Explicit generic failure `LNK-PLAY-007`; no continuing loader at final observation, no System fallback, no sensitive diagnostic, zero renderer after leave; valid file reopened in cycle 1. |
| 20 MPV open/play/leave cycles | **20/20 PASS** | Real frame across surface, PLAYING, native audio RUNNING; every leave removed surface and all app audio renderers; same app process throughout. |
| Background/foreground | PASS | Home paused native audio; foreground retained frame/PAUSED; normal resume advanced position, then pause succeeded. |
| Fullscreen/orientation | **FAIL** | Landscape surface overflows display and clips the bottom of the video; returned to portrait and released as cleanup. |

P02 remained COMPLETED across observations separated by **10.993 s**, with no trailing downgrade to PAUSED. Its final progress was approximately **19.976 s / 20 s**; the UI floors that to `0:19`. The MPV terminal event was observed and not inferred solely from the slider. Portrait surface was **1216×684**; image inspection and six samples across the controlled color bars confirmed that the old small lower-left rectangle did not recur.

The corrupt test's exact transition time was not sampled during a host-side gap: early captures still showed connecting, and the later capture showed terminal failure about 165 s after opening. The source timeout is 12,000 ms, but this report does **not** claim a measured 12 s runtime latency. A navigation/foreground interruption happened before the corrupt file was opened; foreground was restored without repeating a completed case. The error UI did not expose credentials, upstream URL or concrete proxy token.

Audio evidence uses AudioPolicy renderer blocks matched to the app's private UID: SDK states RUNNING=2 and PAUSED=5, with zero app renderer blocks after leave. No subjective loudspeaker-output result is claimed. UI, screenshots and audio dumps are collected sequentially, so a near-EOF UI snapshot can precede the audio dump by seconds.

### New stopping defect: fullscreen geometry

For the paused controlled frame at **4.667 s / frame 140**, landscape screen size was **2688×1216**, but XComponent geometry was:

```text
origBounds: [0,0][2688,1512]
visible bounds: [0,0][2688,1216]
```

Scaling the 1280×720 source to width 2688 requires height 1512. Only 1216 pixels are visible, so the bottom **296 pixels**, approximately **19.6%** of the frame, are clipped. This is not aspect-preserving fitting with borders. The unchanged native screenshot and a decoded reference from the hash-identical controlled file show the same frame/counter and establish the lost lower portion:

- [Fullscreen native screenshot](../test-lab/playback/phase8a-rerun-1-mpv-state-surface-20261007/fullscreen-controlled-source.png).
- [Controlled source reference frame](../test-lab/playback/phase8a-rerun-1-mpv-state-surface-20261007/controlled-reference-4667.png).
- [Geometry and provenance](../test-lab/playback/phase8a-rerun-1-mpv-state-surface-20261007/fullscreen-geometry.json).

The fullscreen image contains only the owned fixture, its filename and player controls; system bars/private source alias are absent. It is published unchanged. The reference was decoded from the hash-matching owned video; no phone screenshot was edited.

Read-only review points to the shared PlayerPage's unconditional 16:9 surface layout exceeding the landscape viewport. This was observed while using MPV; System fullscreen was not tested, so no System fullscreen outcome is claimed. GPT owns the diagnosis and any correction.

After detecting the failure, no playback opening or retry occurred. Cleanup returned to portrait (1216×684, normal frame again), left the player, confirmed no surface and zero app audio renderers, and restored the initial Auto UI preference. No layout/source/test/policy change was made.

### Transport, protection and limits

REMOTE_FILE playback continues through `NetworkDirectoryService.openSource -> RandomAccessSource -> NetworkFileProxy -> localhost UUID URL -> backend`. Fresh remote playback and seek passed; all five case leaves and twenty cycle leaves released visible playback/audio resources. Direct token invalidation and exact upstream high-offset accounting are **NOT PROVEN**: no safe complete production diagnostics surface exists, and UI seek progress is not byte-offset proof. No instrumentation was added.

All **2,360** initially tracked files were compared before report editing; other protected files and the old failed evidence directory remained unchanged. Original workspace HEAD/branch/status/diff hashes were unchanged. Only this report and the authorized new evidence directory are published. Raw build outputs are preserved in exact gzip originals; readable versions normalize whitespace/encoding only. Private portrait screenshots, layouts, logs, config and signing material remain local.

No crash/ANR was observed during the fresh cases and twenty cycles. This functional run makes no performance ranking, global Auto policy, broad codec, HDR/passthrough, memory/power/thermal, Direct I/O or Phase 8B claim.

**Final classification: FAIL — MPV PLAYBACK FOUNDATION (fullscreen layout boundary).** P01–P05 and the newly executed later passes are evidence from this corrected source, not relabeling of the historical NOT RUN items. Push and remote containment verification are required before handoff; independent review remains pending.

## GPT independent review and correction — 2026-10-07

Reviewed remote evidence commit:

`08852ccc0ae1806b8270f2a248113eeedd61b5f9`

Ruling:

**VALID RUNTIME DEFECT — MPV unified-state/EOF mapping, with a separate confirmed surface-unit integration defect.**

The failed run remains a failure. P03-P05, lifecycle, negative path and remote seek-byte behavior remain NOT RUN / NOT PROVEN.

### Root cause: unified MPV state

The upstream `@mpv-ohos/mpv-arkts` wrapper emits `stream.playing=true` on `MPV_EVENT_START_FILE`, before Linkora's `FILE_LOADED` preparation boundary can complete. Linkora's `MpvPlaybackPort` intentionally ignored playing changes while `prepared=false`. A later explicit `player.play()` only sets mpv's pause property; it does not provide Linkora with a guaranteed fresh stream callback. Therefore the underlying player can advance while `PlaybackEngine` remains READY.

Correction:

- a successful Linkora `play()` command now publishes `PortPlaybackState.PLAYING` explicitly;
- a successful `pause()` command publishes `PAUSED` explicitly;
- native stream callbacks remain useful confirmations/externally-originated transitions.

### Root cause: EOF ordering

The upstream wrapper handles `eof-reached=true` by publishing EOF and then publishing `playing=false`. Linkora previously mapped those as:

```text
COMPLETED
-> PAUSED
```

Correction:

- `MpvPlaybackPort` tracks terminal completion;
- trailing `playing=false` after EOF cannot downgrade COMPLETED;
- seek/play clears the terminal guard so replay can become PLAYING normally.

Pure MPV adapter regression coverage now includes both ordering defects.

### Surface-size correction

The device run showed MPV video confined to a small lower-left rectangle.

ArkUI `onAreaChange` dimensions are logical vp. The mpv-ohos `ohos-surface-size` property expects physical pixel dimensions. Linkora previously forwarded Area values unchanged.

Correction:

```text
Area width/height (vp)
-> UIContext.vp2px
-> PlaybackEngine/AdaptivePlaybackPort
-> MpvPlaybackPort
-> ohos-surface-size (px)
```

This code correction still requires the fresh Mate60 rerun to prove actual rendering.

### Validation boundary

No Auto policy, MediaProxy transport, Direct I/O, codec matrix, thumbnail research, or advanced AV behavior was changed.

The correction is not accepted runtime evidence until a fresh exact-source signed arm64 run passes the READY rerun task.


## Historical initial Phase 8A validation — failure retained

Task: `phase8a-mate60-playback-foundation`.

- Accepted Phase 7A baseline: `e81766309fab4bf61222c64f95c25bd9ad5fd148`.
- Implementation source: `fd76b28a85522a94db40e754dd87c62960dc71ad`.
- Actual tested dispatch HEAD: `38fce8b2ff7feb56cb21aa537ceb90419864987e`.
- Both required ancestor relationships passed. Source-to-HEAD drift was exactly `docs/CODEX_VALIDATION_TASK.md`.
- New isolated validation clone; pinned submodules initialized and verified. Original user checkout preserved.
- Evidence: [phase8a-mate60-foundation-20261006](../test-lab/playback/phase8a-mate60-foundation-20261006/).

### Build and deployment

One normal `ohpm install` passed. Four known lockfiles were strictly proven equivalent to HEAD under CRLF-to-LF normalization and restored only in the isolated checkout.

One fresh `verify.ps1` passed: architecture fixtures 5/5, FFmpeg pure 15/15, analysis pure 46/46, artifact fixtures 17/17, MPV mapping 5/5, Hypium **210 PASS / 0 Failure / 0 Error / 0 Ignore**, Debug/Release HAR and HAP, and two exact-nine AArch64 audits. No historical sub-gate result was reused. The current task did not require simulator validation.

One fresh signed default/debug HAP passed the existing exact-nine artifact audit and was explicitly installed on the real Mate60 (arm64, API 26), without uninstalling or clearing app data. Bundle/version: `com.linkora.player` / `0.1.0`, debug.

- HAP SHA-256: `EAA380932C7360976ECDC9651537B2930DBDF451999C5F6E3427005C378E9E19`.
- HAP size: **64,546,622 bytes**.
- Root signing-only overlay SHA-256: `5143AE29AFDA4A20ECECCDD7495E1B1759FD40A77A0312BBCFD63F97E04E9F6C`.

The main checkout no longer contained signing configuration. The previously accepted private signing overlay supplied the same existing material, whose files were freshly checked. No main-workspace edit occurred. All non-signing semantics were compared to HEAD; the temporary overlay was restored before installation. The phone accepted the signature.

Both valid controlled WebDAV fixtures and the corrupt fixture passed fresh remote SHA-256 and TLS-verified Range/206 checks. Private environment details are excluded from published evidence.

### Runtime result and stop

| Case | Fresh result | Evidence |
| --- | --- | --- |
| P01 forced System / H.264 MP4 | PASS, functional case | Real frame; 20 s / 1280×720; pause/resume; native seekDone at 10,000 and 18,000 ms; continued playback; `播放完成` at 20/20 s; XComponent removed and AVPlayer instances for app became zero after leave. |
| P02 forced MPV / H.264 MP4 | **FAIL** | Real video and position progressed, but UI remained `已就绪` / READY with `▶` instead of a pause action. At 20/20 s it displayed `已暂停` / PAUSED, rather than completion. |
| P03 forced MPV / HEVC MKV | NOT RUN | STOP after P02. |
| P04 Auto / H.264 MP4 | NOT RUN | STOP after P02. |
| P05 Auto / HEVC MKV | NOT RUN | STOP after P02. |
| O01 forced System / HEVC MKV | NOT RUN | STOP after P02. |
| Corrupt forced MPV | NOT RUN | Fixture available, but STOP after P02. |
| 20 MPV cycles | NOT RUN | STOP after P02. |
| Background/foreground; fullscreen/orientation | NOT RUN | STOP after P02. |
| Remote seek byte offsets / token invalidation | NOT PROVEN | No direct production diagnostics endpoint; stopped before further behavioral collection. Seek progress alone is not upstream byte-offset proof. |

The single P02 opening showed 0:01 initially, then **13.733 s** while the UI still reported READY/PLAY, and finally 20/20 s with PAUSED. A pause click was refused because the fresh layout contained no pause button; no coordinates were guessed. The observation label `P02-paused` denotes that attempted checkpoint, **not** a successful pause. No second opening or retry was performed.

The MPV image was also a small rectangle at the lower-left of an otherwise black video surface. This is a secondary rendering observation; the mandatory unified playback-state/EOF failure is sufficient to stop the task. No surface correction was attempted.

Forced MPV selection was confirmed again in Settings during cleanup. Real video appeared with zero AVPlayer instances for the app, consistent with the verified production MPV factory. The internal committed-backend field is not exposed by the UI, and OS process-map access returned `Operation not permitted`; these limitations are recorded rather than replaced with an injected observer.

After the stop, the existing player was left/released: XComponent removed, app responsive, AVPlayer instances zero. The initial Auto UI preference was restored as cleanup. No crash/ANR was observed during this short run; historical LowMemoryKill records preceding the test window were not counted as test failures. No subjective audible-output or 20-cycle resource-stability claim is made.

### Review hypotheses, not fixes

Read-only review suggests checking the timing of native `playing` events versus `prepared` and candidate commit, and the ordering of `eof` versus `playing=false`. `CandidateObserver` does not replay a cached state; `MpvPlaybackPort` ignores playing notifications before preparation. Review should also check the units used for surface size. These are hypotheses requiring GPT review, not proven root causes or authorization to patch source.

### Protection and interpretation

All **2,317** initially tracked file bytes remained unchanged before the authorized report/evidence update; original workspace HEAD, branch, status and diff hashes were unchanged. Production source, tests, expectations, build configuration, lockfile semantics and task file were not modified. No policy tuning, Direct I/O, thumbnail research branch work, Phase 8B matrix or performance conclusions were undertaken.

Raw build outputs are retained as exact gzip originals with SHA-256 and decompression checks; readable copies only normalize encoding/line endings/trailing whitespace. Runtime screenshots/layouts/logs that contain private source labels or system information remain local; published observations retain original hashes and sanitized facts. The security audit includes decompressed originals.

**Final classification: FAIL — MPV PLAYBACK FOUNDATION.** Evidence must be pushed and remote containment verified before handoff. Independent review remains pending.

## Baseline

Inherited accepted architecture includes:

- SystemPlaybackPort;
- MpvPlaybackPort using `@mpv-ohos/mpv-arkts@1.0.0`;
- AdaptivePlaybackPort;
- Auto/System/MPV preference;
- candidate-event isolation and one-shot Auto fallback;
- NetworkPlaybackSourceResolver;
- REMOTE_FILE -> RandomAccessSource -> shared MediaProxy -> backend;
- surface size / seek complete / buffering / tracks / video-info contracts.

Build/static coverage exists, but current architecture lacks accepted real-Mate60 MPV playback runtime evidence.

## Phase 8A scope

Use the controlled WebDAV H.264/AAC MP4 and HEVC/AAC MKV fixtures to validate:

- forced System baseline;
- forced MPV baseline;
- Auto baseline;
- seek/EOF/release;
- MPV surface lifecycle;
- remote MediaProxy playback;
- bounded negative behavior;
- 20-cycle MPV lifecycle.

No broad codec/container claim and no performance policy is authorized by this stage.

## Phase 8B direction

After Phase 8A acceptance, reuse `test-lab/media-compatibility` as the shared Tier A/B/C capability corpus rather than creating a separate playback-only corpus.
