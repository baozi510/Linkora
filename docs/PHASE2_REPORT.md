# Phase 2 Report — Network Storage Provider Registry

## Phase

Phase 2: productionize the storage contract around the existing network protocol implementations.

## Goal

Route production network directory access through a single provider abstraction without rewriting the existing WebDAV/SMB/SFTP/FTP/NFS protocol code.

## Main changes

### Core storage contract

`StorageProvider` is now bound to one logical storage account/server and operates on provider-relative locators:

- `stat(locator)`
- `list(locator, options)`
- `open(locator)`

Added:

- `StorageListOptions`
- `RandomAccessSourceSessionAdapter`

The two compatibility adapters now allow migration in both directions:

```text
RemoteReadSession
        ↓
RemoteReadSessionAdapter
        ↓
RandomAccessSource
```

and, for legacy call sites:

```text
RandomAccessSource
        ↓
RandomAccessSourceSessionAdapter
        ↓
RemoteReadSession
```

## New production registry

Added:

- `NetworkStorageProvider`
- `NetworkStorageProviderRegistry`
- `NetworkStorageOpenOptions`
- default providers for WebDAV / SMB / SFTP / FTP / NFS
- an HTTP compatibility provider for the existing direct-stream behavior

The provider registry is keyed by `RemoteProtocol`.

## Existing code reused

No protocol transport was reimplemented.

The following existing classes remain the real protocol implementations:

- `WebDavBrowserService`
- `SmbBrowserService`
- `SftpBrowserService`
- `FtpBrowserService`
- `NfsBrowserService`
- `HttpRemoteReadSession`
- `NativeRemoteReadSession`

Provider adapters translate their current entry/read APIs into:

- `StorageEntry`
- `RandomAccessSource`
- `SourceCapabilities`

## NetworkDirectoryService

The service no longer contains protocol-specific branches for:

- list
- initial path
- display path
- directory normalization
- download
- direct file URL
- open reader
- cache prefix
- cancel

It now resolves one provider from the registry and delegates those operations.

The public `NetworkDirectoryService` API is unchanged, so current callers continue to work.

## Behavior preserved

WebDAV:

- existing PROPFIND implementation remains unchanged
- existing Basic auth behavior remains unchanged
- existing HTTP Range reader remains unchanged
- directory path normalization remains unchanged

SMB/SFTP/FTP/NFS:

- existing native browser implementations remain unchanged
- existing native positioned read implementations remain unchanged
- setup-observer behavior remains preserved
- SFTP expected host fingerprint is forwarded through `NetworkStorageOpenOptions`

HTTP:

- remains a direct-stream compatibility source
- directory browsing remains unsupported
- `openReader()` preserves the previous direct-URL error behavior

## Source capabilities

Current provider adapters declare:

WebDAV:

- seekable
- size known
- random byte range capable
- reopenable
- direct URI available

SMB/SFTP/FTP/NFS:

- seekable
- size known
- positioned random read capable
- reopenable
- no direct URI fast path declared

These capabilities describe the current reader implementations; they are not player capability claims.

## Tests

Added `NetworkStorageProvider.test.ets` covering:

- protocol -> provider registry resolution
- `NetworkDirectoryService` routing through an injected provider
- force-refresh option forwarding
- SFTP-style expected fingerprint forwarding path
- StorageEntry -> NetworkDirectoryEntry mapping
- RandomAccessSource -> legacy RemoteReadSession migration adapter
- cancel/close ownership propagation

Registered the test in `entry/src/test/List.test.ets`.

## Deliberately unchanged

- no FFmpeg
- no MPV
- no player backend selection
- no database schema change
- no media analysis split yet
- no thumbnail pipeline change
- no MediaProxy behavior change
- no removal of ProgressiveDownloadRegistry
- no changes to native SMB/SFTP/FTP/NFS libraries

## Validation

Post-commit diff and source review completed.

GitHub Actions: no workflow run is configured/triggered for this commit.

A direct container clone/build could not be performed because the execution environment cannot resolve github.com.

Build status: **NOT BUILD VERIFIED in this environment**.

Device status: **NOT DEVICE TESTED**.

Before merging the stacked branch to main, run the existing HarmonyOS build/unit tests in DevEco/Hvigor.

## Next phase

Phase 3 should split the current System media analysis path without changing the UI:

1. create `SystemMediaProbe`
2. create `SystemThumbnailExtractor`
3. introduce `MediaProbeService`
4. introduce `ThumbnailService`
5. keep `NetworkMediaProbe` as a temporary compatibility facade
6. migrate `NetworkMediaLoader` away from directly owning probe engine selection
7. do not add FFmpeg yet
