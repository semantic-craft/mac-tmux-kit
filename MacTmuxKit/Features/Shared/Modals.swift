import SwiftUI

// MARK: - Text prompt (new / rename)

/// A one-field text prompt, presented as a sheet via `.sheet(item:)`.
struct TextPrompt: Identifiable {
    let id = UUID()
    let title: String
    let placeholder: String
    var initial: String = ""
    let confirmLabel: String
    let onConfirm: (String) -> Void
}

struct TextPromptSheet: View {
    let prompt: TextPrompt
    @Environment(\.dismiss) private var dismiss
    @State private var text: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(prompt.title).font(Theme.Font.bodyEmphasis)
            TextField(prompt.placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
                .frame(width: 300)
                .onSubmit(confirm)
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(prompt.confirmLabel, action: confirm)
                    .keyboardShortcut(.defaultAction)
                    .disabled(trimmed.isEmpty)
            }
        }
        .padding(16)
        .onAppear { text = prompt.initial }
    }

    private var trimmed: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }

    private func confirm() {
        guard !trimmed.isEmpty else { return }
        prompt.onConfirm(trimmed)
        dismiss()
    }
}

// MARK: - Destructive confirmation

struct ConfirmAction: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let confirmLabel: String
    var isDestructive: Bool = true
    let onConfirm: () -> Void
}

extension View {
    /// Present a destructive confirmation alert bound to an optional action.
    func confirm(_ action: Binding<ConfirmAction?>) -> some View {
        alert(
            action.wrappedValue?.title ?? "",
            isPresented: Binding(
                get: { action.wrappedValue != nil },
                set: { if !$0 { action.wrappedValue = nil } }
            ),
            presenting: action.wrappedValue
        ) { item in
            Button(item.confirmLabel, role: item.isDestructive ? .destructive : nil) {
                item.onConfirm()
            }
            Button("Cancel", role: .cancel) {}
        } message: { item in
            Text(item.message)
        }
    }
}
