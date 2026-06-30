# Implement Claude Design blue rebrand across popover, dashboard, palette

## Goal

Implement the approved Claude Design mockup (`design-source.dc.html`, project "Tmux Kit
macOS GUI") faithfully in SwiftUI across the three primary surfaces — menu-bar popover,
Dashboard, command palette — and rebrand the accent from green to TokyoNight blue.

This replaces the current flat/low-contrast UI the user rejected. The design's core idea:
**the attached session is the single loud signal**; everything else is quiet, native,
light-frosted chrome.

## Scope decisions (confirmed with user)

- **Full accent rebrand green → blue.** In-app chrome uses TokyoNight blue `#7aa2f7`
  (= `Theme.ghostty.blue`) for attached / active / selected / primary. Plus a **new blue
  Dock/Finder app icon**. The menu-bar status icon stays a monochrome template (unchanged).
- `success` stays green, `danger`/kill stays red/pink — status colors keep signalling state.
- Colors route through `Theme` tokens (no hardcoded hex in views) so the GUI keeps tracking
  the user's live Ghostty theme.

## Requirements

### R1 — Theme tokens (blue accent)
- `Theme.accent` and `Theme.attached` resolve to `ghostty.blue`.
- Selection fill (`accentSoft`) becomes a blue wash (low-alpha blue), not the dark
  `ghostty.selection`.
- Add a derived darker `accentInk` for legible accent-colored **text/icons on light chrome**
  (the design's `#2f5aa8`), computed from `ghostty.blue` (theme-tracked), not hardcoded.

### R2 — Menu-bar popover (390pt)
- Header: app-mark tile (blue), "Tmux Kit", subtitle "N sessions · saved <time>", and
  refresh / restore / settings icon buttons.
- "RECENT SESSIONS" mono caps label.
- Session rows as cards: attached row = blue left-bar + filled blue dot (with glow ring) +
  **ATTACHED** pill; detached row = hollow dot + "detached" pill; subtitle `~/path · 0: win`
  (mono); right rail `Nw · Np` (mono). Hover/selected = blue wash.
- "New session" (blue tile + plus) and "More sessions ›" rows.
- Footer strip: Dashboard, Palette (⌥Space kbd hint), spacer, ⋯ overflow (Console,
  Cheatsheet, Save layout, Copy debug snapshot, Quit).
- **Empty / Error / Loading states**, all distinct, per the design:
  - Empty: tray icon, "No tmux sessions", actionable subtitle, "New session" button.
  - Error: plug icon (danger tint), "Can't reach the tmux server", hint, retry.
  - Loading: small spinner + "Querying tmux server…" + skeleton rows.

### R3 — Dashboard (3-column window)
- Sessions sidebar: session cards (same language as popover) + the long-CJK secondary line +
  `N windows · N panes` mono; "New session" footer.
- Windows & panes: window header (index badge, name, ACTIVE pill, `Np`), pane rows
  (state dot, name + command mono, `%id` + `WxH` dims mono); selected pane = blue wash.
  Persistent pane action bar: Split R, Split D, Break, Rename, Kill (icon + label).
- Pane detail: "PANE PREVIEW" label + live dot; pane title/cmd/ACTIVE + `%id`/dims header;
  captured-pane content on the terminal canvas (`Theme.terminalBackground/Text`).

### R4 — Command palette (560pt)
- Search field with the "Switch session, or › to run a tmux command…" prompt.
- Grouped results: **SESSIONS** (selected = blue wash, trailing "switch & focus ↵") and
  **ACTIONS** (Save layout / Restore / Refresh, icon tile + mono hint).
- Footer hint bar: `↵ switch & focus · ↑↓ move · › tmux command · esc close`.

### R5 — Iconography & tokens discipline
- All glyphs are **SF Symbols** (map from the design's Phosphor icons).
- No hardcoded hex/gray in views; radius from `Theme.Radius.*`; technical labels monospaced
  via `Theme.Font.*`.

### R6 — Blue app icon
- New Dock/Finder app icon in blue, consistent with the existing icon's silhouette intent.
  Regenerate the asset via the existing `scripts/make-icon.swift` path.

## Non-goals
- No behavior/logic changes to `AppState`/`TmuxService` beyond what the new views require.
- Settings, Console, Cheatsheet windows are out of scope (only the overflow entry points).
- No new dependencies.

## Acceptance Criteria
- [ ] All three surfaces visually match the design (verified by screenshot vs `design-source.dc.html`).
- [ ] Accent is blue everywhere in-app; `success` green / `danger` red retained; no hardcoded hex in views.
- [ ] Popover empty / error / loading states render and are distinct.
- [ ] New blue app icon ships and the icon cache shows it.
- [ ] `Core` tests + `AppStateRefreshTests` still pass.
- [ ] Builds clean via `./scripts/run.sh`.
