# Core and Service Directory Structure

Use the existing package and feature boundaries. Do not create a web-style
backend tree for this app.

## Source of Truth

`project.yml` is the project definition. Regenerate the ignored Xcode project
with XcodeGen when needed; do not hand-edit generated project files.

```yaml
# project.yml
packages:
  TmuxKitCore:
    path: Core
```

## Pure Core

Put side-effect-free domain logic in `Core/Sources/TmuxKitCore/`.

Good fits:

- tmux model types such as `TmuxSession`, `TmuxWindow`, `TmuxPane`, `TmuxClient`.
- parser and format contracts in `TmuxFormat` and `TmuxParser`.
- value-type helpers such as `TmuxTree` and `PaneNaming`.

Core code should not import AppKit, SwiftUI, UserDefaults, Process, or
Accessibility APIs. It is tested with `cd Core && swift test`.

Reference files:

- `Core/Sources/TmuxKitCore/TmuxFormat.swift`
- `Core/Sources/TmuxKitCore/TmuxParser.swift`
- `Core/Sources/TmuxKitCore/TmuxTree.swift`
- `Core/Tests/TmuxKitCoreTests/TmuxParserTests.swift`

## Service Adapters

Put side-effecting integrations in `MacTmuxKit/Services/`.

- `MacTmuxKit/Services/Tmux/` owns the tmux CLI adapter, process execution,
  typed errors, and per-domain extensions for sessions, windows, panes, server
  commands, and resurrect actions.
- `MacTmuxKit/Services/Ghostty/` owns terminal focus and theme discovery.
- Service files should expose typed Swift APIs to `AppState`; views should not
  call `Process`, build tmux argument lists, or parse tmux output directly.

The local pattern is one small adapter core plus domain extensions:

```swift
// MacTmuxKit/Services/Tmux/TmuxService.swift
final class TmuxService: Sendable {
    let binary: URL
    let socket: String

    @discardableResult
    func run(_ args: [String], timeout: TimeInterval = 5) async throws -> String {
        let result = try await ProcessRunner.run(
            executable: binary,
            arguments: ["-S", socket] + args,
            timeout: timeout
        )
        ...
    }
}
```

## App Orchestration

Keep app-level coordination in `MacTmuxKit/App/`.

- `AppState.swift` owns the shared observable state, `TmuxService`, the
  current sessions/windows/panes, status text, toasts, and action methods.
- `MacTmuxKitApp.swift` owns lifecycle events, menu bar setup, wake/foreground
  refresh triggers, and hotkey registration.

When new work needs both UI and tmux state, prefer adding a small method on
`AppState` that calls a service API, then have the view trigger that method.

## Build and Tooling Scripts

Keep local build, run, signing, and release mechanics in `scripts/`.

Known commands:

- `cd Core && swift test` for pure domain and parser tests.
- `./scripts/build-app.sh` for a signed app installed to `/Applications`.
- `./scripts/run.sh` for debug build, re-sign, and relaunch while preserving
  Accessibility permission.

Avoid adding script-only behavior that bypasses the Swift service layer unless
it is strictly build or release tooling.
