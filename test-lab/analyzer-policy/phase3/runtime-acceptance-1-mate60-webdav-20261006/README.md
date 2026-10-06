# Phase 3 Mate60 runtime acceptance — 2026-10-06

Result: **BLOCKED — LOCAL_DOCUMENT THUMBNAIL ACCEPTANCE**.

Task: phase3-runtime-acceptance-1-mate60-webdav. Implementation 44d0f62816b73ebd3bab8069be5b74f51e2c6999; runtime baseline 4ced68f1b5cae7000ce9a24183d4a1d1b1c747a8; actual tested checkout 30c19502aa06e82b4fe75624c9f0d817fd36eb6d.

Fresh signed default/debug HAP built, exact-nine AArch64 audit passed, signing overlay restored, exact hashed HAP explicitly installed without uninstall. No verifier/simulator/unit/build matrix rerun.

The user interrupted the initial form automation, then explicitly replaced only the fixture environment with a supplied HTTPS WebDAV/SSH media directory. Controlled files were copied into a new isolated child directory; previous media untouched; hashes matched. Human saved the new server; app-side browse independently observed. The endpoint/password/SSH private identity are omitted. Test clients made only read requests; no claim is made that the external account itself is read-only.

MP4 cold/reopen, HEVC-MKV cold/reopen, corrupt/no-invalid-image/backoff, naturally exercisable cancellation/stale UI, and 20 completed production lifecycle cycles pass in the evidence scopes declared by case-results.json. Direct proxy counters and native fallback-start tracing are not available and are not fabricated. Active refresh could not be proved before analysis completion, so that subcase remains NOT RUN. No artificial delay/instrumentation was introduced.

LOCAL_DOCUMENT: normal system DocumentViewPicker imported the exact controlled MP4; row shows 20 s/720P; local playback renders the test pattern, reports 1280x720, and completes. System metadata FileDescriptor API calls are recorded. Its list thumbnail remains a placeholder. Read-only source shows LocalMediaThumbnailLoader fetches PhotoAccessHelper assets and has no document-frame fallback. This is source-supported evidence of an existing limitation, not proof of a Phase 3 regression. The mandatory local-thumbnail acceptance is left BLOCKED for independent review; no source/expectation change was made.

Metadata RDB is encrypted; direct stock sqlite read was unavailable, not database corruption. UI reopen verifies available metadata; no DB dump/decrypt workaround. Actual generated thumbnail location includes the entry module's context.cacheDir, not an app-level guessed cache path.

Early UI-control/UTF8 capture issues happened before the affected action/cycle and were not application test failures or reclassified PASS. Five-cycle batches continued one continuous fresh 1..20 table. Raw forms, private layouts, screenshots, credentials, keys, signed HAP and full app data are not published. No performance rankings, merge or next-phase work.
