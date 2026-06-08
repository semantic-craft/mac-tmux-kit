<p align="center">
  <img src="assets/icon.png" width="128" alt="Tmux Kit 图标">
</p>

<h1 align="center">Tmux Kit</h1>

<p align="center">
  一个快速、原生的 macOS 应用，为 <a href="https://github.com/tmux/tmux">tmux</a> 套上友好的图形界面——
  切换会话、管理窗口与窗格、执行命令，全程不用背任何快捷键。
  <br>
  <strong>它不取代 tmux，而是叠在你正在用的那个 tmux 之上——并自动染上你终端的配色。</strong>
</p>

<p align="center">
  <img alt="platform" src="https://img.shields.io/badge/macOS-14%2B-black?logo=apple">
  <img alt="swift" src="https://img.shields.io/badge/SwiftUI%20%2B%20AppKit-orange?logo=swift">
  <img alt="no network" src="https://img.shields.io/badge/network-none-success">
  <img alt="license" src="https://img.shields.io/badge/license-MIT-blue">
</p>

<p align="center"><a href="README.md">English</a> · <b>简体中文</b></p>

---

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

- **🎨 自动染上你终端的配色** — 启动时读取你的 [Ghostty](https://ghostty.org) 主题并与之匹配（[详见下文](#-它看起来就属于你的终端)）。应用像是终端的一部分，而不是一个外来窗口。
- **菜单栏快速切换器** — 所有会话一目了然（彩色圆点 = 已 attach），一键切换并聚焦其终端。
- **自动聚焦正确的窗口** — 切换会话时把它的终端窗口拉到前台（经由 Accessibility API）；若该会话处于 detached，则新开一个窗口，而不是劫持你当前的窗口。
- **命令面板** — 从任何地方模糊查找并切换会话；输入 `>` 执行任意 tmux 命令；输入一个新名字当场创建会话。可用全局快捷键（`⌥⌘T`，可改键）、菜单栏，或在 Dashboard 内用 **`⌘K`** 唤起。
- **Dashboard** — 三栏浏览器（会话 → 窗口/窗格 → 实时窗格预览），打开即落在你最近的会话上，底部常驻动作条：split、定向 swap、break out、kill / kill-others。
- **行内重命名** — 就地重命名任意会话、窗口或窗格；点铅笔、输入、回车。
- **可交互小抄** — 约 50 条 tmux 原生快捷键，可搜索、点击即复制。学习时一直开着，点着点着就记住了键。
- **tmux 控制台** — 执行任意 tmux 命令，带预设与历史（破坏性命令先确认），stdout/stderr 内联显示。
- **布局备份** — 经由 [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) 一键保存/恢复（前提是你装了它）。
- **全局快捷键** — 从任何地方唤起 Dashboard（`⌃⌥⌘⇧D`）、命令面板，或"切换到最近会话"；全部可改键。

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

---

<p align="center">
  为守 tmux、又喜欢把自己环境收拾得<em>干净</em>的人而做。如果那是你，点个 ⭐ 吧。
</p>
