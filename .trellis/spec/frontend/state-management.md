# State Management

`AppState` is the shared source of truth for tmux data and app actions. There
is no external state-management library.

## AppState Owns tmux State

`MacTmuxKit/App/AppState.swift` owns:

- sessions, windows, panes, and `hostShort`;
- `statusMessage`, `isLoading`, and `toast`;
- `TmuxService` and `GhosttyFocusService`;
- surface controllers for Dashboard, console, cheatsheet, and command palette;
- mutating action methods reused by views and hotkeys.

The local pattern:

```swift
@MainActor
@Observable
final class AppState {
    private(set) var sessions: [TmuxSession] = []
    private(set) var windows: [TmuxWindow] = []
    private(set) var panes: [TmuxPane] = []
    private(set) var statusMessage: String?
    private(set) var isLoading = false
    ...
}
```

Views should not duplicate this data in separate caches. Derive UI from
`app.sessions`, `app.tree`, and helper methods on `AppState`.

## Refresh Model

`AppState.refresh()` is the only normal refresh path. It loads sessions,
windows, panes, and host name in parallel, sorts sessions by activity, updates
the shared arrays, and sets a status message for empty/error states.

If a refresh is already running, it sets `refreshAgain` so exactly one follow-up
refresh runs after the current one finishes.

Future refresh improvements should preserve this contract rather than adding
independent timers to views.

## View-local State

Use local `@State` for UI-only state that can be rebuilt from shared app state:

- selected IDs in Dashboard;
- inline rename text;
- popover confirmation dialogs;
- hover/pressed affordances.

Dashboard selection is a local view concern, but external open requests flow
through `DashboardRequest` on `AppState`:

```swift
// MacTmuxKit/App/AppState.swift
struct DashboardRequest: Equatable {
    let sessionId: String
    let token = UUID()
}
```

The token intentionally makes repeated requests for the same session observable.

## Actions

Mutating actions should live on `AppState` or `TmuxService`, not in row views.
Use `AppState.run(success:_:)` for mutating tmux actions that should refresh and
surface success/failure feedback.

## Anti-patterns

- separate per-surface tmux polling;
- hidden copies of sessions/windows/panes in feature views;
- calling `TmuxService` directly from reusable row components;
- mutating view state to pretend a tmux action succeeded before the shared
  refresh confirms it, except for short toasts already handled by `AppState`.
