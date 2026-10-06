# Analysis Benchmark + Policy — Phase 7 Manual

> Stage: Phase 7A benchmark foundation and real-arm64 WebDAV baseline.
>
> Phase 3 production functional policy is accepted. This phase measures it and its engines; it does not silently rewrite routing while measuring.

## 1. Goal

Collect reproducible real-Mate60 evidence comparing:

```text
System
vs
FFmpeg
```

for the same remote file source.

The initial baseline measures:

- metadata LIST;
- metadata ADVANCED;
- thumbnail extraction + common WebP encode + local write.

Primary decision order:

```text
correctness / success
-> completeness
-> bytes read
-> HTTP Range count
-> latency
-> memory when reliable
```

No x86/simulator performance ranking is allowed.

## 2. Architecture

The benchmark runner must reuse production adapters and transport:

```text
saved NetworkServerEntry
-> NetworkDirectoryService
-> NetworkMediaSourceFactory
-> HarmonyAnalysisInputs
-> MediaAnalysisInputResolver
-> fresh NetworkFileProxy per sample
-> explicit SystemMediaProbeAdapter or FfmpegMediaProbeAdapter
```

Thumbnail:

```text
SystemThumbnailFallback
or FfmpegThumbnailExtractorAdapter
-> SystemWebPEncoder
-> benchmark-local temporary file write
```

`ProductionMediaAnalysisPolicy` is not consulted to select the benchmark engine.

The benchmark must not write production media cache records or alter user media/history.

## 3. Debug-only trigger

A debug build may be started with Want parameter:

`linkoraAnalysisBenchmarkConfig`

Its value is a loopback config endpoint:

```text
http://127.0.0.1:<HDC-reversed-port>/<uuid>
```

The endpoint payload may identify the locally saved benchmark server and fixture paths. It is runtime-private and is not committed.

The runner writes:

```text
<context.cacheDir>/analysis-benchmark-results.ndjson
<context.cacheDir>/analysis-benchmark-state.json
```

Do not expose the config payload in Hilog.

## 4. Phase 7A controlled corpus

Reuse the two already-controlled valid WebDAV fixtures where possible:

1. H.264/AAC MP4, 1280x720, ~20 s.
2. HEVC/AAC MKV, 1280x720, ~20 s.

The runtime config supplies private directory/file mapping.

Example shape:

```json
{
  "schemaVersion": 1,
  "serverName": "runtime-private-name",
  "warmups": 2,
  "repetitions": 20,
  "cases": [
    {
      "caseId": "mp4-h264-aac",
      "directoryPath": "/private/runtime/path",
      "fileName": "h264-aac.mp4",
      "container": "mp4",
      "expectedDurationMs": 20000,
      "expectedWidth": 1280,
      "expectedHeight": 720
    },
    {
      "caseId": "mkv-hevc-aac",
      "directoryPath": "/private/runtime/path",
      "fileName": "hevc-aac.mkv",
      "container": "matroska",
      "expectedDurationMs": 20021,
      "expectedWidth": 1280,
      "expectedHeight": 720
    }
  ]
}
```

Never commit the actual server name/path when private.

## 5. Sampling design

For each case:

1. warm System and FFmpeg before measured samples;
2. run 20 measured iterations by default;
3. alternate engine order every iteration;
4. for each engine collect:
   - metadata LIST;
   - metadata ADVANCED;
   - thumbnail;
5. construct a fresh proxy/resolver/adapter for every measured operation;
6. close/release the operation before the next sample.

This is a crossover baseline to reduce fixed engine-order bias.

Do not run other heavy workloads on the target during the benchmark.

## 6. Metadata metrics

Each record must include:

- engine;
- caseId/container/sourceType;
- requirement;
- correctness;
- success;
- completeness;
- elapsedMs;
- prepareMs;
- probeMs;
- upstream bytesRead;
- upstream readRequests;
- actual proxy HTTP rangeRequests;
- errorCode.

LIST correctness for the baseline fixtures requires duration within 250 ms and exact expected dimensions.

ADVANCED may be PARTIAL on System by design; record that fact rather than forcing a fallback or merger.

## 7. Thumbnail metrics

Use the common `DefaultThumbnailTimePolicy` and quality policy.

Record:

- extraction success/correctness;
- output dimensions;
- extractMs;
- common WebP encodeMs;
- temporary writeMs;
- total elapsedMs;
- upstream bytesRead;
- readRequests;
- HTTP rangeRequests;
- WebP byte size;
- errorCode.

Current adapters do not expose backend-internal seek/decode/resize as separate reliable stages for both engines. Do **not** fabricate those values. Phase 7A records extraction as one stage and leaves deeper stage attribution for later instrumentation only if the baseline shows it is decision-relevant.

## 8. Range metric

`NetworkFileProxyDiagnostics.rangeRequests` is the count of valid GET requests that:

- carry a Range header; and
- resolve to HTTP 206.

It is distinct from:

- `readRequests`: upstream `RandomAccessSource.readAt` calls;
- `bytesRead`: upstream bytes delivered.

Do not label `readRequests` as HTTP Range count.

## 9. Memory

`memoryBytes` is nullable in Phase 7A.

If a stable target-side process-memory collection method is available, collect it as separate evidence with exact method and sampling points.

If not, keep `memoryBytes = null`.

Never coerce unavailable memory to zero.

The WebDAV baseline cannot justify a final policy solely on latency when required memory evidence or broader corpus evidence is still missing.

## 10. Statistical output

Use:

```powershell
node scripts/summarize-benchmark.cjs <results.ndjson> <report.md>
```

Review:

- sample count;
- success rate;
- complete rate;
- P50;
- P95;
- average bytes;
- average HTTP Range count;
- thumbnail encode/write/WebP size.

Do not delete outliers merely because they are inconvenient.

If a sample is invalid due to an environment event, retain it in raw evidence and explain any exclusion in a separate reviewed derived report.

## 11. Security

Committed records must not contain:

- Authorization;
- Cookie;
- passwords;
- private server name;
- private upstream URL/path;
- proxy token;
- device private identifier;
- signing material.

Case IDs should be generic permanent corpus IDs.

## 12. Phase 7A decision boundary

The first two-case WebDAV baseline can establish:

- benchmark runner correctness;
- whether System/FFmpeg differences are measurable on real arm64;
- preliminary LIST/ADVANCED/thumbnail tradeoffs.

It does **not** automatically authorize:

- changing production policy;
- adding a field merger;
- implementing Direct I/O;
- claiming SMB/Local performance;
- claiming broad codec superiority.

After evidence is pushed, GPT independently reviews it.

Possible next decisions:

1. runner/instrumentation defect -> GPT fixes benchmark infrastructure;
2. baseline valid but corpus insufficient -> expand permanent corpus/source families;
3. data strongly supports a narrow policy change -> GPT makes the policy change and dispatches functional regression validation;
4. MediaProxy is not shown to be a bottleneck -> Direct I/O remains deferred.

## 13. Phase completion

Phase 7 is not complete merely because Phase 7A runs.

Final Analysis Benchmark + Policy acceptance requires a reviewed corpus sufficient for the actual policy decisions being made.

No policy is changed by the benchmark runner itself.
