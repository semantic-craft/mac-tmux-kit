# Finish trustworthy refresh state

## Source

- GitHub issue: https://github.com/semantic-craft/mac-tmux-kit/issues/3
- Parent Trellis task: `06-29-adopt-proven-tmux-management-patterns`

## Problem

When tmux changes while Tmux Kit is already running, the Dashboard and menu-bar popover must not show stale or misleading session state. A real tmux session that is visible to the CLI must become visible in the UI without restarting the app.

## Requirements

- Opening the menu-bar popover refreshes sessions, windows, panes, and host state.
- Showing or refocusing the Dashboard refreshes sessions, windows, panes, and host state.
- App foreground activation and system wake trigger refresh.
- A refresh requested while another refresh is active is not silently dropped; one follow-up refresh runs after the active refresh completes.
- Loading state stays quiet and does not replace existing session content with a false empty state.
- Empty tmux state is distinct from tmux binary/socket/command failure.
- Preserve the current local-only model and stable tmux socket behavior.

## Acceptance Criteria

- [ ] Creating a new tmux session while the app is running causes it to appear after a visible refresh path without app restart.
- [ ] The menu-bar popover and Dashboard do not present stale state after being opened.
- [ ] A refresh-in-progress indicator is visible where appropriate and does not hide existing sessions.
- [ ] A true empty tmux server state reads as empty.
- [ ] A tmux access failure reads as an error, not as "No tmux sessions."
- [ ] Behavior tests cover refresh coalescing and empty/error state classification at the shared state seam.
- [ ] Manual verification records the tmux session name and socket used for the smoke test.

## TDD Notes

- Preferred seam: the shared app state tmux-state reader interface.
- Tests should exercise observable state after `refresh()`, not timer internals or SwiftUI private layout.
- Do not test the exact polling interval.
