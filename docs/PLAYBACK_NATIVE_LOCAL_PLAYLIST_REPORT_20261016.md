# Native local playlists and nested local fixtures — 2026-10-16

## Result and scope

Local native System playlist operations passed the bounded API26 x86_64 simulator checks below. This includes actual decoded frames, source changes, selected start, previous/next, selection, EOF, single-item repeat, stop/replay and return/reopen. MPV has contract/host coverage only: the installed simulator HAR deliberately does not implement native MPV. Network list preparation remains available, but network native queues are not enabled by this change. Subtitles remain TODO.

Base: `de8c0165227a15891718027881187585e5d303b1`. Candidate branch: `codex/linkora-native-playlist-controls-v1`. The built and installed bytes correspond to this source diff over that base; this report and the fixture manifest were added after the build. No production branch merge is implied.

## Implemented behavior

- The shared port accepts an ordered immutable list and exposes native item selection and native current-index notifications. The engine/controller update item identity, metadata, timing and bookmark ownership from actual acknowledgements; a selection call alone does not change the displayed current item.
- System API26 uses `addPlaybackMediaSource`, real source IDs, `advanceToMediaSource`, `onPlaybackContentChanged` and native playlist loop mode. File descriptors remain owned until the native player is released. There is no application EOF reopen loop.
- MPV uses native `Playlist`, `jump` and `playlist-playing-pos`; it does not treat the wrapper's optimistic playlist stream as acknowledgement. Native `idle-active` terminates a failed handoff instead of leaving preparation pending indefinitely.
- The actual application exposes previous/next, an item selector and the acknowledged index. Stop/replay preserves the current item. Single-source paths remain supported. System native lists require API26; the API minimum is unchanged.
- Composition enables queues only for ordinary local document items. Progressive and network items retain selected-item opening until their lazy source ownership is implemented.

## Automated verification

| Check | Observed result |
| --- | --- |
| Production engine/controller/adapters through controlled host boundaries | 64/64 passed, 0 failed/cancelled/skipped; repeated before publication |
| SDK unit hook, freshly executed default target | 253/253 passed, Failure 0, Error 0, Ignore 0 |
| Artifact and architecture guard tests | 22 passed |
| Architecture boundary check and whitespace diff check | Passed |
| Source-driven simulator builds | 6 builds, all compiler BUILD SUCCESSFUL; runtime failures below were retained |
| Final simulator lock guard and strict HAP ABI audit | Passed; one approved x86_64 FFmpeg native library, no foreign ARM MPV/AKI/C++ libraries |
| Final normal HDC install and EntryAbility start | Explicit success, no manual signing or uninstall/reset |

Final unsigned HAP SHA256: `A76E018B795982F4235AC67C83836A05D1A6BBEBCC2D9281D20E8B8CA1480D15`.

The simulator was restarted once after the host automation service restarted and the previous connection went offline. It remained API26/x86_64; media and application data persisted. The final HAP was installed and the selected-start check repeated on the new live connection. This was not a physical-device run. Existing compiler warnings remain.

## Actual native results and failures found

1. A three-item 12-second H.264 list exercised native sequential advance to its last item, terminal completion, previous and the item selector. Actual red/green/blue frames identify the opened fixture, beyond an index label or PID.
2. Native preparation starts at the first physical source even when predecessors were inserted around the requested item. An early version therefore opened the wrong start item. The final code appends in original order, then advances to the clicked native ID before playback.
3. Merely seeing the new ID while the old source still reports prepared was insufficient: build 4 produced a real `5400102` play failure. The final barrier requires the selected-ID content event, actual current ID, fresh readiness and completion of the native advance call. Build 5 and final build 6 opened the requested second item and decoded its expected frame.
4. Native playlist loop mode setters are queued. Immediate readback left the UI showing OFF even while the device repeated the item. The final code waits for a read-only native task on the same queue, then reads back the accepted mode, with release/request fencing. Final device checkpoints showed ON, remained on the same 12-second item across the end, then showed OFF when disabled.
5. Final build 6: stop showed stopped; replay stayed on the acknowledged second item and decoded it. Previous changed second to first, next returned first to second; final EOF showed 0:12/0:12 and completed. Return/reopen of the sibling folder's same-named video showed the correct distinct frame.

Failing host assertions, mock-clock harness timeouts, build-4 runtime failure and the earlier incorrect loop UI remain in private evidence. A successful compiler exit does not erase them. The final host tests include ordered native IDs, selected-start readiness, no optimistic acknowledgements, stale/released callbacks, bounds, per-item resets, bookmark/replay attribution, failed append cleanup, release during preparation, failed MPV handoff and loop request fencing.

## User-requested nested directories and videos

Real fixture files were copied into a new simulator Documents tree, then selected through the actual system DocumentViewPicker. Matching application organization folders were created through the normal UI. No database seeding, debug-only import route or recursive scanner was added.

```text
LP-Nested-1016/
  root-01.mp4                  red, 12 seconds
  root-02.mp4                  green, 12 seconds
  note.txt
  photo.png
  tv/
    episode-01.mp4             green, 12 seconds
    Season-01/
      episode-01.mp4           blue, 12 seconds
      episode-02.mp4           red, 12 seconds
  movie/
    movie-01.mp4               blue, 12 seconds
    readme.txt
```

The accompanying `docs/validation/playlist-native-local-fixture-20261016.json` records all nine real files, byte counts and hashes. A device-to-host round trip matched every file hash. The six MP4 files are real synthetic H.264/yuv420p videos, 640×360 at 24 fps, not filename-only placeholders. They do not exercise audio, varied codecs or large-file performance.

| Actual application scope | Expected and observed list | Additional observation |
| --- | --- | --- |
| Test root, with three application subfolders | `root-02`, `root-01`: 2 items | Selected root-02 showed 1/2 and decoded video; folders were not queued |
| `tv`, with nested `Season-01` | `episode-01`: 1 item | 1/1, green decoded frame; descendants excluded |
| `tv/Season-01` | `episode-02`, `episode-01`: 2 items | Clicked second showed 2/2, blue decoded frame; same name as parent remained a different item |
| `movie` | `movie-01`: 1 item | 1/1 and native preparation/play/pause completed |
| Application `empty` folder | 0 videos | Empty-state view, no player opened |
| System picker in the physical root/movie directories | Video files and relevant subfolders only | PNG/TXT were not offered as videos |

The final build also played the root list unattended from root-02 (1/2, green) to root-01 (2/2, red), then reached 0:12/0:12 and completed. No control was used between these two checkpoints.

Important distinction: application's manual folders are virtual organization with retained document URIs. They do not move files or automatically mirror a physical directory. PhotoAccessHelper albums are a separate local source. The test proves the existing picker/import, virtual hierarchy and current-folder playlist behavior, not automatic recursive physical-folder import.

An empty host directory was also created, but HDC omitted it during directory transfer. The ordinary shell was denied permission to create it in Documents. Therefore a physically empty device directory was **not** covered; the application empty-folder check above was covered. No permission changes or root-mode workaround were used.

## Evidence and remaining work

Raw native logs, layouts, screenshots and generated videos remain private. The report and fixture manifest are the published evidence; raw bytes are not remotely replayable from this commit alone. No passwords, account databases, device identifiers or media URLs are published. Generated dependency lock changes remain unstaged. The protected original workspace was not edited or built; no exhaustive byte-for-byte nonmutation claim is made.

Remaining: network lazy native queue ownership and playback, real MPV runtime verification, physical-device/API-below-26 regression, large mixed-format directory stress and subtitles. Playlist insertion/removal/reorder, whole-list repeat and shuffle are not implemented in this slice. These limits must not be described as all playlist functionality passing.
