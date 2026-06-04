import SwiftUI
import AppKit
import TmuxKitCore

/// Column 3: detail for the selected pane — a header, a small floating action
/// bar, and the captured pane content in monospaced, selectable text.
struct PaneDetailColumn: View {
    @Environment(AppState.self) private var app
    let paneId: String?

    @State private var content: String = ""
    @State private var loading = false

    private var pane: TmuxPane? { app.pane(id: paneId) }

    var body: some View {
        Group {
            if let pane {
                VStack(spacing: 0) {
                    header(pane)
                    Divider()
                    terminal
                }
                .task(id: pane.id) { await load(pane) }
            } else {
                EmptyStateView(icon: "terminal", title: "Select a pane")
            }
        }
    }

    private func header(_ pane: TmuxPane) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(pane.command)
                    .font(Theme.Font.detailTitle)
                Text("\(pane.id)  ·  \(pane.width)x\(pane.height)  ·  pid \(pane.pid)")
                    .font(Theme.Font.metric)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 6) {
                Button { copy() } label: { Image(systemName: "doc.on.doc") }
                    .help("Copy content")
                Button { Task { await load(pane) } } label: { Image(systemName: "arrow.clockwise") }
                    .help("Reload")
            }
            .buttonStyle(.borderless)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Theme.Radius.card))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private var terminal: some View {
        ScrollView([.vertical, .horizontal]) {
            Text(content.isEmpty ? (loading ? "Loading…" : "(empty)") : content)
                .font(Theme.Font.terminal)
                .foregroundStyle(content.isEmpty ? Theme.terminalText.opacity(0.5) : Theme.terminalText)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(12)
        }
        .background(Theme.terminalBackground)
    }

    private func load(_ pane: TmuxPane) async {
        loading = true
        content = await app.capture(pane)
        loading = false
    }

    private func copy() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(content, forType: .string)
    }
}
