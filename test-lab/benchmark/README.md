# Linkora Benchmark Lab

This directory defines the stable benchmark data format for media analysis and playback.

## Current analyzer stage

The active analyzer benchmark is **Phase 7A: real-arm64 benchmark foundation + WebDAV baseline**.

It must not change `ProductionMediaAnalysisPolicy` while collecting data.

Read:

- `docs/ANALYSIS_BENCHMARK_PHASE7_MANUAL.md`
- current `docs/CODEX_VALIDATION_TASK.md`

## Goals

The analysis benchmark must answer, for the same source and corpus:

1. Which engine succeeds correctly more often?
2. Which engine returns the required fields completely?
3. How many upstream bytes are read?
4. How many localhost HTTP Range GET requests are generated?
5. What are P50/P95 operation latencies?
6. What are thumbnail extraction, WebP encode and local write costs?
7. What memory cost can be measured reliably on the target?

The first WebDAV baseline is not sufficient by itself to finalize all long-term policies. The permanent matrix remains in `cases.json` and later expands to Local/SMB and advanced media.

## Record format

Write one JSON object per line to an NDJSON file.

Analysis metadata example:

```json
{"operation":"analysis.metadata","engine":"ffmpeg","sourceType":"webdav","caseId":"mp4-h264-aac","requirement":"list","iteration":0,"success":true,"correct":true,"completeness":"complete","elapsedMs":120,"prepareMs":35,"probeMs":82,"bytesRead":524288,"readRequests":2,"rangeRequests":2,"memoryBytes":null}
```

Thumbnail example:

```json
{"operation":"analysis.thumbnail","engine":"system","sourceType":"webdav","caseId":"mp4-h264-aac","requirement":"thumbnail","iteration":0,"success":true,"correct":true,"completeness":"complete","elapsedMs":210,"extractMs":160,"encodeMs":35,"writeMs":2,"bytesRead":1048576,"readRequests":4,"rangeRequests":3,"webpBytes":7102,"memoryBytes":null}
```

### Metric semantics

- `elapsedMs`: monotonic target-side wall duration for the measured operation.
- `prepareMs`: resolver/open/proxy preparation measured by the probe adapter.
- `probeMs`: engine metadata probe duration.
- `extractMs`: thumbnail extraction duration. Current baseline does not falsely split seek/decode/resize when the backend does not expose those stages separately.
- `encodeMs`: common WebP encoder duration.
- `writeMs`: app-cache file write call duration for the benchmark output.
- `bytesRead`: upstream bytes read through the benchmark-owned MediaProxy.
- `readRequests`: upstream RandomAccessSource read calls.
- `rangeRequests`: actual valid HTTP GET requests carrying a Range header and served as 206 by MediaProxy.
- `memoryBytes`: nullable. Missing memory instrumentation is recorded as unavailable, never as zero.

Never include credentials, Authorization headers, signed URLs, cookies, passwords, private server names or private paths in committed benchmark records.

## Sampling

For a real-device baseline:

- at least 1 warm-up per engine/case;
- at least 5 measured repetitions;
- Phase 7A default: 2 warm-ups and 20 measured repetitions;
- alternate engine order by iteration to reduce order bias;
- use the same exact media source for System and FFmpeg;
- do not mix simulator/x86 samples into arm64 summaries.

## Summarize

```powershell
node scripts/summarize-benchmark.cjs results.ndjson report.md
```

The report groups by operation / requirement / engine / source and also by case.

## Permanent corpus

`cases.json` remains the long-term matrix:

- MP4 H264 AAC
- MP4 HEVC AAC
- MKV H264
- MKV HEVC
- HEVC Main10
- HDR10 / HLG / Dolby Vision
- AC3 / EAC3 / DTS / DTS-HD MA / TrueHD
- ASS / PGS
- multi-audio / multi-subtitle
- long-GOP
- 4K remux
- broken/unusual container

Target source families are Local, WebDAV and SMB.

Phase 7A starts with the already-controlled WebDAV MP4 H264/AAC and MKV HEVC/AAC cases. That baseline is enough to validate the benchmark machinery, **not enough to rewrite every policy**.

## Decision priority

For remote media analysis:

1. correctness / success rate
2. required-field completeness
3. bytes read
4. Range request count
5. latency
6. memory

For thumbnail analysis, include output correctness and WebP size before latency optimization.

Any policy change is a separate reviewed step after the benchmark evidence is pushed.
