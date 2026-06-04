import SwiftUI

/// A transient confirmation message (the optimistic-UI feedback from the macOS
/// design skill: act immediately, then confirm with a small auto-dismissing
/// toast). Emitted by `AppState` after a mutating action succeeds or fails.
struct ToastInfo: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let kind: Kind

    enum Kind {
        case success, failure

        var symbol: String {
            switch self {
            case .success: "checkmark.circle.fill"
            case .failure: "exclamationmark.triangle.fill"
            }
        }
        var tint: Color {
            switch self {
            case .success: .green
            case .failure: .orange
            }
        }
    }
}

/// A small, rounded toast pill: icon + short text on `.ultraThinMaterial`, with
/// a hairline edge and soft shadow. Sits over chrome, never over content.
struct ToastView: View {
    let info: ToastInfo

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: info.kind.symbol)
                .foregroundStyle(info.kind.tint)
            Text(info.text)
                .font(.system(size: 13))
                .lineLimit(1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(Color.primary.opacity(0.08)))
        .shadow(color: .black.opacity(0.18), radius: 12, y: 4)
        .padding(.bottom, 18)
    }
}
