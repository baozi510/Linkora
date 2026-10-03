# Phase 1 Report — Contracts + Compatibility Adapters

## Phase

Phase 1: Core contract alignment.

## Goal

Introduce the target player/media architecture contracts without changing the current production playback, network browsing, media probe, thumbnail, proxy, database, or UI behavior.

## Files changed

Added:

- `linkora_core/src/main/ets/models/MediaInfo.ets`
- `linkora_core/src/main/ets/contracts/StoragePorts.ets`
- `linkora_core/src/main/ets/contracts/MediaInput.ets`
- `linkora_core/src/main/ets/contracts/MediaAnalysisPorts.ets`
- `linkora_core/src/main/ets/contracts/ThumbnailPorts.ets`
- `linkora_core/src/main/ets/playback/PlaybackBackend.ets`
- `entry/src/test/ArchitectureContracts.test.ets`

Updated:

- `linkora_core/src/main/ets/models/MediaSource.ets`
- `linkora_core/Index.ets`
- `entry/src/test/List.test.ets`

## Existing code reused

- `RemoteReadSession` remains unchanged.
- `RemoteReadSessionAdapter` exposes existing sessions through the new `RandomAccessSource` contract.
- Existing `PlaybackPort` remains unchanged; `PlaybackBackend` extends it for future System/MPV backends.
- Existing `MediaSource` constructors remain compatible.
- Existing `progressiveKey` remains available for migration compatibility.

## New contracts

Storage:

- `SourceCapabilities`
- `RandomAccessSource`
- `StorageProvider`
- `StorageEntry`
- `RemoteReadSessionAdapter`

Input resolution:

- `ResolvedMediaInput`
- `ResolvedMediaInputKind`
- `RequestPolicy`

Media analysis:

- `MediaInfo`
- video/audio/subtitle/chapter models
- `IMediaProbe`
- `ProbeRequirement`
- `ProbeCompleteness`
- `ProbeResult`
- field-origin and diagnostics models

Thumbnail:

- `IThumbnailExtractor`
- `IThumbnailProcessor`
- `IThumbnailEncoder`
- `RawThumbnail`
- extract/process/encode request models

Playback:

- `PlaybackBackend`
- `PlayerBackendKind`
- `PlayerBackendPreference`
- `PlayerBackendCapabilities`

## MediaSource compatibility change

Added the unused-until-migrated `REMOTE_FILE` kind plus optional:

- `sourceId`
- `credentialRef`
- `fingerprint`

Added `MediaSource.fromRemoteFile()`.

The existing positional constructor remains source compatible because all new constructor arguments are appended with defaults.

`progressiveKey` is retained and documented as a legacy migration field.

## Runtime behavior

No production dependency wiring was changed.

The following remain exactly on the existing path:

- System AVPlayer remains the only playback backend.
- NetworkMediaLoader still owns current system probe/thumbnail behavior.
- linkora_proxy behavior is unchanged.
- ProgressiveDownloadRegistry remains unchanged.
- No FFmpeg dependency was added.
- No MPV dependency was added.
- No database schema was changed.
- No UI code was changed.

## Tests

Added architecture-contract tests covering:

- RemoteReadSession -> RandomAccessSource adapter;
- REMOTE_FILE stable identity fields;
- MediaSource identity vs ResolvedMediaInput separation;
- partial ProbeResult with per-field engine origins;
- target thumbnail defaults (480x270 / quality 80);
- playback backend capability defaults.

The test was registered in `entry/src/test/List.test.ets`.

## Validation

- Git diff reviewed after commit.
- Public exports reviewed after commit.
- Existing interface implementations are not required to implement the new contracts in this phase.
- GitHub Actions: no workflow runs are configured/triggered for this commit.

Build status: **NOT BUILD VERIFIED in this environment**.

Device status: **NOT DEVICE TESTED**.

A HarmonyOS toolchain/device build should be run before merging this stack to main.

## Architecture deviations

None intentional.

This phase deliberately does not migrate production call sites yet. That belongs to the next phase.

## Next phase

Phase 2 should productionize storage contracts without rewriting protocol implementations:

1. Adapt WebDAV/SMB/SFTP/FTP/NFS existing services to StorageProvider/RandomAccessSource.
2. Start routing NetworkDirectoryService through a provider/plugin registry.
3. Keep existing direct browser and progressive paths as compatibility fallback.
4. Do not add FFmpeg or MPV yet.
