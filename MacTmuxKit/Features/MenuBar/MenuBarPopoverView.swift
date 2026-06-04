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
        .frame(width: 340)
        .task { await app.refresh() }
    }

    private var permissionBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.shield")
                .foregroundStyle(.orange)
            Text("Allow Accessibility to focus Ghostty windows")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 4)
            Button("Enable") {
                app.requestAXPermission()
                app.openAccessibilitySettings()
            }
            .buttonStyle(.borderless)
            .font(.system(size: 11))
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
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var content: some View {
        if !app.sessions.isEmpty {
            ScrollView {
                LazyVStack(spacing: 3) {
                    ForEach(app.sessions) { session in
                        SessionRow(session: session) {
                            Task { await app.switchTo(session) }
                        }
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
            }
            .frame(maxHeight: 380)
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
        HStack(spacing: 12) {
            Button {
                openWindow(id: WindowID.dashboard)
                // Dock + foreground activation handled by DashboardView.onAppear.
            } label: {
                Label("Dashboard", systemImage: "rectangle.3.group")
            }
            SettingsLink {
                Label("Settings", systemImage: "gearshape")
            }
            .help("Settings (⌘,)")
            Spacer()
            Button {
                app.showCommandPalette()
            } label: {
                Image(systemName: "magnifyingglass")
            }
            .help("Command palette (⌥⌘T)")
            Button {
                Task { await app.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .help("Refresh")
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
    let onSwitch: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: onSwitch) {
            HStack(spacing: 10) {
                Image(systemName: session.attached ? "circle.fill" : "circle")
                    .font(.system(size: 9))
                    .foregroundStyle(session.attached ? Color.green : Color.secondary)
                VStack(alignment: .leading, spacing: 2) {
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
                Spacer(minLength: 8)
                Text("\(session.windowCount)w")
                    .font(.system(size: 11).monospacedDigit())
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .opacity(hovering ? 1 : 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .background(hovering ? Color.primary.opacity(0.07) : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }

    private func folder(_ path: String) -> String {
        path.isEmpty ? "~" : URL(fileURLWithPath: path).lastPathComponent
    }
}
