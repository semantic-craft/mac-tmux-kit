# Tmux Kit 开发入口

Tmux Kit 是 macOS 原生 tmux 管理应用。产品行为、环境和构建入口见 [README](README.md)；设计改动读 [DESIGN](DESIGN.md) 和 [DESIGN-CHECKLIST](DESIGN-CHECKLIST.md)。

| 改动 | 入口 |
| --- | --- |
| 领域模型、tmux 输出解析 | [Core/Sources](Core/Sources/)、[Core/Tests](Core/Tests/) |
| 原生界面、窗口与系统集成 | [MacTmuxKit](MacTmuxKit/)、[MacTmuxKitTests](MacTmuxKitTests/) |
| 构建与应用配置 | [project.yml](project.yml)、[scripts/build-app.sh](scripts/build-app.sh) |

从根目录运行 `swift test --package-path Core` 验证纯逻辑；应用构建按 README。`project.yml` 是 XcodeGen 原件，生成的 Xcode 工程不作为编辑入口。
实际 tmux 会话、终端聚焦和辅助功能效果另做原生验收；`scripts/run.sh` 会运行应用，不能当作只读检查。
当前仓库没有 `.trellis` 工作流，使用上述实际存在的入口。
实现、评审或验收前读相关 [lessons](lessons.md)；出现可复用的纠正或漏验时更新原条目。
