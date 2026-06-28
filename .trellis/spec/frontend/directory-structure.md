# UI Directory Structure

Keep UI work organized by surface. Each feature owns its views and AppKit
window/controller glue.

## Feature Surfaces

`MacTmuxKit/Features/` contains user-facing surfaces:

- `MenuBar/` for the status item popover quick switcher.
- `Dashboard/` for the three-column session/window/pane browser.
- `CommandPalette/` for fuzzy switch and command entry.
- `Console/` for explicit tmux command execution.
- `Cheatsheet/` for discoverable tmux shortcuts.
- `Settings/` for app preferences and hotkey configuration.

Use the existing surface directory before creating a new shared abstraction.
For example, Dashboard-specific row views should live under `Features/Dashboard`
unless they are reused by another surface.

## Shared UI

Use `MacTmuxKit/Shared/` for genuinely shared SwiftUI pieces such as icon
buttons, empty states, or toasts. Shared components should stay small and
theme-driven.

Use `MacTmuxKit/Design/` for design tokens and theme resolution. Do not place
per-feature layout code there.

## AppKit Controllers

AppKit glue belongs next to the surface it opens:

- `DashboardWindowController` in `Features/Dashboard/`
- command palette controller in `Features/CommandPalette/`
- console controller in `Features/Console/`
- cheatsheet controller in `Features/Cheatsheet/`

The controller should open, focus, and size the window. Feature behavior should
stay in SwiftUI views and `AppState` actions.

## Composition Pattern

The local Dashboard pattern is a thin surface view composed from columns:

```swift
// MacTmuxKit/Features/Dashboard/DashboardView.swift
NavigationSplitView {
    SessionSidebar(selectedSessionId: $selectedSessionId)
} content: {
    WindowPaneColumn(sessionId: selectedSessionId, selectedPaneId: $selectedPaneId)
} detail: {
    PaneDetailColumn(paneId: selectedPaneId)
}
```

Avoid large multi-purpose views that mix window setup, tmux actions, parser
logic, and visual rows in one file.
