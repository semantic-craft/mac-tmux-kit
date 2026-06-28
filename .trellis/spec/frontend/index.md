# SwiftUI and AppKit UI Guidelines

In this repository, Trellis' `frontend` spec means the native macOS UI:
SwiftUI views, AppKit window/status-item controllers, settings, command
palette, console, cheatsheet, Dashboard, and menu-bar popover.

This is not a web frontend. There is no React, DOM, CSS, Tailwind, browser
router, or TypeScript layer.

## Guides

| Guide | Applies to | Status |
| --- | --- | --- |
| [Directory Structure](./directory-structure.md) | `MacTmuxKit/Features/`, `MacTmuxKit/Design/`, `MacTmuxKit/Shared/` | Project-specific |
| [Component Guidelines](./component-guidelines.md) | SwiftUI view composition, rows, buttons, empty/loading/error states | Project-specific |
| [SwiftUI Lifecycle Guidelines](./hook-guidelines.md) | `.task`, `.onChange`, `@State`, `@AppStorage`, environment state | Project-specific |
| [State Management](./state-management.md) | `AppState`, local view state, Dashboard selection requests | Project-specific |
| [Type Safety](./type-safety.md) | Swift models, stable tmux IDs, parser contracts, optional handling | Project-specific |
| [Quality Guidelines](./quality-guidelines.md) | macOS design, accessibility, motion, visual verification | Project-specific |

## UI Source of Truth

- `DESIGN.md` defines native macOS design rules.
- `DESIGN-CHECKLIST.md` is the review checklist for surfaces.
- `MacTmuxKit/Design/DesignTokens.swift` is the single source of truth for
  color, type, radius, and terminal preview colors.
- `.claude/skills/swiftui-taste/SKILL.md` is the project-specific design skill
  distilled for SwiftUI/AppKit work.

Native macOS conventions win over generic web taste advice.
