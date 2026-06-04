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
                            Section {
                                ForEach(app.tree.panes(in: window.id)) { pane in
                                    PaneRow(pane: pane)
                                        .tag(pane.id)
                                        .contextMenu { paneMenu(pane) }
                                }
                            } header: {
                                WindowHeaderRow(window: window)
                                    .contextMenu { windowMenu(window) }
                            }
                        }
                    }
                    .listStyle(.inset)

                    Divider()
                    PaneActionBar(pane: app.pane(id: selectedPaneId), prompt: $prompt, confirm: $confirm)
                }
                .navigationTitle(session.name)
                .navigationSubtitle("\(session.windowCount) windows")
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
        Button("Mark Pane") { Task { await app.markPane(pane) } }
        Button("Clear History") { Task { await app.clearHistory(pane) } }
        Divider()
        Button("Kill Pane", role: .destructive) { confirmKill(pane) }
    }

    private func confirmKill(_ pane: TmuxPane) {
        confirm = ConfirmAction(
            title: "Kill pane \(pane.id)?",
            message: "Running: \(pane.command)",
            confirmLabel: "Kill"
        ) { Task { await app.killPane(pane) } }
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
    @State private var editing = false
    @State private var draft = ""

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "rectangle.split.3x1")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            if editing {
                Text("\(window.index):")
                    .font(Theme.Font.sectionHeader)
                    .foregroundStyle(.secondary)
                RenameField(
                    text: $draft, prompt: "Window name",
                    font: Theme.Font.sectionHeader,
                    onCommit: commit, onCancel: { editing = false }
                )
            } else {
                Text("\(window.index): \(window.name)")
                    .font(Theme.Font.sectionHeader)
                if window.active {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(Theme.accent)
                }
            }
            Spacer()
            if !editing {
                RenamePencil(action: startEditing)
                Text("\(window.paneCount)p")
                    .font(Theme.Font.metricSmall)
                    .foregroundStyle(.tertiary)
            }
        }
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

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: pane.active ? "square.fill" : "square")
                .font(.system(size: 9))
                .foregroundStyle(pane.active ? Theme.accent : Color.secondary)
            VStack(alignment: .leading, spacing: 1) {
                if editing {
                    RenameField(
                        text: $draft, prompt: "Pane title",
                        font: Theme.Font.rowTitlePlain,
                        onCommit: commit, onCancel: { editing = false }
                    )
                } else {
                    Text(app.paneName(pane))
                        .font(Theme.Font.rowTitlePlain)
                        .lineLimit(1)
                }
                Text(folderName(pane.path))
                    .font(Theme.Font.rowSubtitle)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 6)
            if !editing {
                RenamePencil(action: startEditing)
                Text("\(pane.width)x\(pane.height)")
                    .font(Theme.Font.metricSmall)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
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

    private func folderName(_ path: String) -> String {
        path.isEmpty ? "" : URL(fileURLWithPath: path).lastPathComponent
    }
}
