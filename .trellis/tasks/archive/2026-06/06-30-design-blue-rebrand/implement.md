# Implement — execution plan

Source: `design-source.dc.html` + `design.md`. Build via `./scripts/run.sh` (only correct
path — preserves the Accessibility grant). Screenshot-verify each surface against the design.

## Order (each step independently checkable)

### Step 1 — Theme tokens  → verify: builds, token test passes
- [ ] `DesignTokens.swift`: `accent`/`attached` → `ghostty.blue`; `accentSoft` → blue wash;
      add `accentWash`, `accentInk` (via new `Color.darkened(_:)`), `Font.pill`, `Font.capsLabel`.
- [ ] Add one test (`Core` or app) asserting `darkened` returns a darker luminance.
- verify: `swift build` (Core) + app target compiles; `accentInk` ≠ `accent`.

### Step 2 — Shared atoms  → verify: compiles, used by step 3
- [ ] `Features/Shared/SessionPresentation.swift`: `StatusDot`, `StatePill`, `MonoCount`.

### Step 3 — Menu-bar popover  → verify: screenshot vs design zone 01 (all 4 states)
- [ ] Rewrite `MenuBarPopoverView.swift`: header, RECENT SESSIONS, happy rows, New/More,
      footer + overflow `Menu`.
- [ ] Add `AppState.lastRefreshFailed` (set/clear in `refresh()`); wire empty/error/loading.
- [ ] Empty / error / loading cards.
- verify: launch, toggle states (kill server for error; quiet refresh for loading).

### Step 4 — Command palette  → verify: screenshot vs design zone 03
- [ ] Restyle `CommandPaletteView` list: SESSIONS/ACTIONS groups, blue selection,
      "switch & focus ↵", footer hint bar. Logic unchanged.

### Step 5 — Dashboard  → verify: screenshot vs design zone 02
- [ ] `SessionSidebar` rows → card look; `.tint(Theme.accent)`.
- [ ] `WindowPaneColumn`: window header (badge + ACTIVE pill + Np), pane rows (%id + dims);
      `.tint`. Move Swap / Kill-Others into `paneMenu`.
- [ ] `PaneActionBar`: 5-button icon+label bar (Split R/D, Break, Rename, Kill).
- [ ] `PaneDetailColumn`: PANE PREVIEW label + live dot.

### Step 6 — Blue app icon  → verify: Dock shows blue icon after run.sh
- [ ] Recolor `scripts/make-icon.swift` palette; regenerate appiconset.

### Step 7 — Final pass  → verify: pre-ship checklist + tests + full build
- [ ] swiftui-taste pre-ship checklist (no hardcoded hex in views; one accent; radius scale;
      mono technical labels; states distinct; reduce-motion; SF Symbols; AA contrast).
- [ ] `swift test` (Core) + app `AppStateRefreshTests` green.
- [ ] `./scripts/run.sh` clean; screenshot all three surfaces, compare to design.

## Validation commands
- Core tests: `cd Core && swift test`
- App build/run: `./scripts/run.sh`
- Hardcoded-hex guard (should only hit Theme + icon script):
  `grep -rnE 'Color\(hex:|0x[0-9A-Fa-f]{6}|\.opacity\(' MacTmuxKit/Features | grep -v Theme`

## Review gates
- After Step 3 (popover) — the highest-value surface; confirm look before doing 4–6.
- After Step 7 — full screenshot review of all three vs `design-source.dc.html`.

## Rollback points
- Each step is one commit. Theme change (Step 1) is the riskiest blast radius; if the blue
  reads wrong, revert just that commit — views reference tokens, so they follow.
