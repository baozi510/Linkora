# ARM64 Device Validation Runbook

> Source baseline: `test/player-architecture-validation`
> Required validated code baseline: `7621608b4acce6daa5d7d399bb1feb8ddc384524` or a later documentation-only commit.
> Do not merge before this runtime pass.

## Purpose

This is the next validation stage after desktop/Hvigor verification.

Desktop/build validation is accepted:

- full `verify.ps1`: PASS
- Hypium: 145/145 PASS
- architecture fixtures: 5/5 PASS
- MPV adapter desktop regression: 5/5 PASS
- Debug/Release HAR: PASS
- Debug/Release arm64 HAP: PASS

The x86_64 emulator cannot install the current arm64-v8a HAP and is not a valid MPV/native runtime target.

The next task requires a **real arm64 HarmonyOS device**.

## Branch

Continue on:

`test/player-architecture-validation`

Do not modify:

- `main`
- Phase 0–8 branches

Do not merge PR #10 during runtime validation.

## Before testing

Read:

1. `docs/SESSION_HANDOFF.md`
2. `docs/VALIDATION_REPORT.md`
3. `docs/TEST_MANUAL.md`
4. this file
5. `docs/FFMPEG_INTEGRATION_BLOCKER.md`

Confirm the working tree is clean.

Run:

```powershell
git fetch --all
git checkout test/player-architecture-validation
git status
ohpm install
./scripts/verify.ps1
```

Do not start device testing if `verify.ps1` fails.

## Device record

Before installation, record in `docs/VALIDATION_REPORT.md`:

- device model
- SoC if known
- HarmonyOS version/build
- CPU ABI
- display HDR capability if known
- network type
- whether TV/AVR/external display is connected
- installation/signing method

Confirm device ABI is arm64/aarch64.

## Signing and installation

Produce a signed Debug HAP using the normal project signing flow.

Do not:

- commit signing passwords
- commit private certificates/keys
- place signing secrets in validation logs

Install the exact current validation build.

Record:

- source commit SHA
- HAP SHA256
- install result

## Stage 1 — app launch and navigation

Verify:

- cold launch
- navigation to player
- settings page
- Auto/System/MPV selector
- return/back
- reopen player

Result must be recorded as PASS / FAIL.

## Stage 2 — System backend smoke

Force:

`播放器内核 = 系统`

Minimum media:

1. local H.264/AAC MP4
2. local HEVC/AAC MP4
3. HTTPS H.264/AAC MP4
4. WebDAV H.264/AAC MP4

For every case verify:

- prepare
- first frame
- play
- pause
- seek 50%
- seek 90%
- resume after seek
- completion
- replay
- release

Record:

- prepare time
- first-frame time
- seek time
- visible/audio errors

Do not infer unsupported formats as application bugs until the backend error is identified.

## Stage 3 — MPV backend smoke

Force:

`播放器内核 = MPV`

Minimum media:

1. local H.264/AAC MP4
2. local MKV H.264
3. local MKV HEVC
4. WebDAV MKV
5. SMB MKV

Verify:

- surface attach
- actual visible frame
- surface resize/fullscreen
- first frame
- play/pause
- 50% seek
- 90% seek
- seek-complete state restoration
- buffering
- EOF
- release

Important:

The recent desktop fix changed MPV `stream.error` handling.

During runtime, specifically record:

- error-level mpv log messages
- whether playback continues after recoverable error log lines
- whether a true open failure now waits for the 12-second prepare timeout
- whether timeout diagnostics are useful but do not expose credentials

If actual MPV runtime exposes a better structured failure signal, document evidence; do not redesign on assumption alone.

## Stage 4 — Auto backend

Set:

`播放器内核 = 自动`

Verify at least:

- ordinary MP4 expected System candidate
- MKV expected MPV candidate
- one deliberately unsupported System case if available

Confirm:

- selected backend is shown/observable in diagnostics
- failed candidate does not leak duration/tracks/HDR/error into committed session
- only one fallback occurs
- forced System never auto-falls back
- forced MPV never auto-falls back

Do not tune the selector yet.

## Stage 5 — Surface lifecycle

The post-validation fix connected:

```text
PlayerPage
→ PlayerFeatureController
→ PlaybackEngine
→ AdaptivePlaybackPort
→ backend
```

Explicitly test:

- portrait open
- rotate/fullscreen
- return from fullscreen
- background/foreground
- detach/recreate surface
- reopen another file

For MPV watch for:

- stretched output
- 1x1 output that never resizes
- black frame after rotation
- stale frame
- crash in surface detach
- old-session events after reopen

Run at least 20 repeated open/close cycles during this stage.

## Stage 6 — remote MediaProxy

Use WebDAV and SMB.

For each:

- open file
- play for 30 seconds
- seek to 50%
- seek to 90%
- close

Collect actual proxy diagnostics:

- activeSources
- activeClients
- readRequests
- bytesRead
- releasedSources

Required behavior:

- proxy binds localhost only
- token URL exposes no credentials/upstream path
- activeSources returns to 0 after release
- seeking to 70–90% must not sequentially read the complete file from byte 0

If possible capture byte/range request trace.

## Stage 7 — remote thumbnail

Open a network directory containing video files.

Confirm on device:

- thumbnail actually renders
- newly written persistent file is WebP
- no new JPEG fallback is generated
- duration-based time selection is reasonable
- aspect ratio is preserved
- max box is 480x270
- reopen uses cache

Test:

- landscape 16:9
- ultrawide
- portrait video

Record actual generated dimensions and file extension.

## Stage 8 — protocol application tests

The server-side protocol lab already passed. Now verify the app path.

Test at minimum:

- WebDAV
- SMB

If available, also:

- SFTP
- FTP
- NFS

For each record separately:

- auth
- list
- open RandomAccessSource
- playback
- seek
- cancellation
- close/reconnect

Do not mark a protocol application PASS based only on Docker/server lab results.

## Stage 9 — media compatibility

Use `test-lab/benchmark/cases.json`.

Priority:

- H.264/AAC
- HEVC/AAC
- HEVC Main10
- HDR10
- HLG
- Dolby Vision
- DTS
- DTS-HD MA
- TrueHD
- ASS
- PGS
- long GOP
- 4K remux

For every case record backend and result.

## Stage 10 — HDR validation

Current metadata labels are:

- PQ / ST2084 -> HDR10 label
- HLG -> HLG
- other transfers -> no HDR label

Confirm metadata labeling separately from physical output behavior.

For HDR10/HLG record:

- source metadata
- MPV video params
- backend
- whether device/display actually enters HDR mode
- visible tone mapping/output behavior

For Dolby Vision:

Do not equate opening the file with native DV output.

Record separately:

- DV file decodes
- DV-aware metadata/rendering behavior
- display actually enters Dolby Vision mode, if observable

## Stage 11 — advanced audio

Test when hardware supports it:

- AAC
- AC3
- EAC3
- DTS
- DTS-HD MA
- TrueHD
- Atmos
- DTS:X

Record separately:

- audio is audible
- decoder path
- channel output
- passthrough yes/no
- AVR/TV codec indicator

"Audio works" is not proof of lossless passthrough.

## Stage 12 — resource/stability

Mandatory:

### 50 source changes

Alternate local/WebDAV/SMB if possible.

After the test verify:

- no crash
- no stale session events
- no residual audio
- no accumulating black surfaces
- proxy activeSources returns to 0
- memory does not monotonically grow without recovery

### Background/foreground

While playing:

- Home
- return
- lock/unlock if permitted
- fullscreen enter/exit

### Long playback

If practical, run at least 2 hours on one high-bitrate source.

Record:

- crash
- A/V sync
- buffering
- thermal behavior
- memory trend

## Stage 13 — benchmark

Only after functional smoke is stable.

Use NDJSON format from:

`test-lab/benchmark/README.md`

For selected cases, run at least 5 repetitions.

Required playback measurements:

- first frame
- seek 50%
- seek 90%
- buffering
- bytesRead
- rangeRequests
- backend

Generate:

```powershell
node scripts/summarize-benchmark.cjs test-lab/benchmark/results.ndjson test-lab/benchmark/report.md
```

Do not tune Auto backend until this data is reviewed.

## Security

Before committing evidence, scan for:

- Authorization
- Cookie
- password
- signed URL query
- SMB password
- SFTP secrets
- signing secrets

Redact before commit.

MPV error diagnostics must not persist credentials.

## Do not start yet

Still blocked/not authorized during this device pass:

- FFmpegMediaProbe
- FFmpegThumbnailExtractor
- OH_AVDataSource
- AVIOContext
- libmpv stream callback
- major Auto policy rewrite
- track-selection architecture redesign

## Required output

Update:

`docs/VALIDATION_REPORT.md`

Add a new section:

`ARM64 device runtime validation`

Also commit, when available:

- sanitized runtime evidence
- benchmark NDJSON/report
- no binary HAP
- no secrets

## Stop and return for architecture review when

Any one is true:

1. System/MPV/Auto smoke is completed;
2. MPV runtime behavior contradicts the adapter assumptions;
3. MediaProxy appears to be the performance bottleneck;
4. HDR/DV/audio results require policy decisions;
5. benchmark data is available;
6. a common playback/storage contract needs modification;
7. a blocker cannot be fixed without a new architecture decision.

Do not merge PR #10.

Return with:

- final branch SHA
- updated VALIDATION_REPORT.md
- device model/OS
- System result
- MPV result
- Auto result
- MediaProxy diagnostics
- thumbnail result
- benchmark data if run
- all runtime fixes and commit SHAs
