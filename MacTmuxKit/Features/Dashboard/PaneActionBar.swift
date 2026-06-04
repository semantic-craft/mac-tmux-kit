import SwiftUI
import TmuxKitCore

/// Always-visible action bar for the selected pane. Covers the common Raycast
/// operations as one-click buttons (no menu paging). Disabled when nothing is
/// selected.
struct PaneActionBar: View {
    @Environment(AppState.self) private var app
    let pane: TmuxPane?
    @Binding var prompt: TextPrompt?
    @Binding var confirm: ConfirmAction?

    var body: some View {
        HStack(spacing: 6) {
            iconButton("Split right", "rectangle.righthalf.inset.filled") {
                if let p = pane { await app.split(p, horizontal: true) }
            }
            iconButton("Split down", "rectangle.bottomhalf.inset.filled") {
                if let p = pane { await app.split(p, horizontal: false) }
            }

            swapMenu

            Divider().frame(height: 16)

            iconButton("Break to window", "rectangle.badge.plus") {
                if let p = pane { await app.breakPane(p) }
            }
            iconButton("Mark pane", "pin") {
                if let p = pane { await app.markPane(p) }
            }
            iconButton("Clear history", "eraser") {
                if let p = pane {
                    confirm = ConfirmAction(
                        title: "Clear history for \(p.id)?",
                        message: "Removes this pane's scrollback.",
                        confirmLabel: "Clear", isDestructive: false
                    ) { Task { await app.clearHistory(p) } }
                }
            }

            Spacer()

            iconButton("Kill other panes", "rectangle.on.rectangle.slash", destructive: true) {
                if let p = pane {
                    confirm = ConfirmAction(
                        title: "Kill other panes?",
                        message: "Keeps only \(p.id) in its window.",
                        confirmLabel: "Kill Others"
                    ) { Task { await app.killOtherPanes(p) } }
                }
            }
            iconButton("Kill pane", "xmark.square", destructive: true) {
                if let p = pane {
                    confirm = ConfirmAction(
                        title: "Kill pane \(p.id)?",
                        message: "Running: \(p.command)",
                        confirmLabel: "Kill"
                    ) { Task { await app.killPane(p) } }
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .disabled(pane == nil)
        .opacity(pane == nil ? 0.5 : 1)
    }

    private var swapMenu: some View {
        Menu {
            Button("Swap Left") { swap(.left) }
            Button("Swap Right") { swap(.right) }
            Button("Swap Up") { swap(.up) }
            Button("Swap Down") { swap(.down) }
        } label: {
            Image(systemName: "arrow.left.arrow.right")
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .help("Swap with neighbor")
    }

    private func swap(_ direction: PaneDirection) {
        guard let p = pane else { return }
        Task { await app.swap(p, direction) }
    }

    private func iconButton(
        _ help: String,
        _ symbol: String,
        destructive: Bool = false,
        _ action: @escaping () async -> Void
    ) -> some View {
        Button {
            Task { await action() }
        } label: {
            Image(systemName: symbol)
                .foregroundStyle(destructive ? Color.red : Color.primary)
        }
        .buttonStyle(.borderless)
        .help(help)
    }
}
