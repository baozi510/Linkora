# Simulator validation evidence

Main report: ../../SIMULATOR_VALIDATION_REPORT.md. Tested source04814840403b54d8dd0e0e61798be1fb3f8f8da8. Final full default run07 exit0; latest simulator run05 exit0; signed install03 success. Build logs, actual Hypium149/149 summary, fail-before-fix4/149 summary, sanitized runtime ledgers, selected fresh screenshots, and FFmpeg toolchain/config/hash audits are included.

Runtime ledgers contain only the test fixture/profile names, playback states/positions and bounded counters. UI protocol-error JSON is extracted from named captured SDK dumpLayout files, omitting TextInput contents and original profiles. upstream-range-ledger.json records actual test-lab WebDAV request ranges and wire counts, not MediaProxy internal stats. No credentials or raw OS logs are submitted.

Screenshots are selected fresh captures using unique remote filenames. Older fixed-name PNG captures could contain stale trailing bytes; those are not committed. frame-checks.json evaluates only the first valid image of each of20 player cycles, with real color regions; it is not an audio/leak proof. appearance-persisted.png shows the temporary test preference; preference-final.png confirms original Auto and both enabled toggles restored.

Full original failures, successful builds/configure logs, source pin proof, lab setup helpers, input/retry harness logs and generated fixtures/artifacts remain local at D:\Linkora-validation\artifacts\simulator-validation. Generated FFmpeg static libraries/headers remain in ignored third_party/ffmpeg/prebuilt; do not confuse them with App integration.

NOT RUN gaps are intentional, visible in the main report: private cache files and App proxy counters inaccessible, required AAC local/HTTPS cases unexecuted, precise Auto runtime events uncollected, and real ARM64-only capabilities unavailable. These are not PASS.
