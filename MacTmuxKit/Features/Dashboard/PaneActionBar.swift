import SwiftUI
import TmuxKitCore

/// Always-visible action bar for the selected pane: the five most common
/// operations as icon + label, one tap each. Lower-frequency actions (Swap,
/// Kill Others, Mark, Clear History) live in the pane's right-click menu.
/// Disabled when no pane is selected.
struct PaneActionBar: View {
    @Environment(AppState.self) private var app
    let pane: TmuxPane?
    @Binding var prompt: TextPrompt?
    @Binding var confirm: ConfirmAction?

    var body: some View {
        HStack(spacing: 2) {
            barButton("Split R", "rectangle.split.2x1") {
                if let p = pane { Task { await app.split(p, horizontal: true) } }
            }
            barButton("Split D", "rectangle.split.1x2") {
                if let p = pane { Task { await app.split(p, horizontal: false) } }
            }
            barButton("Break", "rectangle.portrait.and.arrow.right") {
                if let p = pane { Task { await app.breakPane(p) } }
            }
            barButton("Rename", "pencil") { renamePane() }
            barButton("Kill", "xmark", tint: Theme.danger) {
                if let p = pane { askKillPane(p) }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.bar)
        .disabled(pane == nil)
        .opacity(pane == nil ? 0.55 : 1)
    }

    // MARK: - Buttons

    private func barButton(_ title: String, _ symbol: String, tint: Color? = nil,
                           _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: symbol).font(.system(size: 15))
                Text(title).font(.system(size: 9.5))
            }
            .foregroundStyle(tint ?? .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .hoverHighlight(fill: tint == nil ? Theme.hoverFill : tint!.opacity(0.12))
    }

    // MARK: - Actions

    private func renamePane() {
        guard let p = pane else { return }
        prompt = TextPrompt(
            title: "Rename pane", placeholder: "Pane title",
            initial: app.paneCustomName(p), confirmLabel: "Rename"
        ) { title in Task { await app.renamePane(p, to: title) } }
    }

    private func askKillPane(_ p: TmuxPane) {
        confirm = ConfirmAction(
            title: "Kill pane \(p.id)?",
            message: "Running: \(p.command)",
            confirmLabel: "Kill"
        ) { Task { await app.killPane(p) } }
    }
}
