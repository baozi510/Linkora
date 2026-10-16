# Native playlist controls implementation plan

User-approved phase 2 follows the completed local/network preparation phase. Execute inline and test the actual simulator app.

First slice: local native queues, with no application-level EOF reopen loop. Keep the original ordered snapshot and map real System source IDs / MPV playlist positions back to its indices. Support native select, previous/next, sequential EOF and existing single-item repeat. Preserve single-source opening and do not change the API floor. Reject unsupported API26 list operations explicitly.

Reach: PlaybackPort/observer, PlaybackSnapshot/engine, PlayerFeatureController, Adaptive/System/MPV adapters, simulator compile-only MPV declaration, application composition/page/controls, existing fakes and host/SDK tests. Index change comes only from native acknowledgement; stale/released callbacks cannot update the active session. Per-item timing/track state must reset and bookmarks must use the correct source.

Network native queues require deferred source opening and ownership beyond the existing eight-source proxy limit. Keep their completed preparation/single-selected-item behavior during the local slice; do not eagerly open the entire network directory or label it a native queue.

- [x] Write failing engine/adapter tests for ordered lists, selected start, native index acknowledgements, bounds, stale/released callbacks, EOF, disposal and per-item reset.
- [x] Implement the smallest contract and local native adapters. Preserve the existing single-source path and single-repeat semantics.
- [x] Wire previous/next/select and live native index to the actual app; reject unsupported operations without fabricated current-item updates.
- [x] Run host/SDK checks, fresh simulator HAP build/audit/install and actual local list transition tests. Keep negative outcomes.
- [x] Create real nested document fixtures and import them through the actual file picker into matching application folders; verify direct-child list scope and distinct same-name files.
- [x] Publish the local slice report and nested fixture manifest.
- [ ] Implement network native source ownership in a subsequent slice. MPV native execution remains blocked by the simulator's unsupported HAR.

References: installed API26 media declaration and OpenHarmony AVPlayer addPlaybackMediaSource / onPlaybackContentChanged documentation; installed real mpv-arkts contract and upstream Player implementation. MPV simulator HAR intentionally throws on native creation and provides no runtime proof.
