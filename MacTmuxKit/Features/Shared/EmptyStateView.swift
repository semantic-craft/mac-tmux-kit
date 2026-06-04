import SwiftUI

/// Composed empty state: SF Symbol + one plain line (+ optional subtitle).
struct EmptyStateView: View {
    let icon: String
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundStyle(.secondary)
            Text(title)
                .font(Theme.Font.body)
                .foregroundStyle(.secondary)
            if let subtitle {
                Text(subtitle)
                    .font(Theme.Font.rowSubtitle)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
}
