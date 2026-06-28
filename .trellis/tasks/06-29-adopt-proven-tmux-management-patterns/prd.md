# Adopt proven tmux management patterns

## Source

- GitHub parent issue: https://github.com/semantic-craft/mac-tmux-kit/issues/2

## Problem

Tmux Kit is the local macOS control surface for the user's tmux sessions, windows, and panes. The user needs the UI to stay trustworthy when tmux changes outside the app, and wants the project to adopt proven patterns from mature tmux management tools without turning Tmux Kit into a full terminal emulator.

## Requirements

- Keep session state fresh at user-visible moments.
- Make loading, empty, and tmux access/error states distinct.
- Prioritize important sessions with pinned sessions.
- Preview selected session pane output before switching.
- Provide a lightweight debug snapshot for stale-state diagnosis.
- Keep all behavior local-only: no telemetry, accounts, network dependency, tmux plugin install, or automatic tmux config edits.
- Continue using stable tmux IDs for live mutations.
- Keep the UI native macOS, terminal-adjacent, and compact.

## Child Tasks

- `06-29-finish-trustworthy-refresh-state` — GitHub #3.
- `06-29-preview-selected-session-pane` — GitHub #4.
- `06-29-pin-important-tmux-sessions` — GitHub #5.
- `06-29-copy-tmux-debug-snapshot` — GitHub #6, blocked by refresh state.

## Acceptance Criteria

- [ ] Each child task has its own Trellis PRD and can be implemented independently.
- [ ] GitHub issues remain the external tracker; Trellis tasks hold repo-local working context.
- [ ] Implementation tasks do not start until `.trellis/spec/` is bootstrapped for this SwiftUI/AppKit/tmux project or the task explicitly lists the temporary specs it relies on.
- [ ] The final integration keeps Dashboard, menu-bar popover, command palette, tmux service, and Core model behavior consistent.

## Notes

- Reference projects: https://github.com/devload/TmuxBar and https://github.com/daxliar/tmux-bar.
- Main lesson from those projects: use lightweight refresh and clear stale/empty/error state before considering heavyweight tmux control mode.
