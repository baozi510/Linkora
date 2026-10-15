# Playback event and control completion — 2026-10-15

Outcome: IMPLEMENTED AND COMPILED; DEVICE ACCEPTANCE NOT RUN.

This is a direct user-requested extension of the existing application wrappers, following the request to fill missing playback events and controls. It is not a rerun of a closed validation dispatch and does not change its historical results. Subtitles remain a user-deferred TODO.

- Base: `da15f074a53270b603315c23fb46610f82a7c15c`.
- Candidate branch: `codex/linkora-playback-event-completion-v1`; no merge to the product branch.
- Structure retained: PlaybackPort → System/MPV adapters → Adaptive gate → PlaybackEngine → PlayerFeatureController → existing PlayerPage.
- No new package dependency, compatibility layer, automatic backend-selection rule, or alternative test application was added.

## Implemented behavior

| Area | System AVPlayer | MPV wrapper | Application behavior |
| --- | --- | --- | --- |
| Playback rate | API20 `setPlaybackRate`, native rate/speed completion | speed property stream | Display changes from adapter callbacks, not immediately from the requested value; controls retain the existing 0.5–2 range |
| Volume | native volume-change callback | volume property stream, normalized to 0–1 | Same confirmed-event display; rejects nonfinite input |
| Single-file loop | native loop setting/readback, endOfStream | File/None loop mode and wrapper mode stream | Toggle in normal/fullscreen controls; configuration acknowledgement is not proof of a completed physical loop |
| Stop/replay | native stop/state callback | wrapper stop and state transition | STOPPED state, distinct STOP end reason; replay opens from zero after disposal and rechecks the controller network policy |
| Audio tracks | descriptions, selected-track query, track-update/change callbacks | existing wrapper tracks/selection streams | Only known audio IDs may be selected; normal/fullscreen selector; no external URI injection |
| Stream termination | endOfStream → EOF, stopped → STOP | EOF, explicit STOP, unknown unload | Exposes reason and loop flag separately from state; does not guess native fatal codes from log messages |
| Audio interruption | hint, forced/shared flag, event type | Not supplied by the current binding | Details preserved in snapshots; existing pause-on-interruption policy retained; no automatic resume added |
| Output devices | device types and change reason | Not supplied by the current binding | Exposes categories without hardware IDs |
| Nonfatal warning | optional metadata/control failures | diagnostic log or control failures | Snapshot warning and generic user message; an optional operation does not tear down otherwise valid playback |

The original 12 observer callbacks remain; seven appended default callbacks cover rate, volume, loop, stream end, interruption details, output changes and warnings. Existing construction sites remain valid. Port implementations and test doubles implement the three new controls.

MPV track-selection and loop streams reflect wrapper operations; they are not an independent audible-track or whole-file-repeat oracle. System metadata discovery is asynchronous and cannot hold playback preparation hostage. Superseded/released candidates cannot publish new setting events.

## Checks and actual actions

| Check/action | Result and boundary |
| --- | --- |
| Adapter/Engine host regressions | 44/44 PASS; executes production ArkTS through the existing transpilation checks with controlled platform boundaries, not native playback |
| SDK/Hypium suite | 223/223 PASS, zero failures/errors; includes settings acknowledgement, stop/replay and policy-blocked replay |
| Architecture/artifact-checker self-tests | 22/22 PASS |
| Architecture boundary check | PASS |
| Local persistence checks | PASS against disposable desktop SQLite; not a Harmony device persistence claim |
| ARM64 debug application builds | Two successful builds; final package includes the final adapter event guards and actual page bindings |
| Required native artifact audit | PASS: nine ARM64 libraries in the final fresh unsigned HAP |
| Signing/install/start/media | NOT RUN in this round; package is unsigned, and no signing configuration or credential was copied or probed |
| Phone connection | One attempt to the previously supplied address failed; target list empty. User was asked for the current wireless-debugging endpoint |
| Simulator/GUI/timers | No simulator or GUI actions; the cancelled recurring automation remains cancelled |

The first SDK attempt failed because this new isolated checkout lacked ignored ARM64 FFmpeg inputs. The second failed because three pinned submodules had not been initialized. Both failures were retained. Known prebuilt headers/four static libraries/manifest were copied read-only into the isolated ignored prefix and hash-checked (138 files); the existing pinned submodules were initialized. Subsequent SDK checks succeeded. There were six SDK test invocations in total: two dependency-setup failures and four successful test runs, including the final 223-test run. No production compatibility workaround was added for those setup failures.

Regression tests were first observed failing for absent event mapping, metadata blocking, late released MPV callbacks, loop EOF followed by playing=false, optional loop rejection during open, EOF→Stop end-reason deduplication, and late EOF after unknown unload. Their corrected paths pass. The policy-aware stopped replay is also covered in the SDK suite. Read-only independent review identified the loop/open/policy/stop issues; fixes were verified locally.

## Fresh artifact

- Product/module/build: default / entry@default / debug / ARM64.
- File: `entry-default-unsigned.hap`; 64,075,644 bytes.
- SHA256: `698C5FB1239CC579882ED3753CB0980FE9C068D876DE9FFD75E3634FB9F7F909`.
- This is a fresh compiled artifact, not installed-device or runtime acceptance evidence.
- Raw build/test output and input-copy hashes remain private. Generated lock files are unstaged; Git-normalized lock content equals the base. No original-workspace write operation was issued; no exhaustive bytewise nonmutation snapshot was performed.

## Remaining acceptance and explicit limits

1. On the reconnected unlocked phone, explicitly select System and MPV separately in the actual application. Check rate and volume callbacks, stop/restart from zero, a real loop crossing EOF, and selection of two existing audio tracks where a suitable sample has them. Confirm sound with the user; screenshots alone cannot prove it.
2. Exercise actual focus loss and audio-device route changes for System. MPV equivalents require support from its native binding; no synthetic parity is claimed.
3. MPV END_FILE exposes no reason/error payload in the installed EventObserver interface. Unknown unload remains UNKNOWN; structured EOF error parity is not implemented. First-frame and play/pause semantics remain the existing adapter semantics, not newly certified frame/audio observations.
4. Subtitle controls/testing remain TODO. DRM/key-system, SEI, amplitude, super-resolution, adaptive bitrate selection, chapters/playlists, full audio/video parameter telemetry, physical output calibration, endurance and performance were not completed by this change. This is not a claim to wrap every backend API.

API evidence: installed DevEco SDK media/audio declarations and installed MPV package declarations. Upstream reference: [MPV ArkTS Player implementation](https://github.com/mpv-ohos/mpv-arkts/blob/main/mpv/src/main/ets/Player.ets); current upstream source is explanatory and does not replace verification of the installed binding or actual device playback.
