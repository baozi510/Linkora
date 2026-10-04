# FFmpeg analyzer Phase2 implementation plan

> Execute inline with superpowers:executing-plans. The user's explicit instruction to execute the existing runbook is authorization for its specified adapters and functional tests; no new architecture/policy design is proposed.

Goal: functional System/FFmpeg analysis plugins over the same leased input, without production selection changes.

Spec: docs/CODEX_FFMPEG_ANALYZER_INTEGRATION_PHASE2.md (fully read at starting SHA c5429529094d0a8b6c0fbf34e3d22f81b50a41a0).

Architecture: pure entry/analysis resolver, lease and adapters; platform input/backend composition separate; simulator-only comparison runner. Inject one shared proxy, create fresh leases and independent engine instances. Use existing core contracts, FFmpeg mapper/raw frame and System NetworkMediaProbe/SystemWebPEncoder.

Global constraints: no native FFmpeg protocol/auth knowledge; no public contract changes; no production loader/cache/playback policy changes; no AVIO callbacks; raw RGBA, existing WebP encoder; no timing/median/p95/CPU/GPU/power ranking; arm64 performance deferred.

Review focus / tests: cancellation during delayed open and proxy registration; cancelled native success arriving late; close waits cleanup before allowing new work; ambiguous missing metadata vs true zero stream counts; token/locator-bearing exceptions never enter diagnostics. Pin these in deterministic tests and real cancellation/cleanup smoke.

## Task 1 — resolver, adapters, pure comparison

Files: entry/src/main/ets/analysis/{AnalysisOperation,MediaAnalysisInputResolver,FfmpegMediaProbeAdapter,SystemMediaProbeAdapter,FfmpegThumbnailExtractorAdapter,MediaAnalysisComparison}.ets; entry/src/test/MediaAnalysisAdapters.test.ets; List.test.ets; scripts/check-ffmpeg-phase1.cjs; verify.ps1.

Interfaces: resolver.resolve(MediaSource, engine, AnalysisOperation) returns owned AnalysisInputLease with ResolvedMediaInput, stable identity, access counters and idempotent release. Adapters implement unchanged IMediaProbe/IThumbnailExtractor. Pure comparison classifies MATCH/SYSTEM_MISSING/FFMPEG_MISSING/VALUE_DIFFERENCE/ENGINE_UNAVAILABLE, no timing fields and no merged result.

- [x] Write deterministic tests first; run --phase2 and retain missing implementation RED.
- [x] Implement supported source kinds without opening in canProbe; network file HTTP via RandomAccessSource/proxy, REMOTE_FILE via storage registry, HLS/DASH System network-only, unresolved local document unsupported.
- [x] Implement unique IDs, stable numeric error mapping, LIST/DETAIL/ADVANCED completeness, conservative System dimensions-only provenance, raw-frame lifecycle.
- [x] Verify tests GREEN and register in Hypium/full verify; commit coherent source changes.

## Task 2 — platform composition and real functional comparison

Files: entry/src/main/ets/analysis/{HarmonyAnalysisInputPorts,HarmonySystemAnalysisBackend}.ets; target AnalysisComposition.ets; simulator diagnostics/RuntimeDiagnostics; host lab/collector scripts.

- [x] Bind NetworkServerStore → NetworkDirectoryService.openSource, HttpRemoteReadSession → adapter, and existing shared proxy; no protocol if/else.
- [x] Bind real native factory through target composition and existing System implementation, preserving production isolation guards.
- [x] Generate original fixtures with host FFmpeg and independent ffprobe truth: H264/AAC, HEVC Main/Main10, PQ, HLG, multiaudio, text subtitle, long GOP; attempt bitmap toolchain and record NOT RUN if unavailable.
- [x] Build/sign/install simulator safely; run both real IMediaProbe engines independently, same bounds/time thumbnails, shared WebP diagnostic, corrupt/unsupported input, cancel/close and remote70% random-access cleanup. No latency samples, no performance comparison.
- [x] Preserve all FAILs and real results; commit harness/platform integration separately.

## Task 3 — final regression, evidence and review

- [x] Full simulator verifier (automatic dependency restore) then full default verify; exact9 AArch64 Debug/Release, Hypium >=164, no skipped failure.
- [x] Security/protected-path checks; own lab/fixture/server-record cleanup. Source manifests and sanitized functional records only, no binary/signing/private hilog.
- [x] One fresh whole-branch independent review, one justified Critical/Important fix pass with RED/GREEN if required; no review loop.
- [x] Finish docs/FFMPEG_ANALYZER_INTEGRATION_REPORT.md, final small commits/push, clean status. Stop for analyzer policy review, no merge or production selection.

Preflight: resolver ownership is consumed by both probes and thumbnail adapter; native ports preserve numeric public ProbeResult errorCode and native string errors map locally. Comparator consumes only structural fields and known/unavailable semantics, never timing. No core contract change is required. User runbook is binding if the execution details need correction; record rulings in the report.
