import SwiftUI
import TmuxKitCore

/// One palette result.
struct CommandPaletteItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let attached: Bool
    let run: () async -> Void
}

/// Spotlight-style command palette: type to filter sessions, arrow keys to move,
/// Return to switch + focus, Esc to dismiss.
struct CommandPaletteView: View {
    @Environment(AppState.self) private var app
    let dismiss: () -> Void

    @State private var query = ""
    @State private var selection = 0
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            field
            Divider()
            list
        }
        .frame(width: 560, height: 380)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.primary.opacity(0.08))
        )
        .task { focused = true; await app.refresh() }
        .onChange(of: query) { _, _ in selection = 0 }
        .onKeyPress(.downArrow) { move(1) }
        .onKeyPress(.upArrow) { move(-1) }
        .onKeyPress(.escape) { dismiss(); return .handled }
    }

    // MARK: - Subviews

    private var field: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
            TextField("Switch session, or > to run a tmux command…", text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 16))
                .focused($focused)
                .onSubmit { runSelected() }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var list: some View {
        let entries = items
        return ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, item in
                        row(item, selected: index == selection)
                            .id(index)
                            .contentShape(Rectangle())
                            .onTapGesture { run(item) }
                    }
                    if entries.isEmpty {
                        Text("No matches")
                            .font(.system(size: 13))
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

    private func row(_ item: CommandPaletteItem, selected: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: item.icon)
                .font(.system(size: 9))
                .foregroundStyle(item.attached ? Color.green : (selected ? .white : .secondary))
                .frame(width: 14)
            Text(item.title)
                .font(.system(size: 14))
                .foregroundStyle(selected ? .white : .primary)
            Spacer(minLength: 8)
            if !item.subtitle.isEmpty {
                Text(item.subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(selected ? Color.white.opacity(0.85) : .secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(selected ? Color.accentColor : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 7))
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
                    attached: s.attached
                ) { await app.switchTo(s) }
            }

        // Offer to create a session when the query is a fresh, valid name.
        if isValidSessionName(raw),
           !app.sessions.contains(where: { $0.name.caseInsensitiveCompare(raw) == .orderedSame }) {
            result.append(CommandPaletteItem(
                id: "create", title: "Create session \"\(raw)\"", subtitle: "new",
                icon: "plus.circle", attached: false
            ) { await app.newSession(name: raw, startDir: nil) })
        }

        // Static actions, filtered by the query.
        let actions = [
            CommandPaletteItem(id: "act:save", title: "Save layout", subtitle: "tmux-resurrect",
                               icon: "tray.and.arrow.down", attached: false) { _ = await app.resurrectSave() },
            CommandPaletteItem(id: "act:refresh", title: "Refresh", subtitle: "",
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
        dismiss()
        Task { await item.run() }
    }
}
