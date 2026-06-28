# SwiftUI Lifecycle Guidelines

This file replaces the template "hook" concept with SwiftUI lifecycle and state
rules. There are no React hooks in this project.

## Environment State

Views read shared app state with `@Environment(AppState.self)`.

```swift
// MacTmuxKit/Features/MenuBar/MenuBarPopoverView.swift
@Environment(AppState.self) private var app
```

Trigger app actions from event handlers or lifecycle modifiers, not from view
body evaluation.

## Async Work

Use `.task` when a surface should refresh or initialize on appearance:

```swift
// MacTmuxKit/Features/Dashboard/DashboardView.swift
.task {
    await app.refresh()
    applySelection()
}
```

Use `Task { ... }` inside button actions when invoking async app methods:

```swift
IconButton(systemName: "arrow.clockwise", help: "Refresh") {
    Task { await app.refresh() }
}
```

Do not start long-running subprocesses from a computed property or a view
builder branch.

## Local State

Use `@State` for transient view-local UI state: selected IDs, hover state,
inline editing text, confirm dialogs, and local progress flags.

Examples:

- `DashboardView.selectedSessionId`
- `DashboardView.selectedPaneId`
- `MenuBarPopoverView.confirmRestore`
- inline rename state in Dashboard row views

Use `@AppStorage` only for simple user preferences that map to `UserDefaults`.

## Change Handling

Use `.onChange` to react to a specific observable value, as Dashboard does for
`dashboardRequest` and selection changes.

Keep these handlers small. If a change needs tmux I/O or shared mutation, move
the work to `AppState` and call it from the handler.

## Motion

Gate animations on `accessibilityReduceMotion`.

```swift
// MacTmuxKit/Features/Dashboard/DashboardView.swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion
...
.animation(reduceMotion ? nil : .easeOut(duration: 0.25), value: app.toast)
```

Avoid infinite ambient animations and visual motion that does not communicate a
state change.
