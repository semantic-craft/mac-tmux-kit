# Tmux Kit — Design System

Synthesized from four references the user supplied:
- **ceorkm/macos-design-skill** (native macOS / Apple HIG) — the authority; native rules win.
- **leonxlnx/taste-skill** (anti-"AI-slop") — restraint, single accent, consistent scales, complete states, zero em-dash.
- **macosui/macos_ui** (Flutter) — visual inspiration only; we match its macOS look natively.
- **maoyama/Changes** (SwiftUI Git client) — structural template for the 3-pane browse/detail window.

**Conflict rule:** when web "taste" advice and native macOS guidance disagree, **native wins** — system font (San Francisco), system accent color, semantic system colors, vibrancy on chrome, 13px body. No custom web fonts (Geist/Inter), no oversaturated custom palettes.

## Tokens

| Token | Value |
|---|---|
| Body font | `.system(size: 13)` |
| Secondary / caption | `.system(size: 11)` `.foregroundStyle(.secondary)` |
| Section title | `.system(size: 15, weight: .semibold)` |
| Terminal / mono | `.system(size: 12, design: .monospaced)` |
| Accent | `Color.accentColor` (system) — the ONE accent |
| Backgrounds | `Color(nsColor: .windowBackgroundColor)` / `.controlBackgroundColor` / `.textBackgroundColor` |
| Status: attached / active | `.green` dot / `.accentColor` |
| Destructive | `.red` — only for kill / clear |
| Spacing grid | 8px base; row padding v6 / h8–12; panel padding 12–16 |
| Corner radius | controls/cards 6, badges 4 — one scale, list rows flat |
| Vibrancy | `.ultraThinMaterial` on toolbars / floating action bars / command palette ONLY; never on terminal content |
| Motion | 150–250ms; honor `accessibilityReduceMotion` |

## Per-surface rules

**Menu-bar popover** — translucent by default; compact session list, 13px names, 11px metadata, green/gray status dot, click to switch. Keep it to the quick switcher.

**Command palette** (later) — floating `NSPanel` (`.floating`, `.fullSizeContentView`, no titlebar), centered, `.ultraThinMaterial`, autofocus field, Esc dismiss, arrow-key nav, mono shortcut hints.

**Dashboard** — `NavigationSplitView` 3 columns (Apple formula):
- *Sidebar*: `List(.sidebar)` of sessions, 200–260pt, status dot + name + `Nw`.
- *Content*: windows as `Section` headers, panes as selectable rows; List arrow-key nav for free; an **always-visible action bar** for the selected pane (the "one-click, no paging" requirement).
- *Detail*: header (command + dims + pid) + small `.ultraThinMaterial` action bar + `capture-pane` output in a monospaced, selectable `ScrollView` over `.textBackgroundColor`.
- Empty states everywhere: SF Symbol + one plain line.

## Copy

Verb-noun, <=3 words ("Switch", "Kill Pane", "New Window"). No filler ("Seamlessly", "Elegantly"). Plain errors. **Zero em-dash** in any UI string.

## Keyboard-first

List handles arrow-key nav natively. Global hotkeys via `KeyboardShortcuts` (later); in-window actions via `.keyboardShortcut` / `CommandGroup`. Every primary action gets a shortcut + `.help()` tooltip.
