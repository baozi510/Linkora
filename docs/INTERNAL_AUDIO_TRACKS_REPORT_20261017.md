# Internal audio track preferences — 2026-10-17

## Delivered scope

Internal audio track selection now shares ordered language preferences, per-video manual-selection memory, native auto/default selection and richer track details across System AVPlayer and MPV. External audio and audio delay are excluded. Subtitles remain TODO.

Base: `2d818512c340413f1b4571897be66ea877d4baca`. Candidate: `codex/linkora-internal-audio-tracks-v1`. This report describes the source diff over that base; it does not imply a production merge.

| Behavior | Implementation |
| --- | --- |
| Ordered languages | Up to eight validated language tags, exact language match before base-language fallback; ISO 639-2 B/T aliases normalize to the corresponding two-letter codes. Within a language match, a reported default track wins. |
| Per-video memory | A confirmed manual selection is stored by hashed original media identity, including a fingerprint when present. Language, title and channels identify the track across backend-specific IDs. Memory takes priority over global languages. |
| Auto | Clears this video's manual choice, then uses language preferences or the native default. System deselects the selected audio track to restore default selection; MPV sets `aid=auto`. Neither operation means mute. |
| Remember toggle | Disabling it prevents subsequent manual choices from being persisted or restored. Existing stored choices are retained while the policy is disabled. |
| Details | Language/title/codec plus channel count, sample rate, bitrate and default flag where reported. Unknown numbers remain zero and unknown default remains null; the UI omits unavailable details. |
| Selection acknowledgement | The feature waits for command acceptance and actual selected-track state before saving a concrete selection. Rejection, a five-second timeout, source/backend change or leaving playback cannot become a remembered success. |
| UI | Auto/track selector, actual selected-track details, language input/apply and remember toggle in the existing scrollable controls. Loading/switching disables edits; errors are visible. Dark-control text and input contrast were corrected after screenshot inspection. |

System details use SDK track descriptions and selected-track queries. MPV combines its wrapper track stream with optional native `track-list` metadata. The pinned real MPV HAR declarations were inspected for the property methods used; native MPV was not run.

## Verification

| Check | Result |
| --- | --- |
| Host tests: audio policy/store/controller, both native adapters, adaptive adapter, playlists, orientation and artifact/architecture guards | 131 passed; zero failed/cancelled/skipped in the final combined run |
| SDK ArkTS/Hypium unit hook | 256 passed, Failure 0, Error 0, Ignore 0; includes three new audio policy tests |
| Independent focused review | Three findings reproduced and fixed; 13 focused tests passed on re-review, no remaining finding |
| Simulator application builds | First failed on an ArkTS untyped alias literal; second passed. Third passed after UI contrast changes and supplied the final installed bytes. |
| Final HAP ABI audit | Passed: one approved x86_64 FFmpeg library, no ARM MPV/AKI/C++ libraries |
| Normal HDC installation and explicit simulator EntryAbility start | Passed, no signing bypass, manual signer, uninstall, wipe or reset |
| Architecture boundary and whitespace checks | Passed |

Final unsigned HAP SHA256: `9AEBF38D2AB9C955903D7D7B3BB65CDE1560A45401EC757789AE8FA73AAFD424`.

Review regressions cover a delayed old playlist preference load overwriting a newer edit, ISO language aliases such as `it/ita` and `nl/nld/dut`, and late default-flag enrichment not reevaluating automatic selection. Old load generations are fenced and the track-change signature now includes the default flag. Earlier failing assertions and compiler output are retained privately.

## Actual application test actions

An existing API26 x86_64 simulator was started with the installed official CLI. A new 120-second 640×360/24fps H.264 MP4 was generated with two real mono AAC/48kHz audio streams: `eng`/440Hz as container default and `zho`/880Hz. It was transferred into Documents and imported through the application's normal system document picker into the existing local fixture folder. The device-to-host round trip matched all 19,427,045 bytes by SHA256: `1AC372E6938FFCB1A4F7CB4F0E63585C32A9318485E71ACD5184203F438BF78F`.

The final application build was installed and restarted before the following bounded checks. Decoded test-pattern frames and advancing progress were observed; selection results below come from the UI's separate backend-selected track detail, not merely the requested selector label.

| Action | Observed result |
| --- | --- |
| Open the fixture | Real decoded frames; two audio options, language/codec/1ch/48kHz/approximately 96kbps details. |
| With the stored Chinese preference, manually choose English, leave and reopen | Actual track changed to English; reopening restored English despite the Chinese preference. |
| Choose Auto, leave and reopen | Actual track became Chinese by preference; reopening remained Auto/Chinese, proving the old manual English memory had been cleared. |
| Enter an invalid language tag | Visible validation error; the last valid preference remained in effect. An automation append produced `zhfr`; it was corrected using ordinary select-all/delete editing. |
| Set unmatched French preference | Auto used the native default English track on reopen. |
| Disable memory, manually select Chinese, leave and reopen | Actual manual Chinese selection was observed; reopening returned Auto/English rather than restoring that manual selection. |
| From a manual Chinese selection, choose Auto with no matching language | Actual selected-track details returned to English in the same open player. |
| Restore test settings | Language input cleared, memory reenabled, Auto/English, fixture paused. Saved network servers and earlier local fixtures retained. |

An existing network item also exposed actual AC3/6ch/48kHz/640kbps metadata during navigation. It was not a multiple-audio network acceptance test. No external audio or subtitle was opened. No desktop GUI automation was used.

Early document-path probes failed before using the documented transfer path; a layout assertion caught an automation Back action that had left playback. These were corrected navigation/fixture operations, not accepted audio results. The initial player entry showed a screen-orientation warning; later fresh entries and the final screenshot showed Follow system normally. No orientation code changed and orientation acceptance was not repeated in this round.

## Limits and evidence

- System internal audio behavior above has actual simulator coverage. MPV has production-adapter host tests and real HAR API declaration inspection only: this checkout's simulator MPV HAR is a stub, so this is not MPV native playback or physical-device audio acceptance.
- No human listening check was performed. Decoded video and selected-track callbacks do not independently prove the acoustic output or audible continuity.
- Memory deliberately declines ambiguous semantic matches, and tracks without useful language/title metadata cannot be reliably restored across backend IDs. It falls back to the language/default policy instead of guessing.
- Network multi-track switching, large codecs, channel-layout/acoustic validation and physical-device regression remain untested here. Default-track flags are unavailable from the current System track-description mapping; they are not invented from the selected flag.
- Logs, layouts, screenshots, generated media and downloaded HAR remain private. No credentials, server addresses or device identifiers are published. The four generated lockfiles remain unstaged. The protected original workspace was not edited or built; no exhaustive bytewise snapshot is claimed.

Language-code correspondence source: [Library of Congress ISO 639-2 list](https://www.loc.gov/standards/iso639-2/ISO-639-2_utf-8.txt). Document transfer route: [Huawei device file explorer documentation](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V14/ide-device-file-explorer-V14).
