# Design — blue rebrand & three-surface redesign

Source of truth: `design-source.dc.html` (in this task dir). Implement faithfully, but route
all color through `Theme` and use SF Symbols (the `.dc.html` uses Phosphor + raw hex).

## 1. Theme tokens (`MacTmuxKit/Design/DesignTokens.swift`)

The whole rebrand pivots here, so views need almost no color literals.

| token | now (green) | after (blue) |
|---|---|---|
| `accent` | `ghostty.green` | `ghostty.blue` |
| `attached` | `ghostty.green` | `ghostty.blue` |
| `accentSoft` | `ghostty.selection` | `ghostty.blue.opacity(0.16)` (selection wash) |
| `accentInk` *(new)* | — | `ghostty.blue` darkened ~32% — legible accent text/icons on light chrome |
| `success` | green | **unchanged** (green) |
| `warning`/`danger` | yellow/red | **unchanged** |

- `accentInk` is computed, not hardcoded, so it tracks the live theme:
  add `Color.darkened(_:)` using `NSColor(self).blended(withFraction:of:.black)`.
- The design's selection wash is blue at 0.08 (hover) / 0.16 (selected). Expose
  `Theme.accentWash` = `accent.opacity(0.16)` and reuse `hoverFill` as-is (or a blue 0.08).
- Add a `Theme.Font.pill` (mono 9, semibold) and `Theme.Font.capsLabel` (mono 10, tracking)
  for the `RECENT SESSIONS` / `SESSIONS` / `ACTIONS` mono section labels.

## 2. Shared atoms (new file `Features/Shared/SessionPresentation.swift`)

Don't build one mega session-card (popover vs sidebar differ). Share the small atoms only:
- `StatusDot(attached: Bool)` — filled blue dot + glow ring when attached; hollow ring when not.
- `StatePill(attached: Bool)` — `ATTACHED` (blue, `accentInk` on `accentWash`) / `detached`
  (secondary on gray). Mono, 9pt.
- `MonoCount(text:)` — right-rail `3w · 5p` style, `Theme.Font.metric`, tertiary.
These are reused by the popover rows and the Dashboard sidebar rows.

## 3. Menu-bar popover (`Features/MenuBar/MenuBarPopoverView.swift`) — full rewrite

Structure (replaces the current section-card stack):
- **header**: blue app-mark tile (`terminal` SF Symbol, `accentInk`) + title + subtitle
  (`headerSubtitle`, already exists) + `IconButton`s: refresh / restore (`arrow.counterclockwise`,
  triggers `confirmRestore`) / settings.
- **`RECENT SESSIONS`** caps label.
- **state switch** on `app`:
  - happy → `pinnedFirstSessions(limit: 3)` rows (attached variant gets blue left-bar +
    `StatusDot` + `StatePill`; subtitle `sessionSubtitle`; right `Nw · Np`), then a divider,
    then **New session** (blue tile + `plus`) and **More sessions** (`square.stack` + chevron → `showDashboard()`).
  - empty (`sessions.isEmpty` && no error) → centered `tray` empty card + New session button.
  - error (`statusMessage` indicates failure) → `powerplug`/`bolt.horizontal` danger card +
    `tmux start-server` code chip + Retry (`refresh`).
  - loading (`isLoading` && `sessions.isEmpty`) → spinner "Querying tmux server…" + 2 skeleton rows.
- **footer**: Dashboard, Palette (⌥Space kbd chip), spacer, `ellipsis` overflow button →
  a small menu (Console, Cheatsheet, Save layout, Copy debug snapshot, Quit). Use a SwiftUI
  `Menu` (native) for the overflow rather than the design's positioned panel.

Empty-vs-error distinction must use real signal: an error is when `refresh()` set
`statusMessage` from a thrown `TmuxError` (server unreachable / binary missing), not merely
zero sessions. Add a tiny `AppState.lastRefreshFailed: Bool` (set in `refresh()` catch,
cleared on success) so the view can tell empty from error — this is the one allowed AppState
addition (R-non-goal exception, needed for R2 states).

## 4. Command palette (`Features/CommandPalette/CommandPaletteView.swift`)

Keep the existing key-handling/filter logic. Restyle `list` + `row`:
- Group rows under mono caps headers **SESSIONS** / **ACTIONS** (split `items` into the two
  buckets; the create/command rows fold under SESSIONS/ACTIONS appropriately).
- Selected row → `Theme.accentWash` rounded fill (already uses `accentSoft`; now blue) +
  trailing "switch & focus ↵" on the selected session row.
- Session rows: `StatusDot` + name + mono `attached · 3w`. Action rows: icon tile + title +
  mono hint.
- Add the **footer hint bar** (`↵ switch & focus · ↑↓ move · › tmux command · esc close`).

## 5. Dashboard

- **`SessionSidebar.swift`**: keep `List(.sidebar)` (native keyboard nav, vibrancy) but
  `.tint(Theme.accent)` so selection is blue, and rebuild `SessionSidebarRow` to the card
  look: `StatusDot` + name + `StatePill`; subtitle `~/path · 0: win` (mono); the long-CJK
  secondary line when present (`session` has no CJK field — reuse the readable subtitle / drop
  if empty); `N windows · N panes` mono. Keep hover pencil + switch button.
  - **Deliberate deviation:** native `List` selection (rounded blue) replaces the design's
    hand-drawn left-bar+wash. Lower risk, more native; flagged for user.
- **`WindowPaneColumn.swift`**: `List(.inset).tint(Theme.accent)`. `WindowHeaderRow` → index
  badge chip + name + `ACTIVE` pill (when `window.active`) + `Np`. `PaneRow` → `StatusDot`
  (active) + name + command (mono) + right `%id`+`WxH` (mono). Action bar (see below).
- **`PaneActionBar.swift`**: switch to the design's 5-button horizontal icon+label bar:
  Split R (`rectangle.split.2x1`), Split D (`rectangle.split.1x2`), Break
  (`rectangle.portrait.and.arrow.right`), Rename (`pencil`), Kill (`xmark`, danger).
  - Rename needs a pane-title prompt: lift the `prompt`/`confirm` bindings already threaded in.
  - **Swap** and **Kill Others** leave the bar → add them to `PaneRow`'s context menu
    (`paneMenu` in WindowPaneColumn) so no function is lost.
- **`PaneDetailColumn.swift`**: add the `PANE PREVIEW` caps label + "live" dot to the header
  row; keep the captured-pane terminal canvas (`Theme.terminalBackground/Text`) and the
  copy/reload buttons. Title row gets the `ACTIVE` pill + `%id`/dims mono (mostly present).

## 6. App icon (`scripts/make-icon.swift` + menu-bar icon untouched)

Recolor the existing pane-split concept from violet → TokyoNight blue. Keep geometry; swap:
- `bgTop/bgBottom` → deep blue indigo (e.g. `#2A3158` / `#1C2138`).
- `violet/violetDeep` (active pane) → `#7AA2F7` / `#5E83E0`.
- `cursorInk` → a dark blue `#202542`.
Regenerate the appiconset; rebuild clears the icon cache via `scripts/run.sh`.

## 7. Icon map (Phosphor → SF Symbol)

terminal-window→`terminal` · arrow-clockwise→`arrow.clockwise` · arrow-counter-clockwise→
`arrow.counterclockwise` · gear-six→`gearshape` · plus→`plus` · stack→`square.stack` ·
caret-right→`chevron.right` · squares-four→`square.grid.2x2` · magnifying-glass→
`magnifyingglass` · dots-three→`ellipsis` · tray→`tray` · plugs→`powerplug` · floppy-disk→
`tray.and.arrow.down` · columns→`rectangle.split.2x1` · rows→`rectangle.split.1x2` ·
arrow-square-out→`rectangle.portrait.and.arrow.right` · pencil-simple→`pencil` · x→`xmark` ·
keyboard→`keyboard` · sign-out→`power`.

## 8. Risks / checks
- `accentInk` contrast: verify AA on the light frosted panel (target ≥ 4.5:1 for text).
- `List.tint` selection color: confirm it actually recolors on the target macOS; if not, fall
  back to `.listRowBackground` wash.
- Reduce-motion: gate the loading spinner/skeleton pulse on `accessibilityReduceMotion`.
- Keep `AppStateRefreshTests`/`PaneNamingTests` green; add a token test for `accentInk`
  darkening (one assert).
