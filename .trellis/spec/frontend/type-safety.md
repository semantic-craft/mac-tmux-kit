# Type Safety

Use Swift types and stable tmux identities to keep UI behavior trustworthy.

## Domain Models

Use the models from `Core/Sources/TmuxKitCore/` throughout the app:

- `TmuxSession`
- `TmuxWindow`
- `TmuxPane`
- `TmuxClient`
- `TmuxTree`

Do not pass dictionaries or raw parsed arrays into views when a typed model
already exists.

## Stable Targets

Prefer stable IDs for tmux actions and selection state:

- `session.id` (`$N`)
- `window.id` (`@N`) or a target string built by the model when tmux requires it
- `pane.id` (`%N`)

Names are not stable. A session called "taiwan" can be renamed; its ID remains
the trustworthy target.

## Optionals

Treat missing selections as normal. Dashboard columns often start with nil
selected IDs and then choose the active/first pane.

```swift
// MacTmuxKit/Features/Dashboard/DashboardView.swift
private func defaultPaneId(for sessionId: String?) -> String? {
    guard let sessionId else { return nil }
    let panes = app.panes.filter { $0.sessionId == sessionId }
    return (panes.first(where: \.active) ?? panes.first)?.id
}
```

Avoid force unwraps at UI and tmux boundaries. A pane, window, or session can
disappear between refreshes.

## Parser Safety

Parser changes belong in Core and should preserve malformed-record tolerance:
skip records with too few fields instead of crashing.

Reference tests:

- `Core/Tests/TmuxKitCoreTests/TmuxParserTests.swift`
- `Core/Tests/TmuxKitCoreTests/TmuxTreeTests.swift`
- `Core/Tests/TmuxKitCoreTests/PaneNamingTests.swift`

## Type Boundaries

Keep AppKit/SwiftUI types out of Core. Keep subprocess and Accessibility types
inside service/app layers. UI feature views should work with typed app state
and action methods rather than raw CLI outputs.
