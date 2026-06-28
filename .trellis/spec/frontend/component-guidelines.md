# SwiftUI Component Guidelines

SwiftUI components should feel native, compact, and terminal-adjacent. Follow
`DESIGN.md`, `DESIGN-CHECKLIST.md`, and `MacTmuxKit/Design/DesignTokens.swift`.

## Theme Tokens

Use `Theme` roles for app-specific color, type, radius, and terminal canvas
colors. Do not hardcode hex colors or gray values in views.

```swift
// MacTmuxKit/Design/DesignTokens.swift
static var accent: Color { ghostty.green }
static var terminalBackground: Color { ghostty.background }
static let rowTitle = SwiftUI.Font.system(size: 13, weight: .medium)
static let metric = SwiftUI.Font.system(size: 11, design: .monospaced).monospacedDigit()
```

Use semantic macOS styles (`.primary`, `.secondary`, system materials,
`List(.sidebar)`) for native chrome.

## Rows and Buttons

Prefer native controls and SF Symbols. Icon buttons need `.help(...)`.
Use existing shared components before inventing a new visual language.

Local examples:

- `IconButton` in `MacTmuxKit/Shared/`
- `MenuItemRow` and `StaticMenuLine` in `Features/MenuBar/`
- `SessionSidebar` and `WindowPaneColumn` row patterns in `Features/Dashboard/`

Menu-bar rows stay compact and glanceable. Dashboard rows support selection,
hover affordances, inline rename, and keyboard navigation where native lists
provide it.

## States

Every surface that depends on tmux data needs distinct loading, empty, and
error states.

- Loading: quiet inline `ProgressView().controlSize(.small)`, usually in a
  header or row-shaped skeleton.
- Empty: plain copy with an SF Symbol and a useful next action when possible.
- Error: use `AppState.statusMessage` / `TmuxError.userMessage`; do not disguise
  failures as ordinary emptiness.

The menu-bar popover header shows the local loading pattern:

```swift
// MacTmuxKit/Features/MenuBar/MenuBarPopoverView.swift
if app.isLoading {
    ProgressView()
        .controlSize(.small)
        .frame(width: 26, height: 26)
} else {
    IconButton(systemName: "arrow.clockwise", help: "Refresh") {
        Task { await app.refresh() }
    }
}
```

## Copy and Icons

- UI copy is short verb-noun text: "Switch", "Kill Pane", "Open Dashboard".
- Keep errors plain and specific.
- Do not use emoji in UI strings.
- Do not use em dashes in UI strings.
- Use SF Symbols rather than custom SVG or drawn paths.

## Anti-patterns

- decorative gradients, invented purple accents, or status colors as flair;
- cards nested inside cards;
- full-window spinners for routine refreshes;
- view-local subprocesses or tmux parsing;
- a new row style for one isolated button when an existing row/button component
  fits the surface.
