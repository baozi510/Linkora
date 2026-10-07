# Playback Phase 8 Report

> Status: CORRECTION SOURCE PREPARED — prior P02 FAIL independently reviewed; fresh Mate60 rerun required.
> Branch: `feat/playback-capability-phase8`
> Validation date: 2026-10-07 (Asia/Shanghai)

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


## Fresh Phase 8A validation

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
