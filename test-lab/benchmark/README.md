# Linkora Benchmark Lab

This directory defines the stable benchmark data format for media analysis and playback.

## Goals

The benchmark must answer:

1. Which analysis engine succeeds more often?
2. Which engine returns the required fields?
3. How many remote bytes and Range requests are consumed?
4. What are P50/P95 latency values?
5. Which playback backend has better first-frame/seek/buffering behavior?
6. Which backend preserves required HDR/audio/subtitle behavior?

## Record format

Write one JSON object per line to an NDJSON file.

Example:

```json
{"operation":"playback.first_frame","engine":"mpv","sourceType":"webdav","caseId":"mkv-hevc-main10","success":true,"elapsedMs":842,"bytesRead":4194304,"rangeRequests":18}
```

Supported operation names:

- analysis.metadata
- analysis.thumbnail
- playback.first_frame
- playback.seek
- playback.long_run

Recommended fields:

- operation
- engine
- sourceType
- caseId
- container
- success
- elapsedMs
- bytesRead
- rangeRequests
- memoryBytes
- cpuPercent
- bufferingCount
- bufferingMs
- notes

Never include credentials, Authorization headers, signed URLs, cookies or passwords.

## Summarize

```powershell
node scripts/summarize-benchmark.cjs test-lab/benchmark/results.ndjson test-lab/benchmark/report.md
```

The generated report groups by operation / engine / source type and reports:

- count
- success rate
- P50 latency
- P95 latency
- average bytes read
- average Range requests

## Required sources

Run the same media case through:

- Local
- WebDAV
- SMB

Optional after baseline:

- SFTP
- FTP
- NFS

## Decision priority

For remote media analysis:

1. success rate
2. required-field completeness
3. bytes read
4. Range request count
5. latency
6. CPU
7. memory

For playback:

1. correctness
2. success rate
3. first-frame latency
4. seek P95
5. buffering
6. CPU/memory/power
