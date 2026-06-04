import SwiftUI

/// Inline rename text field for the Dashboard rows. Autofocuses on appear;
/// Return commits the trimmed value, Esc or losing focus cancels. The owning
/// row holds the draft text and the edit flag, so this view stays stateless
/// apart from focus.
struct RenameField: View {
    @Binding var text: String
    var prompt: String = "Name"
    var font: Font = Theme.Font.body
    let onCommit: () -> Void
    let onCancel: () -> Void

    @FocusState private var focused: Bool

    var body: some View {
        TextField(prompt, text: $text)
            .textFieldStyle(.plain)
            .font(font)
            .focused($focused)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: Theme.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .strokeBorder(Theme.accent.opacity(0.65))
            )
            .onAppear { focused = true }
            .onSubmit(onCommit)
            .onExitCommand(perform: onCancel)
            .onChange(of: focused) { _, isFocused in
                if !isFocused { onCancel() }
            }
    }
}

/// Always-visible pencil button that starts an inline rename. Sized to sit
/// quietly in a row's trailing area next to the count/dimension label.
struct RenamePencil: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "pencil")
                .imageScale(.small)
        }
        .buttonStyle(.borderless)
        .foregroundStyle(.secondary)
        .help("Rename")
    }
}
