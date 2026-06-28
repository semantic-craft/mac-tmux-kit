# External State and Persistence

This project has no database. Treat this file as the guide for the external
state Tmux Kit is allowed to read or write.

## tmux Server State

The tmux server is the main external state. Read it through `TmuxService`, not
from views or ad hoc shell scripts.

Important local rules:

- Resolve the tmux socket explicitly and pass `-S <socket>` on every call.
- Prefer stable tmux IDs (`$N`, `@N`, `%N`) for mutation targets.
- Use names only for display, creation text, or tmux APIs that explicitly
  return names.
- A missing tmux server is a valid empty state for read paths.

Reference files:

- `MacTmuxKit/Services/Tmux/TmuxService.swift`
- `MacTmuxKit/Services/Tmux/TmuxService+Sessions.swift`
- `MacTmuxKit/Services/Tmux/TmuxService+Windows.swift`
- `MacTmuxKit/Services/Tmux/TmuxService+Panes.swift`

## User Preferences

Small UI and runtime preferences live in `UserDefaults` / `@AppStorage`.
Examples already in the app:

- `tmuxBinaryPath` in `AppState.init()`.
- `sessionClickAction` in `AppState.activateFromMenuBar(_:)`.
- `resurrectRestoreProcesses` in `MenuBarPopoverView`.
- `pinnedSessionNames` in `AppState`, stored as session names so recreated
  project sessions can be prioritized again.

Do not introduce a database, JSON store, or migration system for simple app
preferences unless the project first gains a real persistence requirement.

Pinned session names are preferences, not live tmux state. UI lists must still
come from the current tmux session array, and tmux mutations must continue to
target stable session IDs.

## Project Files

`project.yml` is the source of truth for the app target and dependencies. The
generated `.xcodeproj` is ignored and should not be treated as durable state.

## Local Config Boundaries

Tmux Kit reads local tools but does not silently modify user configuration.

Allowed current behavior:

- run the user's local `tmux` executable;
- read Ghostty theme configuration at launch;
- use Accessibility when the user grants permission;
- save/restore layouts through tmux-resurrect only when the user invokes that
  action.

Forbidden patterns:

- automatic edits to `~/.tmux.conf`;
- automatic plugin installation;
- telemetry, accounts, or remote network calls;
- logging pane content or environment variables as persistent app state.
