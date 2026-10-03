# Phase 4 Report — WebP Thumbnail Pipeline

## Phase

Phase 4: move thumbnail policy, WebP encoding and new thumbnail persistence out of NetworkMediaLoader.

## Added

- `DefaultThumbnailTimePolicy`
- `ThumbnailPlan`
- `SystemWebPEncoder`
- `NetworkThumbnailCache`
- explicit thumbnail plan callback support in `NetworkMediaProbe`
- `SystemThumbnailExtractor.extractAt()`
- thumbnail policy unit tests

## Default thumbnail policy

- duration < 30 seconds: frame at 20%
- duration >= 30 seconds: min(duration * 10%, 60 seconds)
- bounding box: 480 x 270
- fit mode: aspect ratio preserved
- quality: 80
- algorithmVersion: 1

Examples:

- 1920x1080 -> 480x270
- 3840x1600 -> 480x200
- 1080x1920 -> 152x270

## WebP

Newly generated network-video thumbnails are encoded only as WebP.

`SystemWebPEncoder` checks ImagePacker supported formats and fails the thumbnail operation if WebP encoding is unavailable. It does not generate a new JPEG fallback.

This is intentional: persistent video thumbnails follow the latest project rule that WebP is the canonical new format.

## Legacy compatibility

Existing `NetworkMediaCache` records can still read prior WebP/JPEG thumbnails.

If a legacy image exists and decodes successfully it can still be displayed.

New generation is stored through the new `NetworkThumbnailCache` as `.webp`.

## Cache identity

The new thumbnail cache key includes:

- server id / updatedAt / protocol
- path / size / modifiedAt
- frame time
- target width / height
- quality
- algorithmVersion

This prevents a thumbnail algorithm or rendering-size change from silently reusing an incompatible old image.

## Metadata separation

`NetworkMediaCache` remains the current metadata compatibility store.

New thumbnail bytes are no longer persisted through that metadata store. The job result can carry WebP bytes transiently for immediate display, while metadata persistence remains image-free.

## Remote open efficiency

`NetworkMediaProbe` gained a caller-provided thumbnail plan callback. In BOTH mode the callback is evaluated after metadata is known, so the caller can select the correct frame time and fit size without opening the remote source twice.

## Tests

Added policy tests for:

- short-video 20% timing
- 60-second cap
- 16:9 sizing
- ultrawide sizing
- portrait sizing
- quality / algorithm version defaults

## Deliberately unchanged

- no FFmpeg
- no MPV
- no MediaProxy lifecycle change yet
- no DB schema change
- existing local PhotoAccessHelper thumbnail fast path unchanged
- legacy cache schema unchanged

## Validation

Post-commit diff review completed.

GitHub Actions are not configured/triggered for this branch.

Build status: NOT BUILD VERIFIED in this environment.

Device status: NOT DEVICE TESTED.

## Next phase

Phase 5:

1. make MediaProxy shared instead of one listener per media-analysis job
2. expose RandomAccessSource-first registration
3. preserve RemoteReadSession compatibility
4. add proxy diagnostics for bytes/read requests/active sources
5. route NetworkMediaLoader through the shared proxy
6. keep progressive playback as fallback until the player migration
