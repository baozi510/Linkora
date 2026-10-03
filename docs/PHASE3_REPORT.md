# Phase 3 Report — Split System Metadata and Thumbnail Stages

## Phase

Phase 3: separate the System media metadata stage from the System thumbnail extraction stage while preserving the existing network-probe behavior.

## Goal

Remove the direct metadata/frame responsibilities from the compatibility facade without causing a remote BOTH inspection to open the source twice.

## Added

### SystemMediaProbe

`linkora_media_probe/src/main/ets/SystemMediaProbe.ets`

Responsibilities:

- call `AVMetadataExtractor.fetchMetadata()`
- normalize duration / width / height
- return a small System metadata result

It does not:

- create/release the extractor
- own URL/header setup
- own timeout/cancellation
- extract thumbnails
- encode/cache images

### SystemThumbnailExtractor

`linkora_media_probe/src/main/ets/SystemThumbnailExtractor.ets`

Responsibilities:

- choose the current compatibility frame time
- call `fetchFrameByTime()`
- return PixelMap + extraction coordinates

It does not:

- fetch metadata
- encode WebP/JPEG
- write cache files
- own the long-term thumbnail time policy
- own extractor lifecycle

## Compatibility facade

`NetworkMediaProbe` remains public and keeps its existing API.

It still owns:

- URL/header validation
- one active job
- timeout
- cancellation
- extractor creation/release
- PixelMap cleanup
- phase timings

For `ProbeMode.BOTH`, one `AVMetadataExtractor` is still shared:

```text
create extractor once
      ↓
SystemMediaProbe
      ↓
same extractor
      ↓
SystemThumbnailExtractor
      ↓
release once
```

This avoids a regression where splitting responsibilities would double remote opens/Range traffic.

## Existing behavior intentionally preserved

The compatibility facade still uses the existing thumbnail compatibility settings:

- 224x126 requested frame
- near-1-second frame selection
- same ProbeStatus values
- same MediaProbeResult shape
- same timeout
- same cancellation/release semantics

The new project-wide thumbnail policy (480x270 fit, WebP quality 80, duration-based time policy) is intentionally not activated in this phase. That belongs to the dedicated thumbnail pipeline migration.

## Tests

Added `SystemMediaStages.test.ets` covering:

- metadata extraction independently of lifecycle ownership
- thumbnail extraction independently of encoding/cache
- frame timestamp calculation
- target dimensions

Existing `NetworkMediaProbe.test.ets` remains registered and should continue to validate:

- metadata survives frame failure
- metadata failure skips frame
- cancel during extractor creation
- late frame cleanup
- successful frame ownership transfer
- unsafe URL/header rejection
- close idempotency

## Deliberately unchanged

- no FFmpeg
- no MPV
- no NetworkMediaLoader behavior change
- no WebP pipeline change
- no NetworkMediaCache change
- no thumbnail algorithm change
- no database change
- no MediaProxy change

## Validation

Post-commit source review completed.

GitHub Actions: no workflow is configured/triggered for this commit.

Build status: **NOT BUILD VERIFIED in this environment**.

Device status: **NOT DEVICE TESTED**.

## Next phase

The next migration should introduce the real Thumbnail Pipeline and move encoding/cache policy out of `NetworkMediaLoader`:

1. ThumbnailTimePolicy
2. ThumbnailProcessor
3. WebP encoder abstraction
4. ThumbnailCache adapter
5. 480x270 fit default
6. quality 80
7. algorithmVersion in cache key
8. remove new JPEG generation while retaining legacy JPEG read compatibility
