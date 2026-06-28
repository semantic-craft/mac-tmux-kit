import SwiftUI
import AppKit
import TmuxKitCore

/// Menu-bar popover: a compact command center for restoring, switching, and
/// opening the deeper tmux surfaces.
struct MenuBarPopoverView: View {
    @Environment(AppState.self) private var app
    @AppStorage("resurrectRestoreProcesses") private var restoreProcesses = true
    @State private var backupStatus = ""
    @State private var backupWorking = false
    @State private var snapshotStatus = ""
    @State private var confirmRestore = false

    private let visibleSessionLimit = 3

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    restoreCard
                    sessionsSection
                    statusSection
                    if !app.hasAXPermission {
                        attentionSection
                    }
                    actionsSection
                }
                .padding(12)
            }
        }
        .frame(width: 390, height: 560, alignment: .topLeading)
        .background(.thinMaterial)
        .task { await app.refresh() }
        .confirmationDialog("Restore last saved layout?", isPresented: $confirmRestore) {
            Button("Restore", role: .destructive) {
                performBackupAction(success: restoreProcesses ? "Restored layout and commands" : "Restored layout") {
                    await app.resurrectRestore()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(restoreProcesses ? "This recreates the saved sessions, windows, panes, and saved commands." : "This recreates the saved sessions, windows, and panes.")
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Theme.accent.opacity(0.16))
                Image(systemName: "terminal")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.accent)
            }
            .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 1) {
                Text("Tmux Kit")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(headerSubtitle)
                    .font(Theme.Font.rowSubtitle)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            if app.isLoading {
                ProgressView()
                    .controlSize(.small)
                    .frame(width: 26, height: 26)
            } else {
                IconButton(systemName: "arrow.clockwise", help: "Refresh") {
                    Task { await app.refresh() }
                }
            }
            IconButton(systemName: "gearshape", help: "Settings") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var restoreCard: some View {
        Button {
            confirmRestore = true
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Theme.accent.opacity(0.18))
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                }
                .frame(width: 30, height: 30)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Restore layout")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(restoreSubtitle)
                        .font(Theme.Font.rowSubtitle)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer(minLength: 8)

                if backupWorking {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "return")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(11)
            .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
            .background(Theme.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Theme.accent.opacity(0.20), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(!app.resurrectAvailable || app.resurrectLastSaved() == nil || backupWorking)
        .opacity(app.resurrectAvailable && app.resurrectLastSaved() != nil ? 1 : 0.55)
    }

    private var sessionsSection: some View {
        MenuSection(title: app.sessions.isEmpty ? "Sessions" : "Recent") {
            if app.sessions.isEmpty {
                StaticMenuLine(
                    systemName: "terminal",
                    title: app.statusMessage ?? "No tmux sessions",
                    subtitle: "Restore a saved layout or open Ghostty"
                )
            } else {
                ForEach(app.pinnedFirstSessions(limit: visibleSessionLimit)) { session in
                    let window = app.activeWindow(in: session)
                    let pane = app.activePane(in: window)
                    MenuItemRow(
                        systemName: session.attached ? "smallcircle.filled.circle" : "circle",
                        iconTint: session.attached ? Theme.accent : .secondary,
                        title: session.name,
                        subtitle: sessionSubtitle(session: session, window: window, pane: pane)
                    ) {
                        Task { await app.activateFromMenuBar(session) }
                    }
                }
                MenuItemRow(systemName: "rectangle.grid.1x2", title: "More", subtitle: "", accessory: .chevron) {
                    app.showDashboard()
                }
            }
        }
    }

    private var statusSection: some View {
        MenuSection(title: "Backup") {
            StaticMenuLine(systemName: "clock", title: "Last saved", subtitle: lastSavedText)
            StaticMenuLine(
                systemName: restoreProcesses ? "checkmark.circle" : "minus.circle",
                iconTint: restoreProcesses ? Theme.success : .secondary,
                title: "Saved commands",
                subtitle: restoreProcesses ? "Restore enabled" : "Restore disabled"
            )
        }
    }

    private var attentionSection: some View {
        MenuSection(title: "Attention") {
            MenuItemRow(
                systemName: "exclamationmark.triangle",
                iconTint: Theme.warning,
                title: "Accessibility",
                subtitle: "Needed to focus Ghostty windows",
                accessory: .chevron
            ) {
                app.requestAXPermission()
                app.openAccessibilitySettings()
            }
        }
    }

    private var actionsSection: some View {
        MenuSection(title: "Actions") {
            MenuItemRow(
                systemName: "tray.and.arrow.down",
                title: "Save current layout",
                subtitle: "",
                accessory: backupWorking ? .progress : .none,
                isEnabled: app.resurrectAvailable && !backupWorking
            ) {
                performBackupAction(success: "Saved layout") { await app.resurrectSave() }
            }
            MenuItemRow(systemName: "rectangle.3.group", title: "Open Dashboard", subtitle: "", accessory: .chevron) {
                app.showDashboard()
            }
            MenuItemRow(
                systemName: "doc.on.doc",
                title: "Copy Debug Snapshot",
                subtitle: snapshotStatus,
                accessory: snapshotStatus == "Copying..." ? .progress : .none
            ) {
                snapshotStatus = "Copying..."
                Task {
                    snapshotStatus = await app.copyDebugSnapshot() ? "Copied" : "Copy failed"
                }
            }
            MenuItemRow(systemName: "command", title: "Command Palette", subtitle: "", accessory: .chevron) {
                app.showCommandPalette()
            }
            MenuItemRow(systemName: "terminal", title: "Console", subtitle: "", accessory: .chevron) {
                app.showConsole()
            }
            MenuItemRow(systemName: "keyboard", title: "Cheatsheet", subtitle: "", accessory: .chevron) {
                app.showCheatsheet()
            }
            MenuItemRow(systemName: "power", iconTint: Theme.danger, title: "Quit", subtitle: "", accessory: .none) {
                NSApplication.shared.terminate(nil)
            }
        }
    }

    private var headerSubtitle: String {
        let count = app.sessions.count
        let sessionText = count == 1 ? "1 session" : "\(count) sessions"
        guard let date = app.resurrectLastSaved() else { return sessionText }
        return "\(sessionText) · saved \(timeString(date))"
    }

    private var restoreSubtitle: String {
        if backupWorking { return "Working..." }
        if !backupStatus.isEmpty { return backupStatus }
        guard app.resurrectAvailable else { return "tmux-resurrect not found" }
        guard let date = app.resurrectLastSaved() else { return "No saved layout" }
        return "Last saved \(timeString(date))"
    }

    private var lastSavedText: String {
        guard let date = app.resurrectLastSaved() else { return "Never" }
        return dateString(date)
    }

    private func sessionSubtitle(session: TmuxSession, window: TmuxWindow?, pane: TmuxPane?) -> String {
        let folder = pathLastComponent(pane?.path ?? session.path) ?? "~"
        guard let window else { return folder }
        let windowReadableName = app.windowReadableName(window, activePane: pane)
        let windowName = "\(window.index): \(windowReadableName)"
        guard let pane else { return "\(folder) · \(windowName)" }
        let paneName = app.paneReadableName(pane)
        if paneName == windowReadableName { return "\(folder) · \(windowName)" }
        return "\(folder) · \(windowName) · \(paneName)"
    }

    private func performBackupAction(success: String, op: @escaping () async -> String?) {
        backupWorking = true
        backupStatus = ""
        Task {
            let error = await op()
            backupWorking = false
            backupStatus = error ?? success
        }
    }

    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

private enum MenuAccessory {
    case none
    case chevron
    case progress
}

private struct IconButton: View {
    let systemName: String
    let help: String
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 26, height: 26)
                .background(hovering ? Theme.hoverFill : Color.clear, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .buttonStyle(.plain)
        .help(help)
        .onHover { hovering = $0 }
    }
}

private struct MenuSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(Theme.Font.sectionHeader)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .padding(.horizontal, 2)
            VStack(spacing: 2) {
                content
            }
            .padding(4)
            .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Theme.hairline, lineWidth: 1)
            }
        }
    }
}

private struct MenuItemRow: View {
    let systemName: String
    var iconTint: Color = .secondary
    let title: String
    let subtitle: String
    var accessory: MenuAccessory = .none
    var isEnabled = true
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            MenuRowContent(
                systemName: systemName,
                iconTint: iconTint,
                title: title,
                subtitle: subtitle,
                accessory: accessory
            )
            .opacity(isEnabled ? 1 : 0.42)
            .background(hovering && isEnabled ? Theme.hoverFill : Color.clear, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .onHover { hovering = $0 }
    }
}

private struct StaticMenuLine: View {
    let systemName: String
    var iconTint: Color = .secondary
    let title: String
    let subtitle: String

    var body: some View {
        MenuRowContent(
            systemName: systemName,
            iconTint: iconTint,
            title: title,
            subtitle: subtitle,
            accessory: .none
        )
        .opacity(0.78)
    }
}

private struct MenuRowContent: View {
    let systemName: String
    let iconTint: Color
    let title: String
    let subtitle: String
    let accessory: MenuAccessory

    var body: some View {
        HStack(alignment: .center, spacing: 9) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(iconTint)
                .frame(width: 18, height: 18)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(Theme.Font.rowTitle)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(Theme.Font.rowSubtitle)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            Spacer(minLength: 8)

            switch accessory {
            case .none:
                EmptyView()
            case .chevron:
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.tertiary)
            case .progress:
                ProgressView()
                    .controlSize(.small)
            }
        }
        .frame(maxWidth: .infinity, minHeight: subtitle.isEmpty ? 30 : 40, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}
