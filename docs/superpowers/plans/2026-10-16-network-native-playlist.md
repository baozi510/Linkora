# Network native playlist completion

User approved continuing the existing playlist implementation and using the persisted real WebDAV/SMB servers. Execute inline in the existing isolated checkout, preserving those application entries and all generated locks outside commits.

Use the existing native System/MPV queue contract. Resolve a remote snapshot into stable, opaque loopback URLs, preserving original item IDs/order/start. Keep credential lookup and upstream paths behind NetworkDirectoryService. The engine/controller retain the original snapshot for bookmarks and display; only backend configuration receives the resolved snapshot.

Ruling: a queue owns a separate proxy, with exactly one logical URL slot per list item and the existing client/read limits. This does not increase the shared proxy's eight-source budget. URL registration opens no remote file. A serialized lazy owner retains at most one real upstream reader; switching requested files closes the previous reader before opening the next, and revisiting reopens it. This trades speculative prefetch throughput for a simple hard resource bound.

Validate positive known directory sizes before registration, and actual size/seekability on first read. Changed/unknown sizes report an explicit error instead of silently truncating data or switching to a compatibility path. Release cancels pending reads and closes late-returned opens; cleanup failures remain failures.

Reach: new network source owner, NetworkPlaybackSourceResolver result and cleanup, Adaptive backend configuration, application queue gate, focused production-code host tests and existing adapter tests. No new dependency, credential source, global cap change, application EOF loop, server modification or schema migration.

- [x] RED/GREEN: lazy ownership, serialization, >8 metadata entries, backward reopen, size/capability rejection, pending-open/read release and cleanup errors.
- [x] Resolve the complete remote list and forward it through Adaptive; keep single/local source behavior.
- [x] Run host, SDK, architecture, simulator build and strict ABI checks.
- [x] Test the actual persisted real WebDAV: list display, selected start, previous/next/select, progress, EOF, return/reopen and release behavior. The 22-item 4K/60fps directory timed out; record this case separately from the successful 6/20-item H.264 directories.
- [x] Whole-change review and report. Publish the candidate normally and verify fetch/readback as the final repository operation. Preserve real server settings.

MPV and native SMB runtime remain unavailable in this x86 simulator package. They are not counted as passing from host mocks. Subtitles remain TODO.
