import SwiftUI
import AppKit
import TmuxKitCore

/// Column 3: detail for the selected pane — a header, a small floating action
/// bar, and the captured pane content in monospaced, selectable text.
struct PaneDetailColumn: View {
    @Environment(AppState.self) private var app
    let sessionId: String?
    let paneId: String?
    let reloadToken: UUID

    @State private var preview = PanePreview.empty
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
                .task(id: "\(pane.id)-\(reloadToken)") { await load(pane) }
            } else if sessionId != nil {
                EmptyStateView(
                    icon: "rectangle.split.3x1",
                    title: "No panes",
                    subtitle: "This session has no pane output to preview"
                )
            } else {
                EmptyStateView(icon: "terminal", title: "Select a pane")
            }
        }
    }

    private func header(_ pane: TmuxPane) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("PANE PREVIEW")
                    .font(Theme.Font.capsLabel)
                    .tracking(1)
                    .foregroundStyle(.tertiary)
                Spacer()
                HStack(spacing: 5) {
                    Circle().fill(Theme.accent).frame(width: 6, height: 6)
                    Text("live").font(Theme.Font.metricSmall).foregroundStyle(.tertiary)
                }
            }
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 7) {
                        Text("\(pane.index): \(app.paneReadableName(pane))")
                            .font(Theme.Font.detailTitle)
                        if pane.active {
                            Text("ACTIVE")
                                .font(Theme.Font.pill)
                                .tracking(0.4)
                                .foregroundStyle(Theme.accentInk)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(Theme.accentSoft, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                        }
                    }
                    Text(detailLine(pane))
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
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private var terminal: some View {
        Group {
            if preview.failed {
                EmptyStateView(
                    icon: "exclamationmark.triangle",
                    title: "Preview unavailable",
                    subtitle: preview.errorMessage
                )
                .background(Theme.terminalBackground)
            } else {
                ScrollView([.vertical, .horizontal]) {
                    Text(preview.content.isEmpty ? (loading ? "" : "(empty)") : preview.content)
                        .font(Theme.Font.terminal)
                        .foregroundStyle(preview.content.isEmpty ? Theme.terminalText.opacity(0.5) : Theme.terminalText)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(12)
                }
                .background(Theme.terminalBackground)
                .overlay {
                    // Quiet first-load indicator; reloads keep the old content visible.
                    if loading && preview.content.isEmpty {
                        ProgressView().controlSize(.small)
                    }
                }
            }
        }
    }

    private func detailLine(_ pane: TmuxPane) -> String {
        var parts: [String] = [pane.id, "\(pane.width)x\(pane.height)", "pid \(pane.pid)"]
        if !pane.command.isEmpty {
            parts.append(pane.command)
        }
        if !pane.path.isEmpty {
            parts.append(pane.path)
        }
        return parts.joined(separator: "  ·  ")
    }

    private func load(_ pane: TmuxPane) async {
        loading = true
        preview = await app.capturePreview(pane)
        loading = false
    }

    private func copy() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(preview.content, forType: .string)
    }
}
