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
    @State private var showSwap = false

    // Two equal columns (not .adaptive — that doesn't guarantee equal widths,
    // and a content-sized cell lets the Swap Menu shrink below the others).
    private let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            button("Split Right", "rectangle.righthalf.inset.filled") {
                if let p = pane { await app.split(p, horizontal: true) }
            }
            button("Split Down", "rectangle.bottomhalf.inset.filled") {
                if let p = pane { await app.split(p, horizontal: false) }
            }
            // Plain Button (not a Menu — Menu won't stretch to fill the cell);
            // the four directions open in a confirmationDialog on click.
            Button { showSwap = true } label: {
                Label("Swap", systemImage: "arrow.left.arrow.right")
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            button("Break Out", "rectangle.badge.plus") {
                if let p = pane { await app.breakPane(p) }
            }
            // Destructive: both kills lightly red-tinted (a solid red FILL needs
            // .borderedProminent, which sizes differently — so we tint instead,
            // keeping all six buttons one uniform .bordered size).
            button("Kill Others", "rectangle.on.rectangle.slash", tint: Theme.danger) {
                if let p = pane { askKillOthers(p) }
            }
            button("Kill Pane", "xmark.square", tint: Theme.danger) {
                if let p = pane { askKillPane(p) }
            }
        }
        .padding(12)
        .background(.bar)
        .disabled(pane == nil)
        .opacity(pane == nil ? 0.55 : 1)
        .confirmationDialog("Swap pane with neighbor", isPresented: $showSwap, titleVisibility: .visible) {
            Button("Swap Left") { swap(.left) }
            Button("Swap Right") { swap(.right) }
            Button("Swap Up") { swap(.up) }
            Button("Swap Down") { swap(.down) }
        }
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
