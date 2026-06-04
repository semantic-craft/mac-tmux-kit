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

/// One session row: status dot + name + current folder. On hover, a quick
/// "switch and focus" button replaces the window count (BucketDrop pattern).
private struct SessionSidebarRow: View {
    @Environment(AppState.self) private var app
    let session: TmuxSession
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: session.attached ? "circle.fill" : "circle")
                .font(.system(size: 8))
                .foregroundStyle(session.attached ? Color.green : Color.secondary)
            VStack(alignment: .leading, spacing: 1) {
                Text(session.name)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(folder(session.path))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 6)
            if hovering {
                Button { Task { await app.switchTo(session) } } label: {
                    Image(systemName: "arrow.up.forward.app")
                }
                .buttonStyle(.borderless)
                .help("Switch and focus")
            } else {
                Text("\(session.windowCount)w")
                    .font(.system(size: 11).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 3)
        .onHover { hovering = $0 }
    }

    private func folder(_ path: String) -> String {
        path.isEmpty ? "~" : URL(fileURLWithPath: path).lastPathComponent
    }
}
