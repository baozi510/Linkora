# Analysis Benchmark + Policy Phase 7 Report

> Status: FOUNDATION IMPLEMENTED — validation/benchmark execution pending.
> Branch: `feat/analysis-benchmark-policy-phase7`
> Date: 2026-10-06

## Scope

Phase 7A implements benchmark infrastructure and a real-arm64 WebDAV baseline.

It does not change `ProductionMediaAnalysisPolicy`.

## Foundation changes

- debug-only Want-triggered `AnalysisBenchmarkRunner`;
- explicit System vs FFmpeg execution on the same production source path;
- metadata LIST + ADVANCED benchmark records;
- thumbnail extraction + common WebP encode + temporary write records;
- MediaProxy valid HTTP Range GET counter;
- real adapter prepare/probe timing fields;
- NDJSON output and improved summarizer;
- stable `docs/ANALYSIS_BENCHMARK_PHASE7_MANUAL.md`.

## Initial baseline

Target:

- real Mate60 arm64;
- WebDAV source through production storage -> RandomAccessSource -> MediaProxy.

Initial controlled cases:

- H.264/AAC MP4 1280x720 ~20 s;
- HEVC/AAC MKV 1280x720 ~20 s.

Default sampling:

- 2 warm-ups;
- 20 measured repetitions;
- alternating System/FFmpeg order;
- LIST, ADVANCED and thumbnail per engine.

## Policy boundary

No production routing change is authorized until fresh benchmark evidence is independently reviewed.

The two-case WebDAV baseline validates the measurement path and provides preliminary data only. Broader policy claims require a sufficient permanent corpus and source-family coverage.
