# Phase 6 Report — MPV + Adaptive Dual Backend Foundation

## Phase

Phase 6: add the first MPV backend, adaptive backend selection, remote playback resolution through MediaProxy, and user backend preference.

## Implemented

### MPV dependency

Entry now declares:

`@mpv-ohos/mpv-arkts: 1.0.0`

The upstream public package currently supports arm64-v8a only, so the entry ABI filter was reduced to arm64-v8a.

The generated `entry/oh-package-lock.json5` was intentionally not hand-edited. Run `ohpm install` in a real HarmonyOS development environment to resolve and regenerate the lockfile.

### MpvPlaybackPort

Maps Linkora PlaybackPort behavior to mpv-arkts:

- existing XComponent surfaceId -> `player.native.attachSurface()`
- open / prepare
- play / pause
- absolute seek
- playback rate
- volume
- duration / position
- buffering state / percent / cached duration
- first playback restart as first-frame signal
- video size
- EOF / error
- release / detach

MPV uses milliseconds at the Linkora boundary and seconds internally.

### SystemPlaybackPort

Now implements `PlaybackBackend` and declares a conservative capability baseline.

Its legacy progressive-input branch remains available for migration compatibility, but new network browser opens no longer create progressive downloads.

### AdaptivePlaybackPort

Introduced a backend coordinator with:

- Auto / System / MPV preference
- baseline selector
- one-shot fallback in Auto mode
- no fallback when the user explicitly forces System or MPV
- candidate-event gating so a failed backend does not leak its prepare/error events into the active PlaybackEngine session
- resolved remote-source lease ownership

The current Auto selector is intentionally conservative and temporary:

- MP4 / HLS / DASH -> System baseline
- Matroska / other complex or unknown formats -> MPV baseline

This is not the final policy. Later playback/analysis benchmark data should replace it.

### Remote playback

Network browser file opens now create a stable `MediaSourceKind.REMOTE_FILE` instead of creating a temporary progressive-download file.

Playback resolution:

```text
REMOTE_FILE
    ↓
NetworkServerStore
    ↓
NetworkDirectoryService
    ↓
RandomAccessSource
    ↓
shared MediaProxy
    ↓
localhost URL
    ↓
System or MPV
```

The ProxyUrlLease belongs to the playback port and is released with the playback session.

Existing `ProgressiveDownloadRegistry` code remains in the repository for rollback/migration compatibility but is no longer the new NetworkDirectoryBrowser open path.

### Settings

Added persisted player backend preference:

- Auto
- System
- MPV

Preferences schema bumped to 8.

Player settings UI exposes all three choices.

## Important limitations

### arm64 only

Current public mpv-arkts is arm64-v8a only. x86_64 emulator builds are therefore no longer a supported target for this branch.

### Package lock

The package lock is stale until `ohpm install` is run. It is generated data and was not manually fabricated.

### Surface size

The upstream mpv PlayerSurface calls:

`native.setProperty("ohos-surface-size", "<width>x<height>")`

when its XComponent surface changes size.

Linkora currently reuses its existing XComponent surfaceId directly, but the PlaybackPort contract does not yet forward surface-size changes. This is a known integration item for the next playback-contract phase.

### MPV error stream

mpv-arkts forwards log-level error messages to `Player.stream.error`. The current MVP maps that stream to Linkora playback errors. This should be validated against real media because some mpv error-level log lines may not be session-fatal.

## FFmpeg analysis

FFmpeg analysis was not implemented in this phase. See `docs/FFMPEG_INTEGRATION_BLOCKER.md`.

## Validation

- upstream mpv-arkts API reviewed against the adapter
- post-commit source review performed
- selector/settings unit tests added

GitHub Actions: no configured/triggered workflow.

Build status: **NOT BUILD VERIFIED**.

Device status: **NOT DEVICE TESTED**.

A real DevEco/Hvigor arm64 build and `ohpm install` are required before merging this phase to main.
