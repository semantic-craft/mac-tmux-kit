import SwiftUI
import AppKit
import TmuxKitCore

/// Menu-bar popover — the glanceable switcher. The attached session is the single
/// loud signal (blue bar + dot + ATTACHED pill); everything else stays quiet. The
/// list leads, restore/backup collapse into the header + overflow, and the four
/// states (sessions / empty / error / loading) are visually distinct.
struct MenuBarPopoverView: View {
    @Environment(AppState.self) private var app
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("resurrectRestoreProcesses") private var restoreProcesses = true
    @State private var confirmRestore = false

    private let visibleSessionLimit = 3

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
            Divider()
            footer
        }
        .frame(width: 390, alignment: .topLeading)
        .background(.thinMaterial)
        .task { await app.refresh() }
        .confirmationDialog("Restore last saved layout?", isPresented: $confirmRestore) {
            Button("Restore", role: .destructive) {
                Task { _ = await app.resurrectRestore() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(restoreProcesses
                 ? "This recreates the saved sessions, windows, panes, and saved commands."
                 : "This recreates the saved sessions, windows, and panes.")
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            appMark
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
                ProgressView().controlSize(.small).frame(width: 26, height: 26)
            } else {
                IconButton(systemName: "arrow.clockwise", help: "Refresh") {
                    Task { await app.refresh() }
                }
            }
            IconButton(systemName: "arrow.counterclockwise", help: "Restore layout") {
                confirmRestore = true
            }
            .disabled(!app.resurrectAvailable || app.resurrectLastSaved() == nil)
            IconButton(systemName: "gearshape", help: "Settings") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    private var appMark: some View {
        RoundedRectangle(cornerRadius: 7, style: .continuous)
            .fill(Theme.accent.opacity(0.22))
            .overlay {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .strokeBorder(Theme.accent.opacity(0.4), lineWidth: 0.5)
            }
            .overlay {
                Image(systemName: "terminal")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.accentInk)
            }
            .frame(width: 28, height: 28)
    }

    // MARK: - Content (state switch)

    @ViewBuilder
    private var content: some View {
        if app.isLoading && app.sessions.isEmpty {
            loadingState
        } else if app.sessions.isEmpty && app.lastRefreshFailed {
            errorState
        } else if app.sessions.isEmpty {
            emptyState
        } else {
            sessionList
        }
    }

    private var sessionList: some View {
        VStack(spacing: 0) {
            capsLabel("RECENT SESSIONS")
            ForEach(app.pinnedFirstSessions(limit: visibleSessionLimit)) { session in
                let window = app.activeWindow(in: session)
                PopoverSessionRow(
                    name: session.name,
                    attached: session.attached,
                    pinned: app.isPinned(session),
                    subtitle: popoverSubtitle(session, window),
                    counts: "\(session.windowCount)w · \(app.paneCount(in: session))p",
                    detach: session.attached ? { Task { await app.detachSession(session) } } : nil
                ) { Task { await app.activateFromMenuBar(session) } }
                .contextMenu {
                    Button {
                        app.togglePin(session)
                    } label: {
                        Label(app.isPinned(session) ? "Unpin" : "Pin",
                              systemImage: app.isPinned(session) ? "pin.slash" : "pin")
                    }
                    Button { promptRename(session) } label: {
                        Label("Rename…", systemImage: "pencil")
                    }
                    Divider()
                    Button(role: .destructive) { confirmKill(session) } label: {
                        Label("Kill Session", systemImage: "trash")
                    }
                }
            }
            Divider().padding(.horizontal, 14).padding(.vertical, 6)
            actionRow(icon: "plus", tinted: true, title: "New session") { promptNewSession() }
            actionRow(icon: "square.stack", tinted: false, title: "More sessions", chevron: true) {
                app.showDashboard()
            }
        }
        .padding(.bottom, 4)
    }

    // MARK: - Empty / error / loading

    private var emptyState: some View {
        stateCard(icon: "tray", iconTint: .secondary, iconBg: Color.primary.opacity(0.045),
                  title: "No tmux sessions",
                  subtitle: "Nothing is running on the tmux server yet. Start one in your terminal, or create it here.") {
            pillButton("New session", icon: "plus", prominent: true) { promptNewSession() }
        }
    }

    private var errorState: some View {
        stateCard(icon: "powerplug", iconTint: Theme.danger, iconBg: Theme.danger.opacity(0.12),
                  title: "Can't reach the tmux server",
                  subtitle: "The socket isn't responding. Make sure tmux is running, then try again.") {
            VStack(spacing: 10) {
                Text("tmux start-server")
                    .font(Theme.Font.metricSmall)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9).padding(.vertical, 3)
                    .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
                    .overlay { RoundedRectangle(cornerRadius: 5, style: .continuous).strokeBorder(Theme.hairline) }
                pillButton("Retry", icon: "arrow.clockwise", prominent: false) {
                    Task { await app.refresh() }
                }
            }
        }
    }

    private var loadingState: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                ProgressView().controlSize(.small)
                Text("Querying tmux server…").font(.system(size: 12)).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14).padding(.top, 10).padding(.bottom, 8)
            SkeletonRow()
            SkeletonRow()
        }
        .padding(.bottom, 6)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 4) {
            footerButton("Dashboard", "square.grid.2x2") { app.showDashboard() }
            footerButton("Palette", "magnifyingglass", kbd: "⌥Space") { app.showCommandPalette() }
            Spacer(minLength: 8)
            overflowMenu
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.primary.opacity(0.015))
    }

    private var overflowMenu: some View {
        Menu {
            Button { app.showConsole() } label: { Label("Console", systemImage: "terminal") }
            Button { app.showCheatsheet() } label: { Label("Cheatsheet", systemImage: "keyboard") }
            Button { Task { _ = await app.resurrectSave() } } label: {
                Label("Save layout", systemImage: "tray.and.arrow.down")
            }
            .disabled(!app.resurrectAvailable)
            Button { Task { await app.copyDebugSnapshot() } } label: {
                Label("Copy debug snapshot", systemImage: "doc.on.doc")
            }
            Divider()
            Button(role: .destructive) { NSApplication.shared.terminate(nil) } label: {
                Label("Quit", systemImage: "power")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 30, height: 26)
                .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("More")
    }

    // MARK: - Small builders

    private func capsLabel(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(Theme.Font.capsLabel)
                .tracking(1)
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 4)
    }

    private func actionRow(icon: String, tinted: Bool, title: String, chevron: Bool = false,
                           action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if tinted {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Theme.accent.opacity(0.2))
                        .overlay {
                            Image(systemName: icon)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Theme.accentInk)
                        }
                        .frame(width: 22, height: 22)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                        .frame(width: 22, height: 22)
                }
                Text(title)
                    .font(.system(size: 13, weight: tinted ? .medium : .regular))
                    .foregroundStyle(tinted ? .primary : .secondary)
                Spacer(minLength: 8)
                if chevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .hoverHighlight(radius: 0)
    }

    private func footerButton(_ title: String, _ symbol: String, kbd: String? = nil,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: symbol).font(.system(size: 13)).foregroundStyle(.secondary)
                Text(title).font(.system(size: 11.5)).foregroundStyle(.secondary)
                if let kbd {
                    Text(kbd)
                        .font(.system(size: 9.5, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 4).padding(.vertical, 1)
                        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                        .overlay { RoundedRectangle(cornerRadius: 4, style: .continuous).strokeBorder(Theme.hairline) }
                }
            }
            .padding(.horizontal, 8).padding(.vertical, 5)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .hoverHighlight()
    }

    private func pillButton(_ title: String, icon: String, prominent: Bool,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 11, weight: prominent ? .semibold : .regular))
                Text(title).font(.system(size: 12, weight: prominent ? .semibold : .medium))
            }
            .foregroundStyle(prominent ? Theme.accentInk : .primary)
            .padding(.horizontal, 13).padding(.vertical, 6)
            .background(prominent ? Theme.accentSoft : Color.primary.opacity(0.04),
                        in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .strokeBorder(prominent ? Theme.accent.opacity(0.5) : Theme.hairline)
            }
        }
        .buttonStyle(.plain)
    }

    private func stateCard<Extra: View>(icon: String, iconTint: Color, iconBg: Color,
                                        title: String, subtitle: String,
                                        @ViewBuilder extra: () -> Extra) -> some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(iconBg)
                .overlay { Image(systemName: icon).font(.system(size: 21)).foregroundStyle(iconTint) }
                .frame(width: 46, height: 46)
                .padding(.bottom, 6)
            Text(title).font(.system(size: 13, weight: .semibold)).foregroundStyle(.primary)
            Text(subtitle)
                .font(.system(size: 11.5))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 240)
                .fixedSize(horizontal: false, vertical: true)
            extra().padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.vertical, 28)
    }

    // MARK: - Strings / actions

    private var headerSubtitle: String {
        let count = app.sessions.count
        let sessionText = count == 1 ? "1 session" : "\(count) sessions"
        guard let date = app.resurrectLastSaved() else { return sessionText }
        return "\(sessionText) · saved \(timeString(date))"
    }

    private func popoverSubtitle(_ session: TmuxSession, _ window: TmuxWindow?) -> String {
        let folder = pathLastComponent(app.sessionDisplayPath(session)) ?? "~"
        guard let window else { return folder }
        let name = app.windowReadableName(window, activePane: app.activePane(in: window))
        return "\(folder) · \(window.index): \(name)"
    }

    /// Native name prompt — robust from a transient popover (a SwiftUI sheet would be
    /// dismissed with the popover when focus leaves).
    private func promptNewSession() {
        let alert = NSAlert()
        alert.messageText = "New session"
        alert.informativeText = "Name the new tmux session."
        alert.addButton(withTitle: "Create")
        alert.addButton(withTitle: "Cancel")
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 220, height: 24))
        field.placeholderString = "Name"
        alert.accessoryView = field
        alert.window.initialFirstResponder = field
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        let name = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        Task { await app.newSession(name: name, startDir: nil) }
    }

    /// Native rename prompt, pre-filled with the current name (same transient-popover
    /// robustness as `promptNewSession`).
    private func promptRename(_ session: TmuxSession) {
        let alert = NSAlert()
        alert.messageText = "Rename session"
        alert.informativeText = "Enter a new name for “\(session.name)”."
        alert.addButton(withTitle: "Rename")
        alert.addButton(withTitle: "Cancel")
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 220, height: 24))
        field.stringValue = session.name
        alert.accessoryView = field
        alert.window.initialFirstResponder = field
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        let name = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name != session.name else { return }
        Task { await app.renameSession(session, to: name) }
    }

    /// Native confirm before killing — destructive and irreversible.
    private func confirmKill(_ session: TmuxSession) {
        let alert = NSAlert()
        alert.messageText = "Kill session “\(session.name)”?"
        alert.informativeText = "This ends the session and every process running in it. This can't be undone."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Kill")
        alert.addButton(withTitle: "Cancel")
        alert.buttons.first?.hasDestructiveAction = true
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        Task { await app.killSession(session) }
    }

    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Rows

/// One session row: blue left-bar + filled dot + ATTACHED pill when attached;
/// hollow dot + quiet text when detached. Mono subtitle + right-rail counts.
private struct PopoverSessionRow: View {
    let name: String
    let attached: Bool
    var pinned: Bool = false
    let subtitle: String
    let counts: String
    /// Non-nil only for attached sessions; surfaced as a hover-revealed Detach pill.
    var detach: (() -> Void)? = nil
    let action: () -> Void

    @State private var hovering = false

    private var showDetach: Bool { hovering && detach != nil }

    var body: some View {
        // Detach is a sibling overlay, not nested in the row Button — so its hit
        // area intercepts the click cleanly and the row's attach action never fires.
        ZStack(alignment: .trailing) {
            Button(action: action) {
                HStack(alignment: .top, spacing: 10) {
                    StatusDot(attached: attached).padding(.top, 3)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 7) {
                            Text(name)
                                .font(.system(size: 13, weight: attached ? .semibold : .medium))
                                .foregroundStyle(attached ? .primary : .secondary)
                                .lineLimit(1)
                            StatePill(attached: attached)
                            if pinned {
                                Image(systemName: "pin.fill")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.tertiary)
                                    .help("Pinned")
                            }
                        }
                        Text(subtitle)
                            .font(Theme.Font.metric)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    Spacer(minLength: 8)
                    Text(counts)
                        .font(Theme.Font.metric)
                        .foregroundStyle(.secondary)
                        .padding(.top, 1)
                        .opacity(showDetach ? 0 : 1)  // keep width to avoid reflow
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(background)
                .overlay(alignment: .leading) {
                    if attached {
                        UnevenRoundedRectangle(bottomTrailingRadius: 3, topTrailingRadius: 3)
                            .fill(Theme.accent)
                            .frame(width: 3)
                            .padding(.vertical, 7)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showDetach, let detach {
                DetachRowButton(action: detach).padding(.trailing, 14)
            }
        }
        .onHover { hovering = $0 }
    }

    private var background: Color {
        if attached { return hovering ? Theme.accent.opacity(0.15) : Theme.accentFaint }
        return hovering ? Theme.hoverFill : .clear
    }
}

/// Trailing Detach pill, revealed on row hover for attached sessions. Detach is
/// non-destructive (the session keeps running), so it stays neutral — never danger.
private struct DetachRowButton: View {
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "eject").font(.system(size: 10, weight: .semibold))
                Text("Detach").font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(hovering ? Theme.hoverFill : Color.primary.opacity(0.04),
                        in: RoundedRectangle(cornerRadius: Theme.Radius.row, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Radius.row, style: .continuous)
                    .strokeBorder(Theme.hairline)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .help("Detach clients from this session")
    }
}

/// Pulsing skeleton placeholder for the first load.
private struct SkeletonRow: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 10) {
            Circle().fill(bar).frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 5) {
                RoundedRectangle(cornerRadius: 3).fill(bar).frame(width: 120, height: 9)
                RoundedRectangle(cornerRadius: 3).fill(barFaint).frame(width: 180, height: 7)
            }
            Spacer(minLength: 8)
            RoundedRectangle(cornerRadius: 3).fill(barFaint).frame(width: 36, height: 9)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .opacity(reduceMotion ? 0.85 : (pulse ? 0.85 : 0.4))
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { pulse = true }
        }
    }

    private var bar: Color { Color.primary.opacity(0.09) }
    private var barFaint: Color { Color.primary.opacity(0.06) }
}

// MARK: - Icon button

private struct IconButton: View {
    let systemName: String
    let help: String
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .frame(width: 26, height: 26)
                .background(hovering ? Theme.hoverFill : Color.clear,
                            in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .buttonStyle(.plain)
        .help(help)
        .onHover { hovering = $0 }
    }
}
