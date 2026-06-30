import SwiftUI
import AppKit
import TmuxKitCore

/// Column 2: the selected session's windows (as sections) and panes (as rows).
/// A persistent action bar at the bottom operates on the selected pane, so the
/// common operations are always one click away.
struct WindowPaneColumn: View {
    @Environment(AppState.self) private var app
    let sessionId: String?
    @Binding var selectedPaneId: String?

    @State private var prompt: TextPrompt?
    @State private var confirm: ConfirmAction?

    private var session: TmuxSession? { app.session(id: sessionId) }
    private var windows: [TmuxWindow] { sessionId.map { app.tree.windows(in: $0) } ?? [] }

    var body: some View {
        Group {
            if let session {
                VStack(spacing: 0) {
                    List(selection: $selectedPaneId) {
                        ForEach(windows) { window in
                            let windowPanes = app.tree.panes(in: window.id)
                            let activePane = windowPanes.first { $0.active } ?? windowPanes.first
                            Section {
                                ForEach(windowPanes) { pane in
                                    PaneRow(pane: pane)
                                        .tag(pane.id)
                                        .contextMenu { paneMenu(pane) }
                                }
                            } header: {
                                WindowHeaderRow(
                                    window: window,
                                    title: app.windowReadableName(window, activePane: activePane)
                                )
                                    .contextMenu { windowMenu(window) }
                            }
                        }
                    }
                    .listStyle(.inset)
                    .tint(Theme.accent)

                    Divider()
                    PaneActionBar(pane: app.pane(id: selectedPaneId), prompt: $prompt, confirm: $confirm)
                }
                .navigationTitle(session.name)
                .navigationSubtitle(session.windowCount == 1 ? "1 window" : "\(session.windowCount) windows")
            } else {
                EmptyStateView(icon: "sidebar.squares.leading", title: "Select a session")
            }
        }
        .toolbar {
            if let session {
                ToolbarItem {
                    Button { promptNewWindow(in: session.id) } label: {
                        Image(systemName: "plus.rectangle")
                    }
                    .help("New window")
                }
            }
        }
        .sheet(item: $prompt) { TextPromptSheet(prompt: $0) }
        .confirm($confirm)
    }

    // MARK: - Menus

    @ViewBuilder
    private func windowMenu(_ window: TmuxWindow) -> some View {
        Button("Switch to Window") { Task { await app.selectWindow(window) } }
        Button("Rename") {
            prompt = TextPrompt(
                title: "Rename window", placeholder: "Name",
                initial: window.name, confirmLabel: "Rename"
            ) { name in Task { await app.renameWindow(window, to: name) } }
        }
        Divider()
        Button("Kill Window", role: .destructive) {
            confirm = ConfirmAction(
                title: "Kill window \"\(window.name)\"?",
                message: "This closes every pane in the window.",
                confirmLabel: "Kill"
            ) { Task { await app.killWindow(window) } }
        }
    }

    @ViewBuilder
    private func paneMenu(_ pane: TmuxPane) -> some View {
        Button("Split Right") { Task { await app.split(pane, horizontal: true) } }
        Button("Split Down") { Task { await app.split(pane, horizontal: false) } }
        Divider()
        Button("Break to Window") { Task { await app.breakPane(pane) } }
        Menu("Swap With") {
            Button("Left") { Task { await app.swap(pane, .left) } }
            Button("Right") { Task { await app.swap(pane, .right) } }
            Button("Up") { Task { await app.swap(pane, .up) } }
            Button("Down") { Task { await app.swap(pane, .down) } }
        }
        Button("Mark Pane") { Task { await app.markPane(pane) } }
        Button("Clear History") { Task { await app.clearHistory(pane) } }
        Divider()
        Button("Kill Other Panes", role: .destructive) { confirmKillOthers(pane) }
        Button("Kill Pane", role: .destructive) { confirmKill(pane) }
    }

    private func confirmKill(_ pane: TmuxPane) {
        confirm = ConfirmAction(
            title: "Kill pane \(pane.id)?",
            message: "Running: \(pane.command)",
            confirmLabel: "Kill"
        ) { Task { await app.killPane(pane) } }
    }

    private func confirmKillOthers(_ pane: TmuxPane) {
        confirm = ConfirmAction(
            title: "Kill other panes?",
            message: "Keeps only \(pane.id) in its window.",
            confirmLabel: "Kill Others"
        ) { Task { await app.killOtherPanes(pane) } }
    }

    private func promptNewWindow(in sessionId: String) {
        prompt = TextPrompt(
            title: "New window", placeholder: "Name (optional)", confirmLabel: "Create"
        ) { name in Task { await app.newWindow(inSession: sessionId, name: name, startDir: nil) } }
    }
}

// MARK: - Rows

private struct WindowHeaderRow: View {
    @Environment(AppState.self) private var app
    let window: TmuxWindow
    let title: String
    @State private var editing = false
    @State private var draft = ""
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 8) {
            Text("\(window.index)")
                .font(Theme.Font.metricSmall)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 5)
                .padding(.vertical, 1)
                .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 4, style: .continuous))
            if editing {
                RenameField(
                    text: $draft, prompt: "Window name",
                    font: Theme.Font.bodyEmphasis,
                    onCommit: commit, onCancel: { editing = false }
                )
            } else {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                if window.active {
                    Text("ACTIVE")
                        .font(Theme.Font.pill)
                        .tracking(0.4)
                        .foregroundStyle(Theme.accentInk)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Theme.accentSoft, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                }
            }
            Spacer()
            if !editing {
                if hovering { RenamePencil(action: startEditing) }
                Text("\(window.paneCount)p")
                    .font(Theme.Font.metricSmall)
                    .foregroundStyle(.tertiary)
            }
        }
        .onHover { hovering = $0 }
    }

    private func startEditing() {
        draft = window.name
        editing = true
    }

    private func commit() {
        let name = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        editing = false
        guard !name.isEmpty, name != window.name else { return }
        Task { await app.renameWindow(window, to: name) }
    }
}

private struct PaneRow: View {
    @Environment(AppState.self) private var app
    let pane: TmuxPane
    @State private var editing = false
    @State private var draft = ""
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 9) {
            StatusDot(attached: pane.active, size: 6)
            if editing {
                RenameField(
                    text: $draft, prompt: "Pane title",
                    font: Theme.Font.rowTitlePlain,
                    onCommit: commit, onCancel: { editing = false }
                )
            } else {
                Text(app.paneReadableName(pane))
                    .font(.system(size: 12.5, weight: pane.active ? .semibold : .medium))
                    .foregroundStyle(pane.active ? .primary : .secondary)
                    .lineLimit(1)
                if !pane.command.isEmpty {
                    Text(pane.command)
                        .font(Theme.Font.rowSubtitle)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            Spacer(minLength: 8)
            if !editing {
                if hovering { RenamePencil(action: startEditing) }
                Text(pane.id)
                    .font(Theme.Font.metricSmall)
                    .foregroundStyle(.tertiary)
                Text("\(pane.width)×\(pane.height)")
                    .font(Theme.Font.metricSmall)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
        .onHover { hovering = $0 }
    }

    private func startEditing() {
        draft = app.paneCustomName(pane)
        editing = true
    }

    private func commit() {
        let title = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        editing = false
        guard title != app.paneCustomName(pane) else { return }
        Task { await app.renamePane(pane, to: title) }
    }
}
