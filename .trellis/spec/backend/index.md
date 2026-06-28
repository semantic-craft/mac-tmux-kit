# Core and Service Guidelines

In this repository, Trellis' `backend` spec means the non-UI side of Tmux
Kit: the pure `Core/` Swift package, tmux and Ghostty service adapters,
process execution, app orchestration helpers, and build scripts.

This is not a web backend. There is no API server, database, ORM, migrations,
network service, account system, or telemetry layer.

## Guides

| Guide | Applies to | Status |
| --- | --- | --- |
| [Directory Structure](./directory-structure.md) | `Core/`, `MacTmuxKit/Services/`, `MacTmuxKit/App/`, `scripts/`, `project.yml` | Project-specific |
| [External State and Persistence](./database-guidelines.md) | tmux server state, user defaults, generated project files, local config boundaries | Project-specific |
| [Error Handling](./error-handling.md) | `TmuxError`, `ProcessRunnerError`, UI-facing status messages | Project-specific |
| [Quality Guidelines](./quality-guidelines.md) | tmux CLI safety, parsing, IDs, tests, build verification | Project-specific |
| [Logging and Debug Output](./logging-guidelines.md) | status text, toasts, debug snapshots, sensitive output boundaries | Project-specific |

## Architecture Summary

Tmux Kit is a local-only native macOS app layered as:

```text
SwiftUI/AppKit UI
AppState actions and state
Services: Tmux, Ghostty, hotkeys
Core domain models, parser, tree helpers
local tmux and Ghostty processes
```

Reference files:

- `README.md` documents the product boundary: local-only, no telemetry, no
  edits to `~/.tmux.conf`, and no tmux plugin installation.
- `project.yml` is the source of truth for the Xcode project. The generated
  `.xcodeproj` is not committed.
- `Core/Package.swift` defines the pure Swift package used for headless tests.
- `MacTmuxKit/Services/Tmux/TmuxService.swift` is the high-level tmux adapter.
- `MacTmuxKit/App/AppState.swift` owns shared app state and mutating actions.
