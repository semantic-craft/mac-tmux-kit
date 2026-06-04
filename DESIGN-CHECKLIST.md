# Tmux Kit — macOS Design Review Checklist

Grounded in [`ceorkm/macos-design-skill`](https://github.com/ceorkm/macos-design-skill)
(its `visual-design`, `layout-and-composition`, `interaction-patterns` references +
five core principles), **translated to native SwiftUI** per [`DESIGN.md`](DESIGN.md):
when the skill's web/CSS advice and native macOS guidance diverge, **native wins**
(`backdrop-filter`→`.ultraThinMaterial`, `#007AFF`→`Color.accentColor`, hex grays→
semantic system colors).

Run each surface against this: menu-bar popover · command palette · Dashboard ·
console · cheatsheet · Settings.

## 1 · Color & Dark Mode
- [ ] Semantic system colors (`.windowBackgroundColor` / `.controlBackgroundColor` / `.textBackgroundColor`), not hardcoded hex
- [ ] Single accent = `Color.accentColor`; never fills large background areas
- [ ] Dark mode is not an inversion; no pure black `#000000`
- [ ] Secondary text de-emphasized by `.secondary`/opacity, not lighter weight
- [ ] Status colors reserved: `.green` attached/active, `.red` destructive only

## 2 · Typography
- [ ] Body 13 / caption 11 `.secondary` / section title 15 semibold / mono 12
- [ ] Weights Regular–Bold only; hierarchy by size+color, not weight
- [ ] System San Francisco only (no Geist/Inter)

## 3 · Edges, Shadows & Vibrancy
- [ ] Borders sparse — hairline separators, not boxes (skill: "use borders sparingly")
- [ ] `.ultraThinMaterial` only on chrome (toolbars, action bar, palette, popover); never on `capture-pane` content
- [ ] Floating surfaces use soft layered shadow, not a flat border

## 4 · Spacing, Sizing & Radii (8px grid)
- [ ] 8px grid: row padding ~v6/h8–12, panel padding 12–16
- [ ] Control sizes native: rows 28–32, primary buttons `.controlSize(.large)`, toolbar icons 28×28
- [ ] Corner radii one scale: controls/cards 6, badges 4; list rows flat
- [ ] Icon-to-label gap ~6–8

## 5 · Layout & Composition
- [ ] Native window chrome (10px corner, standard traffic lights)
- [ ] Dashboard sidebar 200–260pt, vibrant `List(.sidebar)`, caps section headers
- [ ] 3-column `NavigationSplitView` sidebar→content→detail; detail keeps context
- [ ] Toolbar sparse, breathing room; search prominent; segmented controls for view switches
- [ ] Single-purpose utility windows (cheatsheet, console) carry no sidebar

## 6 · Empty States & Progressive Disclosure
- [ ] Every empty column: SF Symbol + one plain line (+ CTA where it acts)
- [ ] Secondary UI hidden until useful (filters with content, metadata on hover, low-freq behind `…`)
- [ ] Pane action bar disabled/dimmed when no pane selected

## 7 · Keyboard & Shortcuts
- [ ] Standard: `⌘,` Settings, `⌘W` close, `Esc` dismiss, `Enter` confirm, `⌘F`/palette search
- [ ] Global summons via `KeyboardShortcuts`, each rebindable
- [ ] Lists give arrow-key nav; every primary button has `.help()`
- [ ] Shortcut hints mono/`kbd`-style, dimmed (~0.6)
- [ ] Discoverable cheat sheet exists

## 8 · Motion & Feedback
- [ ] State changes animate ~150ms (small) / ~250ms (panels), honor `accessibilityReduceMotion`
- [ ] Optimistic UI: act immediately, lightweight success toast ("Saved/Copied"), auto-dismiss ~2s, revert + error toast on failure
- [ ] No gratuitous motion; transitions use transform+opacity together

## 9 · Controls & Iconography
- [ ] SF Symbols only, thin monoline, 16 default / 12 inline
- [ ] Labeled `.bordered` `.controlSize(.large)` buttons for primary actions, not tiny icon-only
- [ ] Copy verb-noun ≤3 words, zero em-dash, plain errors

## 10 · Interaction specifics (this app)
- [ ] Inline rename: always-visible pencil → inline field, Enter saves / Esc cancels, optimistic
- [ ] Menu-bar popover stays a quick switcher (translucent, compact, click-to-switch)
- [ ] Command palette = centered floating `NSPanel`, `.ultraThinMaterial`, autofocus, arrow-nav, Esc, mono hints
- [ ] Pane detail floating action bar = pill, materials, icon+label, common actions one click
- [ ] Hover-reveal affordances; metadata/actions not shown by default
