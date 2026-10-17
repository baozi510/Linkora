# Default proportional fit recovery — 2026-10-17

User request: videos should open in proportional fit, rather than stretch to fill the screen. Candidate `codex/linkora-default-fit-20261017`, based on `e170a07f8d8a05ddb65bf9b79968ece8ea9da2c8`.

## Observed failure and change

The engine already requested FIT by default. On the existing System native playlist, the UI still said fit while the actual 640x360 video filled the tall screen and was visibly stretched. Cycling the three existing display choices back to fit immediately produced a proportional, centered picture with black bars. Before/reapply screenshots are retained privately.

System now retains the last successfully applied display mode (initially FIT) and reapplies it through the existing native setter at each first rendered frame. This covers a native reset after preparation or a playlist transition. Existing user-selected crop/stretch modes remain usable. A failed reapplication emits a nonfatal display warning, and the engine invalidates the old display-mode acknowledgement instead of claiming it remains applied.

No custom size/aspect-ratio calculations, new compatibility branches, dependencies or settings were added. The full-screen playback page, screen-direction behavior and MPV native mode mapping are unchanged.

## This round's actual behavior

1. Reproduced the stretch-with-fit-label mismatch in the installed application using the existing two-audio local fixture.
2. Manually cycled crop/stretch/fit and inspected the resulting correctly proportioned picture, confirming the native fit mode works when applied after playback has started.
3. Built one simulator package with the fix, audited its native ABI, installed it normally and explicitly started the simulator application.
4. Opened the video through its normal library entry: the 16:9 picture was centered with black space above and below, without a manual mode change.
5. Used previous to move from item 4 to item 3, and next to return to item 4. UI tree confirmed the actual filenames/indices; both resulting screenshots retained proportional fit. Audio metadata and remembered Chinese/English selections remained present.
6. Paused playback; final UI tree showed the play button and fit mode.

Two earlier coordinate clicks occurred after controls hid and did not change the item. They are not counted as queue validation; the later captures above confirmed actual 3/4 and 4/4 transitions.

## Verification and limits

| Check | Result |
| --- | --- |
| Regression-first checks | Three failing assertions observed before the fix: default frame scale, failed recovery warning, and stale display acknowledgement. Final focused run: 57 passed. |
| Combined host regression suite | 135 passed; zero failed, cancelled or skipped. Covers both adapter boundaries, engine/adaptive, audio memory, playlists, orientation and artifact/architecture checks. |
| SDK ArkTS/Hypium hook | 256 run, Pass 256, Failure 0, Error 0, Ignore 0. |
| Simulator build | One build, successful. |
| Native HAP audit | One approved x86_64 FFmpeg library; no ARM MPV/AKI/C++ native libraries. |
| HDC installation/start and application UI | Passed; new open and actual previous/next screenshots inspected. No uninstall, wipe, reset or manual signing. |
| Exact diff/whitespace review | Only two production files, two existing test files and this report staged. Generated dependency locks excluded. |

Installed simulator HAP SHA256: `9C3D8C14991DDB83605030C9114FCB806B2A5ABF85278FD6066378AB2828E3DF`.

One edit command failed on a line-ending anchor before writing production files; it was corrected. No compiler or final test failures were hidden. Raw device evidence remains private. Existing server/media records and original workspace were not edited or cleaned. Candidate publication is not a production merge.

Physical-device rendering, native MPV rendering, landscape/axis-flip rendering and other source aspect ratios were not rerun in this round. MPV tests are controlled-boundary checks, and this simulator still uses the MPV stub. This report establishes System simulator proportional-fit recovery for the tested local fixture, not general rendering certification.
