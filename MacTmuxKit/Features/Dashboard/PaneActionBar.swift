import SwiftUI
import TmuxKitCore

/// Always-visible action bar for the selected pane: labeled, comfortably sized
/// buttons for the common operations (no menu paging). Low-frequency actions
/// (Mark, Clear History) live in the pane's right-click menu. Disabled when no
/// pane is selected.
struct PaneActionBar: View {
    @Environment(AppState.self) private var app
    let pane: TmuxPane?
    @Binding var prompt: TextPrompt?
    @Binding var confirm: ConfirmAction?

    private let columns = [GridItem(.adaptive(minimum: 116), spacing: 8)]

    var body: some View {
        VStack(spacing: 0) {
            if let pane {
                Text("Pane \(pane.id) · \(pane.command)")
                    .font(Theme.Font.metric)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 8)
            }
            LazyVGrid(columns: columns, spacing: 8) {
                button("Split Right", "rectangle.righthalf.inset.filled") {
                    if let p = pane { await app.split(p, horizontal: true) }
                }
                button("Split Down", "rectangle.bottomhalf.inset.filled") {
                    if let p = pane { await app.split(p, horizontal: false) }
                }
                swapMenu
                button("Break Out", "rectangle.badge.plus") {
                    if let p = pane { await app.breakPane(p) }
                }
                button("Kill Others", "rectangle.on.rectangle.slash", destructive: true) {
                    if let p = pane { askKillOthers(p) }
                }
                button("Kill Pane", "xmark.square", destructive: true) {
                    if let p = pane { askKillPane(p) }
                }
            }
        }
        .padding(12)
        .background(.bar)
        .disabled(pane == nil)
        .opacity(pane == nil ? 0.55 : 1)
    }

    // MARK: - Buttons

    private func button(
        _ title: String,
        _ symbol: String,
        destructive: Bool = false,
        _ action: @escaping () async -> Void
    ) -> some View {
        Button {
            Task { await action() }
        } label: {
            Label(title, systemImage: symbol)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .tint(destructive ? Theme.danger : nil)
    }

    private var swapMenu: some View {
        Menu {
            Button("Swap Left") { swap(.left) }
            Button("Swap Right") { swap(.right) }
            Button("Swap Up") { swap(.up) }
            Button("Swap Down") { swap(.down) }
        } label: {
            Label("Swap", systemImage: "arrow.left.arrow.right")
                .lineLimit(1)
                .frame(maxWidth: .infinity)
        }
        .menuStyle(.button)
        .buttonStyle(.bordered)
        .controlSize(.large)
    }

    // MARK: - Actions

    private func swap(_ direction: PaneDirection) {
        guard let p = pane else { return }
        Task { await app.swap(p, direction) }
    }

    private func askKillPane(_ p: TmuxPane) {
        confirm = ConfirmAction(
            title: "Kill pane \(p.id)?",
            message: "Running: \(p.command)",
            confirmLabel: "Kill"
        ) { Task { await app.killPane(p) } }
    }

    private func askKillOthers(_ p: TmuxPane) {
        confirm = ConfirmAction(
            title: "Kill other panes?",
            message: "Keeps only \(p.id) in its window.",
            confirmLabel: "Kill Others"
        ) { Task { await app.killOtherPanes(p) } }
    }
}
