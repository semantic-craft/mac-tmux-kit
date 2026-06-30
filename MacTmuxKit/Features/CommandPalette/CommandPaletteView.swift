import SwiftUI
import TmuxKitCore

/// Which group a palette row belongs to — drives the SESSIONS / ACTIONS headers.
enum PaletteGroup { case session, action }

/// One palette result.
struct CommandPaletteItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let attached: Bool
    var group: PaletteGroup = .action
    let run: () async -> Void
}

/// Spotlight-style command palette: type to filter sessions, arrow keys to move,
/// Return to switch + focus, Esc to dismiss.
struct CommandPaletteView: View {
    @Environment(AppState.self) private var app
    @AppStorage("resurrectRestoreProcesses") private var restoreProcesses = true
    let dismiss: () -> Void

    @State private var query = ""
    @State private var selection = 0
    @State private var confirmRestore = false
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            field
            Divider()
            list
            Divider()
            footerHints
        }
        .frame(width: 560, height: 400)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.panel))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.panel)
                .strokeBorder(Theme.hairline)
        )
        .task { focused = true; await app.refresh() }
        .onChange(of: query) { _, _ in selection = 0 }
        .onKeyPress(.downArrow) { move(1) }
        .onKeyPress(.upArrow) { move(-1) }
        .onKeyPress(.escape) { dismiss(); return .handled }
        .confirmationDialog("Restore last saved layout?", isPresented: $confirmRestore) {
            Button("Restore", role: .destructive) {
                dismiss()
                Task { _ = await app.resurrectRestore() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(restoreProcesses ? "This recreates the saved sessions, windows, panes, and saved commands." : "This recreates the saved sessions, windows, and panes.")
        }
    }

    // MARK: - Field

    private var field: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18))
                .foregroundStyle(.secondary)
            TextField("Switch session, or > to run a tmux command…", text: $query)
                .textFieldStyle(.plain)
                .font(Theme.Font.paletteField)
                .focused($focused)
                .onSubmit { runSelected() }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
    }

    // MARK: - List

    private var list: some View {
        let entries = items
        return ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, item in
                        VStack(alignment: .leading, spacing: 2) {
                            if index == 0 || entries[index - 1].group != item.group {
                                groupHeader(item.group)
                            }
                            row(item, selected: index == selection)
                                .id(index)
                                .contentShape(Rectangle())
                                .onTapGesture { run(item) }
                        }
                    }
                    if entries.isEmpty {
                        Text("No matches")
                            .font(Theme.Font.body)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                    }
                }
                .padding(8)
            }
            .onChange(of: selection) { _, new in
                proxy.scrollTo(new, anchor: .center)
            }
        }
    }

    private func groupHeader(_ group: PaletteGroup) -> some View {
        Text(group == .session ? "SESSIONS" : "ACTIONS")
            .font(Theme.Font.capsLabel)
            .tracking(1)
            .foregroundStyle(.tertiary)
            .padding(.horizontal, 10)
            .padding(.top, 6)
            .padding(.bottom, 2)
    }

    private func row(_ item: CommandPaletteItem, selected: Bool) -> some View {
        HStack(spacing: 11) {
            if item.group == .session {
                StatusDot(attached: item.attached)
                HStack(spacing: 8) {
                    Text(item.title)
                        .font(.system(size: 13.5, weight: item.attached ? .semibold : .medium))
                        .foregroundStyle(.primary)
                    if !item.subtitle.isEmpty {
                        Text(item.subtitle)
                            .font(Theme.Font.metric)
                            .foregroundStyle(item.attached ? Theme.accentInk : .secondary)
                    }
                }
                Spacer(minLength: 8)
                if selected {
                    HStack(spacing: 6) {
                        Text("switch & focus").font(.system(size: 11)).foregroundStyle(.secondary)
                        keyCap("↵")
                    }
                }
            } else {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.primary.opacity(0.05))
                    .overlay { Image(systemName: item.icon).font(.system(size: 13)).foregroundStyle(.secondary) }
                    .frame(width: 22, height: 22)
                Text(item.title).font(.system(size: 13)).foregroundStyle(.primary)
                Spacer(minLength: 8)
                if !item.subtitle.isEmpty {
                    Text(item.subtitle).font(Theme.Font.metricSmall).foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(selected ? Theme.accentSoft : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.row, style: .continuous))
    }

    // MARK: - Footer

    private var footerHints: some View {
        HStack(spacing: 14) {
            hint("↵", "switch & focus")
            hint("↑↓", "move")
            hint("›", "tmux command")
            Spacer(minLength: 8)
            hint("esc", "close")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(Color.primary.opacity(0.02))
    }

    private func hint(_ key: String, _ text: String) -> some View {
        HStack(spacing: 5) {
            keyCap(key)
            Text(text).font(.system(size: 10.5)).foregroundStyle(.secondary)
        }
    }

    private func keyCap(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, design: .monospaced))
            .foregroundStyle(.secondary)
            .frame(minWidth: 16, minHeight: 16)
            .padding(.horizontal, 4)
            .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 4, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: 4, style: .continuous).strokeBorder(Theme.hairline) }
    }

    // MARK: - Items

    private var items: [CommandPaletteItem] {
        let raw = query.trimmingCharacters(in: .whitespaces)

        // Command mode: ">" or ":" runs a raw tmux command.
        if let prefix = [">", ":"].first(where: { raw.hasPrefix($0) }) {
            let cmd = String(raw.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
            guard !cmd.isEmpty else {
                return [hint("Type a tmux command after \(prefix)", "terminal")]
            }
            return [CommandPaletteItem(
                id: "run", title: "Run: \(cmd)", subtitle: "tmux command",
                icon: "terminal", attached: false
            ) { _ = await app.runRaw(cmd) }]
        }

        let lower = raw.lowercased()
        var result = app.sessions
            .filter { lower.isEmpty || $0.name.lowercased().contains(lower) }
            .map { s in
                CommandPaletteItem(
                    id: "session:\(s.id)",
                    title: s.name,
                    subtitle: s.attached ? "attached · \(s.windowCount)w" : "\(s.windowCount)w",
                    icon: s.attached ? "circle.fill" : "circle",
                    attached: s.attached,
                    group: .session
                ) { await app.switchTo(s) }
            }

        // Offer to create a session when the query is a fresh, valid name.
        if isValidSessionName(raw),
           !app.sessions.contains(where: { $0.name.caseInsensitiveCompare(raw) == .orderedSame }) {
            result.append(CommandPaletteItem(
                id: "create", title: "Create session \"\(raw)\"", subtitle: "new session",
                icon: "plus", attached: false, group: .session
            ) { await app.newSession(name: raw, startDir: nil) })
        }

        // Static actions, filtered by the query.
        let actions = [
            CommandPaletteItem(id: "act:save", title: "Save layout", subtitle: "snapshot all panes",
                               icon: "tray.and.arrow.down", attached: false) { _ = await app.resurrectSave() },
            CommandPaletteItem(id: "act:restore", title: "Restore layout", subtitle: "tmux-resurrect",
                               icon: "arrow.counterclockwise", attached: false) { _ = await app.resurrectRestore() },
            CommandPaletteItem(id: "act:refresh", title: "Refresh", subtitle: "re-query server",
                               icon: "arrow.clockwise", attached: false) { await app.refresh() },
        ]
        result += actions.filter { lower.isEmpty || $0.title.lowercased().contains(lower) }
        return result
    }

    private func hint(_ text: String, _ icon: String) -> CommandPaletteItem {
        CommandPaletteItem(id: "hint", title: text, subtitle: "", icon: icon, attached: false) {}
    }

    private func isValidSessionName(_ name: String) -> Bool {
        !name.isEmpty && name.range(of: "[^A-Za-z0-9_-]", options: .regularExpression) == nil
    }

    // MARK: - Key handling

    private func move(_ delta: Int) -> KeyPress.Result {
        let count = items.count
        guard count > 0 else { return .handled }
        selection = (selection + delta + count) % count
        return .handled
    }

    private func runSelected() {
        let entries = items
        guard entries.indices.contains(selection) else { return }
        run(entries[selection])
    }

    private func run(_ item: CommandPaletteItem) {
        if item.id == "act:restore" {
            confirmRestore = true
            return
        }
        dismiss()
        Task { await item.run() }
    }
}
