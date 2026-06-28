# Preview selected session pane

## Source

- GitHub issue: https://github.com/semantic-craft/mac-tmux-kit/issues/4
- Parent Trellis task: `06-29-adopt-proven-tmux-management-patterns`

## Problem

When several tmux sessions are active, names alone are often not enough to identify the right workspace. The Dashboard should let the user inspect a session's current pane output, command, and directory before switching.

## Requirements

- Selecting a session in the Dashboard shows a preview of the session's active pane.
- If no active pane is known, preview the first pane in the session.
- If the session has no panes, show a contained empty state.
- The preview includes recent pane output, current command, and current directory when available.
- Capture failures show a contained fallback and do not break the Dashboard.
- Preview refresh happens on selection, open, and manual refresh; do not add continuous streaming.
- Reuse existing tmux capture behavior.

## Acceptance Criteria

- [x] Selecting a running session shows recent active-pane output.
- [x] A session with no active pane falls back to its first pane.
- [x] A missing/no-pane case renders a clear fallback state.
- [x] Capture failure is contained to the preview surface.
- [x] Preview does not add background continuous streaming.
- [x] Tests cover active pane selection, first pane fallback, and capture failure behavior at the shared state/service seam.
- [x] Manual verification includes one active agent/build pane and one quiet shell pane.

## Notes

- Rich preview belongs in the Dashboard first; keep the menu-bar popover compact unless a later task proves a compact preview is needed.

## Verification

- `swift test` in `Core/`: PASS, 17 tests.
- `xcodebuild test -scheme MacTmuxKit -destination 'platform=macOS'`: PASS, 6 app tests. Xcode printed a CoreSimulator version warning, but macOS tests completed successfully.
- `./scripts/build-app.sh`: PASS, installed and launched `/Applications/MacTmuxKit.app`.
- Manual build/agent-like pane: session `preview-agent-031940`, pane `%7`, socket `/private/tmp/tmux-501/default`, capture included `agent-build-pane-031940` and `build-ok`.
- Manual quiet shell pane: session `preview-shell-031940`, pane `%8`, command `zsh`, path `/Users/xianweizhang/Projects/mac-tmux-kit`.
- Temporary smoke sessions were removed after verification.
