# Descriptive observations — Mate60 WebDAV two-case baseline

- All 240 measured samples succeeded with fixture duration/dimensions correctness; 200 COMPLETE and 40 PARTIAL. System ADVANCED: 0/40 COMPLETE (40 valid PARTIAL); FFmpeg ADVANCED: 40/40 COMPLETE. LIST and thumbnail: both engines 40/40 COMPLETE.
- Aggregate LIST elapsed P50/P95: System 366/454 ms; FFmpeg 245/404 ms. FFmpeg P50 was 121 ms lower on this corpus. Aggregate ADVANCED: System 331/464 ms; FFmpeg 230/391 ms (P50 101 ms lower for FFmpeg).
- Aggregate thumbnail elapsed P50/P95: System 719/794 ms; FFmpeg 1030/1894 ms. System P50 was 311 ms lower. Average extraction was approximately 641 vs 1296 ms, encode 72 vs 80 ms, write about 2 ms for each.
- Average upstream thumbnail bytes: System 681,500; FFmpeg 7,190,498. Average valid HTTP Range counts: 3.0 for each. Upstream readRequests remains distinct and retained in raw NDJSON. These byte counts may exceed file length because of repeated/overlapping reads; no records were edited or excluded.
- Average encoded WebP sizes: System 6,495; FFmpeg 7,051 bytes. Successful frame dimensions were within the common 480x270 plan.
- Per-case tables matter: FFmpeg HEVC/MKV thumbnail P50/P95 1842/1906 ms vs System 694/752 ms; FFmpeg MP4 926/995 ms vs System 761/828 ms. The aggregate combines two different distributions.
- memoryBytes is null for every record: memory unavailable, not zero. No CPU/GPU/power/thermal or broad codec/Local/SMB conclusions.
- One run only, 2 configured warmups and 20 measured repetitions per group, alternating engine order; no normal Network UI operations during sampling. No valid failed/outlier sample was removed (this run had no failed measured sample).
- This is descriptive measurement evidence, not a recommendation to alter ProductionMediaAnalysisPolicy, choose a final engine, implement Direct I/O or start Phase 7B. Corpus/source-family expansion and any policy decision require independent review.
