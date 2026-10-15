# Network playlist preparation implementation plan

> **For agentic workers:** Execute inline with superpowers:executing-plans; request independent final review.

**Goal:** Complete the network half of user-approved phase 1, then continue to native playlist playback validation.

**Architecture:** Reuse the existing provider directory result and browser order. Build the common immutable PlaybackPlaylist from direct video children, preserving server/path identity and credential references. Resolving playable URLs remains outside preparation. Keep existing single audio opening behavior.

**Spec:** Approved in-chat two-stage design; user subsequently asked for continuous progress and simulator testing.

## Constraints and review focus

- Existing isolated checkout only; no new dependency, secret inspection, production workspace mutation, API-floor change or recursive scan.
- Same paths on different servers must remain distinct; same display names do not identify items.
- Exclude directories, non-video files, duplicate paths, descendants and sibling-directory responses.
- Empty, invalid server or missing selected item must not fall back to index zero.
- Loading/stale rendered directories cannot initiate video opening under a newer directory scope.
- Current provider list contract returns one awaited directory array, with no exposed pagination cursor. Successful load means that result completed; no fabricated pagination support or file accessibility guarantee.
- Simulator supports WebDAV and the system player. MPV and native storage protocols may be unavailable in its target substitutions; report actual support rather than fake success.

### Task 1: Builder and tests

Files: new services/NetworkPlaybackPlaylist.ets and NetworkPlaybackPlaylist.test.ets; List.test.ets registration.

- [x] Write 10 tests for source filtering, direct-parent scope, relative/root paths, order, duplicates, remote identity, server isolation, missing selection, invalid identities and incomplete snapshots.
- [x] Run simulator SDK tests RED for the missing service before implementation.
- [x] Implement and run the complete SDK suite GREEN: 253 cases. The simulator unit hook reused an older 243-case report, so it is not accepted as new-test coverage; the default SDK target freshly executed the registered ten cases.

### Task 2: Actual browser path

Files: NetworkDirectoryBrowser, NetworkBrowserPage and Index.

- [x] Forward a separate playlist callback for videos; retain single-source audio opening.
- [x] Guard unfinished/stale directory opens; no proxy URL or network source opening during model construction.
- [x] Independent review found no important code issues. Fresh x86_64 build and ABI audit passed; normal install and actual WebDAV root/tv/movie/empty directory and context-menu selection checked.
- [x] Record the phase report with concrete actions, negative outcomes and limitations; native queue playback is the next phase.
