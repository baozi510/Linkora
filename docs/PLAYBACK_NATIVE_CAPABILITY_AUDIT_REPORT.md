# Playback Native Capability Audit Report

> Classification: PASS — NATIVE PLAYBACK CAPABILITY AUDIT COLLECTED
> Task: phase8c-sim-native-first-capability-audit
> Branch: feat/playback-capability-phase8
> Date: 2026-10-08 (Asia/Shanghai)

Implementation/validation source: `99ab47020f81391b7640d44c58ccb719491b4106`.

Actual tested dispatch: `e835a3567132c9f496d0c79f3c1eab88f1916774`.

Evidence directory: `test-lab/playback/phase8c-native-capability-audit-20261008/`.

This is a native capability audit, not product feature implementation, codec/container acceptance, a performance benchmark or final ARM64 output acceptance. All normalized contract recommendations are `DEFER_TO_GPT`. The six historical System FAIL observations remain unchanged. Phase 8B-SIM acceptance at `dcb34487e2043ba37f763c2ee50f4e040b597fbd` is a prerequisite, not a substitute for this fresh run.

## Fresh source/build/runtime evidence

The new isolated checkout matched repository, branch, READY task and dispatch. Accepted evidence is an ancestor of source; source is an ancestor of HEAD; source-to-HEAD diff is exactly `docs/CODEX_VALIDATION_TASK.md`. Three pinned submodules were initialized and checked. Required-reading provenance distinguishes complete current-file reads from previously complete, byte-identical sections revalidated against Git. Actual normally resolved package declarations and compiled implementation were inspected; no previous application artifact or PASS was reused.

One normal initial `ohpm install` succeeded. Four allowlisted locks received fresh Git-blob/exact CRLF-to-LF byte/semantic-content/full tracked-byte proofs before isolated restore. The simulator verifier's internal finally install received a separate fresh proof/restore. Both returned clean; no dependency/version/checksum/graph/comment change or repair reinstall occurred.

Fresh default → simulator → final default passed. Both default runs returned Hypium **210 PASS / 0 Failure / 0 Error / 0 Ignore**, architecture fixtures 5, FFmpeg pure 15/15, analysis pure 46/46, artifact fixtures 17 and MPV mapping 7. Debug/Release HARs for four modules and HAPs passed; two exact-nine AArch64 audits occurred per default run. Separate original Hypium files were retained. Eight reused FFmpeg dependency archives were freshly hashed and every member's ABI checked. Simulator parity/isolation, audio schema guard and the sole real x86_64 FFmpeg library audit passed. Final default gates and exact package hashes prove the real default dependency graph was restored.

Target was x86_64, API 26, OpenHarmony 7.0.0.105, HDC 3.2.0f, bundle `com.linkora.player` debug 0.1.0. No physical ARM64 test was started.

Fresh unsigned simulator HAP: SHA-256 `E445315C36A671DF826425152664286B6F0E6922AB63A4A507C5BDFF85E74C49`, 25,087,238 bytes. Its normal replace-install was rejected solely by signature enforcement code9568332 despite HDC transport exit0. Existing legal profile membership was checked; the accepted unchanged SDK signing procedure signed that exact artifact, without profile/source/dependency/ABI modification or signature/permission bypass. Signed exact-artifact x86 audit and explicit replace-install/cold launch passed, retaining app data.

Installed signed HAP: SHA-256 `6C4F5080B62EBDDA8E7FBD041E6FC7614E8534E19532A38D39DCFEA875C5B7A9`, 25,281,133 bytes.

## Audio schema correction and ordinary regression

The four owned audio fixture inputs were freshly whole-GET/hash/Range206/PROPFIND207 checked through authenticated controlled WebDAV with TLS verification, against committed truth; host ffprobe independently verified audio-only codec/channels/sample rate. The actual persisted profile was unique. The exact-source diagnostic was cold-dispatched **once**. Its POST records match independent app hilog records.

| Fixture | Actual result | Code | Final activeSources |
| --- | --- | ---: | ---: |
| MP3 | PASS / complete, 3000ms, zero video, mp3/1 channel/48000Hz | 0 | 0 |
| FLAC | PASS / complete, 3000ms, zero video, flac/1 channel/48000Hz | 0 | 0 |
| TrueHD | bounded FAIL / unavailable | 23002 | 0 |
| WavPack | bounded FAIL / unavailable | 23002 | 0 |

**Exactly five events:** four unique complete fixture records plus one summary. No redundant code-only post-assertion note remains. Raw summary is preserved as **FAIL, total4/pass2/fail2**, reflecting the permitted optional x86 capability failures, not a schema/infrastructure failure. No audio thumbnail/frame request or fabricated video dimensions occurred. Pre-final-proxy-close cleanup is asserted by source; emitted final source counts are zero. No unexposed independent counter is invented.

Afterward a normal cold launch without diagnostic parameters ran **one** forced-System owned 20-second H.264/AAC smoke. Actual native XComponent multicolor frame pixels, PLAYING in both snapshots and position **1614ms → 3701ms** were observed. One leave produced zero sampled surfaces, app player service entries and app audio renderers. Service entries are not advertised as independent instance counts. Screenshots/raw logs remain private; published RGB samples/digests support the frame observation. This proves only that exercised normal System path, not every native control or physical output. No crash/ANR was observed in the focused run; comprehensive leak freedom is not claimed.

Original Auto was restored, owned config service stopped, no new HDC forward created, and owned WebDAV profile/media retained as instructed.

## Source hierarchy and audit scope

The matrix contains exactly **39 unique seed feature IDs**, both backends, required API/version/range/state/event/exposure/source fields, privilege and output boundaries, and deferred normalized-contract recommendations. No `AUDIT_REQUIRED` remains. `matrix-validation.json` records inventory/schema checks.

System compile/target API is26.0.0 with compatible API20. Actual ETS SDK identity is26.0.0.105. Sixteen relevant installed metadata/declaration/header files were independently SHA-256 checked. Source references are relative SDK identities with line ranges and current official Huawei/OpenHarmony references. Installed declarations are compile-time truth when current docs differ. `NATIVE_VERIFIED` on unexercised APIs means a documented static native capability, not a runtime claim; each row marks its evidence scope and whether unchanged Linkora can reach it.

MPV is the actually resolved `@mpv-ohos/mpv-arkts@1.0.0`, compatibleSDK20, with18 distributed declaration files and compiled `ets/modules.abc`. This distribution has no plain `Player.ets`; it was not misrepresented as available plaintext source. The installed SDK disassembler successfully inspected the exact hashed bytecode. Native library embedded identity is **mpv v0.41.0-dev-g6edeee00a / FFmpeg n8.0**. Matching upstream commit `6edeee00a07b9b76f197aa71eee3d029fb090de4` (2026-07-13, OHOS support) and stable v0.41.0 reference (release2025-12-21) were separately researched. Embedded identity and matching-source inspection are not a reproducible unmodified binary-source proof.

The wrapper publicly exposes `Player.native: MpvLib` with generic command, command-with-return, property/option setters/getters and observation. Bytecode forwards these with no property-name whitelist. Therefore a missing convenience method is **not** `WRAPPER_NOT_EXPOSED` where the verified generic surface can reach the identified native capability. Real MPV remains unavailable in simulator; no fake runtime/codec matrix was generated.

| Backend | Static audit verdict counts |
| --- | --- |
| System | 14 NATIVE_VERIFIED;10 NATIVE_PARTIAL;14 NATIVE_ABSENT scoped to public AVPlayer/API26;1 DEVICE_CONFIRMATION_REQUIRED |
| MPV | 37 DEVICE_CONFIRMATION_REQUIRED;1 NATIVE_PARTIAL (passthrough);1 NOT_APPLICABLE (platform media-session ownership) |

SDK-only negative verdicts are scoped: absence from public AVPlayer does not assert absence from all HarmonyOS/native-window/image-processing/internal facilities. Related public NativeWindow transform/unscaled/capture and standalone VideoProcessing APIs are identified separately, with no claim they are currently integrated into the ArkTS player. Ordinary AVPlayer symbols do not carry system-app annotations; own-session AVSession differs from privileged global media-resource management, and background continuous tasks require their permission/mode/policy.

Current Huawei pages that timed out are recorded as fetch limitations, not supporting content. Current official OpenHarmony primary pages were opened and source-hashed. A standalone VPE page was unavailable, so those related-platform claims are bounded to installed symbols. SDK/current-documentation conflicts and remaining uncertainties remain in each row/research log rather than being silently reconciled.

## Material baseline findings for GPT review

1. **System speed mapping is narrower than native capability.** Existing code forwards only1/1.25/1.5/2, floors requests below1 to1 and caps rates above2 at2. The SDK exposes additional discrete rates and continuous setPlaybackRate since20. Installed API26 permits up to8, while compatible<=24 and current docs retain an upper4 context. Requested/UI speed is not native accepted-speed evidence. Future contract needs supported rates/modes and acceptance feedback.
2. **MPV cache-end timestamp is stored as cached duration.** Actual wrapper bytecode forwards `demuxer-cache-time` into buffer; the adapter emits it as CACHED_DURATION and PlaybackEngine stores it as bufferedDuration. These timeline-end and duration quantities differ. INT64 observation also risks fractional precision. Native cache-pause/threshold-fill percentage are separately scoped, not total download progress.
3. **Seek completion is not uniform frame-position proof.** System seekDone carries requested time according to installed declaration. MPV maps one pending boolean to the next PLAYBACK_RESTART without independent request correlation. Its absolute seek defaults to exact intent in the matching native manual even without an explicit +exact; lack of the explicit flag is not proof of inaccurate/keyframe seeking. Media/decoder precision and actual presented position still need separate observation.
4. **Native first-frame signals are weaker than visible-output evidence.** System startRenderFrame signals frame submission, and MPV PLAYBACK_RESTART covers discontinuity/reinitialization. Neither independently guarantees a visible first video frame. This run's System pixel capture is separate direct evidence; MPV real output remains untested.
5. **Display defaults and viewport ownership are explicit.** System FIT=stretch, FIT_CROP=aspect-preserving fill/crop, SCALED_ASPECT=contain since20. Linkora does not expose scale-mode control and leaves native FIT default; its System surface-size method is a no-op. An unscaled NativeWindow mode outside AVPlayer is not automatically an implemented backend original-size contract.
6. **System track/video-info observers are not wired.** Native track-description/change APIs exist, but SystemPlaybackPort does not emit contract onTracksChange/onVideoInfoChange. MPV exposes read-only metadata/selection observation; dependency switching convenience exists but no unified switching method is implemented. Enumeration is not codec/render capability.
7. **OHOS HDR and passthrough need precise platform interpretation.** Matching MPV core includes NativeWindow color/PQ/HLG metadata integration; older stable-manual platform enumeration is not proof OHOS HDR is absent. Conversely generic audio-spdif does not prove encoded passthrough: the matching OHAudio AO maps PCM formats/default RAW encoding. Neither metadata flags nor option acceptance establish HDR/DV or object-audio/bitstream physical output.

No production fix, temporary hook, wrapper/SDK patch, UI control, display-mode implementation, backend-selection/Auto tuning, Direct I/O or thumbnail-research change was made. Existing differences are reported for GPT; this audit does not grandfather them or implement its proposals.

## Device delta and publication

`device-confirmation-delta.json` contains38 feature-specific native findings/check groups, including the researched partial passthrough path, not a copy of unrelated performance/storage/codec backlogs. Each identified capability has a specific real-backend/output/route check. Previous Phase8A foundation evidence is retained but does not substitute for the exact semantics newly audited. Ordinary app/session/contract work that can proceed on simulator is not classified hardware-only just because it remains unimplemented.

Only this report and the dispatched new evidence directory are published. Production/task/test/profile/manifest/semantic-lock/SDK/package files, old evidence and the original user workspace are protected. Original build logs remain local PRIVATE; public readable/compressed copies retain every warning/result with declared encoding/whitespace and absolute-checkout/Studio path replacements. Public compressed copies are correctly labelled sanitized, not falsely claimed byte-identical originals. Signing material, credentials/endpoints/identifiers, generated media/HAP and screenshots are excluded. Completion requires normal push and fresh remote containment/blob verification; no force/merge is authorized.

## Feature inventory

| Feature | System | MPV |
| --- | --- | --- |
| transport.play | NATIVE_VERIFIED | DEVICE_CONFIRMATION_REQUIRED |
| transport.pause | NATIVE_VERIFIED | DEVICE_CONFIRMATION_REQUIRED |
| transport.stop-replay | NATIVE_VERIFIED | DEVICE_CONFIRMATION_REQUIRED |
| timeline.seek | NATIVE_VERIFIED | DEVICE_CONFIRMATION_REQUIRED |
| timeline.speed | NATIVE_VERIFIED | DEVICE_CONFIRMATION_REQUIRED |
| audio.volume-mute | NATIVE_VERIFIED | DEVICE_CONFIRMATION_REQUIRED |
| state.buffering | NATIVE_VERIFIED | DEVICE_CONFIRMATION_REQUIRED |
| tracks.enumerate | NATIVE_PARTIAL | DEVICE_CONFIRMATION_REQUIRED |
| tracks.audio-select | NATIVE_VERIFIED | DEVICE_CONFIRMATION_REQUIRED |
| tracks.subtitle-select | NATIVE_PARTIAL | DEVICE_CONFIRMATION_REQUIRED |
| subtitles.external | NATIVE_PARTIAL | DEVICE_CONFIRMATION_REQUIRED |
| subtitles.delay | NATIVE_ABSENT | DEVICE_CONFIRMATION_REQUIRED |
| audio.delay | NATIVE_ABSENT | DEVICE_CONFIRMATION_REQUIRED |
| display.fit-contain | NATIVE_VERIFIED | DEVICE_CONFIRMATION_REQUIRED |
| display.fill-crop | NATIVE_VERIFIED | DEVICE_CONFIRMATION_REQUIRED |
| display.stretch | NATIVE_VERIFIED | DEVICE_CONFIRMATION_REQUIRED |
| display.original | NATIVE_ABSENT | DEVICE_CONFIRMATION_REQUIRED |
| display.aspect-override | NATIVE_ABSENT | DEVICE_CONFIRMATION_REQUIRED |
| display.rotation | NATIVE_ABSENT | DEVICE_CONFIRMATION_REQUIRED |
| display.zoom-pan | NATIVE_PARTIAL | DEVICE_CONFIRMATION_REQUIRED |
| timeline.frame-step | NATIVE_ABSENT | DEVICE_CONFIRMATION_REQUIRED |
| navigation.chapters | NATIVE_ABSENT | DEVICE_CONFIRMATION_REQUIRED |
| repeat.loop | NATIVE_VERIFIED | DEVICE_CONFIRMATION_REQUIRED |
| repeat.ab | NATIVE_PARTIAL | DEVICE_CONFIRMATION_REQUIRED |
| capture.screenshot | NATIVE_PARTIAL | DEVICE_CONFIRMATION_REQUIRED |
| processing.deinterlace | NATIVE_ABSENT | DEVICE_CONFIRMATION_REQUIRED |
| processing.video-filter | NATIVE_PARTIAL | DEVICE_CONFIRMATION_REQUIRED |
| processing.audio-filter | NATIVE_PARTIAL | DEVICE_CONFIRMATION_REQUIRED |
| decode.hw-select | NATIVE_ABSENT | DEVICE_CONFIRMATION_REQUIRED |
| decode.hw-fallback | NATIVE_ABSENT | DEVICE_CONFIRMATION_REQUIRED |
| color.hdr | DEVICE_CONFIRMATION_REQUIRED | DEVICE_CONFIRMATION_REQUIRED |
| color.tonemap | NATIVE_ABSENT | DEVICE_CONFIRMATION_REQUIRED |
| color.adjust | NATIVE_ABSENT | DEVICE_CONFIRMATION_REQUIRED |
| audio.passthrough | NATIVE_ABSENT | NATIVE_PARTIAL |
| network.cache-buffer | NATIVE_PARTIAL | DEVICE_CONFIRMATION_REQUIRED |
| network.reconnect | NATIVE_ABSENT | DEVICE_CONFIRMATION_REQUIRED |
| timeline.start-position | NATIVE_VERIFIED | DEVICE_CONFIRMATION_REQUIRED |
| surface.render-options | NATIVE_PARTIAL | DEVICE_CONFIRMATION_REQUIRED |
| background.media-session | NATIVE_VERIFIED | NOT_APPLICABLE |
