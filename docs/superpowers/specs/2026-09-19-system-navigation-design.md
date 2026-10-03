# System Navigation Migration

## Goal

Use ArkUI's native `Navigation`, `NavPathStack`, and `NavDestination` for hierarchical screens so system back gestures, toolbar back actions, route lifecycle, and default transition animations follow one navigation stack.

Top-level Library, Network, History, and Settings tabs remain peer sections and do not animate as forward navigation.

## Scope

Move existing hierarchical states into system destinations:

- local media folders;
- settings detail screens;
- saved network server browsers and their directories;
- hidden local items;
- the system component demo.

The player remains a full-screen overlay because it is an immersive mode rather than ordinary hierarchical navigation. Native sheets and dialogs continue to use their existing system dismissal behavior.

## Structure

`Index` owns one `NavPathStack` and wraps `AdaptiveAppShell` in a stack-mode `Navigation`. The shell is the navigation root. Destinations cover the whole shell, so the bottom bar is visible only on the four top-level sections.

Each logical forward step pushes a typed route parameter:

- local folder: folder URI;
- settings detail: detail identifier;
- network browser: server identity, protocol, and directory path;
- hidden items and component demo: no additional parameter.

Existing custom `AppToolbar` components stay visible inside destinations. Their back buttons call `NavPathStack.pop()`. Default `Navigation` title bars stay hidden.

## Navigation Behavior

- Tapping a folder, settings row, or saved server pushes a `NavDestination` with the default system animation.
- Opening another local or remote directory pushes another destination.
- Toolbar back and the system edge-back gesture pop the same stack entry.
- When the stack is empty, system back on Network, History, or Settings returns to Library.
- When Library is the active root and the stack is empty, system back exits the application.
- No custom page transition is applied; ArkUI owns forward, backward, and gesture-driven animation.

`BackNavigationController` and its component registrations are removed after the destinations cover the same paths.

## State and Data

Route parameters hold navigation identity only. Media lists, settings, credentials, loading state, and playback data remain in their current controllers and stores.

Each destination derives its visible content from its route parameter. Retained destinations preserve their scroll position naturally while they remain on the stack. Popping a destination restores the previous route without rebuilding a parallel application-managed history.

Opening a media item still launches the existing player overlay. Closing the player reveals the same destination and navigation stack position.

## Error Handling

Existing loading and failure UI remains unchanged. If a destination parameter points to a removed folder or server, the destination shows the existing unavailable/error state and still allows a normal system back action.

## Verification

- Unit-test any route-parameter or parent-path logic owned by Linkora; do not test ArkUI's animation implementation.
- Run the existing unit suite and Debug/Release HAR and HAP builds.
- On a device or emulator, verify forward animation and both toolbar and edge-back behavior for every destination type.
- Verify top-level tab changes remain non-directional and that player close restores the previous destination.

## Deliberate Limits

- No custom transition tuning, shared-element animation, deep links, or persisted navigation stack.
- No new navigation abstraction over `NavPathStack`.
- Multi-window navigation is deferred until the app supports multiple windows.
