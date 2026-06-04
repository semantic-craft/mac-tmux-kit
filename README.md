# Tmux Kit

A native macOS app for managing tmux (sessions / windows / panes) with one-click
actions, configurable keyboard shortcuts, and automatic focusing of the matching
Ghostty terminal window when you switch sessions.

Built to cover and exceed the prior Raycast extension (`~/Projects/raycast-tmux`).

## Status

Phased build — see `/Users/example/.claude/plans/mac-app-users-example-user-projects-ray-dazzling-owl.md`.
Currently: **Phase 0 — scaffold + build green**.

## Architecture

Native SwiftUI + AppKit, menu-bar resident (`LSUIElement`). Layering:

```
UI (Features) → Actions (registry) → Services (Tmux / Ghostty / Hotkeys) → Domain (models)
```

- **tmux control**: shell out to the `tmux` CLI via `Process` (not control mode `-CC`).
- **Ghostty focus**: macOS Accessibility API (AXUIElement) — Ghostty has no scripting CLI.
- **Global hotkeys**: the `KeyboardShortcuts` Swift package (added in Phase 1).

The app is **non-sandboxed** (required for arbitrary `Process` execution + Accessibility),
so it ships outside the Mac App Store.

## Develop

Requires Xcode, [XcodeGen](https://github.com/yonaskolb/XcodeGen), and tmux.

```sh
xcodegen generate            # regenerate MacTmuxKit.xcodeproj from project.yml
open MacTmuxKit.xcodeproj    # or build from CLI:
xcodebuild -scheme MacTmuxKit -configuration Debug build CODE_SIGNING_ALLOWED=NO
```

The `.xcodeproj` is generated from `project.yml` (the source of truth) and is git-ignored.

### First run

The app needs **Accessibility** permission (System Settings → Privacy & Security →
Accessibility) to focus Ghostty windows. It will guide you on first launch.

Destructive tmux tests run against a dedicated socket (`tmux -L mactmuxkit-dev`) so they
never touch your real sessions.
