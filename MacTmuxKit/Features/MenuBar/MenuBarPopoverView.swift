import SwiftUI
import AppKit
import TmuxKitCore

/// Menu-bar popover: the quick session switcher. Lists sessions (most recently
/// active first); clicking one switches the attached tmux client to it.
struct MenuBarPopoverView: View {
    @Environment(AppState.self) private var app
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            content
            Divider()
            footer
        }
        .frame(width: 300)
        .task { await app.refresh() }
    }

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "terminal")
            Text("Tmux Kit").font(.headline)
            Spacer()
            if app.isLoading {
                ProgressView().controlSize(.small)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var content: some View {
        if !app.sessions.isEmpty {
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(app.sessions) { session in
                        SessionRow(session: session) {
                            Task { await app.switchTo(session) }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(maxHeight: 320)
        } else {
            Text(app.statusMessage ?? "No tmux sessions.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 16)
        }
    }

    private var footer: some View {
        HStack {
            Button {
                openWindow(id: WindowID.dashboard)
                NSApplication.shared.activate()
            } label: {
                Label("Dashboard", systemImage: "rectangle.3.group")
            }
            Button {
                Task { await app.refresh() }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            Spacer()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

/// One session row. Filled green dot = a client is attached.
private struct SessionRow: View {
    let session: TmuxSession
    let onSwitch: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: onSwitch) {
            HStack(spacing: 8) {
                Image(systemName: session.attached ? "circle.fill" : "circle")
                    .font(.system(size: 8))
                    .foregroundStyle(session.attached ? Color.green : Color.secondary)
                Text(session.name)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: 8)
                Text("\(session.windowCount)w")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .background(hovering ? Color.accentColor.opacity(0.15) : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}
