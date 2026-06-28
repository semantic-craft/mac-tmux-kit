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

- [ ] Selecting a running session shows recent active-pane output.
- [ ] A session with no active pane falls back to its first pane.
- [ ] A missing/no-pane case renders a clear fallback state.
- [ ] Capture failure is contained to the preview surface.
- [ ] Preview does not add background continuous streaming.
- [ ] Tests cover active pane selection, first pane fallback, and capture failure behavior at the shared state/service seam.
- [ ] Manual verification includes one active agent/build pane and one quiet shell pane.

## Notes

- Rich preview belongs in the Dashboard first; keep the menu-bar popover compact unless a later task proves a compact preview is needed.
