# Pin important tmux sessions

## Source

- GitHub issue: https://github.com/semantic-craft/mac-tmux-kit/issues/5
- Parent Trellis task: `06-29-adopt-proven-tmux-management-patterns`

## Problem

When many tmux sessions exist, recency alone is not enough. The user needs important project sessions to stay easy to find in compact switching surfaces.

## Requirements

- The user can pin and unpin a session from a native context menu.
- Pinned sessions persist across app restarts.
- Pinned sessions appear before non-pinned recent sessions in the menu-bar popover.
- Pinned sessions are visually indicated in the Dashboard session list.
- Store pinned sessions by session name so common project sessions remain prioritized when recreated.
- Do not create phantom rows for pinned names that are not currently running.
- Continue using stable tmux IDs for live mutations.

## Acceptance Criteria

- [x] Pin and unpin actions are available from session context menus.
- [x] Pinned sessions are visibly marked in the Dashboard.
- [x] Pinned running sessions appear before non-pinned recents in the menu-bar popover.
- [x] Pinned session names persist across app restart.
- [x] Unknown or deleted pinned names are ignored in live session lists.
- [x] A recreated session with a pinned name is prioritized again.
- [x] Tests cover ordering, persistence loading, unknown pinned names, and recreated pinned names at the shared state/model seam.

## Notes

- This task is a prioritization feature, not a full grouping/template system.

## Verification

- `xcodebuild test -scheme MacTmuxKit -destination 'platform=macOS'`: PASS, 10 app tests. Xcode printed the existing CoreSimulator version warning, but macOS tests completed successfully.
- `./scripts/build-app.sh`: PASS, installed and launched `/Applications/MacTmuxKit.app`.
- Manual live state: `tmux ls` showed running `develop` and `taiwan` sessions.
- Manual defaults smoke: with no existing `pinnedSessionNames`, temporarily wrote `taiwan` to `com.gakalone.MacTmuxKit`, read it back successfully, then deleted the temporary key.
