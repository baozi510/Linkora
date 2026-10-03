# System Navigation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace Linkora's state-driven secondary-page navigation with ArkUI `Navigation`, `NavPathStack`, and `NavDestination` so forward navigation, toolbar back, system back, edge-back gestures, and page transitions use one native stack.

**Architecture:** `Index` owns a single stack-mode `Navigation`; `AdaptiveAppShell` remains its root and the player remains a full-screen overlay. Typed destination parameters identify local folders, settings details, network server directories, hidden items, and the component demo; destination components use custom Linkora toolbars but call the native stack for push/pop.

**Tech Stack:** ArkTS, ArkUI `Navigation`/`NavPathStack`/`NavDestination`, Hypium, Hvigor, HarmonyOS compile/target SDK 26 with compatible SDK 12.

**Spec:** `docs/superpowers/specs/2026-09-19-system-navigation-design.md`

## Global Constraints

- Keep Library, Network, History, and Settings as non-directional peer tabs.
- Use ArkUI's default destination transition; do not add `transition`, `animation`, or `customNavContentTransition`.
- Keep the player as the existing full-screen overlay.
- Keep native sheets and dialogs on their existing system dismissal behavior.
- Add no navigation dependency and no wrapper around `NavPathStack`.
- Do not persist the path stack or add deep-link handling.
- The workspace contains pre-existing modified and untracked application files. Do not stage or commit product-code files during execution; use verification checkpoints so unrelated user work is never captured in a commit.

## Review Focus

- Invalid or mismatched `unknown` destination parameters show a recoverable “页面无法打开” destination with a working back button; Task 1 unit-tests the validators and Task 2 renders the fallback.
- A saved server deleted before its destination loads shows “服务器已不存在” and still allows native back; Task 4 verifies this with a missing positive server ID.
- Nested local and remote directories create one native stack entry per level, so one edge-back action removes exactly one level; Tasks 3 and 4 include device checks.
- Closing the player from a nested destination reveals the same destination and scroll state; Task 5 includes a device check.
- With an empty destination stack, back returns Network/History/Settings to Library, and back from Library root exits; Task 5 covers both cases.

---

### Task 1: Typed Destination Contract

**Files:**
- Create: `entry/src/main/ets/models/AppNavigation.ets`
- Create: `entry/src/test/AppNavigation.test.ets`
- Modify: `entry/src/test/List.test.ets`

**Interfaces:**
- Produces: `AppDestination`, `SettingsDetail`, `LocalFolderDestinationParams`, `SettingsDetailDestinationParams`, `NetworkDirectoryDestinationParams`, and `AppNavigationParams` validators.
- Consumes: no earlier task interfaces.

- [ ] **Step 1: Write the failing destination-parameter tests**

Create `entry/src/test/AppNavigation.test.ets`:

```typescript
import { describe, expect, it } from '@ohos/hypium';
import { AppNavigationParams, LocalFolderDestinationParams,
  NetworkDirectoryDestinationParams, SettingsDetail, SettingsDetailDestinationParams } from
  '../main/ets/models/AppNavigation';

export default function appNavigationTest(): void {
  describe('AppNavigationParams', () => {
    it('acceptsOnlyValidLocalFolderParams', 0, () => {
      expect(AppNavigationParams.localFolder(new LocalFolderDestinationParams('file://videos'))?.folderUri)
        .assertEqual('file://videos');
      expect(AppNavigationParams.localFolder(new LocalFolderDestinationParams(''))).assertNull();
      expect(AppNavigationParams.localFolder(new SettingsDetailDestinationParams(SettingsDetail.PLAYER)))
        .assertNull();
    });

    it('acceptsOnlyValidSettingsDetailParams', 0, () => {
      expect(AppNavigationParams.settingsDetail(
        new SettingsDetailDestinationParams(SettingsDetail.APPEARANCE))?.detail)
        .assertEqual(SettingsDetail.APPEARANCE);
      expect(AppNavigationParams.settingsDetail(new LocalFolderDestinationParams('file://videos'))).assertNull();
    });

    it('acceptsPositiveServerIdsAndAnyDirectoryPath', 0, () => {
      expect(AppNavigationParams.networkDirectory(new NetworkDirectoryDestinationParams(7, ''))?.serverId)
        .assertEqual(7);
      expect(AppNavigationParams.networkDirectory(new NetworkDirectoryDestinationParams(7, '/movies'))?.path)
        .assertEqual('/movies');
      expect(AppNavigationParams.networkDirectory(new NetworkDirectoryDestinationParams(0, '/movies'))).assertNull();
    });
  });
}
```

Import and invoke `appNavigationTest()` from `entry/src/test/List.test.ets`.

- [ ] **Step 2: Run the test and verify RED**

Run:

```powershell
& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' test --mode module -p module=entry@default -p product=default --no-daemon
```

Expected: `UnitTestArkTS` fails because `models/AppNavigation` does not exist.

- [ ] **Step 3: Add the minimal route names, parameters, and validators**

Create `entry/src/main/ets/models/AppNavigation.ets`:

```typescript
export enum AppDestination {
  LOCAL_FOLDER = 'local_folder',
  SETTINGS_DETAIL = 'settings_detail',
  NETWORK_DIRECTORY = 'network_directory',
  HIDDEN_ITEMS = 'hidden_items',
  SYSTEM_COMPONENTS = 'system_components'
}

export enum SettingsDetail {
  HOME = 'home',
  PLAYER = 'player',
  NETWORK = 'network',
  LOCAL_MEDIA = 'local_media',
  APPEARANCE = 'appearance'
}

export class LocalFolderDestinationParams {
  readonly folderUri: string;
  constructor(folderUri: string) { this.folderUri = folderUri; }
}

export class SettingsDetailDestinationParams {
  readonly detail: SettingsDetail;
  constructor(detail: SettingsDetail) { this.detail = detail; }
}

export class NetworkDirectoryDestinationParams {
  readonly serverId: number;
  readonly path: string;
  constructor(serverId: number, path: string) {
    this.serverId = serverId;
    this.path = path;
  }
}

export class AppNavigationParams {
  static localFolder(param: unknown): LocalFolderDestinationParams | null {
    return param instanceof LocalFolderDestinationParams && param.folderUri.length > 0 ? param : null;
  }

  static settingsDetail(param: unknown): SettingsDetailDestinationParams | null {
    return param instanceof SettingsDetailDestinationParams && param.detail !== SettingsDetail.HOME ? param : null;
  }

  static networkDirectory(param: unknown): NetworkDirectoryDestinationParams | null {
    return param instanceof NetworkDirectoryDestinationParams && param.serverId > 0 ? param : null;
  }
}
```

- [ ] **Step 4: Run the unit suite and verify GREEN**

Run the Hvigor test command from Step 2.

Expected: `BUILD SUCCESSFUL`, and `entry/.test/default/intermediates/test/coverage_data/test_result.txt` contains `Failure: 0` and `Error: 0`.

- [ ] **Step 5: Record the checkpoint without staging product files**

Run `git diff --check` and record “Task 1 green” in the execution log. Do not commit because `List.test.ets` already contains pre-existing user changes.

---

### Task 2: Native Navigation Shell and Simple Destinations

**Files:**
- Modify: `entry/src/main/ets/pages/Index.ets:23-452`
- Modify: `entry/src/main/ets/pages/SettingsPage.ets:7-486`
- Modify: `entry/src/main/ets/models/AppNavigation.ets`

**Interfaces:**
- Consumes: Task 1 destination names, parameter classes, and validators.
- Produces: `Index.navigationStack: NavPathStack`, `Index.destinationBuilder(name, param)`, and `SettingsPage.onOpenDetail/onBack` callbacks.

- [ ] **Step 1: Record the current non-native settings behavior as RED**

On an emulator/device, open Settings → Appearance and use edge-back. Record that `SettingsPage.detail` changes directly, with no `NavDestination` entry or system transition. Also record that Hidden Items uses a hand-written `TransitionEffect`, not the system navigation transition. These are the two behaviors this task replaces.

- [ ] **Step 2: Convert SettingsPage from internal navigation state to route input**

In `SettingsPage.ets`, import `SettingsDetail`, remove the local enum and `BackNavigationController`, and replace internal navigation ownership with:

```typescript
@Prop detail: SettingsDetail = SettingsDetail.HOME;
onOpenDetail: (detail: SettingsDetail) => void = () => {};
onBack: () => void = () => {};

aboutToAppear(): void {
  if (this.detail === SettingsDetail.LOCAL_MEDIA) {
    this.videoExtensionsText = this.settings.localVideoExtensions.join(', ');
    this.subtitleExtensionsText = this.settings.localSubtitleExtensions.join(', ');
  }
}
```

Change the Local Media row to call `this.onOpenDetail(SettingsDetail.LOCAL_MEDIA)`, Player to call `this.onOpenDetail(SettingsDetail.PLAYER)`, Network Playback to call `this.onOpenDetail(SettingsDetail.NETWORK)`, and Appearance to call `this.onOpenDetail(SettingsDetail.APPEARANCE)`. Change the toolbar to `showBack: this.detail !== SettingsDetail.HOME` and `onBack: this.onBack`. Keep all existing setting controls and callbacks unchanged.

- [ ] **Step 3: Wrap the shell in Navigation and push simple destinations**

In `Index.ets`, add:

```typescript
private navigationStack: NavPathStack = new NavPathStack();

private openSettingsDetail(detail: SettingsDetail): void {
  this.navigationStack.pushPath(new NavPathInfo(AppDestination.SETTINGS_DETAIL,
    new SettingsDetailDestinationParams(detail)));
}
```

Replace the root layout with this shape:

```typescript
Stack() {
  Navigation(this.navigationStack) {
    AdaptiveAppShell({
      activeSection: this.activeSection,
      navigationHidden: this.localSelectionMode,
      networkStorageEnabled: this.settings.experimentalNetworkStorage,
      onSectionChange: (section: AppSection) => {
        this.activeSection = section;
        this.localSelectionMode = false;
        this.selectedLocalEntryKeys = [];
      }
    }) {
      this.currentSection()
    }
  }
  .mode(NavigationMode.Stack)
  .hideTitleBar(true)
  .navDestination(this.destinationBuilder)

  if (this.activeSource !== null) {
    PlayerPage({
      source: this.activeSource as MediaSource,
      settings: this.settings,
      onBack: () => {
        this.activeSource = null;
        this.libraryController?.refreshPlaybackProgress().catch(() => {});
      },
      onOpenSettings: () => {
        this.activeSource = null;
        this.libraryController?.refreshPlaybackProgress().catch(() => {});
        this.activeSection = AppSection.SETTINGS;
      }
    })
      .zIndex(2)
  }
}
```

Use one `if / else if` chain in `destinationBuilder`, with one `NavDestination` per branch. Hide every system title bar. For settings, validate with `AppNavigationParams.settingsDetail(param)` and render `SettingsPage` with the validated detail plus `onBack: () => this.navigationStack.pop()`.

Push `AppDestination.HIDDEN_ITEMS` and `AppDestination.SYSTEM_COMPONENTS` from the existing callbacks. Move their existing component bodies into corresponding `NavDestination` branches and delete `hiddenItemsPageVisible`, `systemComponentDemoVisible`, and the hand-written hidden-page transition.

For an invalid name or parameter, render:

```typescript
NavDestination() {
  Column({ space: 12 }) {
    Text('页面无法打开')
    Button('返回').onClick(() => this.navigationStack.pop())
  }
  .width('100%')
  .height('100%')
  .justifyContent(FlexAlign.Center)
}
.hideTitleBar(true)
```

- [ ] **Step 4: Compile the native shell**

Run `& '.\scripts\verify.ps1'`.

Expected: unit tests plus Debug/Release HAR and HAP builds pass. Existing ArkTS warnings may remain, but there must be no new navigation compiler error.

- [ ] **Step 5: Record the checkpoint without staging product files**

Run `git diff --check` and record “Task 2 green” in the execution log. Do not commit pre-existing user files.

---

### Task 3: Local Folder Destinations

**Files:**
- Modify: `entry/src/main/ets/pages/Index.ets:253-333`
- Modify: `entry/src/main/ets/pages/LibraryPage.ets:20-1130`

**Interfaces:**
- Consumes: `AppDestination.LOCAL_FOLDER`, `LocalFolderDestinationParams`, and `Index.navigationStack`.
- Produces: `LibraryPage.onOpenFolder(folderUri)` and `LibraryPage.onBack()`; one native destination per folder.

- [ ] **Step 1: Create a manual RED reproduction record**

On an emulator/device with nested local folders, record the current behavior: open folder A, open child B, edge-back once. Expected current failure: no native destination transition/stack entry exists for B, so the gesture cannot perform a system animated one-level pop.

- [ ] **Step 2: Make LibraryPage route-driven**

Remove its `BackNavigationController` import, handler, and registration. Keep `selectedFolderUri` as an input prop, and replace `onFolderChange` with:

```typescript
onOpenFolder: (folderUri: string) => void = () => {};
onBack: () => void = () => {};
```

Change the toolbar to call `this.onBack()` when `selectedFolderUri.length > 0`. Pass `this.onOpenFolder` into `LocalMediaBrowser` so every child folder selection requests a push instead of mutating the current page. Delete `parentDirectoryUri()` because native pop owns ancestry.

- [ ] **Step 3: Reuse one Index builder for root and destination instances**

Extract the existing `LibraryPage({...})` argument list into:

```typescript
@Builder
private libraryPage(folderUri: string) {
  LibraryPage({
    recentItems: this.recentItems,
    localItems: this.localItems,
    localFolders: this.localFolders,
    hiddenItems: this.hiddenLocalItems,
    selectionMode: this.localSelectionMode,
    selectedEntryKeys: this.selectedLocalEntryKeys,
    playbackProgress: this.playbackProgress,
    selectedFolderUri: folderUri,
    folderFilter: this.folderFilter,
    browseMode: this.browseMode,
    localScanState: this.localScanState,
    localFailure: this.localFailure,
    localScanFailure: this.localScanFailure,
    refreshing: this.localRefreshing,
    onSelectLocal: () => this.selectLocalMedia(),
    onScanLocal: () => this.scanLocalMedia(),
    onFolderFilterChange: (filter: LocalMediaFolderFilter) => {
      this.libraryController?.setFolderFilter(filter).catch(() => {});
      this.settingsController?.setLocalMediaFolderFilter(filter);
    },
    onOpenFolder: (nextFolderUri: string) => {
      this.navigationStack.pushPath(new NavPathInfo(AppDestination.LOCAL_FOLDER,
        new LocalFolderDestinationParams(nextFolderUri)));
    },
    onBack: () => this.navigationStack.pop(),
    onBrowseModeChange: (mode: LocalBrowseMode) => {
      this.libraryController?.setBrowseMode(mode).catch(() => {});
    },
    onOpenNetwork: () => {
      this.activeSection = AppSection.NETWORK;
    },
    onPlay: (source: MediaSource) => this.openSource(source),
    onHideFolder: (folder: LocalMediaFolder) => {
      this.hideLocalItem(HiddenLocalItem.fromFolder(folder)).catch(() => {});
    },
    onHideMedia: (item: LocalMediaAsset) => {
      this.hideLocalItem(HiddenLocalItem.fromFile(item)).catch(() => {});
    },
    onRestoreHidden: (item: HiddenLocalItem) => {
      this.restoreHiddenLocalItem(item).catch(() => {});
    },
    onHideMany: (items: HiddenLocalItem[]) => {
      this.hideLocalItems(items).catch(() => {});
    },
    onRestoreManyHidden: (items: HiddenLocalItem[]) => {
      this.restoreHiddenLocalItems(items).catch(() => {});
    },
    onSelectionModeChange: (enabled: boolean) => {
      this.localSelectionMode = enabled;
      if (!enabled) {
        this.selectedLocalEntryKeys = [];
      }
    },
    onSelectedEntryKeysChange: (keys: string[]) => {
      this.selectedLocalEntryKeys = keys;
    },
    onOpenHiddenItems: () => {
      this.navigationStack.pushPath(new NavPathInfo(AppDestination.HIDDEN_ITEMS, null));
    },
    onRemoveManual: (uri: string) => {
      this.libraryController?.removeManual(uri).catch(() => {});
    },
    onCleanUnavailable: () => {
      this.libraryController?.removeUnavailableManual().catch(() => {});
    },
    loadLocalThumbnail: (uri: string): Promise<image.PixelMap | null> => {
      return this.thumbnailLoader?.load(uri) ?? Promise.resolve(null);
    }
  })
}
```

Render `this.libraryPage('')` in the Library tab. Add a `LOCAL_FOLDER` destination branch that validates the parameter and renders `this.libraryPage(route.folderUri)` inside `NavDestination().hideTitleBar(true)`. Stop calling `LibraryFeatureController.selectFolder()` for navigation; the route parameter is the only folder location.

- [ ] **Step 4: Build and verify one-level native pops**

Run `& '.\scripts\verify.ps1'`, then verify on device/emulator:

1. Root → folder A → folder B shows the system forward transition twice.
2. Toolbar back from B returns to A once.
3. Re-enter B; edge-back returns to A once with the system transition.
4. Back from A returns to the Library root.
5. An empty or removed folder displays the existing empty/unavailable UI and can still pop.

- [ ] **Step 5: Record the checkpoint without staging product files**

Run `git diff --check` and record “Task 3 green” in the execution log.

---

### Task 4: Network Server and Directory Destinations

**Files:**
- Create: `entry/src/main/ets/pages/NetworkBrowserPage.ets`
- Modify: `entry/src/main/ets/pages/Index.ets`
- Modify: `entry/src/main/ets/pages/NetworkPage.ets:60-1955`
- Modify: `entry/src/main/ets/components/WebDavBrowser.ets:14-300`
- Modify: `entry/src/main/ets/components/SmbBrowser.ets:18-320`
- Modify: `entry/src/main/ets/components/SftpBrowser.ets:18-315`
- Modify: `entry/src/main/ets/components/FileProtocolBrowser.ets:20-275`

**Interfaces:**
- Consumes: `NetworkDirectoryDestinationParams(serverId, path)` and `Index.navigationStack`.
- Produces: `NetworkPage.onOpenServer(serverId)`, `NetworkBrowserPage.onOpenDirectory(path)/onBack/onOpenSource`, and route-driven browser component props.

- [ ] **Step 1: Create the missing-server RED case**

Temporarily push `new NetworkDirectoryDestinationParams(2147483647, '')` from the Network toolbar in a local run. Record the current failure: no `NavDestination` resolves the ID or presents a recoverable missing-server screen. Remove the temporary trigger before Step 2.

- [ ] **Step 2: Make NetworkPage push a server route**

Delete `browserServer`, `browserGridView`, `closeBrowser()`, and the four inline browser component branches. Add:

```typescript
onOpenServer: (serverId: number) => void = () => {};
```

For WebDAV, SMB, SFTP, FTP, and NFS in `openServer(server)`, call `this.onOpenServer(server.id)`. Keep HTTP opening through `onOpenSource` and keep unsupported-protocol error handling unchanged.

- [ ] **Step 3: Add the destination wrapper that loads a server by ID**

Create `NetworkBrowserPage.ets` with these externally visible fields:

```typescript
@Component
export struct NetworkBrowserPage {
  @Prop serverId: number;
  @Prop path: string = '';
  onOpenDirectory: (path: string) => void = () => {};
  onBack: () => void = () => {};
  onOpenSource: (source: MediaSource) => void = () => {};

  @State private server: NetworkServerEntry | null = null;
  @State private loading: boolean = true;
  @State private failure: string = '';
  @State private gridView: boolean = NetworkViewSettingsStore.peek() ?? false;
}
```

In `aboutToAppear`, create `NetworkServerStore` and `NetworkViewSettingsStore`, load the server list, select the entry whose `id === serverId`, and set `failure = '服务器已不存在'` when no match exists. Render a centered loading state, a failure state with `AppToolbar({ title: '网络', showBack: true, onBack: this.onBack })`, or the protocol browser selected by `server.protocol`. Persist grid changes through `NetworkViewSettingsStore.save()`.

- [ ] **Step 4: Make each protocol browser represent exactly one route path**

For `WebDavBrowser`, remove `BackNavigationController`, add `@Prop path: string = ''`, `onOpenDirectory: (path: string) => void`, and `onBack: () => void`. Initialize `currentPath` to `path` when non-empty or normalized `server.rootPath` otherwise. On a directory entry call `onOpenDirectory(entry.path)`; pass `onBack` directly to `NetworkBrowserToolbar`.

For `SmbBrowser`, remove `BackNavigationController`, add the same three inputs, initialize `currentPath` to `path` or `service.location.initialPath`, call `onOpenDirectory(entry.path)` for directories, and pass `onBack` to the toolbar.

For `SftpBrowser`, remove `BackNavigationController`, add the same three inputs, initialize `currentPath` to `path` or `service.initialPath`, call `onOpenDirectory(entry.path)` for directories, and pass `onBack` to the toolbar.

For `FileProtocolBrowser`, remove `BackNavigationController`, add the same three inputs, initialize `currentPath` to `path` or `service.initialPath()`, call `onOpenDirectory(entry.path)` for directories, and pass `onBack` to the toolbar.

Delete each component's `goBack()` method and path mutation on directory open. Keep file opening, loading cancellation, errors, format detection, and progressive download logic unchanged.

- [ ] **Step 5: Connect network pushes and pops in Index**

Pass this callback to root `NetworkPage`:

```typescript
onOpenServer: (serverId: number) => {
  this.navigationStack.pushPath(new NavPathInfo(AppDestination.NETWORK_DIRECTORY,
    new NetworkDirectoryDestinationParams(serverId, '')));
}
```

Add the `NETWORK_DIRECTORY` destination branch. After validation, render `NetworkBrowserPage` with:

```typescript
NetworkBrowserPage({
  serverId: route.serverId,
  path: route.path,
  onOpenDirectory: (path: string) => {
    this.navigationStack.pushPath(new NavPathInfo(AppDestination.NETWORK_DIRECTORY,
      new NetworkDirectoryDestinationParams(route.serverId, path)));
  },
  onBack: () => this.navigationStack.pop(),
  onOpenSource: (source: MediaSource) => this.openSource(source)
})
```

- [ ] **Step 6: Build and verify every network protocol path**

Run `& '.\scripts\verify.ps1'`, then verify on device/emulator:

1. Open a saved server and two nested directories; each forward step uses the system transition.
2. Toolbar back and edge-back each remove exactly one directory level.
3. At the server root, back returns to the Network server list.
4. WebDAV, SMB, SFTP, FTP, and NFS preserve existing loading and file-open behavior.
5. A destination using a deleted positive server ID shows “服务器已不存在” and its back button pops normally.

- [ ] **Step 7: Record the checkpoint without staging product files**

Run `git diff --check` and record “Task 4 green” in the execution log.

---

### Task 5: Remove the Parallel Back Stack and Verify the Full Flow

**Files:**
- Delete: `entry/src/main/ets/services/BackNavigationController.ets`
- Delete: `entry/src/test/BackNavigationController.test.ets`
- Modify: `entry/src/main/ets/pages/Index.ets:88-115`
- Modify: `entry/src/test/List.test.ets`

**Interfaces:**
- Consumes: the complete native destination flow from Tasks 2–4.
- Produces: one navigation authority: ArkUI `NavPathStack` for secondary screens and `Index.onBackPress()` only for player/root fallback.

- [ ] **Step 1: Remove the obsolete controller test and verify RED**

Delete `BackNavigationController.ets` while its test/imports still exist and run the Task 1 Hvigor test command.

Expected: `UnitTestArkTS` fails because `BackNavigationController.test.ets` imports the removed module. This proves the old navigation path is still wired into the suite.

- [ ] **Step 2: Remove every old registration and test reference**

Delete `BackNavigationController.test.ets`, remove its import/invocation from `List.test.ets`, and confirm this command returns no matches:

```powershell
rg -n "BackNavigationController|systemBackHandler" entry/src/main/ets entry/src/test
```

Expected: exit code 1 with no output.

- [ ] **Step 3: Limit Index.onBackPress to root-level behavior**

Keep only this order:

```typescript
onBackPress(): boolean {
  if (this.activeSource !== null) {
    this.activeSource = null;
    this.libraryController?.refreshPlaybackProgress().catch(() => {});
    return true;
  }
  if (this.localSelectionMode) {
    this.localSelectionMode = false;
    this.selectedLocalEntryKeys = [];
    return true;
  }
  if (this.activeSection !== AppSection.LIBRARY) {
    this.activeSection = AppSection.LIBRARY;
    return true;
  }
  return false;
}
```

Do not pop `navigationStack` here. A visible `NavDestination` must receive the system back event first so ArkUI owns its gesture and transition.

- [ ] **Step 4: Run complete automated verification**

Run `& '.\scripts\verify.ps1'`.

Expected final line: `Verification completed: unit tests, Debug/Release HAR and Debug/Release HAP passed.`

- [ ] **Step 5: Run the final device navigation matrix**

Verify:

1. Top-level tab changes have no forward/back slide.
2. Settings detail, hidden items, component demo, local folders, saved servers, and remote directories use native forward/back transitions.
3. The toolbar back button and edge-back gesture pop the same destination.
4. Open a video from a nested local or remote destination, close the player, and confirm the same destination and scroll position remain.
5. At an empty destination stack, back from Network/History/Settings returns to Library; back from Library root exits.
6. Native sheets/dialogs dismiss before navigation changes.

- [ ] **Step 6: Inspect only the task diff**

Run:

```powershell
git diff --check
git status --short
rg -n "transition\(|customNavContentTransition|BackNavigationController" entry/src/main/ets entry/src/test
```

Expected: no whitespace errors; no custom navigation transition or old controller remains. Report pre-existing unrelated dirty files separately and do not stage them.
