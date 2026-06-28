# Error Handling

Errors should be typed near the boundary where they happen, then surfaced as
plain user-facing status text through `AppState`.

## tmux Errors

Classify failed tmux CLI invocations in `TmuxError`, based on stderr and exit
code. The UI should consume `userMessage` instead of rendering raw technical
messages in normal states.

```swift
// MacTmuxKit/Services/Tmux/TmuxError.swift
static func classify(stderr: String, code: Int32) -> TmuxError {
    let s = stderr.lowercased()
    if s.contains("no server running") || s.contains("error connecting to") {
        return .serverNotRunning
    }
    if s.contains("no current client") || s.contains("no client") {
        return .noClient
    }
    ...
}
```

Read methods treat `serverNotRunning` as an empty result, because "no tmux
server yet" is a normal local-machine state:

```swift
// MacTmuxKit/Services/Tmux/TmuxService.swift
func listSessions() async throws -> [TmuxSession] {
    do {
        let out = try await run(["list-sessions", "-F", TmuxFormat.session])
        return TmuxParser.sessions(out)
    } catch TmuxError.serverNotRunning {
        return []
    }
}
```

Do not convert all failures to empty arrays. Missing binaries, no attached
client, bad targets, timeouts, and unknown CLI failures should remain visible.

## Process Errors

`ProcessRunner` throws `ProcessRunnerError.launchFailed` when macOS cannot
launch the executable. Continue to pass arguments as arrays and keep timeout
behavior in the runner.

## AppState Surfacing

`AppState.refresh()` sets `statusMessage` for refresh-level failures.
`AppState.run(success:_:)` sets both inline status and a failure toast for
mutating action failures.

Reference files:

- `MacTmuxKit/App/AppState.swift`
- `MacTmuxKit/Shared/ToastView.swift`
- `MacTmuxKit/Features/MenuBar/MenuBarPopoverView.swift`

## Anti-patterns

- Do not `try?` a tmux mutation whose failure changes user trust.
- Do not show "No tmux sessions" for binary-not-found or command-failed states.
- Do not force-unwrap process output or parsed values at tmux boundaries.
- Do not leak raw stderr into permanent logs; use it for the immediate user
  error where it is useful.
