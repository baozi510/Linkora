# FFmpeg Analyzer Integration Phase 2 Report

> Status: READY FOR ANALYZER POLICY REVIEW — functional validation completed, no merge.
> Branch: `feat/ffmpeg-analyzer-integration-phase2`
> Date: 2026-10-04 (Asia/Shanghai)

## Git / Environment

- Starting SHA: `c5429529094d0a8b6c0fbf34e3d22f81b50a41a0`.
- Final default tested source SHA: `ab083e34c1f228f4c9ef8afc91f8e7870a0b84b6`.
- Final simulator executed source SHA: `a51faf9f513b83d2b53f16d10e97d80460b8e81c`; subsequent application/native source diff is empty (test typing/report only).
- Final report/evidence commit: supplied in final handoff after committing this report.
- Windows host, PowerShell7, isolated checkout `D:/Linkora-validation`; original dirty `D:/Linkora` main preserved.
- DevEco26.0.0.821, SDK26.0.0.105/API26, Hvigor6.26.4, ohpm26.0.0.630, Node24.14.1.
- Real x86_64 emulator `127.0.0.1:5557`, HarmonyOS7.0.0.107(SP8DEVC00E999R4P11), final runtime PID4838. No arm64 device: runtime/output/performance NOT RUN.
- FFmpeg8.1.3 dual-ABI bootstrap/native implementation is the accepted baseline and remains unchanged.

## Architecture / Production Isolation

- Entry `MediaAnalysisInputResolver` supplies owned `ResolvedMediaInput`, opaque stable identity, idempotent release and source-read diagnostics.
- REMOTE_FILE: actual NetworkServerStore lookup → protocol-agnostic NetworkDirectoryService.openSource → RandomAccessSource → one injected shared NetworkFileProxy → localhost PROXY_URL.
- HTTP file links: existing HttpRemoteReadSession → RemoteReadSessionAdapter → same proxy. Native FFmpeg receives neither upstream URL nor credentials.
- SystemMediaProbeAdapter implements unchanged IMediaProbe using existing NetworkMediaProbe/System stage, claiming only positive duration/dimensions with System provenance.
- FfmpegMediaProbeAdapter implements IMediaProbe using real createFfmpegAnalysis, mapper, local numeric errors, LIST/DETAIL/ADVANCED semantics and unique operation IDs.
- FfmpegThumbnailExtractorAdapter implements IThumbnailExtractor and returns raw RGBA. Shared existing SystemWebPEncoder is invoked only by diagnostic harness, quality80; no cache writes or JPEG fallback.
- Target-specific AnalysisComposition makes plugins available; default RuntimeDiagnostics stays no-op. Harness only exists under src/simulator and requires explicit diagnostic launch argument.
- Byte-for-byte baseline diff checks: NetworkMediaLoader, NetworkMediaCache, LinkoraFeatures, all playback code, core public contracts and existing FFmpeg/System/proxy modules unchanged. No production analyzer selection, merger, Auto/System/MPV policy switch or AVIO callback.

## Resolver Matrix

| Input | System | FFmpeg | Lease / cleanup |
| --- | --- | --- | --- |
| HTTP MP4/MKV | Real PASS | Real PASS | Fresh localhost proxy lease per engine, activeSources=0 |
| WebDAV REMOTE_FILE | Real PASS | Real PASS | Actual temporary store row/provider/shared proxy, row removed |
| HLS/DASH network link | Pure support decision only; runtime NOT RUN | Unsupported, pure PASS | System direct URL only; no manifest-only proxy claim |
| LOCAL_DOCUMENT | Unsupported in these adapters | Unsupported, canProbe/canExtract=false | No safe native-path resolution added; existing production local route unchanged |
| Unsafe credential-bearing HTTP / unresolved server | Rejected / error mapping tested | Rejected / error mapping tested | No open in capability checks |
| Resolve/registration error, cancel, late open/register | Pure PASS | Pure PASS | Owned source closes once; late registration released once |

HTTP TS/audio capability branches are supported through the same file resolver but runtime NOT RUN in this fixture matrix. SMB/SFTP/FTP/NFS runtime NOT RUN (x86 native transport boundary unavailable); protocol selection was not rewritten.

## Functional Matrix / Fixture Truth

Owned generated fixtures (host /usr/bin/ffmpeg and ffprobe6.1.1) with hashes and independent truth are in `test-lab/analyzer-integration/phase2/fixture-truth.json`. No commercial samples/downloads. Metadata/cleanup assertions: **352/352 PASS**; actual harness: **39/39 PASS**, failure0.

| Fixture | System DETAIL | FFmpeg | Correctness / completeness |
| --- | --- | --- | --- |
| H264/AAC MP4 | PASS, PARTIAL | PASS, COMPLETE | 640×360,24fps,8bit,codec/profile/audio exact truth; LIST/ADVANCED also exercised |
| HEVC Main/AAC MKV | PASS, PARTIAL | PASS, COMPLETE | Main,8bit,metadata and stream enumeration match |
| HEVC Main10 | PASS, PARTIAL | PASS, COMPLETE | Main10,10bit,yuv420p10le match |
| HDR10 metadata | PASS basics, PARTIAL | PASS, COMPLETE | SMPTE ST2084, BT2020, HDR10 match |
| HLG metadata | PASS basics, PARTIAL | PASS, COMPLETE | ARIB STD-B67, BT2020, HLG match |
| Multi-audio | PASS basics, PARTIAL | PASS, COMPLETE | Two AAC stereo48k tracks, eng/fra and titles match |
| ASS text subtitle | PASS basics, PARTIAL | PASS, COMPLETE | ASS/text,eng,title and counts match |
| Bitmap/PGS subtitle | NOT RUN | NOT RUN | Host has no PGS encoder; no owned bitmap source available |
| Long GOP | PASS, PARTIAL | PASS, COMPLETE | 60.021s,H264/AAC,stream metadata exact truth |
| Existing WebDAV lab remote | PASS, PARTIAL | PASS ADVANCED, COMPLETE | Owned long-GOP file through actual existing guest lab |

Container, duration (100ms tolerance), dimensions/fps, codecs/profiles/depth/pixel format, transfer/primaries/color space, all track counts, generated language/title and subtitle kind checked against host truth. System judged only for claimed fields; empty audio/subtitle arrays represent unknown enumeration rather than true zero. Pure comparator emits MATCH/SYSTEM_MISSING/FFMPEG_MISSING/VALUE_DIFFERENCE/ENGINE_UNAVAILABLE, no field merger or engine ranking.

System H264 LIST COMPLETE; DETAIL/ADVANCED PARTIAL. FFmpeg H264 LIST/DETAIL/ADVANCED COMPLETE and WebDAV ADVANCED COMPLETE. Pure tests cover missing structural fields/PARTIAL/UNAVAILABLE and optional absent chapters/tags. DOVI side-data/BT2020-only conservative mapper tests remain in unchanged baseline suite. Actual DV file/output, HDR display mode, passthrough, Atmos/DTS-HD/TrueHD support NOT RUN/NOT CLAIMED.

## Thumbnail / MediaProxy / Lifecycle

- Both engines: **9/9** real extractions; same requested70% timestamp and 480×270 bounds. All actual frames480×270, 16:9 aspect preserved; no visual pixel-equivalence or exact System decoded PTS claim (existing System uses closest-sync API).
- FFmpeg: rgba_8888, pixels.length=width×height×4, raw read/copy/double-release lifecycle tested. System: existing PixelMap path, actual pixel format recorded. Existing common WebP encoder accepted all **18/18** frames, quality80 and RIFF/WEBP signature validated. No persisted comparison thumbnail or JPEG.
- One shared proxy per harness; independently owned engine leases. activeSources returned0 after each recorded probe/case and final close. Corrupt input, cancel, close-active, timeout and independent concurrent engines were exercised; sourceCloses=1 on stalled-source cleanup.
- System/FFmpeg cancel and close return21005; timeout returns21006. Corrupt System returns22001; corrupt FFmpeg returns23002. Native string errors map to adapter-local numeric contract; notes are bounded and credential-free.
- Cancellation while delayed work rejects and cancellation during pending release: eight observed RED→GREEN pure cases; late output suppressed, raw released, close waits cleanup and new work rejected.
- WebDAV GETs are Range requests. 70% FFmpeg frame: 11 upstream ranges, 2621569 requested bytes of 17855627-byte file, maximum offset17855498; jumps to later offsets with total bytes below half the source. This proves random-access/nonsequential behavior only, not throughput or performance.
- Own lab file removed only after hash/path verification; temporary app server row removed; helper ports19333/19334 and own WSL keeper stopped. Shared protocol services/distro were not stopped.
- Resource claim limited to tested ownership/counters/settled operations. No process-memory leak or memory-efficiency claim.

## Unit / Build Regression

- Adapter/resolver/comparison pure suite **38/38 PASS**; prior FFmpeg pure suite **15/15 PASS**.
- Hypium **202/202 PASS**, Failure0, Error0, Ignore0 (baseline164 plus38). Actual outcomes committed in evidence.
- Native artifact guard **17/17 PASS**, including unknown tenth arm64-library rejection; architecture guards5/5 and complete persistence/network/MPV regressions passed.
- Final `scripts/verify.ps1` exit0, full completion marker. Latest `verify-simulator.ps1` exit0 followed automatic normal ohpm dependency restore; no manual install inserted between simulator/default. Genuine failures retained below and in ledger.

| Artifact | Debug | Release | ABI audit |
| --- | --- | --- | --- |
| linkora_core HAR | PASS | PASS | Full verifier |
| linkora_proxy HAR | PASS | PASS | Full verifier |
| linkora_media_probe HAR | PASS | PASS | Full verifier |
| linkora_ffmpeg HAR | PASS | PASS | Real prebuilt arm64 FFmpeg |
| entry default HAP | PASS | PASS | Exactly9 ELF64 AArch64 (machine183) |
| entry simulator HAP | PASS, installed/launched | NOT RUN | Exactly1 x86_64 FFmpeg ELF (machine62) |

HAP SHA256: Debug `4a0bcdd20e4db5776434a7643f8b490574cd4da8e37847faa6848bc081f44dc3`; Release `5e3dd63972abf38a97ae106e61ed0307f2e08db8393780503526f0409faee2b2`; installed simulator `89a508f86724b6af21a5717ecbe1807762c2f478f98b92109383f21744401c49`. Simulator FFmpeg.so SHA256 `f7a500c641e228753ea066ce7ecefb8b0e0694c6d5ab1bf476e3527b8de1e606` matches accepted baseline. Native-set entries/hashes and verifier commands/exit codes are in artifacts.json. Signing build-profile bytes restored exactly; private signing/raw hilog/binaries not committed. unsigned default HAP signing warning is expected; compiler warnings remain nonblocking.

## Failures / Independent Fix Commits

| Evidence | Original failure / root cause | Minimal correction / retry |
| --- | --- | --- |
| Initial pure run | new NetworkLinkParser().parse is not a function; existing parse is static | Static call,23/23 PASS; included5cbe703 |
| First full verify | ArkTS untyped enum-valued literal; arbitrary-object throw | Explicit error-code switch/AnalysisError,full verify PASS;5cbe703 |
| First simulator compile | RawThumbnail members are methods; proxy requires contentType | Contract-correct callers;962209c +0773d7b,simulator PASS |
| Runtime run1 |38/39; corrupt System yielded empty metadata with error0 |22001 on unusable snapshot;bf42808, subsequent39/39 |
| Intermediate default run | Newly introduced empty-System assertion ran before matching source fix was compiled | Preserved failed attempt; no stale results accepted; fixed source full retry PASS |
| Independent review | Cancelled delayed rejection mapped resolve/open failure; late success during release survived close | Eight reproductions RED→GREEN;a51faf9,38/38 pure and39/39 runtime |
| Reviewed full verification | ArkTS rejects Error-typed callback passed imported FfmpegError at test98/123 |3ec458d interface annotation alone did not fix; corrected diagnosis and actual callback typing ab083e3;full retry202/202 and all builds PASS |

Implementation commits:5cbe703,962209c,0773d7b,53c50bb. Behavioral fixes:bf42808,a51faf9. Test-only typing attempts:3ec458d,ab083e3. Full SHAs available in Git history and execution ledger. No skipped failures or fake lockfile.

## Security / Review / Remaining Gaps

- Final actual process4838 hilog scan:164 own record lines, URL leaks0, endpoint-token leaks0, token occurrences in captured process log0. All functional evidence rejects URL/timing fields before saving; diagnostic exceptions sanitized. Anonymous existing lab only; no credentials in native input or committed evidence.
- One fresh read-only whole-branch review: Critical0; Important cancellation races fixed in one RED→GREEN pass. Deferred minor: stream-count comparison unit assertion can be more explicit; real comparison records already show expected missing-versus-zero semantics. No second review loop.
- Rulings: local-document support deferred for lack of safe existing native path (cost: later resolver review); PGS not run for lack of owned fixture/encoder (cost: open bitmap runtime coverage); native/bootstrap baseline accepted and untouched; production merger/playback/policy and arm64 runtime/output/performance deferred (cost: no production-selection/device conclusion). Final report/regression work set aside by reviewer is completed.
- No architectural blocker found within executed matrix. Device-only performance, output modes, HDR tone mapping/display, DV and high-definition passthrough remain unverified. Protocol-native x86 gaps and PGS/local/streaming-file coverage are explicit NOT RUN.

## Performance Scope / Decision

System-vs-FFmpeg benchmark **NOT RUN**; median/p95 **NOT COLLECTED**; speed/CPU/GPU/memory/power/thermal rankings **NOT CLAIMED**. No Benchmark NDJSON/report was produced. Functional NDJSON and source byte counters are not performance samples. All performance decisions remain deferred to arm64 real device.

**READY FOR ANALYZER POLICY REVIEW**. System basics and FFmpeg structural analysis/raw thumbnails meet this phase's functional evidence requirements. No final merger or default-engine recommendation; optional future policy must account for missing/unknown fields, unsupported input kinds and device evidence. Work stops here; no merge or next-phase development.

## Evidence

Committed directory: `test-lab/analyzer-integration/phase2/` — independent fixture truth, functional NDJSON/checks, sanitized Range ledger, HAP/ELF manifests, actual Hypium results, curated verify markers, security/cleanup, independent review and preserved first genuine runtime failure. Original complete build logs/RED traces and binaries remain ignored under artifacts; no raw sensitive artifacts published.

## Execution ledger

Starting SHA c5429529094d0a8b6c0fbf34e3d22f81b50a41a0, clean isolated branch. Latest runbook fully read. Implementation plan follows authorized existing architecture; pure adapter tests written first and missing resolver implementation RED retained. No performance data/production policy changes. Resolver/probe/thumbnail/comparison → real platform/simulator functional matrix → complete default regression → one independent review/report/commit/stop.

First full verify attempt: ArkTS compiler rejected enum-valued object literal in AnalysisOperation and arbitrary-object throw in FfmpegThumbnailExtractorAdapter. Root causes were integration source syntax incompatible with strict ArkTS. Minimal correction: explicit switch mapping and typed AnalysisError rethrow. Full verify retry phase2-typed-default completed successfully: all HAR/HAP builds and exact 9-library AArch64 audits. Adapter pure tests 23/23 PASS. Simulator matrix remains NOT RUN until real execution below.
Simulator compile attempt found actual RawThumbnail contract uses width()/height()/pixelFormat() methods, and proxy registration requires explicit contentType. Corrected integration callers only; existing contracts and implementations preserved. verify-simulator failure path automatically restored normal dependencies.
Runtime run1: 38/39 cases passed, activeSources=0. System corrupt input returned all-zero snapshot with numeric errorCode=0. Independent adapter unit reproduced 0 != SYSTEM_FAILED(22001) RED. Adapter now rejects entirely unusable System metadata with stable 22001; System stage unchanged. Pure retry 30/30 PASS. Full matrix retry pending. Added cleanup assertion inside System thumbnail finally, including unavailable result path.
Final independent review: no Critical, one Important (cancelled pending rejection lost CANCELLED identity), one Minor (stream-count comparison regression assertion could be more explicit). Review fix pass added eight deterministic cases and watched all eight fail. Also reproduced cancelled success during delayed lease release (three of eight) and graded this Important because close must suppress late results until cleanup finishes. Fixed operation-aware error mapping and post-cleanup cancellation checks; thumbnail discards/releases late raw output. Pure suite 38/38 GREEN. Delayed-release tests prove close stays pending and rejects new work until cleanup finishes. Minor stream-count assertion expansion deferred; implementation is correct and functional comparison records independently confirm unknown System counts versus FFmpeg enumerated counts. Full simulator/default rerun pending for fix source.
Ruling: LOCAL_DOCUMENT adapters remain unsupported — no existing safely resolved native path — cost: local-document integration requires a later reviewed resolver change. Ruling: PGS fixture NOT RUN — no owned bitmap source and host has no PGS encoder — cost: bitmap runtime coverage remains open. Ruling: production analyzer merger/policy and arm64 output/performance are deferred — explicit user/runbook scope — cost: production choice awaits device evidence and architecture review. Accepted bootstrap/native internals remain untouched.
Reviewed simulator retry: 39/39 runtime cases and 352/352 independent functional checks PASS, owned source/temporary server/helper cleaned. Reviewed full default verifier then rejected new multi-engine unit tests at lines98/123 for ArkTS structural typing (inferred conditional concrete classes). Minimal test-only fix: explicitly declare IMediaProbe on the two conditional probe variables; production source unchanged. Full default retry pending, stale prior test_result is not counted for this failed attempt.
Correction to prior compile diagnosis: explicit IMediaProbe annotation alone did not resolve error. Numbered source inspection shows both errors at rejectWork(new FfmpegError(...)), not probe construction. Actual cause is Error-typed callback receiving imported FfmpegError across ArkTS package typing boundary. Callback parameter now explicitly FfmpegError at those two native-error injection sites. Earlier failed compile attempts remain recorded; no stale test result counted.

Final: full native-error-final verifier exit0;202/202 Hypium;38/38 adapter pure;39/39 runtime;352/352 truth/cleanup. Reviewed simulator executed a51faf9; default source ab083e3 includes only test typing corrections after it. Stop for architecture review.
