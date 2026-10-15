# Network playlist preparation — 2026-10-16

Result: phase 1 network preparation passed the checks below. This is preparation plus opening the selected video in the actual application, not native queue advancement or MPV runtime validation.

## Behavior

- Video clicks in network lists, grids and the context menu create the common detached PlaybackPlaylist and forward it through navigation.
- Only direct video children of the displayed directory are included, in browser order; folders, photos, audio, subtitles, descendants, duplicate paths and missing selections are excluded.
- Persisted server identity plus original path identifies each item. Sources retain credential references and original paths; preparation creates no proxy URL and opens no remote file.
- Loading, stale rendered-directory and failed-directory file opens are rejected. Existing audio single-source opening is retained.
- The provider contract returns an awaited directory array without pagination metadata. Complete means this provider result finished; it does not promise remote readability or discovery beyond that result.

## Automated checks

- Missing-service RED: SDK compilation failed as expected before implementation.
- Fresh registered SDK suite: 253 tests, 253 passed, zero failures/errors/ignored, including ten new network preparation cases.
- The simulator SDK unit hook compiled but reused the previous 243-case semantic result. That run does not count as coverage of the new cases. A subsequent default SDK target execution freshly ran all 253 cases.
- Independent read-only code review found no important issues. Source/lock guard and strict fresh-HAP x86_64 ELF audit passed; exactly one approved x86_64 native library.
- Fresh simulator assembleHapSeq passed. HAP SHA256: FBE23CBB4BAB4CE7857B863D39C45F0DEB65A3CB047920A72C404812A027C41A.

## Actual simulator actions

Used the existing API26 x86_64 simulator, official CLI/HDC only, and the separate simulator application identity. No GUI, manual signing, credential inspection, uninstall, wipe or reset.

Normal installation explicitly returned `install bundle successfully`; EntryAbility started successfully. An earlier forward-slash Windows path was rejected by HDC before file transfer; correcting the native path installed the same audited HAP, without rebuilding. A CLI text input containing spaces was rejected; the test server name was entered without spaces. Neither tool error is a product playback failure.

An isolated loopback WebDAV fixture served real repository MP4/PNG bytes with PROPFIND, HEAD and HTTP byte ranges. It used no real account or credentials. Actual app checks:

| Action | Observed result |
| --- | --- |
| Open root containing three folders, two MP4 files, a PNG and a subtitle | Browser shows mixed entries; selected second MP4 opens as 2/2 |
| Inspect selected second MP4 | Green decoded video, 640×360, progress reaches two-second completion |
| Enter tv, containing one child folder and two MP4 files; select second video | 2/2; root and descendant entries are not included |
| Enter movie and open its sole MP4 | 1/1 and actual playback |
| Enter empty | Empty-folder screen; no fabricated playable selection |
| Return to root, switch to grid, long-press second MP4, choose Open | 2/2 and actual playback; context-menu path uses the same builder |
| Return through player/directory navigation | Correct parent listings remain accessible |

Raw UI layouts, fixture requests and a decoded-frame screenshot are retained privately. No device IDs, account data, proxy tokens or raw logs are published.

## Limits and workspace state

No native next/previous/automatic transition, shuffle, list loop, audio listening, subtitle, large-file, real-server, SMB/SFTP/FTP/NFS transport or MPV runtime claim. Missing-selection, incomplete-result and stale-scope branches have model/code coverage, not injected device races in this round. Audio routing is preserved by inspection, not a new audio runtime test.

Four generated OHPM lockfiles remain unstaged in the isolated build checkout, including the effective simulator MPV stub resolution. They are not part of this source change. The original workspace was not edited or built; no exhaustive bytewise workspace snapshot was performed. Existing compiler warnings remain.

Next: connect the prepared snapshot to native playlist controls and actual native item-change events, keeping the two backends' outcomes separate.
