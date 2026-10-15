# Local playlist preparation implementation plan

> **For agentic workers:** Execute inline using superpowers:executing-plans; request an independent final review.

**Goal:** Prepare a local video playlist from the current visible directory/group and carry it to the player without enabling automatic advancement.

**Architecture:** Reuse LocalMediaCatalog and LocalMediaOrdering for scope, visibility and order. A pure local builder maps available videos to an immutable common playlist snapshot. Browser clicks, context menus and list rows share one preparation path; navigation carries the selected source and playlist together.

**Tech Stack:** ArkTS, existing HarmonyOS SDK/Hypium; no new dependencies.

**Spec:** User-approved in-chat two-stage design: local and network preparation are separate; first implementation/test round covers local preparation only.

## Global constraints

- Work only in the existing isolated checkout, never build/write the original workspace.
- Preserve SDK settings and existing generated locks. No network queue, native advancement, signing, installation, media copying or new permissions this round.
- Current directory/group and current UI search/filter/order are authoritative; no recursive scan.
- Keep per-entry identity separate from the playback locator (including manual virtual entries).
- Capture incomplete/cached results honestly; no runtime playback claim from preparation tests.

## Review focus

- Same names and shared underlying locators must not select the wrong virtual entry.
- Stale or unavailable clicked items must not silently play index zero.
- Descendant/hidden/filtered files must not leak into the visible queue.
- Mutating the browser input after navigation must not mutate the playlist snapshot.
- Scanning/refreshing/failed projections must not claim complete results.

### Task 1: Model and local preparation

Files: new core models PlaybackPlaylist.ets / LocalPlaybackPlaylist.ets, core exports, LocalPlaybackPlaylist.test.ets and test registration.

Interfaces: PlaybackPlaylistItem(id, source); PlaybackPlaylist(items, startIndex, complete), items copy getter, currentItem(); LocalPlaybackPlaylist.build(orderedVisibleItems, selectedUri, complete): PlaybackPlaylist | null.

- [x] Write tests for mixed types, availability, empty/missing selection, duplicate identity, duplicate name/locator, source URI conversion, snapshot isolation, directory projection, ordering/search and incomplete data.
- [x] Run the SDK suite and record missing-interface RED before implementation.
- [x] Implement the smallest pure builder and snapshot validation.
- [x] Run the complete SDK suite, inspect semantic summary as well as command exit.

### Task 2: Local opening integration

Files: LocalMediaBrowser, LibraryPage, AppNavigation, Index, PlayerPage, navigation tests.

- [x] Test that a route retains the full list and its selected source, and preserves single-source callers.
- [x] Route grid/list/menu clicks through one builder; attach completeness from the current page projection.
- [x] Carry the snapshot to PlayerPage and display position/count with an incomplete marker. Keep the existing single-item controller unchanged.
- [x] Run full SDK suite (243/243), adapter/checker regressions (74/74), SQLite (9 checks), architecture and diff checks. Initial ARM64 build passed; later user steering prioritized final-source simulator build/audit/install/UI checks, all passed. No final-source ARM64 artifact claim.
- [x] Independent review; fix dropped partial-scan flags, failed-cache reprojection and silent virtual-folder refresh failure. Record red/green evidence and the scope of simulator validation in the round report.
