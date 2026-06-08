<p align="center">
  <img src="assets/icon.png" width="128" alt="Tmux Kit icon">
</p>

<h1 align="center">Tmux Kit</h1>

<p align="center">
  A fast, native macOS app that gives <a href="https://github.com/tmux/tmux">tmux</a> a friendly GUI —
  switch sessions, manage windows and panes, and run commands without memorizing a single keybinding.
  <br>
  <strong>It doesn't replace tmux. It sits on top of the one you already use — and paints itself in your terminal's colors.</strong>
</p>

<p align="center">
  <img alt="platform" src="https://img.shields.io/badge/macOS-14%2B-black?logo=apple">
  <img alt="swift" src="https://img.shields.io/badge/SwiftUI%20%2B%20AppKit-orange?logo=swift">
  <img alt="no network" src="https://img.shields.io/badge/network-none-success">
  <img alt="license" src="https://img.shields.io/badge/license-MIT-blue">
</p>

<p align="center"><b>English</b> · <a href="README.zh-CN.md">简体中文</a></p>

---

A standalone menu-bar app. No account, no telemetry, no plugins, no edits to your `~/.tmux.conf`. It talks to the local `tmux` you already run and gives you a clean, point-and-click layer on top — keyboard-first when you want it, mouse-friendly when you don't.

```sh
git clone https://github.com/semantic-craft/mac-tmux-kit.git
cd mac-tmux-kit && ./scripts/build-app.sh   # builds, signs, installs to /Applications, launches
```

## Why this exists

tmux is having a quiet renaissance. The properties that made it great in 2007 — **session persistence, terminal multiplexing, detach/reattach over SSH, tiny resource use** — are exactly what modern remote development and AI coding agents need.

> *Without tmux, a dropped SSH connection kills every process you were running. With tmux, you reconnect, reattach, and continue where you left off.*

But tmux has one well-documented wall: **the keybindings.** `Ctrl-b "` to split, `Ctrl-b %` to split the other way, `Ctrl-b z` to zoom — none of it is discoverable, and newcomers end up with a cheat sheet taped to the monitor.

**Tmux Kit is that cheat sheet, made interactive — plus a GUI that does the work for you.** You keep tmux (your config, your muscle memory, your remote servers); you just get a clean, native layer on top.

## Who this is for

**Tmux loyalists who want a control panel, not a new religion.**

You already run parallel sessions — agents, builds, SSH work — and you want the visual management and discoverability that modern tools promise, without leaving the tmux stack your servers, config, and muscle memory are built on.

Tmux Kit is for developers who run parallel agents in tmux, love what tmux gives them over SSH, and are tired of pretending `Ctrl-b %` is discoverable. **Keep tmux, lose the friction.**

## Why stay on tmux

**We make the tmux you already run operable — and keep every reason you chose it.**

Tmux Kit doesn't ask you to give up what already works. It adds a native macOS control surface on top of the compatibility you already have: SSH ubiquity, server-side persistence, terminal freedom, scriptability, and a mature plugin ecosystem.

| Strength | What it gives you | Why it matters day-to-day |
|---|---|---|
| **Ubiquity** | tmux is on virtually every server you SSH into | Same workflow locally and remotely — no per-host setup |
| **SSH persistence** | Sessions live on the server; detach, reconnect, reattach | Agents and long builds survive dropped connections |
| **Terminal-agnostic** | Works inside Ghostty, iTerm, Alacritty, or anything else | Pick your terminal; tmux stays the layer that matters |
| **Multi-client** | Two people — or two devices — can attach to the same session | Pair programming and cross-device handoff, built in |
| **Scriptable CLI** | `new-session`, `send-keys`, `capture-pane` — stable shell API | Tmux Kit itself drives tmux through this interface |
| **Mature ecosystem** | [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect), vim-tmux-navigator, TPM, team conventions | Your existing plugins and configs keep working |
| **Lightweight** | ~6 MB per session; fine on old boxes and slow links | Run many panes without paying a heavy runtime tax |

Modern multiplexers like [Zellij](https://zellij.dev) are doing genuinely good work reimagining the terminal workspace. Tmux Kit takes a different path: **make the tmux you already depend on feel as approachable on macOS** — not ask you to start over.

## Built for vibe coding

If your tmux looks like three panes each running a different AI assistant — Claude Code in one, Codex in another, a long build or test agent in a third — the actions you actually reach for are first-class here, no attach required:

- **Peek at what an agent just printed** → the Dashboard's live pane preview renders `capture-pane` output; copy it with one click.
- **Kill the one that's stuck** → *Kill Pane* (just one) or *Kill Others* (keep the working one, nuke the rest).
- **Put two panes side by side** → *Swap ← → ↑ ↓*, or *Mark* one pane and *Swap with marked* — pane ids are global, so source and target can even be different sessions.
- **Promote a runaway pane into its own window** → *Break Out*.
- **Jump between projects** → the menu bar or the command palette switches the attached session and raises its terminal window for you.

## Features

- **🎨 Dresses itself in your terminal's colors** — reads your [Ghostty](https://ghostty.org) theme at launch and matches it ([details below](#-it-looks-like-it-belongs-in-your-terminal)). The app feels like part of your terminal, not a foreign window.
- **Menu-bar quick switcher** — every session at a glance (a colored dot = attached), one click to switch + focus its terminal.
- **Auto-focus the right window** — switching a session brings its terminal window to the front (via the Accessibility API); a detached session opens a fresh window instead of hijacking your current one.
- **Command palette** — fuzzy-find and switch sessions from anywhere; type `>` to run any tmux command; type a new name to create a session on the spot. Open it with a global hotkey (`⌥⌘T`, rebindable), from the menu bar, or with **`⌘K`** inside the Dashboard.
- **Dashboard** — a 3-column browser (sessions → windows/panes → live pane preview) that opens onto your most-recent session, with an always-visible action bar: split, directional swap, break out, kill / kill-others.
- **Inline rename** — rename any session, window, or pane in place; press the pencil, type, `↵`.
- **Interactive cheat sheet** — ~50 stock tmux shortcuts, searchable, click-to-copy. Keep it open while you learn; the clicks become the keystrokes you remember.
- **tmux console** — run any tmux command with presets and history (destructive commands ask first), stdout/stderr shown inline.
- **Layout backup** — one-click save/restore via [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect), if you have it.
- **Global hotkeys** — summon the Dashboard (`⌃⌥⌘⇧D`), the palette, or "switch to recent session" from anywhere; all rebindable.

## 🎨 It looks like it belongs in your terminal

Most GUIs pick a brand color and impose it. Tmux Kit does the opposite: at launch it reads your live Ghostty theme (`ghostty +show-config`) and **maps your terminal's own palette onto the app**:

- the **live pane preview** uses your terminal's exact background and foreground — the preview looks identical to the real thing;
- **status** colors (success / warning / danger) come from your palette's green / yellow / red;
- the **accent** is your terminal's green; **selected rows** use your terminal's own selection color;
- the native macOS chrome (sidebar, lists, toolbars) stays native, so it still feels at home on your desktop.

Change your Ghostty theme, relaunch, and the app follows. No Ghostty? It falls back to a tasteful built-in palette — nothing breaks.

## What you can do

| Level | Actions |
|---|---|
| **Sessions** | switch + focus terminal · rename (inline) · new · kill · kill others |
| **Windows** | new · rename (inline) · switch · kill (and every pane inside) |
| **Panes** | split right / down · swap ← → ↑ ↓ · mark + swap-with-marked · break out · clear history · kill · kill others · live preview + copy content |
| **Anywhere** | command palette (switch / run any tmux command / create session) · tmux console · cheat sheet · resurrect save & restore |

Destructive actions are consistently gated behind a confirm dialog.

## Screenshots

<p align="center">
  <img src="assets/screenshots/palette.png" width="560" alt="Command palette">
</p>
<p align="center"><em>The command palette — fuzzy-switch sessions, run any tmux command (<code>></code>), or create one on the fly. Painted in the live Ghostty theme. (Real session names redacted.)</em></p>

<!-- More on the way: the menu-bar switcher and the 3-column Dashboard. -->

## What makes Tmux Kit different

Tmux Kit is a **control surface**, not a new stack. It talks to the tmux server you already run and adds a native macOS layer on top:

- **Overlay, not replacement** — your sessions, config, and plugins stay exactly where they are
- **Zero config intrusion** — no plugins installed, no edits to `~/.tmux.conf`
- **Any terminal** — not tied to one emulator; theme-matches [Ghostty](https://ghostty.org) when you use it
- **Menu-bar native** — SwiftUI + AppKit, global hotkeys, lives out of the way until you need it
- **Built for parallel agents** — live pane preview, kill-others, cross-session pane swap
- **Private by default** — no network, no account, no telemetry

Plenty of good tools take other paths — [iTerm2's `-CC` integration](https://iterm2.com/documentation-tmux-integration.html) for deep emulator binding, [Termdock](https://termdock.com) for another take on tmux GUI, [Warp](https://www.warp.dev) for an AI-native terminal, [Zellij](https://zellij.dev) for a modern multiplexer from the ground up. **Tmux Kit is for when you want to stay on tmux, keep your terminal, and add a lightweight native control panel on macOS.**

## Keyboard

| Action | Shortcut |
|---|---|
| Open / focus the Dashboard | `⌃⌥⌘⇧D` |
| Command palette (global) | `⌥⌘T` |
| Command palette (in Dashboard) | `⌘K` |
| Switch to recent session | _unbound by default_ |
| Settings | `⌘,` |

All global hotkeys are rebindable in **Settings → Keybindings**.

## Requirements

- macOS 14 (Sonoma) or later
- [`tmux`](https://github.com/tmux/tmux) — auto-detected; path is configurable in Settings
- Any terminal works. Window-focus matching and theme-matching are tuned for [Ghostty](https://ghostty.org); everything else works everywhere.

## Install / Build

Not on the Mac App Store — the app is non-sandboxed (it runs `tmux` and uses the Accessibility API). Building it yourself is quick:

```sh
# prerequisites: Xcode, XcodeGen (brew install xcodegen), tmux
git clone https://github.com/semantic-craft/mac-tmux-kit.git
cd mac-tmux-kit
./scripts/build-app.sh        # builds, signs, installs to /Applications, launches
```

For development, `./scripts/run.sh` builds + re-signs + relaunches a Debug build.

> **First run:** grant **Accessibility** (Settings → Focus → *Open Accessibility Settings*) so Tmux Kit can bring terminal windows forward. The build is signed with your local Apple Development certificate, so the permission persists across rebuilds.

## How it's built

- **Argument-safe.** Every tmux call passes its arguments as an array to `Process` — never interpolated into a shell string — so session names and paths with spaces or metacharacters can't break out.
- **Headless-tested core.** The pure logic — domain models and the tmux `-F` output parser — lives in the `Core/` Swift package and is unit-tested without a UI (`cd Core && swift test`).
- **Stable code identity.** Builds are re-signed with your local Apple Development certificate after `xcodebuild`, so the Accessibility (TCC) grant survives every rebuild instead of resetting.
- **Reads your terminal, writes nothing.** It resolves colors from `ghostty +show-config` at launch; it never installs tmux plugins or edits your `~/.tmux.conf`.
- **Native, not a wrapper.** SwiftUI + AppKit, menu-bar resident (`LSUIElement`). Layering: `UI → Actions → Services (Tmux / Ghostty / Hotkeys) → Domain`. The project is generated from `project.yml` by [XcodeGen](https://github.com/yonaskolb/XcodeGen). Design tokens live in [`MacTmuxKit/Design/`](MacTmuxKit/Design); see [`DESIGN.md`](DESIGN.md).

## Privacy & footprint

No network. No telemetry. No account. It talks only to your local `tmux` server and (optionally) brings terminal windows to the front. It never installs tmux plugins or edits your `~/.tmux.conf`. The single optional config touch — *Install recommended title format* — is a button you press, never automatic.

## Roadmap

- A cheat-sheet **practice mode** (drills, not just lookup)
- More bindable actions in the palette and as global hotkeys
- Sparkle auto-update and Developer ID notarization for one-click sharing across Macs
- Better tab-level focus within a single terminal window

## License

[MIT](LICENSE).

---

<p align="center">
  Built for tmux loyalists who like their setup <em>clean</em>. If that's you, leave a ⭐.
</p>
