# Core and Service Quality Guidelines

Prefer small, typed, testable seams over stringly tmux plumbing scattered
through the UI.

## tmux Invocation Safety

All tmux calls must pass arguments as an array to `Process`. Do not build shell
strings from session names, paths, pane IDs, or user text.

```swift
// MacTmuxKit/Services/Tmux/ProcessRunner.swift
process.executableURL = executable
process.arguments = arguments
```

`TmuxService.run(_:)` is the normal entry point for tmux subcommands. It adds
the resolved socket before invoking `ProcessRunner`.

Forbidden:

- `sh -c "tmux ... \(userInput) ..."` for app actions;
- manually quoting tmux targets in views;
- parsing command output in feature views.

## Stable IDs

Use stable tmux IDs for mutation targets:

- sessions: `$N`
- windows: `@N` or target strings based on stable session ID plus index when
  tmux requires it;
- panes: `%N`

Names can contain spaces, punctuation, and non-English text. Treat names as
display text unless creating or renaming.

Reference files:

- `Core/Sources/TmuxKitCore/TmuxWindow.swift`
- `Core/Sources/TmuxKitCore/TmuxPane.swift`
- `MacTmuxKit/Services/Tmux/TmuxService+Panes.swift`

## Parser Contract

Keep tmux `-F` field order in `TmuxFormat` and consume the same order in
`TmuxParser`. Use ASCII Unit Separator (`0x1F`) between fields so commas,
braces, brackets, Chinese paths, and empty fields survive.

```swift
// Core/Sources/TmuxKitCore/TmuxFormat.swift
public static let unitSeparator: Character = "\u{1F}"
public static func formatString(_ fields: [String]) -> String {
    fields.map { "#{\($0)}" }.joined(separator: us)
}
```

Add Core tests when changing format fields, parsing behavior, pane naming, or
tree geometry.

## Refresh Semantics

`AppState.refresh()` is the shared refresh path. It loads sessions, windows,
panes, and host name in parallel, then updates observable state on the main
actor. If a refresh is already in progress, it queues one follow-up refresh.

Do not create independent session caches in UI surfaces. Use `AppState.tree`
and helper methods such as `activeWindow(in:)`, `activePane(in:)`, and
`paneCount(in:)`.

## Verification

For Core-only changes:

```sh
cd Core && swift test
```

For app or service changes that affect runtime behavior:

```sh
./scripts/build-app.sh
```

For visual/debug development:

```sh
./scripts/run.sh
```

When the bug concerns installed app behavior, verify the real installed app and
real tmux server state instead of relying only on README claims or unit tests.
