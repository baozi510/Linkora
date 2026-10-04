# FFmpeg Media Analysis Phase 1 Report

Status: BUILD/UNIT VALIDATED — STOPPED FOR ARCHITECTURE REVIEW (§22.2).
Date: 2026-10-04. Branch: `feat/ffmpeg-media-analysis-phase1`.

## Git and execution ledger

Starting SHA: `000d00f05b8a282c08397a0d36095b7de26af6b7` (runbook base: test/simulator-validation).
Validated source SHA: `772889a48aabec8d8c427a1222126c1709159ca4`.
Final report commit is the branch HEAD; use `git rev-parse HEAD` / final handoff for its SHA to avoid a self-referential hash.
Workspace: D:/Linkora-validation, clean isolated clone. Original D:/Linkora dirty main was not modified.
Runbook completely read; fetch and checkout used the requested existing feature branch. No merge or PR integration.

1. Implement dedicated typed adapters, raw ownership, request state and native analysis: complete, commit `6622064ee53a9a7d76bb39d4b855e7100cb45f2c`.
2. Register default/simulator ABI targets and add executable artifact/pure regression guards: complete, commit `772889a48aabec8d8c427a1222126c1709159ca4`.
3. Targeted tests → simulator parity → full verify: PASS. Bootstrap unchanged, no rebuild needed.
4. The first successful default Debug native link triggered §22.2. Stop further implementation and simulator build/runtime; finish only the already running complete verify and evidence/commits.

Ruling: Native.ets is an explicit NAPI factory entry; Index.ets exports pure typed APIs so host Hypium does not load native code. Cost if wrong: consumer import/packaging would need a module-local correction; native factory runtime remains NOT RUN.
Ruling: §22 uses “any”; successful arm64 link stops before the later simulator smoke sequence. Cost: x86 runtime confidence is deferred to architecture review, rather than being claimed here.

## Environment and real dependency

Windows 11 26200; DevEco 26.0.0.821; SDK 26.0.0.105/API26; Hvigor 6.26.4; ohpm 26.0.0.630; bundled Node 24.14.1; OHOS target clang 15.0.4.
Native SDK: C:/Program Files/Huawei/DevEco Studio/sdk/default/openharmony/native.
Host helper test uses installed MSVC cl 19.50; it is not a substitute for OHOS native runtime.
Only x86_64 emulator 127.0.0.1:5555 available; no arm64 device.

FFmpeg 8.1.3, tag n8.1.3, commit `1041abdc962f4cc4f394aa8de9dc5236c0c3b9e7`.
Reused genuine preceding bootstrap outputs for x86_64 and arm64-v8a: avformat, avcodec, avutil, swscale. Both ABI manifests match. All archive members audited with SDK llvm-readelf; counts, machine and SHA256 in [archive-audit.json](validation/ffmpeg-phase1/archive-audit.json).
No FFmpeg source patch/build-script change; no host substitute, fabricated headers, or libmpv FFmpeg symbols. Generated headers, archives, native binaries and HAPs remain ignored.
`ohpm install` exit0 resolved normal dependency graph and generated both new module/entry locks; no handcrafted lockfile. Existing @mpv-ohos/mpv-arkts 1.0.0 remains intact.

## Implementation and bounds

Dedicated HAR/native output liblinkora_ffmpeg.so. Async probe/extractFrame/cancel; request deadline starts at enqueue. Work/shared_ptr owns interrupt state through completion; AVIOInterruptCB checks native atomic cancellation/deadline. Registry scoped by NAPI env, at most16 active jobs; wrapper maps external IDs to independent internal IDs, cancels only owned work, and rejects calls after close.

Inputs: bounded native absolute regular-file path, or exact current MediaProxy http://127.0.0.1:port/token. Reject userinfo/query/CR/LF/NUL/unsupported schemes; no direct remote protocol/AVIO storage callback. File stat rejects FIFO/device opens. Self-contained demuxer whitelist excludes playlist/nested URL inputs. Disable HTTP proxy/redirects. Metadata caps64 streams,128 chapters,64 format tags and16KiB shared free-metadata budget. Stable error codes; detail is bounded av_strerror without input; native FFmpeg logs silent.

Software decode/seek → aspect/SAR fit without upscale → RGBA. Bounds: timeout1..120000ms, timestamp0..7days, dimensions1..4096, output≤32MiB and exactly width*height*4. JS ArrayBuffer receives a copy; no external native pointer/double-free. RawThumbnail read returns a copy, release idempotent, reads after release rejected. No WebP/JPEG encoding here.

Pure MediaInfo mapping supplies ffmpeg field origins. PQ→generic HDR10, HLG→HLG, explicit DOVI config→Dolby Vision including profile0. No inference from BT2020/10bit; no physical HDR/passthrough claims.

## Verification and build matrix

`./scripts/verify.ps1` attempt01: **PASS, exit0**, no failing item skipped. Evidence: [verify-summary.txt](validation/ffmpeg-phase1/verify-summary.txt). Complete ignored log artifacts/ffmpeg-phase1/verify-01.log SHA256 FB9B312B103A02FEB1C03B68B982F3E1B2326E3030028FAD362C4F33A4F05F2A.
Includes architecture fixtures, UI state guard, persistence, HTTP range/list regressions, existing MPV mapping checks, SDK Hypium, all HAR/HAP builds and actual ELF audits.

| Product / artifact | Debug | Release |
| --- | --- | --- |
| default linkora_core HAR | PASS | PASS |
| default linkora_proxy HAR | PASS | PASS |
| default linkora_media_probe HAR | PASS | PASS |
| default linkora_ffmpeg HAR / AArch64 native | PASS | PASS |
| default entry arm64 HAP (unsigned) | PASS | PASS |
| simulator linkora_ffmpeg x86_64 native link/HAR | NOT RUN | NOT RUN |
| simulator entry HAP/install/runtime this phase | NOT RUN | NOT RUN |

No signing config: successful outputs are unsigned build artifacts, not an install/runtime or distribution claim. Existing compiler warnings are in the full log; warnings did not become skipped failures.
Default HAP SHA256: Debug F126D32156E772759259E1FE0B75797DEEF1C3BB2736DD0A402FB106283CD51C; Release 88E8C23F9D999E5E1763AD93C383AB93B800F09AF8CC7AE0A61C3EA5D548634C.

ARM unstripped module: Debug E392ADE276CEAC1D1329285B41F8D914F3ED7CCF8046E828E67F5897D82454AE; Release 65A4A2BD764D487684D5AAFC80ED94B8CE9CCB45F49624B5572755E12C67EC95. SDK readelf: ELF64 little-endian AArch64, SONAME liblinkora_ffmpeg.so, DT_NEEDED only libace_napi.z.so/libc.so. No exported av*/sws* dynamic symbols observed.
Packaged/stripped module: Debug 07b747c09dd05120ae848964a0f70173466f4f7702a15e210c0f4c9b81487fd7; Release 17c0a58a9d72f763a4636de8214f0c51202383ac23ebbf38c49fe3b41c94a20b.
Both HAPs contain9 native libraries, all AArch64 in libs/arm64-v8a. [Debug](validation/ffmpeg-phase1/debug-packaged-native-sha256.txt) / [Release](validation/ffmpeg-phase1/release-packaged-native-sha256.txt) manifests retained.
MPV and wrapper SHA unchanged between modes; native protocol source/build configuration unchanged (their Debug/Release compiled hashes differ normally). No claim that rebuilding source produces byte-identical old protocol binaries.
x86 module SHA/ELF: **NOT RUN**. Genuine x86 CMake configure/archive ABI checks PASS; configure does not prove link/runtime. Missing ABI negative configure gives actionable bootstrap command (expected failure PASS).

## Unit and red/green evidence

SDK Hypium: **164/164 PASS, Failure0/Error0/Ignore0**, current149 retained +15 new. [Actual result](validation/ffmpeg-phase1/hypium-result.txt).
Pure Node runner independently executes the same15 cases: PASS. Native host assertions cover URI rejection, aspect/SAR/no-upscale, allocation arithmetic, UTF8 boundaries and isolated timeout/cancel/completed states: PASS. Artifact guard fixtures5/5PASS (valid x86/default, wrong ELF, unexpected native and missing module). Simulator parityPASS.
Host assertions/fake wrapper work do not prove blocking native IO cancellation or device NAPI lifetime.

| Failing command / original error | Root cause / minimal correction | Retry / commit |
| --- | --- | --- |
| Node check-ffmpeg-phase1: module public API missing | Module not implemented; add typed module and adapters |15/15 PASS;6622064 |
| ARM clang -fsyntax-only: napi/native_node_api.h file not found | Wrong SDK include; use actual node_api.h |exit0;6622064 |
| SDK hvigor test attempt01: arkts-no-ctor-prop-decls, arkts-no-standalone-this, arkts-no-untyped-obj-literals | Explicit members/assignment, class static call, tag index assignment |attempt02 still tag literal error, attempt03 163/163, full verify164/164;6622064 |
| UTF8 native helper test: full Chinese final character missing | Truncation treated complete multibyte tail as incomplete |Check remaining codepoint byte length;native host PASS;6622064 |
| DOVI pure test: actual hdr10, expected dolby_vision | Profile>0 conflated config presence with profile value |Explicit config flag;profile0 test PASS;6622064 |
| Shared-native double-wrapper test: false !== true | Same external ID collided before rejected Promise cleanup |Internal unique IDs;PASS;6622064 |
| Artifact fixture test: guard module missing | Artifact audit not yet implemented |Real ELF/path checker,5/5PASS;772889a |

Host harness failures (not product fixes): SDK clang15 with installed modern MSVC STL rejected unsupported compiler; use genuine installed cl for host tests. Initial CMake negative harness lacked Ninja on PATH; give SDK CMAKE_MAKE_PROGRAM explicitly. Correct missing-prebuilt retry fails for intended root cause. No SDK downgrade/source patch.
Original red/green excerpts in validation/ffmpeg-phase1; all fixes bundled in the two isolated implementation/verification commits above, no existing tests weakened.

## Runtime smoke and remaining blockers

| Required case | Result / why |
| --- | --- |
| Native.ets real import and NAPI initialization | NOT RUN — §22.2 stop gate |
| Local H264/AAC MP4 probe; HEVC/MKV probe | NOT RUN — §22.2 |
| WebDAV→RandomAccessSource→shared MediaProxy→FFmpeg MKV metadata | NOT RUN — §22.2 |
| Real frame dimensions/bytes/time, remote nonsequential seek | NOT RUN — §22.2 |
| Corrupt input / stalled localhost timeout / active cancel / actual cleanup | NOT RUN — §22.2 |
| arm64 native probe/frame/device smoke | NOT RUN — DEVICE REQUIRED |
| Security runtime locator leakage scan | NOT RUN |

MediaProxy activeSources/lease/runtime diagnostics for this new FFmpeg path: NOT RUN, no fabricated zero/pass. No System/MPV/Auto runtime retest or strategy changes in this phase. Previous accepted simulator evidence remains historical, not new FFmpeg smoke. Benchmark NOT RUN; no NDJSON invented. WebP encoder remains unchanged; real encoding smoke NOT RUN.
LGPL release packaging/relink compliance not decided or certified; this is local integration evidence only, no distribution/publish.

## Final review and scope

One fresh read-only whole-branch review completed; no remaining Critical/Important. Cross-wrapper cancellation finding verified RED→GREEN with shared fake and included in164/164 suite. No re-review loop.
Final: minor (deferred): CMake manifest commit/ABI regex is not full-line anchored; current genuine pinned manifests match precisely. Future review may harden the guard; no runtime claim depends on a forged manifest.

Production PlaybackBackendSelector/Auto/SystemPlaybackPort/MpvPlaybackPort/NetworkMediaLoader, core public signatures, protocol implementations and FFmpeg bootstrap scripts unchanged; git scoped diff is empty. No policy, merger, AVIO storage callbacks, encoding or playback backend added.
Stopped at §22.2; preserve branch and evidence for architecture review. Do not proceed to simulator smoke or policy integration without next authorized phase.
