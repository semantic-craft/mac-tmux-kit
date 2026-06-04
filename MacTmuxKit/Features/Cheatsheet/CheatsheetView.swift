import SwiftUI
import AppKit

/// Searchable tmux cheatsheet, grouped by section. Click a row to copy its key
/// sequence / command.
struct CheatsheetView: View {
    @State private var query = ""

    private var filtered: [CheatItem] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return Cheatsheet.items }
        return Cheatsheet.items.filter {
            $0.title.lowercased().contains(q)
                || $0.keys.lowercased().contains(q)
                || $0.section.lowercased().contains(q)
                || $0.note.lowercased().contains(q)
        }
    }

    var body: some View {
        List {
            ForEach(Cheatsheet.sections, id: \.self) { section in
                let rows = filtered.filter { $0.section == section }
                if !rows.isEmpty {
                    Section(section) {
                        ForEach(rows) { item in
                            CheatRow(item: item)
                        }
                    }
                }
            }
        }
        .listStyle(.inset)
        .searchable(text: $query, placement: .toolbar, prompt: "Filter shortcuts")
        .frame(minWidth: 460, minHeight: 480)
        .navigationTitle("tmux Cheatsheet")
        .onAppear { AppActivationPolicy.enter() }
        .onDisappear { AppActivationPolicy.leave() }
    }
}

private struct CheatRow: View {
    let item: CheatItem
    @State private var copied = false

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title).font(.system(size: 13))
                if !item.note.isEmpty {
                    Text(item.note).font(.system(size: 11)).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 12)
            Text(copied ? "Copied" : item.keys)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(copied ? .green : .secondary)
                .textSelection(.enabled)
        }
        .contentShape(Rectangle())
        .onTapGesture { copy() }
        .help("Click to copy: \(item.keys)")
    }

    private func copy() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(item.keys, forType: .string)
        copied = true
        Task {
            try? await Task.sleep(nanoseconds: 900_000_000)
            copied = false
        }
    }
}
