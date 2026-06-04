import SwiftUI
import AppKit

/// Run an arbitrary tmux command (like `prefix :`). Presets + history; commands
/// that start with "kill" require confirmation. Shows stdout and stderr.
struct ConsoleView: View {
    @Environment(AppState.self) private var app

    @State private var command = ""
    @State private var output = ""
    @State private var stderr = ""
    @State private var exitCode: Int32?
    @State private var running = false
    @State private var history: [String] =
        (UserDefaults.standard.array(forKey: Self.historyKey) as? [String]) ?? []
    @State private var confirm: ConfirmAction?
    @FocusState private var focused: Bool

    private static let historyKey = "consoleHistory"
    private let presets = [
        "list-sessions", "list-windows -a", "list-clients", "show-options -g",
        "set -g mouse on", "set -g mouse off", "set -g status on", "set -g status off",
        "display-message -p '#{pane_current_path}'", "kill-session -a",
    ]

    var body: some View {
        VStack(spacing: 0) {
            inputBar
            Divider()
            results
        }
        .frame(minWidth: 560, minHeight: 420)
        .onAppear { AppActivationPolicy.enter(); focused = true }
        .onDisappear { AppActivationPolicy.leave() }
        .confirm($confirm)
    }

    private var inputBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "terminal").foregroundStyle(.secondary)
            TextField("tmux command, e.g. list-sessions", text: $command)
                .textFieldStyle(.roundedBorder)
                .font(Theme.Font.terminalInput)
                .focused($focused)
                .onSubmit(submit)

            Menu("Presets") {
                ForEach(presets, id: \.self) { p in
                    Button(p) { command = p }
                }
            }
            .menuStyle(.button)
            .fixedSize()

            Menu("History") {
                if history.isEmpty {
                    Text("Empty")
                } else {
                    ForEach(history, id: \.self) { h in
                        Button(h) { command = h }
                    }
                    Divider()
                    Button("Clear History", role: .destructive) { clearHistory() }
                }
            }
            .menuStyle(.button)
            .fixedSize()
            .disabled(history.isEmpty)

            Button(action: submit) {
                if running { ProgressView().controlSize(.small) } else { Text("Run") }
            }
            .keyboardShortcut(.return)
            .disabled(running || command.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(12)
    }

    private var results: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                if let exitCode {
                    Label(exitCode == 0 ? "Success" : "Failed (exit \(exitCode))",
                          systemImage: exitCode == 0 ? "checkmark.circle" : "xmark.octagon")
                        .font(Theme.Font.body)
                        .foregroundStyle(exitCode == 0 ? Theme.success : Theme.danger)
                }
                if !output.isEmpty { block("stdout", output) }
                if !stderr.isEmpty { block("stderr", stderr) }
                if exitCode == nil {
                    Text("Output appears here.")
                        .font(Theme.Font.body)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(12)
        }
        .background(Color(nsColor: .textBackgroundColor))
    }

    private func block(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(Theme.Font.sectionHeader).foregroundStyle(.secondary)
            Text(text)
                .font(Theme.Font.terminal)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Run

    private func submit() {
        let cmd = command.trimmingCharacters(in: .whitespaces)
        guard !cmd.isEmpty, !running else { return }
        if cmd.lowercased().hasPrefix("kill") {
            confirm = ConfirmAction(
                title: "Run destructive command?",
                message: cmd,
                confirmLabel: "Run"
            ) { execute(cmd) }
        } else {
            execute(cmd)
        }
    }

    private func execute(_ cmd: String) {
        running = true
        Task {
            let result = await app.runRaw(cmd)
            output = result.stdout
            stderr = result.stderr
            exitCode = result.exitCode
            running = false
            pushHistory(cmd)
        }
    }

    private func pushHistory(_ cmd: String) {
        history.removeAll { $0 == cmd }
        history.insert(cmd, at: 0)
        if history.count > 20 { history = Array(history.prefix(20)) }
        UserDefaults.standard.set(history, forKey: Self.historyKey)
    }

    private func clearHistory() {
        history = []
        UserDefaults.standard.removeObject(forKey: Self.historyKey)
    }
}
