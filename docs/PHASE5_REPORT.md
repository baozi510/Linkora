# Phase 5 Report — Shared Random-Access MediaProxy

## Phase

Phase 5: promote the existing loopback proxy from a per-job experimental transport to shared production infrastructure for media analysis.

## Main changes

### RandomAccessSource-first proxy

The primary proxy API is now:

`buildSourceUrl(source: RandomAccessSource, contentType)`

The existing:

`buildProxyUrl(reader: RemoteReadSession, contentType)`

remains as a migration facade and wraps the reader through `RemoteReadSessionAdapter`.

### Shared lifecycle

`LinkoraFeatures` now owns one shared proxy for production NetworkMediaLoader instances.

Network media analysis no longer creates and closes one TCP listener for every metadata/thumbnail job.

Explicit tools/tests can still call `createNetworkFileProxy()` to get an isolated instance.

### NetworkDirectoryService

Added `openSource()` as the new RandomAccessSource-first API.

Existing `openReader()` remains and delegates through `RandomAccessSourceSessionAdapter`.

### Diagnostics

NetworkFileProxy now exposes:

- activeSources
- activeClients
- readRequests
- bytesRead
- releasedSources

NetworkMediaLoader logs per-job proxy deltas:

- proxyBytesRead
- proxyReadRequests

This provides the core metrics required by the later System-vs-FFmpeg analysis benchmark.

### Configuration

Added `NetworkFileProxyConfig` for:

- blockSizeBytes
- timeoutMs
- maxSources
- maxClients

Upstream reads remain capped at 256 KiB because the current RemoteReadSession implementations enforce that bound. A larger speculative read-ahead cache is intentionally not implemented yet.

## Existing behavior preserved

- loopback-only binding
- random token URLs
- GET / HEAD
- HTTP Range
- 200 / 206 / 416
- Content-Length
- Content-Range
- Accept-Ranges
- per-source serialized reads
- cancellation ownership
- source lease cleanup
- legacy RemoteReadSession callers

## Deliberately unchanged

- no FFmpeg
- no MPV
- no disk segment cache
- no speculative L1 read-ahead beyond requested HTTP Range
- progressive playback remains available
- player still uses System AVPlayer only

## Validation

Post-commit source/diff review completed.

GitHub Actions are not configured/triggered for this repository.

Build status: NOT BUILD VERIFIED in this environment.

Device status: NOT DEVICE TESTED.

## Next phase

Phase 6 should add the FFmpeg analysis implementation only after its Native build/dependency path is pinned and reproducible. It must not expose AVFormatContext/AVFrame to ArkTS and remote input should initially use MediaProxy URL.
