# Simulator Validation Report

> Status: NOT RUN  
> Branch: test/simulator-validation  
> This report is for the x86_64 simulator-only product. It must not be used as evidence for MPV/native/HDR/passthrough support.

## Git

- Base branch: test/player-architecture-validation
- Simulator branch: test/simulator-validation
- Starting SHA:
- Final tested SHA:
- Final documentation SHA:

## Environment

- Host OS:
- DevEco Studio:
- HarmonyOS SDK:
- Hvigor:
- ohpm:
- Node:
- Emulator model:
- Emulator OS/build:
- Emulator API:
- Emulator ABI:
- Emulator resolution:

## Dependency / Sync

- ohpm install: NOT RUN
- DevEco Project Sync: NOT RUN
- multi-target package plugin resolved: NOT RUN
- simulatorTargetDependencies applied: NOT RUN
- notes:

## Production regression gate

Command:

~~~powershell
./scripts/verify.ps1
~~~

- Result: NOT RUN
- Hypium:
- default Debug HAR/HAP:
- default Release HAR/HAP:
- architecture checks:
- notes:

## Simulator static gate

Command:

~~~powershell
node scripts/check-simulator-product.cjs
~~~

- Result: NOT RUN
- Notes:

## Simulator build gate

Command:

~~~powershell
./scripts/verify-simulator.ps1
~~~

- Result: NOT RUN
- Discovered Seq task:
- HAP path:
- HAP SHA256:
- BundleName:
- Native .so count:
- MPV real HAR packaged:
- Notes:

Expected:

- BundleName = com.linkora.player.simulator
- Native .so count = 0
- real libmpv.so absent
- liblinkora native adapters absent

## Install / launch

- hdc target:
- ABI:
- install: NOT RUN
- launch: NOT RUN
- cold launch:
- navigation:
- crash:
- native load error:
- evidence:

## Simulator capability UI

| Check | Result | Notes |
| --- | --- | --- |
| Player settings shows System only | NOT RUN | |
| Auto hidden | NOT RUN | |
| MPV hidden | NOT RUN | |
| Simulator notice visible | NOT RUN | |
| WebDAV available | NOT RUN | |
| SMB hidden | NOT RUN | |
| SFTP hidden | NOT RUN | |
| FTP hidden | NOT RUN | |
| NFS hidden | NOT RUN | |

## Settings / database

| Check | Result | Notes |
| --- | --- | --- |
| Settings persist after restart | NOT RUN | |
| Theme persists | NOT RUN | |
| WebDAV server add | NOT RUN | |
| WebDAV server edit | NOT RUN | |
| WebDAV server persists restart | NOT RUN | |
| WebDAV server delete | NOT RUN | |
| DB initialization/migrations | NOT RUN | |

## HTTPS System playback

Media case:

- URL redacted:
- Codec/container:
- Duration:

| Check | Result | Timing / notes |
| --- | --- | --- |
| Open | NOT RUN | |
| Prepare | NOT RUN | |
| First frame | NOT RUN | |
| Play | NOT RUN | |
| Pause | NOT RUN | |
| Resume | NOT RUN | |
| Seek 10% | NOT RUN | |
| Seek 50% | NOT RUN | |
| Seek 90% | NOT RUN | |
| Completion | NOT RUN | |
| Replay | NOT RUN | |
| Release | NOT RUN | |

## Local System playback

| Check | Result | Notes |
| --- | --- | --- |
| File picker/import available | NOT RUN | |
| H264/AAC MP4 open | NOT RUN | |
| First frame | NOT RUN | |
| Pause/resume | NOT RUN | |
| Seek 50% | NOT RUN | |
| Seek 90% | NOT RUN | |
| Completion/reopen | NOT RUN | |

## WebDAV connection

| Check | Result | Notes |
| --- | --- | --- |
| Correct credentials test | NOT RUN | |
| Wrong credentials rejected | NOT RUN | |
| Save server | NOT RUN | |
| Root list | NOT RUN | |
| Nested list | NOT RUN | |
| Chinese filename | NOT RUN | |
| Space filename | NOT RUN | |
| Refresh | NOT RUN | |
| Back navigation | NOT RUN | |

## WebDAV System playback

| Check | Result | Timing / notes |
| --- | --- | --- |
| Open H264/AAC MP4 | NOT RUN | |
| First frame | NOT RUN | |
| Play 30 seconds | NOT RUN | |
| Pause/resume | NOT RUN | |
| Seek 50% | NOT RUN | |
| Seek 90% | NOT RUN | |
| Completion | NOT RUN | |
| Replay | NOT RUN | |
| Release | NOT RUN | |

## MediaProxy runtime

- activeSources before:
- activeSources during:
- activeSources after:
- activeClients:
- readRequests:
- bytesRead:
- releasedSources:
- localhost only: NOT RUN
- token privacy: NOT RUN
- HEAD: NOT RUN
- GET: NOT RUN
- Range: NOT RUN
- 50% seek random access: NOT RUN
- 90% seek avoids sequential byte-0 read: NOT RUN
- lease release: NOT RUN

## Metadata / thumbnail runtime

| Check | Result | Evidence |
| --- | --- | --- |
| Duration | NOT RUN | |
| Width/height | NOT RUN | |
| Thumbnail visible | NOT RUN | |
| New cache extension .webp | NOT RUN | |
| No new JPEG | NOT RUN | |
| Landscape aspect ratio | NOT RUN | |
| Ultrawide aspect ratio | NOT RUN | |
| Portrait aspect ratio | NOT RUN | |
| Max 480x270 | NOT RUN | |
| Cache reuse | NOT RUN | |

## Surface / lifecycle

| Check | Result | Notes |
| --- | --- | --- |
| Fullscreen enter | NOT RUN | |
| Fullscreen exit | NOT RUN | |
| Orientation change | NOT RUN | |
| Background | NOT RUN | |
| Foreground | NOT RUN | |
| Surface recreate | NOT RUN | |
| Old-session event isolation | NOT RUN | |
| 20 open/close cycles | NOT RUN | |

## Error recovery

| Case | Result | Notes |
| --- | --- | --- |
| Empty URL | NOT RUN | |
| Invalid protocol | NOT RUN | |
| HTTP 404 | NOT RUN | |
| HTTP 500 | NOT RUN | |
| Timeout | NOT RUN | |
| Unsupported media | NOT RUN | |
| WebDAV bad password | NOT RUN | |
| WebDAV server stop | NOT RUN | |
| Reopen after server restore | NOT RUN | |

## Security

- Log credential scan: NOT RUN
- Authorization leak: NOT RUN
- Cookie leak: NOT RUN
- Password leak: NOT RUN
- Proxy upstream locator leak: NOT RUN
- Signing/private key leak: NOT RUN

## Stability

- 20 player open/close: NOT RUN
- 20 WebDAV directory enter/exit: NOT RUN
- 10 seek cycles: NOT RUN
- 10 background/foreground cycles: NOT RUN
- crash/ANR:
- black surface:
- residual audio:
- proxy leak:

## Explicitly NOT VALIDATED by simulator

These must remain NOT RUN regardless of simulator success:

- MPV runtime
- SMB/SFTP/FTP/NFS native runtime
- FFmpeg analyzer
- HDR/Dolby Vision physical output
- DTS-HD/TrueHD passthrough
- Atmos/DTS:X
- Audio Vivid
- arm64 hardware decode coverage
- power/thermal performance
- Auto backend benchmark/tuning

## Fixes during simulator validation

| Commit | Failure | Root cause | Files | Verification |
| --- | --- | --- | --- | --- |

## Final assessment

- Production default regression:
- Simulator isolation:
- Simulator build:
- Install:
- Launch:
- System playback:
- WebDAV:
- MediaProxy:
- Thumbnail:
- Lifecycle:
- Security:
- Remaining blockers:

## Handoff decision

Choose exactly one:

- READY FOR ARCHITECTURE REVIEW
- BLOCKED — SIMULATOR PRODUCT BUILD
- BLOCKED — EMULATOR PLATFORM
- VALIDATION FAILED — FIXES REQUIRED
