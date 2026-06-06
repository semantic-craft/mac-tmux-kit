import SwiftUI
import TmuxKitCore

/// Always-visible action bar for the selected pane: labeled buttons for the
/// common operations (no menu paging). Low-frequency actions (Mark, Clear
/// History) live in the pane's right-click menu. Disabled when no pane is
/// selected. Destructive hierarchy: "Kill Pane" is the primary red action;
/// "Kill Others" is rarer, shown lighter (red text, not a red fill).
struct PaneActionBar: View {
    @Environment(AppState.self) private var app
    let pane: TmuxPane?
    @Binding var prompt: TextPrompt?
    @Binding var confirm: ConfirmAction?

    private let columns = [GridItem(.adaptive(minimum: 112), spacing: 8)]

    var body: some View {
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
            // Secondary destructive: red text, plain border.
            Button { if let p = pane { askKillOthers(p) } } label: {
                Label("Kill Others", systemImage: "rectangle.on.rectangle.slash")
                    .lineLimit(1).frame(maxWidth: .infinity)
                    .foregroundStyle(Theme.danger)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            // Primary destructive: solid red (prominent), so it clearly outranks
            // the lighter red-text "Kill Others".
            Button { if let p = pane { askKillPane(p) } } label: {
                Label("Kill Pane", systemImage: "xmark.square")
                    .lineLimit(1).frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .tint(Theme.danger)
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
        tint: Color? = nil,
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
        .controlSize(.regular)
        .tint(tint)
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
        .controlSize(.regular)
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
