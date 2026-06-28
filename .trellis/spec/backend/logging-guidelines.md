# Logging and Debug Output

Tmux Kit does not currently have a persistent logging subsystem. The app is a
local control surface, so most operational feedback belongs in the UI as status
text, progress indicators, or short toasts.

## Current Feedback Channels

- `AppState.statusMessage` for current refresh or availability state.
- `ToastView` via `AppState.showToast` for action success/failure feedback.
- Inline `ProgressView` for routine loading states.
- Shell command output only in explicit utility surfaces such as the tmux
  console.

Reference files:

- `MacTmuxKit/App/AppState.swift`
- `MacTmuxKit/Shared/ToastView.swift`
- `MacTmuxKit/Features/Console/ConsoleWindowController.swift`
- `MacTmuxKit/Features/MenuBar/MenuBarPopoverView.swift`

## Debug Snapshots

Debug snapshot work should be explicit and copyable, not always-on logging. It
collects enough local state to explain refresh problems: tmux binary path,
resolved socket, read failures, parsed session counts, and app status text.

`AppState.debugSnapshot()` owns the text contract. Keep it read-only: it may
call tmux list/display read methods, but it must not mutate tmux state, capture
pane content, or persist logs.

Never include by default:

- full environment variables;
- API keys, tokens, or secrets;
- large pane content;
- private paths beyond what the user deliberately copies.

Pane content is user work. Only capture it for UI preview or explicit copy
actions the user invokes.

## Anti-patterns

- Do not add background telemetry or network diagnostics.
- Do not print noisy logs from every 3-second refresh cycle.
- Do not rely on `print` statements as the main debugging tool for user-facing
  bugs; expose a copyable snapshot when the feature exists.
