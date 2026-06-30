import SwiftUI
import AppKit
import TmuxKitCore

/// Column 1: the session list. Selecting drives the content column; double-click
/// or the context menu switches the attached tmux client to that session.
struct SessionSidebar: View {
    @Environment(AppState.self) private var app
    @Binding var selectedSessionId: String?
    var onRefresh: () -> Void = {}

    @State private var prompt: TextPrompt?
    @State private var confirm: ConfirmAction?

    var body: some View {
        List(selection: $selectedSessionId) {
            ForEach(app.sessions) { session in
                SessionSidebarRow(session: session)
                    .tag(session.id)
                    .contextMenu { menu(for: session) }
                    .simultaneousGesture(TapGesture(count: 2).onEnded {
                        Task { await app.switchTo(session) }
                    })
            }
        }
        .listStyle(.sidebar)
        .tint(Theme.accent)
        .overlay {
            if app.sessions.isEmpty {
                EmptyStateView(
                    icon: "rectangle.3.group",
                    title: app.statusMessage ?? "No tmux sessions",
                    subtitle: "Create one with the + button"
                )
            }
        }
        .navigationTitle("Sessions")
        .toolbar {
            ToolbarItem {
                Button(action: promptNewSession) {
                    Image(systemName: "plus")
                }
                .help("New session")
            }
            ToolbarItem {
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh")
            }
        }
        .sheet(item: $prompt) { TextPromptSheet(prompt: $0) }
        .confirm($confirm)
    }

    @ViewBuilder
    private func menu(for session: TmuxSession) -> some View {
        Button {
            app.togglePin(session)
        } label: {
            Label(app.isPinned(session) ? "Unpin" : "Pin", systemImage: app.isPinned(session) ? "pin.slash" : "pin")
        }
        Button("Switch and Focus") { Task { await app.switchTo(session) } }
        Button("Rename") {
            prompt = TextPrompt(
                title: "Rename session", placeholder: "Name",
                initial: session.name, confirmLabel: "Rename"
            ) { name in Task { await app.renameSession(session, to: name) } }
        }
        Divider()
        Button("Kill", role: .destructive) {
            confirm = ConfirmAction(
                title: "Kill session \"\(session.name)\"?",
                message: "This closes every window and pane in it.",
                confirmLabel: "Kill"
            ) { Task { await app.killSession(session) } }
        }
        Button("Kill Other Sessions", role: .destructive) {
            confirm = ConfirmAction(
                title: "Kill all other sessions?",
                message: "Keeps only \"\(session.name)\".",
                confirmLabel: "Kill Others"
            ) { Task { await app.killOtherSessions(keep: session) } }
        }
    }

    private func promptNewSession() {
        prompt = TextPrompt(
            title: "New session", placeholder: "Name", confirmLabel: "Create"
        ) { name in Task { await app.newSession(name: name, startDir: nil) } }
    }
}

/// One session row: status dot + name + current folder. On hover, a quick
/// "switch and focus" button replaces the window count (BucketDrop pattern).
private struct SessionSidebarRow: View {
    @Environment(AppState.self) private var app
    let session: TmuxSession
    @State private var hovering = false
    @State private var editing = false
    @State private var draft = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 7) {
                StatusDot(attached: session.attached)
                if editing {
                    RenameField(
                        text: $draft, prompt: "Session name",
                        font: Theme.Font.rowTitle,
                        onCommit: commit, onCancel: { editing = false }
                    )
                } else {
                    Text(session.name)
                        .font(.system(size: 13, weight: session.attached ? .semibold : .medium))
                        .foregroundStyle(session.attached ? .primary : .secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    StatePill(attached: session.attached)
                    if app.isPinned(session) {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(Theme.accent)
                            .accessibilityLabel("Pinned")
                    }
                    Spacer(minLength: 4)
                    if hovering {
                        RenamePencil(action: startEditing)
                        Button { Task { await app.switchTo(session) } } label: {
                            Image(systemName: "arrow.up.forward.app")
                        }
                        .buttonStyle(.borderless)
                        .help("Switch and focus")
                    }
                }
            }
            Text(subtitle)
                .font(Theme.Font.metric)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
            Text(countsLine)
                .font(Theme.Font.metricSmall)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
        .onHover { hovering = $0 }
    }

    private func startEditing() {
        draft = session.name
        editing = true
    }

    private func commit() {
        let name = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        editing = false
        guard !name.isEmpty, name != session.name else { return }
        Task { await app.renameSession(session, to: name) }
    }

    private var subtitle: String {
        let folder = pathLastComponent(app.sessionDisplayPath(session)) ?? "~"
        guard let w = app.activeWindow(in: session) else { return folder }
        return "\(folder) · \(w.index): \(app.windowReadableName(w, activePane: app.activePane(in: w)))"
    }

    private var countsLine: String {
        let panes = app.paneCount(in: session)
        let windows = session.windowCount == 1 ? "1 window" : "\(session.windowCount) windows"
        let panesText = panes == 1 ? "1 pane" : "\(panes) panes"
        return "\(windows) · \(panesText)"
    }
}
