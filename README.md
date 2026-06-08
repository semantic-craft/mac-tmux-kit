<p align="center">
  <img src="assets/icon.png" width="128" alt="Tmux Kit icon">
</p>

<h1 align="center">Tmux Kit</h1>

<p align="center">
  A fast, native macOS GUI for <a href="https://github.com/tmux/tmux">tmux</a> — switch sessions, manage panes, run commands without memorizing keybindings.
  <br>
  为 <a href="https://github.com/tmux/tmux">tmux</a> 套上原生 macOS 图形界面——切换会话、管理窗格、执行命令，全程不用背快捷键。
  <br>
  <strong>It doesn't replace tmux — it sits on top of yours. · 不取代 tmux，叠在你正在用的那个之上。</strong>
</p>

<p align="center">
  <img alt="platform" src="https://img.shields.io/badge/macOS-14%2B-black?logo=apple">
  <img alt="swift" src="https://img.shields.io/badge/SwiftUI%20%2B%20AppKit-orange?logo=swift">
  <img alt="no network" src="https://img.shields.io/badge/network-none-success">
  <img alt="license" src="https://img.shields.io/badge/license-MIT-blue">
</p>

<p align="center"><strong>Language · 语言</strong></p>
<p align="center">
  <a href="#readme-en">
    <img alt="English" src="https://img.shields.io/badge/English-Read-0A84FF?style=for-the-badge&labelColor=1C1C1E">
  </a>
  &nbsp;
  <a href="#readme-zh">
    <img alt="简体中文" src="https://img.shields.io/badge/简体中文-阅读-30D158?style=for-the-badge&labelColor=1C1C1E">
  </a>
</p>

---

<a id="readme-en"></a>
<details open>
<summary><h2>English</h2></summary>

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

- **🎨 Dresses itself in your terminal's colors** — reads your [Ghostty](https://ghostty.org) theme at launch and matches it ([details below](#en-terminal-theme)). The app feels like part of your terminal, not a foreign window.
- **Menu-bar quick switcher** — every session at a glance (a colored dot = attached), one click to switch + focus its terminal.
- **Auto-focus the right window** — switching a session brings its terminal window to the front (via the Accessibility API); a detached session opens a fresh window instead of hijacking your current one.
- **Command palette** — fuzzy-find and switch sessions from anywhere; type `>` to run any tmux command; type a new name to create a session on the spot. Open it with a global hotkey (`⌥⌘T`, rebindable), from the menu bar, or with **`⌘K`** inside the Dashboard.
- **Dashboard** — a 3-column browser (sessions → windows/panes → live pane preview) that opens onto your most-recent session, with an always-visible action bar: split, directional swap, break out, kill / kill-others.
- **Inline rename** — rename any session, window, or pane in place; press the pencil, type, `↵`.
- **Interactive cheat sheet** — ~50 stock tmux shortcuts, searchable, click-to-copy. Keep it open while you learn; the clicks become the keystrokes you remember.
- **tmux console** — run any tmux command with presets and history (destructive commands ask first), stdout/stderr shown inline.
- **Layout backup** — one-click save/restore via [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect), if you have it.
- **Global hotkeys** — summon the Dashboard (`⌃⌥⌘⇧D`), the palette, or "switch to recent session" from anywhere; all rebindable.

<a id="en-terminal-theme"></a>
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

<p align="center">
  Built for tmux loyalists who like their setup <em>clean</em>. If that's you, leave a ⭐.
</p>

<p align="center">
  <a href="#readme-zh">↑ 简体中文</a>
</p>

</details>

---

<a id="readme-zh"></a>
<details>
<summary><h2>简体中文</h2></summary>

一个独立的菜单栏应用。无账号、无遥测、无插件、不改你的 `~/.tmux.conf`。它只和你本机正在跑的 `tmux` 对话，给你一层干净的、点一点就能用的界面——想用键盘时键盘优先，想用鼠标时鼠标也顺手。

```sh
git clone https://github.com/semantic-craft/mac-tmux-kit.git
cd mac-tmux-kit && ./scripts/build-app.sh   # 构建、签名、安装到 /Applications 并启动
```

## 为什么做它

tmux 正在悄悄复兴。让它在 2007 年就出色的那些特性——**会话持久化、终端多路复用、SSH 断线后 detach/reattach、极小的资源占用**——恰恰是现代远程开发和 AI 编码 agent 所需要的。

> *没有 tmux，一次 SSH 掉线就会杀掉你正在跑的所有进程。有了 tmux，你重连、reattach，从断点继续。*

但 tmux 有一道公认的墙：**快捷键**。`Ctrl-b "` 横切、`Ctrl-b %` 竖切、`Ctrl-b z` 缩放——没有一个是可发现的，新手最后往往在显示器上贴一张小抄。

**Tmux Kit 就是那张小抄，做成可交互的——再加上一个替你干活的界面。** 你保留 tmux（你的配置、肌肉记忆、远程服务器），只是多了一层干净的原生界面。

## 为谁而做

**守 tmux、要顺手的终端重度用户。**

你已经在并行跑会话——agent、构建、SSH 远程——想要现代工具承诺的可视化管理和可发现性，又不想离开那套围绕 tmux 搭起来的服务器、配置和肌肉记忆。

Tmux Kit 给那些**在 tmux 里并行跑 agent、离不开 SSH 会话持久化、却又受够了「快捷键全靠小抄」**的开发者。**守 tmux，去掉摩擦。**

## 为什么继续用 tmux

**我们让你正在用的那个 tmux 变得好操作——并保留你选择它的每一个理由。**

Tmux Kit 不要求你放弃已经好用的东西。它在 macOS 上加一层原生控制面，叠在你已有的兼容性之上：SSH 普适、服务端持久化、终端随意换、脚本可驱动、成熟的插件生态。

| 优势 | 带给你什么 | 日常里为什么重要 |
|---|---|---|
| **普适性** | 你 SSH 进去的机器上，几乎都有 tmux | 本地和远程同一套工作流，不用每台机器单独折腾 |
| **SSH 持久化** | 会话活在服务器上；detach、重连、reattach | agent 和长时构建扛得住断线 |
| **终端无关** | Ghostty、iTerm、Alacritty……随便换 | 终端随便挑；tmux 才是那层真正重要的东西 |
| **多客户端** | 两个人、两台设备都能 attach 同一会话 | 结对编程和跨设备切换，原生支持 |
| **可脚本化 CLI** | `new-session`、`send-keys`、`capture-pane`——稳定的 shell API | Tmux Kit 本身也是通过这套接口驱动 tmux |
| **成熟生态** | [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect)、vim-tmux-navigator、TPM、团队约定 | 你现有的插件和配置继续有效 |
| **轻量** | 空 session 约 6 MB；老机器、弱网也扛得住 | 多开窗格不用付沉重的运行时代价 |

像 [Zellij](https://zellij.dev) 这样的现代多路复用器，在重新想象终端工作区这件事上做得很好。Tmux Kit 走的是另一条路：**让你已经依赖的 tmux 在 macOS 上同样顺手**——而不是让你从头再来。

## 专为 vibe coding 设计

如果你的 tmux 长这样——三个窗格各跑一个 AI 助手：一个 Claude Code、一个 Codex、第三个跑长时间的构建或测试 agent——那么你真正会用到的操作在这里都是一等公民，无需 attach：

- **瞄一眼某个 agent 刚打印了什么** → Dashboard 的实时窗格预览渲染 `capture-pane` 的输出，一键复制。
- **杀掉卡住的那个** → *Kill Pane*（只杀一个）或 *Kill Others*（保留在干活的，其余清掉）。
- **把两个窗格并排放** → *Swap ← → ↑ ↓*，或先 *Mark* 一个再 *Swap with marked*——pane id 是全局的，所以源和目标甚至可以来自不同会话。
- **把失控的窗格拎成独立窗口** → *Break Out*。
- **在项目间跳转** → 菜单栏或命令面板切换到目标会话，并自动把它的终端窗口拉到前台。

## 功能

- **🎨 自动染上你终端的配色** — 启动时读取你的 [Ghostty](https://ghostty.org) 主题并与之匹配（[详见下文](#zh-terminal-theme)）。应用像是终端的一部分，而不是一个外来窗口。
- **菜单栏快速切换器** — 所有会话一目了然（彩色圆点 = 已 attach），一键切换并聚焦其终端。
- **自动聚焦正确的窗口** — 切换会话时把它的终端窗口拉到前台（经由 Accessibility API）；若该会话处于 detached，则新开一个窗口，而不是劫持你当前的窗口。
- **命令面板** — 从任何地方模糊查找并切换会话；输入 `>` 执行任意 tmux 命令；输入一个新名字当场创建会话。可用全局快捷键（`⌥⌘T`，可改键）、菜单栏，或在 Dashboard 内用 **`⌘K`** 唤起。
- **Dashboard** — 三栏浏览器（会话 → 窗口/窗格 → 实时窗格预览），打开即落在你最近的会话上，底部常驻动作条：split、定向 swap、break out、kill / kill-others。
- **行内重命名** — 就地重命名任意会话、窗口或窗格；点铅笔、输入、回车。
- **可交互小抄** — 约 50 条 tmux 原生快捷键，可搜索、点击即复制。学习时一直开着，点着点着就记住了键。
- **tmux 控制台** — 执行任意 tmux 命令，带预设与历史（破坏性命令先确认），stdout/stderr 内联显示。
- **布局备份** — 经由 [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) 一键保存/恢复（前提是你装了它）。
- **全局快捷键** — 从任何地方唤起 Dashboard（`⌃⌥⌘⇧D`）、命令面板，或"切换到最近会话"；全部可改键。

<a id="zh-terminal-theme"></a>
## 🎨 它看起来就属于你的终端

大多数 GUI 会挑一个品牌色硬塞给你。Tmux Kit 反其道而行：启动时读取你当前的 Ghostty 主题（`ghostty +show-config`），**把你终端自己的调色板映射到应用上**：

- **实时窗格预览**用你终端确切的背景色与前景色——预览看起来和真终端一模一样；
- **状态色**（成功 / 警告 / 危险）取自你调色板里的绿 / 黄 / 红；
- **强调色**就是你终端的绿；**选中行**用你终端自己的选区色；
- 而原生 macOS 外壳（侧栏、列表、工具栏）保持原生，所以它在你的桌面上依然像在家里。

换了 Ghostty 主题，重启应用即跟随。没装 Ghostty？它会回退到一套内置的雅致配色——什么都不会坏。

## 你能做什么

| 层级 | 操作 |
|---|---|
| **会话** | 切换并聚焦终端 · 行内重命名 · 新建 · kill · kill others |
| **窗口** | 新建 · 行内重命名 · 切换 · kill（连同其中每个窗格） |
| **窗格** | 横切 / 竖切 · swap ← → ↑ ↓ · mark + swap-with-marked · break out · 清空历史 · kill · kill others · 实时预览 + 复制内容 |
| **随处可用** | 命令面板（切换 / 执行任意 tmux 命令 / 新建会话）· tmux 控制台 · 小抄 · resurrect 保存与恢复 |

破坏性操作一律有确认弹窗把关。

## 截图

<p align="center">
  <img src="assets/screenshots/palette.png" width="560" alt="命令面板">
</p>
<p align="center"><em>命令面板——模糊切换会话、执行任意 tmux 命令（<code>></code>）、当场新建。配色取自实时的 Ghostty 主题。（真实会话名已打码。）</em></p>

<!-- 后续补：菜单栏切换器与三栏 Dashboard。 -->

## Tmux Kit 的不同之处

Tmux Kit 是一个**控制面板**，不是一套新栈。它和你本机已在跑的 tmux server 对话，在上面加一层原生 macOS 界面：

- **叠加，不替换** — 会话、配置、插件原封不动
- **零配置侵入** — 不装插件、不改 `~/.tmux.conf`
- **任意终端** — 不绑死某一款模拟器；用 Ghostty 时自动跟主题
- **菜单栏原生** — SwiftUI + AppKit、全局快捷键、需要时才出现
- **为并行 agent 设计** — 实时窗格预览、kill-others、跨会话 swap
- **默认私密** — 无网络、无账号、无遥测

生态里有很多好工具走别的路——[iTerm2 的 `-CC` 集成](https://iterm2.com/documentation-tmux-integration.html)做深度模拟器绑定，[Termdock](https://termdock.com) 是另一种 tmux GUI 思路，[Warp](https://www.warp.dev) 做 AI 原生终端，[Zellij](https://zellij.dev) 从零做现代多路复用器。**Tmux Kit 适合这样的你：继续用 tmux、终端随便换、在 macOS 上加一个轻量的原生控制面板。**

## 键盘

| 操作 | 快捷键 |
|---|---|
| 打开 / 聚焦 Dashboard | `⌃⌥⌘⇧D` |
| 命令面板（全局） | `⌥⌘T` |
| 命令面板（Dashboard 内） | `⌘K` |
| 切换到最近会话 | _默认未绑定_ |
| 设置 | `⌘,` |

所有全局快捷键都可在 **Settings → Keybindings** 重新绑定。

## 环境要求

- macOS 14（Sonoma）或更新
- [`tmux`](https://github.com/tmux/tmux) — 自动探测；路径可在 Settings 里配置
- 任意终端都能用。窗口聚焦匹配与主题匹配针对 [Ghostty](https://ghostty.org) 做了调优，其余功能在哪都能用。

## 安装 / 构建

不在 Mac App Store 上架——本应用非沙盒（它要运行 `tmux` 并使用 Accessibility API）。自己构建很快：

```sh
# 前置：Xcode、XcodeGen（brew install xcodegen）、tmux
git clone https://github.com/semantic-craft/mac-tmux-kit.git
cd mac-tmux-kit
./scripts/build-app.sh        # 构建、签名、安装到 /Applications 并启动
```

开发时用 `./scripts/run.sh`：构建 + 重新签名 + 重启一个 Debug 版本。

> **首次运行：** 授予 **Accessibility** 权限（Settings → Focus → *Open Accessibility Settings*），这样 Tmux Kit 才能把终端窗口拉到前台。构建用你本地的 Apple Development 证书签名，所以该权限在每次重建后依然保留。

## 它是怎么构建的

- **参数安全。** 每次 tmux 调用都把参数以数组形式传给 `Process`——绝不拼进 shell 字符串——所以带空格或元字符的会话名、路径都无法越界。
- **核心逻辑无界面测试。** 纯逻辑（领域模型与 tmux `-F` 输出解析器）放在 `Core/` Swift 包里，无 UI 单元测试（`cd Core && swift test`）。
- **稳定的代码身份。** 构建在 `xcodebuild` 之后用你本地的 Apple Development 证书重新签名，于是 Accessibility（TCC）授权在每次重建后都不会被重置。
- **读你的终端，但什么都不写。** 启动时从 `ghostty +show-config` 解析颜色；从不安装 tmux 插件，也不改你的 `~/.tmux.conf`。
- **原生，而非套壳。** SwiftUI + AppKit，菜单栏常驻（`LSUIElement`）。分层：`UI → Actions → Services (Tmux / Ghostty / Hotkeys) → Domain`。工程由 [XcodeGen](https://github.com/yonaskolb/XcodeGen) 从 `project.yml` 生成。设计 token 见 [`MacTmuxKit/Design/`](MacTmuxKit/Design) 与 [`DESIGN.md`](DESIGN.md)。

## 隐私与体积

无网络、无遥测、无账号。它只和你本机的 `tmux` 服务器对话，并（可选地）把终端窗口拉到前台。它从不安装 tmux 插件、也不改你的 `~/.tmux.conf`。唯一一处可选的配置改动——*Install recommended title format*——是一个你主动按的按钮，永远不会自动执行。

## 路线图

- 小抄的**练习模式**（做题，而非只查）
- 命令面板与全局快捷键里更多可绑定的动作
- Sparkle 自动更新 + Developer ID 公证，便于在多台 Mac 间一键分发
- 单个终端窗口内更细的 tab 级聚焦

## 许可

[MIT](LICENSE)。

<p align="center">
  为守 tmux、又喜欢把自己环境收拾得<em>干净</em>的人而做。如果那是你，点个 ⭐ 吧。
</p>

<p align="center">
  <a href="#readme-en">↑ English</a>
</p>

</details>