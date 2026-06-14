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
            if !app.hasAXPermission {
                permissionBanner
                Divider()
            }
            footer
        }
        .frame(width: 360)
        .task { await app.refresh() }
    }

    private var permissionBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.shield")
                .foregroundStyle(Theme.warning)
            Text("Allow Accessibility to focus Ghostty windows")
                .font(Theme.Font.rowSubtitle)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 4)
            Button("Enable") {
                app.requestAXPermission()
                app.openAccessibilitySettings()
            }
            .buttonStyle(.borderless)
            .font(Theme.Font.rowSubtitle)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "terminal")
            Text("Tmux Kit").font(.headline)
            Spacer()
            if app.isLoading {
                ProgressView().controlSize(.small)
            } else if !app.sessions.isEmpty {
                Text(sessionCountText)
                    .font(Theme.Font.metric)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var content: some View {
        if !app.sessions.isEmpty {
            ScrollView {
                VStack(spacing: 3) {
                    ForEach(app.sessions) { session in
                        let window = activeWindow(for: session)
                        SessionRow(
                            session: session,
                            activeWindow: window,
                            activePane: activePane(in: window),
                            hostShort: app.hostShort
                        ) {
                            Task { await app.activateFromMenuBar(session) }
                        }
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
            }
            .frame(height: sessionListHeight)
        } else {
            Text(app.statusMessage ?? "No tmux sessions.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 16)
        }
    }

    private var sessionCountText: String {
        app.sessions.count == 1 ? "1 session" : "\(app.sessions.count) sessions"
    }

    private var sessionListHeight: CGFloat {
        let rowHeight: CGFloat = 68
        let padding: CGFloat = 12
        return min(CGFloat(app.sessions.count) * rowHeight + padding, 380)
    }

    private func activeWindow(for session: TmuxSession) -> TmuxWindow? {
        let windows = app.tree.windows(in: session.id)
        return windows.first { $0.active } ?? windows.first
    }

    private func activePane(in window: TmuxWindow?) -> TmuxPane? {
        guard let window else { return nil }
        let panes = app.tree.panes(in: window.id)
        return panes.first { $0.active } ?? panes.first
    }

    private var footer: some View {
        HStack(spacing: 14) {
            Button {
                app.showDashboard()
            } label: {
                Label("Dashboard", systemImage: "rectangle.3.group")
            }
            .fixedSize()
            SettingsLink {
                Label("Settings", systemImage: "gearshape")
            }
            .fixedSize()
            .help("Settings (⌘,)")
            Spacer()
            Menu {
                Button { app.showCommandPalette() } label: {
                    Label("Command Palette", systemImage: "magnifyingglass")
                }
                Divider()
                Button { openWindow(id: WindowID.console) } label: {
                    Label("Console", systemImage: "terminal")
                }
                Button { openWindow(id: WindowID.cheatsheet) } label: {
                    Label("Cheatsheet", systemImage: "book")
                }
                Divider()
                Button { Task { await app.refresh() } } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .help("More")
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

/// One session row: status dot + name + current folder, with the window count.
/// Filled green dot = a client is attached.
private struct SessionRow: View {
    let session: TmuxSession
    let activeWindow: TmuxWindow?
    let activePane: TmuxPane?
    let hostShort: String
    let onSwitch: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: onSwitch) {
            HStack(spacing: 10) {
                Image(systemName: session.attached ? "circle.fill" : "circle")
                    .font(.system(size: 9))
                    .foregroundStyle(session.attached ? Theme.attached : Color.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.name)
                        .font(Theme.Font.rowTitle)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Text(activeWorkLabel)
                        .font(Theme.Font.rowSubtitle)
                        .foregroundStyle(.primary.opacity(0.72))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Text(folder(session.path))
                        .font(Theme.Font.rowSubtitle)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(session.windowCount)w")
                        .font(Theme.Font.metric)
                        .foregroundStyle(.secondary)
                    if let activeWindow {
                        Text("\(activeWindow.paneCount)p")
                            .font(Theme.Font.metricSmall)
                            .foregroundStyle(.tertiary)
                    }
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .opacity(hovering ? 1 : 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .background(hovering ? Theme.hoverFill : .clear)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.row))
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }

    private var activeWorkLabel: String {
        guard let activeWindow else { return "No windows" }
        let windowName = "\(activeWindow.index): \(activeWindow.name)"
        guard let activePane else { return windowName }
        let paneName = paneDisplayName(
            title: activePane.title,
            command: activePane.command,
            host: hostShort
        )
        if paneName == activeWindow.name { return windowName }
        return "\(windowName) · \(paneName)"
    }

    private func folder(_ path: String) -> String {
        let displayPath = activePane?.path.isEmpty == false ? activePane?.path : path
        guard let displayPath, !displayPath.isEmpty else { return "~" }
        return URL(fileURLWithPath: displayPath).lastPathComponent
    }
}
