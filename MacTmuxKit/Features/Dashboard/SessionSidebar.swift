import SwiftUI
import AppKit
import TmuxKitCore

/// Column 1: the session list. Selecting drives the content column; double-click
/// or the context menu switches the attached tmux client to that session.
struct SessionSidebar: View {
    @Environment(AppState.self) private var app
    @Binding var selectedSessionId: String?

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
                Button { Task { await app.refresh() } } label: {
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

/// One session row: status dot + name + window count.
private struct SessionSidebarRow: View {
    let session: TmuxSession

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: session.attached ? "circle.fill" : "circle")
                .font(.system(size: 8))
                .foregroundStyle(session.attached ? Color.green : Color.secondary)
            Text(session.name)
                .font(.system(size: 13))
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer(minLength: 6)
            Text("\(session.windowCount)w")
                .font(.system(size: 11).monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
