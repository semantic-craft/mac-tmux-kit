# Copy tmux debug snapshot

## Source

- GitHub issue: https://github.com/semantic-craft/mac-tmux-kit/issues/6
- Parent Trellis task: `06-29-adopt-proven-tmux-management-patterns`

## Blocked By

- `06-29-finish-trustworthy-refresh-state`

## Problem

If the CLI can see a tmux session but the UI looks stale or wrong, the next debugging session needs compact evidence: binary path, socket path, app-known state, and tmux read results. Without that snapshot, diagnosis depends on ad hoc shell commands.

## Requirements

- Add a lightweight debug snapshot action from an appropriate native UI surface.
- Snapshot includes tmux binary path and resolved socket path.
- Snapshot includes last refresh status, loading/error state, and app-known session/window/pane counts.
- Snapshot includes concise sessions/windows/panes summary using stable tmux IDs and names.
- Snapshot includes tmux read failures encountered while building the snapshot.
- Snapshot is copied to the clipboard and confirms success using existing toast/status behavior.
- Snapshot generation does not mutate tmux state and does not add persistent logs.

## Acceptance Criteria

- [x] The user can trigger a debug snapshot from the UI.
- [x] The copied snapshot contains binary path, socket path, refresh status, counts, and session summaries.
- [x] A running known tmux session appears in the snapshot.
- [x] Snapshot failures are included as text rather than crashing or showing a silent failure.
- [x] Snapshot action is read-only with respect to tmux.
- [x] Manual verification copies a snapshot while a known session is running and checks that the session name is present.

## Notes

- This is not a logging subsystem.
- Keep the output human-readable and suitable for pasting into an issue or chat.

## Verification

- `xcodebuild test -scheme MacTmuxKit -destination 'platform=macOS'`: PASS, 12 app tests. Xcode printed the existing CoreSimulator version warning, but macOS tests completed successfully.
- `./scripts/build-app.sh`: PASS, installed and launched `/Applications/MacTmuxKit.app`.
- Manual UI smoke: opened the MacTmuxKit menu-bar popover with System Events, clicked the Actions row for `Copy Debug Snapshot`, and read the clipboard.
- Manual clipboard snapshot included `binary: /opt/homebrew/bin/tmux`, `socket: /tmp/tmux-501/default`, app/fresh counts `sessions=2 windows=2 panes=4`, `failures: none`, and the running session names `develop` and `taiwan`.
