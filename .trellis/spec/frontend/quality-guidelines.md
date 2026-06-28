# UI Quality Guidelines

UI changes should preserve the app's native macOS feel and the user's trust
that the tmux state on screen is current.

## Native macOS First

Follow `DESIGN.md`: native conventions beat generic web design advice.

- system San Francisco font;
- semantic text colors (`.primary`, `.secondary`);
- system materials for chrome when useful;
- compact 13px body / 11px metadata rhythm;
- SF Symbols;
- keyboard-first interactions and `.help()` on icon controls.

Use `MacTmuxKit/Design/DesignTokens.swift` for app-specific colors, type roles,
radii, and terminal canvas colors.

## Surface Expectations

- Menu-bar popover: compact quick switcher, fixed small size, recent sessions,
  pinned sessions before non-pinned recents, backup actions, quiet refresh
  indicator, and an explicit copy debug snapshot action for pasteable support
  evidence.
- Dashboard: three-column `NavigationSplitView` with sessions, windows/panes,
  and pane detail. It should open onto a useful selection, not an empty shell.
  Pinned sessions should get a compact SF Symbol marker rather than a bulky
  badge.
- Dashboard pane preview reloads on open, session/pane selection, and manual
  refresh. Do not attach pane preview capture to the auto-refresh loop; that
  becomes accidental streaming.
- Command palette and console: focused utility windows, keyboard-friendly, no
  visual bulk.
- Settings: grouped native forms.

## Accessibility and Motion

- Gate animations with `accessibilityReduceMotion`.
- Use native lists/buttons where they provide keyboard navigation for free.
- Icon-only controls need `.help(...)`.
- Keep destructive actions visually distinct and confirmation-gated.

## Text and Visual Restraint

- No emoji in UI text.
- No em dashes in UI strings.
- No decorative gradients, ambient blobs, or second accent hue.
- Status colors signal real state only.
- Loading, empty, and error states must be distinguishable.

## Verification

For UI-only source changes, run the app build path:

```sh
./scripts/run.sh
```

For shared app state, lifecycle, or UI-triggered refresh behavior, run:

```sh
xcodebuild test -scheme MacTmuxKit -destination 'platform=macOS'
```

For installed-app behavior, run:

```sh
./scripts/build-app.sh
```

When a change affects parser/domain behavior, also run:

```sh
cd Core && swift test
```

When a UI issue was reported from a screenshot or real app state, verify the
actual surface rather than relying only on code inspection.
