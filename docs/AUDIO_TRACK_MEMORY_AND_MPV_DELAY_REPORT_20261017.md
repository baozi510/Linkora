# Per-video audio memory and MPV audio delay — 2026-10-17

## Result and scope

Implemented the user's simplified audio behavior on candidate branch `codex/linkora-audio-memory-delay-v1`, based on `d80015876bd22ea51248f0a584e1abeac3fd2b09`. This supersedes the earlier language-preference UI; the earlier report remains historical evidence.

| Item | Current behavior |
| --- | --- |
| Audio dropdown | Actual internal audio tracks only. Removed the synthetic Auto/default entry, language input/apply, and remember toggle. Track metadata remains visible. |
| First opening | Leaves native/container default selection untouched when this video has no saved manual choice. No language preference selection. |
| Per-video memory | Always saves a manual choice only after command acceptance and actual selected-track acknowledgement. Reopens restore a unique metadata match; ambiguous/missing matches leave the native default. Existing hashed per-video records remain usable; obsolete global preference keys are ignored. |
| MPV synchronization | Native `audio-delay`, signed milliseconds converted to seconds. Earlier/later buttons change 50 ms, reset requests zero; bounds are -10000..10000 ms. Each new source/backend starts a new delay session and requests zero when ready. Offset is not persisted. |
| Confirmation and failure | Reads native delay back; rejected/unconfirmed changes do not invent success. A failed initial reset displays unknown rather than zero; adjustment buttons wait for a known value. Reset allows recovery. Errors remain nonfatal to playback. |
| System synchronization | Not exposed or simulated. System AVPlayer has no delay implementation in this change. |

External audio is excluded. Subtitles remain TODO. No new dependencies or native-library changes.

## Concrete simulator behavior

Used the actual application, System AVPlayer, a local 120-second H264/AAC fixture containing English and Chinese internal audio, and the normal application document picker. This is application playback, not a capability-only harness. Fixture SHA256: `1AC372E6938FFCB1A4F7CB4F0E63585C32A9318485E71ACD5184203F438BF78F`.

1. Imported the same approved fixture under a new filename with no earlier audio memory. Initial selection was the English container default.
2. Opened the audio dropdown: exactly two real audio options; no Auto/default, language input, remember checkbox, or System delay controls.
3. Manually selected Chinese; actual selected-track metadata changed to Chinese.
4. Reopened the video and later restarted the installed application: Chinese selection restored.
5. On the final package, moved from video A (Chinese) to video B (English), then back to A (Chinese). Both retained actual audio metadata and A's remembered selection; no cross-video selection.
6. Paused playback and inspected the final screenshot and UI tree. No new user hearing confirmation was requested, so this round does not claim acoustic verification.

Expanded continuous-playback checks initially failed: the System adapter cleared its local track list without invalidating the candidate observer cache, and metadata queried at content change could still be empty. The final fix publishes track invalidation, refreshes empty metadata at first rendered frame, and waits for playable state before restoring memory. Three regression cases were first observed failing and then passed after the corresponding changes. Early failed runtime snapshots remain private; earlier successful spot checks were not treated as complete acceptance.

## Verification

| Check | Result |
| --- | --- |
| Final combined host tests | 133 passed, zero failed/cancelled/skipped. Covers memory/store/controller, both native boundaries, adaptive/engine, playlists, orientation, ABI and architecture guards. |
| SDK ArkTS/Hypium unit hook | 256 run; Pass 256, Failure 0, Error 0, Ignore 0. This is not native MPV playback. |
| Simulator builds | Six builds completed successfully during this task, including intermediate packages used to expose the playlist/cache issue. Final installed package came from build 6. |
| Final HAP native audit | PASS: exactly one approved x86_64 FFmpeg library, no ARM MPV/AKI/C++ libraries. |
| Final installation/start | Normal HDC install and explicit simulator EntryAbility start succeeded; no uninstall, wipe, reset or signing bypass. |
| Final UI acceptance | Audio-only two-item dropdown; manual selection, reopen/restart memory, previous/next isolation and System delay absence passed. |
| Review | Earlier focused review findings on false reset-zero and uncleared delay warning were fixed and rechecked. First-frame metadata fallback received focused review. Subsequent cache invalidation/readiness fixes were self-reviewed with failing/passing regressions and actual simulator retests. |
| Git checks | Whitespace and exact staged-path review passed before commit. Four generated dependency locks are excluded and retained locally. |

Final simulator HAP SHA256: `8984557BA3694664E891676CAE0427E835C6023CF7A214230AF6828F524EA608`.

MPV property tests confirm signed seconds, readback, invalid inputs, unsupported/released cases, reset boundaries, and recovery using controlled native boundaries. The simulator dependency is an MPV stub: native MPV playback, the MPV-specific controls on a real backend, and actual A/V synchronization/hearing remain NOT RUN. Native positive delay semantics follow the [MPV audio-delay documentation](https://mpv.io/manual/stable/#options-audio-delay).

Raw logs, screenshots and device/application identifiers remain private. No saved servers were deleted or changed. No commands modified, built, reset or cleaned the original workspace; no exhaustive bytewise nonmutation claim is made. This report and candidate publication do not imply a production merge.
