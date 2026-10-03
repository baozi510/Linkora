# ArkUI State Management V2 Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate every ArkUI page and custom component in `entry/src/main/ets` to state management V2, remove the V1 state channel, and preserve all current behavior.

**Architecture:** Keep the existing component tree and business services. Convert local state, inputs, outputs, monitors, theme propagation, and built-in two-way bindings in place; use the existing verification script as a permanent regression guard against reintroducing V1 APIs.

**Tech Stack:** HarmonyOS ArkUI/ArkTS API 12+, `@ComponentV2`, `@Local`, `@Param`, `@Event`, `@Monitor`, `@Provider/@Consumer`, Hvigor, Hypium, PowerShell.

**Spec:** `docs/superpowers/specs/2026-09-21-arkui-state-management-v2-design.md`

## Global Constraints

- Migrate all 37 V1 components; retain the two existing V2 list components.
- Do not change navigation, layout, refresh, virtual scrolling, menu, or playback behavior.
- Do not modify service/store/model code unless device or compiler evidence proves deep V2 observation is required.
- Do not add dependencies or compatibility wrappers.
- Preserve API 12 compatibility.
- Only delete code after a whole-repository reference check proves it unused.

## Review Focus

- Replacing an array or object input must still refresh local folders, network entries, settings, and playback snapshots.
- URI/path/revision monitors must run after a real value change and must not trigger duplicate reloads.
- Changing the accent color in Settings must update every visible descendant without `AppStorage`.
- Dismissing local/network/server sheets must write `false` back through V2 `!!` binding.
- Navigation destinations and the full-screen/embedded player must retain state and system-back behavior.

---

### Task 1: Add a failing V2-only verification guard

**Files:**
- Modify: `scripts/verify.ps1`

**Interfaces:**
- Consumes: `entry/src/main/ets/**/*.ets`.
- Produces: a verification failure whenever V1 component state APIs or undecorated component output callbacks are present.

- [ ] **Step 1: Add the static guard before the existing Hvigor test command**

```powershell
$uiSource = Get-ChildItem -LiteralPath 'entry\src\main\ets' -Recurse -Filter '*.ets'
$legacyPatterns = @(
  '^\s*@Component\s*$',
  '@State\b',
  '@Prop\b',
  '@Watch\b',
  '@StorageProp\b',
  '\$\$this\.',
  '\bAppStorage\.'
)
$legacyUsage = $uiSource | Select-String -Pattern $legacyPatterns
$plainOutputs = $uiSource | Select-String -Pattern `
  '^\s+(on[A-Z][A-Za-z0-9]*|load[A-Z][A-Za-z0-9]*):\s*\([^)]*\)\s*=>.*=\s*'

if ($legacyUsage -or $plainOutputs) {
  @($legacyUsage) + @($plainOutputs) | ForEach-Object { Write-Host $_ }
  throw 'ArkUI state management V1 usage remains.'
}
```

- [ ] **Step 2: Run the guard and verify RED**

Run:

```powershell
& .\scripts\verify.ps1
```

Expected: FAIL before Hvigor runs with `ArkUI state management V1 usage remains.` and matches including `@Component`, `@State`, and `@Prop`.

- [ ] **Step 3: Keep the failing guard unstaged until Task 8**

Do not weaken the patterns to make it pass. Each later task removes a real match.

### Task 2: Migrate shared leaf components

**Files:**
- Modify: `entry/src/main/ets/components/AppActionListItem.ets`
- Modify: `entry/src/main/ets/components/AppIcon.ets`
- Modify: `entry/src/main/ets/components/AppIconButton.ets`
- Modify: `entry/src/main/ets/components/AppPageHeader.ets`
- Modify: `entry/src/main/ets/components/AppSectionHeader.ets`
- Modify: `entry/src/main/ets/components/AppSheetHeader.ets`
- Modify: `entry/src/main/ets/components/AppSheetSurface.ets`
- Modify: `entry/src/main/ets/components/AppToolbar.ets`
- Modify: `entry/src/main/ets/components/FailureNotice.ets`
- Modify: `entry/src/main/ets/components/FileTypeIconTile.ets`
- Modify: `entry/src/main/ets/components/MediaSourceCard.ets`
- Modify: `entry/src/main/ets/components/MetadataChip.ets`

**Interfaces:**
- Consumes: existing constructor property names and trailing `@BuilderParam` closures.
- Produces: the same components using `@ComponentV2`, `@Param`, `@Event`, `@Local`, and `@Consumer('linkoraAccentColor')`.

- [ ] **Step 1: Convert the component declarations and state fields**

Apply these exact mappings without renaming properties:

```arkts
@Component       -> @ComponentV2
@Prop value      -> @Param value
@State value     -> @Local value
onAction: (...)  -> @Event onAction: (...)
```

For the four leaf components currently reading theme storage, replace:

```arkts
@StorageProp('linkoraAccentColor') private accentColor: string = 'system';
```

with:

```arkts
@Consumer('linkoraAccentColor') private accentColor: string = 'system';
```

Keep `@BuilderParam` fields unchanged because they are supported by V2.

- [ ] **Step 2: Compile the migrated leaves**

Run:

```powershell
$env:DEVECO_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'
$env:JAVA_HOME='C:\Program Files\Huawei\DevEco Studio\jbr'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' assembleHap --mode module -p module=entry@default -p product=default -p buildMode=debug --no-daemon
```

Expected: `BUILD SUCCESSFUL`; no compiler error in the twelve migrated files.

- [ ] **Step 3: Commit the leaf migration**

```powershell
git add -- entry/src/main/ets/components/AppActionListItem.ets entry/src/main/ets/components/AppIcon.ets entry/src/main/ets/components/AppIconButton.ets entry/src/main/ets/components/AppPageHeader.ets entry/src/main/ets/components/AppSectionHeader.ets entry/src/main/ets/components/AppSheetHeader.ets entry/src/main/ets/components/AppSheetSurface.ets entry/src/main/ets/components/AppToolbar.ets entry/src/main/ets/components/FailureNotice.ets entry/src/main/ets/components/FileTypeIconTile.ets entry/src/main/ets/components/MediaSourceCard.ets entry/src/main/ets/components/MetadataChip.ets
git commit -m "refactor: migrate shared ArkUI components to V2"
```

### Task 3: Migrate the application root and adaptive shell

**Files:**
- Modify: `entry/src/main/ets/pages/Index.ets`
- Modify: `entry/src/main/ets/components/AdaptiveAppShell.ets`
- Modify: `entry/src/main/ets/components/AppBottomBar.ets`
- Modify: `entry/src/main/ets/components/AppSideBar.ets`

**Interfaces:**
- Consumes: `AppSettings.accentColor`, existing `AppSection` events, and all existing destination builders.
- Produces: root `@Provider('linkoraAccentColor') accentColor: string` and V2 shell events.

- [ ] **Step 1: Migrate the root state and introduce the theme provider**

Change `@Entry @Component` to `@Entry @ComponentV2`, convert every root `@State` to `@Local`, and add:

```arkts
@Provider('linkoraAccentColor') private accentColor: string = 'system';
```

When settings load or `onAccentColorChange` fires, assign both values in the same callback:

```arkts
this.settings = nextSettings;
this.accentColor = nextSettings.accentColor;
```

Keep the existing `AppStorage` write temporarily because unconverted descendants still use `@StorageProp`; Task 8 removes it after the last consumer migrates.

- [ ] **Step 2: Migrate adaptive navigation components**

Use `@Param` for `activeSection`, `navigationHidden`, and `networkStorageEnabled`; use `@Event` for `onSectionChange`/`onChange`; use `@Local` for `windowWidth`. Replace shell theme `@StorageProp` fields with `@Consumer('linkoraAccentColor')`.

- [ ] **Step 3: Compile the mixed V1/V2 tree**

Run:

```powershell
$env:DEVECO_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'
$env:JAVA_HOME='C:\Program Files\Huawei\DevEco Studio\jbr'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' assembleHap --mode module -p module=entry@default -p product=default -p buildMode=debug --no-daemon
```

Expected: `BUILD SUCCESSFUL`, proving the provider crosses the current mixed tree without changing navigation construction.

- [ ] **Step 4: Commit the root and shell migration**

```powershell
git add -- entry/src/main/ets/pages/Index.ets entry/src/main/ets/components/AdaptiveAppShell.ets entry/src/main/ets/components/AppBottomBar.ets entry/src/main/ets/components/AppSideBar.ets
git commit -m "refactor: migrate app shell state to ArkUI V2"
```

### Task 4: Migrate local browsing and history

**Files:**
- Modify: `entry/src/main/ets/pages/LibraryPage.ets`
- Modify: `entry/src/main/ets/pages/HistoryPage.ets`
- Modify: `entry/src/main/ets/pages/HiddenLocalItemsPage.ets`
- Modify: `entry/src/main/ets/components/LocalMediaBrowser.ets`
- Modify: `entry/src/main/ets/components/LocalMediaRow.ets`
- Modify: `entry/src/main/ets/components/MediaThumbnail.ets`
- Modify: `entry/src/main/ets/components/RecentMediaRow.ets`
- Modify: `entry/src/main/ets/components/RecentMediaThumbnail.ets`

**Interfaces:**
- Consumes: `LocalFolderPageData`, `LocalMediaAsset`, thumbnail loader callbacks, and existing local page callbacks.
- Produces: V2 local browsing inputs/events and monitors with unchanged list/grid rendering.

- [ ] **Step 1: Migrate page/component state and callback outputs**

Convert all `@Prop` inputs to `@Param`, all internal `@State` fields to `@Local`, all component callback/loader properties to `@Event`, and all theme storage fields to `@Consumer('linkoraAccentColor')`.

In the already-V2 `LocalMediaBrowser`, change callback and loader declarations from `@Param` to `@Event`; data inputs remain `@Param`.

- [ ] **Step 2: Replace V1 watches with V2 monitors**

Remove each property-level `@Watch('methodName')`. Add `@Monitor('projection')`,
`@Monitor('selectedFolderUri')`, `@Monitor('localViewSettingsRevision')`, and
`@Monitor('accentColor')` immediately above the correspondingly named existing
methods in `LibraryPage.ets`. Add `@Monitor('uri')` immediately above the existing
`onUriChanged` method in `MediaThumbnail.ets`. Do not change any of those method
bodies.

Do not add `@ObservedV2/@Trace`: these paths react to parameter replacement, not nested mutation.

- [ ] **Step 3: Convert the local menu sheet binding**

```arkts
.bindSheet(this.menuVisible!!, this.mediaMenuContent(), {
```

Keep the existing menu close and highlight code unchanged.

- [ ] **Step 4: Run local ordering/state tests and compile**

Run:

```powershell
$env:DEVECO_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'
$env:JAVA_HOME='C:\Program Files\Huawei\DevEco Studio\jbr'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' test --mode module -p module=entry@default -p product=default --no-daemon
& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' assembleHap --mode module -p module=entry@default -p product=default -p buildMode=debug --no-daemon
```

Expected: both commands report `BUILD SUCCESSFUL` and test result contains `Failure: 0` and `Error: 0`.

- [ ] **Step 5: Commit the local browsing migration**

```powershell
git add -- entry/src/main/ets/pages/LibraryPage.ets entry/src/main/ets/pages/HistoryPage.ets entry/src/main/ets/pages/HiddenLocalItemsPage.ets entry/src/main/ets/components/LocalMediaBrowser.ets entry/src/main/ets/components/LocalMediaRow.ets entry/src/main/ets/components/MediaThumbnail.ets entry/src/main/ets/components/RecentMediaRow.ets entry/src/main/ets/components/RecentMediaThumbnail.ets
git commit -m "refactor: migrate local browser state to ArkUI V2"
```

### Task 5: Migrate network browsing

**Files:**
- Modify: `entry/src/main/ets/pages/NetworkPage.ets`
- Modify: `entry/src/main/ets/pages/NetworkBrowserPage.ets`
- Modify: `entry/src/main/ets/components/NetworkBrowserToolbar.ets`
- Modify: `entry/src/main/ets/components/NetworkDirectoryBrowser.ets`
- Modify: `entry/src/main/ets/components/ConnectionTestPanel.ets`

**Interfaces:**
- Consumes: `NetworkServerEntry`, `NetworkDirectoryEntry[]`, existing service calls, refresh state, and server form callbacks.
- Produces: V2 network pages, menu sheets, toolbar events, and directory monitors.

- [ ] **Step 1: Migrate the network pages and toolbar**

Convert `@Component/@State/@Prop` to `@ComponentV2/@Local/@Param`; mark every externally supplied action as `@Event`; replace theme storage fields with `@Consumer('linkoraAccentColor')`.

In the existing V2 `NetworkDirectoryList`, change `onOpen` and `onScrollIndexChange` from `@Param` to `@Event`.

- [ ] **Step 2: Migrate network monitors**

Remove the property-level `@Watch` decorators. Add `@Monitor('path')` immediately
above the existing `onPathChanged` method and `@Monitor('accentColor')`
immediately above the existing `onAccentColorChanged` method. Do not change either
method body.

Preserve the current request generation guard and refresh-indicator lifecycle unchanged.

- [ ] **Step 3: Convert all network sheet bindings**

Replace the directory menu, saved-server menu, and add-server sheet bindings:

```arkts
.bindSheet(this.menuVisible!!, ...)
.bindSheet(this.serverSheetVisible!!, ...)
.bindSheet(this.addSheetVisible!!, ...)
```

- [ ] **Step 4: Run network state tests and compile**

Run:

```powershell
$env:DEVECO_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'
$env:JAVA_HOME='C:\Program Files\Huawei\DevEco Studio\jbr'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' test --mode module -p module=entry@default -p product=default --no-daemon
& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' assembleHap --mode module -p module=entry@default -p product=default -p buildMode=debug --no-daemon
```

Expected: `NetworkDirectoryState` tests and build pass without new compiler warnings in the migrated files.

- [ ] **Step 5: Commit the network migration**

```powershell
git add -- entry/src/main/ets/pages/NetworkPage.ets entry/src/main/ets/pages/NetworkBrowserPage.ets entry/src/main/ets/components/NetworkBrowserToolbar.ets entry/src/main/ets/components/NetworkDirectoryBrowser.ets entry/src/main/ets/components/ConnectionTestPanel.ets
git commit -m "refactor: migrate network browser state to ArkUI V2"
```

### Task 6: Migrate settings and system component demo

**Files:**
- Modify: `entry/src/main/ets/pages/SettingsPage.ets`
- Modify: `entry/src/main/ets/pages/SystemComponentDemoPage.ets`

**Interfaces:**
- Consumes: `AppSettings`, `SettingsDetail`, local view settings, and existing settings callbacks.
- Produces: V2 settings inputs/events and theme consumer.

- [ ] **Step 1: Convert settings state and outputs**

Use `@Param` for externally owned settings/detail inputs, `@Local` for form text/readiness fields, `@Event` for every settings action, and `@Consumer('linkoraAccentColor')` for the accent color.

Convert `SystemComponentDemoPage` state to `@Local`, its `onBack` callback to `@Event`, and its accent color to `@Consumer`.

- [ ] **Step 2: Compile settings pages**

Run:

```powershell
$env:DEVECO_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'
$env:JAVA_HOME='C:\Program Files\Huawei\DevEco Studio\jbr'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' assembleHap --mode module -p module=entry@default -p product=default -p buildMode=debug --no-daemon
```

Expected: `BUILD SUCCESSFUL` with no V2 initialization error for `AppSettings` or `SettingsDetail`.

- [ ] **Step 3: Commit settings migration**

```powershell
git add -- entry/src/main/ets/pages/SettingsPage.ets entry/src/main/ets/pages/SystemComponentDemoPage.ets
git commit -m "refactor: migrate settings pages to ArkUI V2"
```

### Task 7: Migrate player pages and controls

**Files:**
- Modify: `entry/src/main/ets/pages/PlayerPage.ets`
- Modify: `entry/src/main/ets/components/PlayerControls.ets`
- Modify: `entry/src/main/ets/components/PlayerFailureOverlay.ets`
- Modify: `entry/src/main/ets/components/PlayerGestureFeedback.ets`
- Modify: `entry/src/main/ets/components/PlayerStatusPanel.ets`
- Modify: `entry/src/main/ets/components/PlayerTopBar.ets`

**Interfaces:**
- Consumes: `MediaSource`, `AppSettings`, `PlaybackSnapshot`, `PlayerGestureState`, and playback control callbacks.
- Produces: V2 full-screen and preview player components with identical lifecycle behavior.

- [ ] **Step 1: Migrate both components declared in PlayerPage**

Convert both `@Component` declarations in `PlayerPage.ets` to `@ComponentV2`. Use `@Param` for source/settings/preview inputs, `@Local` for snapshot, seek, rate, volume, full-screen, controls, gesture, and surface state, and `@Event` for navigation callbacks.

Do not alter `aboutToAppear`, `aboutToDisappear`, media-surface lifecycle, timers, gesture calculations, or screen-on handling.

- [ ] **Step 2: Migrate player child components**

Use `@Param` for snapshots and display inputs and `@Event` for seek/playback/rate/volume/full-screen/retry/edit/settings/back outputs. No child owns a new copy of `PlaybackSnapshot` beyond its existing default initializer.

- [ ] **Step 3: Compile and run unit tests**

Run:

```powershell
$env:DEVECO_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'
$env:JAVA_HOME='C:\Program Files\Huawei\DevEco Studio\jbr'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' test --mode module -p module=entry@default -p product=default --no-daemon
& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' assembleHap --mode module -p module=entry@default -p product=default -p buildMode=debug --no-daemon
```

Expected: both commands report `BUILD SUCCESSFUL`; existing playback/controller tests remain green.

- [ ] **Step 4: Commit player migration**

```powershell
git add -- entry/src/main/ets/pages/PlayerPage.ets entry/src/main/ets/components/PlayerControls.ets entry/src/main/ets/components/PlayerFailureOverlay.ets entry/src/main/ets/components/PlayerGestureFeedback.ets entry/src/main/ets/components/PlayerStatusPanel.ets entry/src/main/ets/components/PlayerTopBar.ets
git commit -m "refactor: migrate player UI state to ArkUI V2"
```

### Task 8: Remove the V1 state channel and complete cleanup

**Files:**
- Modify: `entry/src/main/ets/pages/Index.ets`
- Modify: `scripts/verify.ps1`

**Interfaces:**
- Consumes: all V2 migrations from Tasks 2-7.
- Produces: a V2-only UI tree and a green permanent guard.

- [ ] **Step 1: Remove the temporary AppStorage bridge**

Delete all `AppStorage.setOrCreate`/`AppStorage.set` calls from `Index.ets`. The root provider assignment remains the sole theme state source:

```arkts
this.accentColor = state.settings.accentColor;
```

- [ ] **Step 2: Run the V2 guard and verify GREEN**

Run:

```powershell
& .\scripts\verify.ps1
```

Expected: the static guard finds no V1 usage, then unit tests plus Debug/Release HAR and HAP builds all pass; final line is `Verification completed: unit tests, Debug/Release HAR and Debug/Release HAP passed.`

- [ ] **Step 3: Check for residual files and imports**

Run:

```powershell
rg -n "@Component$|@State\b|@Prop\b|@Watch\b|@StorageProp\b|\$\$this\.|AppStorage\." entry/src/main/ets
rg -n "NetworkFileRow|LocalDisplayMenu|LocalMediaThumbnail|NetworkLoadingPanel|FileProtocolBrowser|SftpBrowser|SmbBrowser|WebDavBrowser" entry/src/main/ets entry/src/test
git diff --check
```

Expected: both `rg` commands return no matches and `git diff --check` is silent. Do not delete any additional file unless a separate `rg` for its exported symbols also returns no callers.

- [ ] **Step 4: Commit cleanup and the verification guard**

```powershell
git add -- scripts/verify.ps1 entry/src/main/ets/pages/Index.ets
git add -u -- entry/src/main/ets
git commit -m "refactor: complete ArkUI state management V2 migration"
```

### Task 9: Install and perform device regression verification

**Files:**
- No source changes expected.

**Interfaces:**
- Consumes: `entry/build/default/outputs/default/entry-default-signed.hap`.
- Produces: device evidence for theme, navigation, menus, refresh, list/grid switching, and playback.

- [ ] **Step 1: Install and launch the final Debug HAP**

```powershell
& 'C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe' app install -r 'D:\Linkora\entry\build\default\outputs\default\entry-default-signed.hap'
& 'C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe' shell aa start -a EntryAbility -b com.linkora.player
```

Expected: install and ability start both succeed.

- [ ] **Step 2: Verify application shell and theme propagation**

Open Settings, change the accent color, return to Local and Network, and confirm all bars, folders, icons, chips, and loading indicators update without relaunching.

- [ ] **Step 3: Verify local and network browsing**

For both sources, toggle list/grid twice, enter and leave a directory, pull to refresh, long-press an item, dismiss its sheet, and confirm position/icon updates remain atomic with correct target highlighting.

- [ ] **Step 4: Verify player and system back**

Open a playable item from Local and Network, enter/exit full screen, return from the player, then back out of each category root. Confirm player transitions remain intact and category-root back exits instead of returning to another category.

- [ ] **Step 5: Record final repository state**

```powershell
git status --short
git log -8 --oneline
```

Expected: only known pre-existing user files remain uncommitted; migration commits are present and no generated screenshot is left in the workspace.
