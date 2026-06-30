import SwiftUI

/// Shared session/pane status atoms used across the popover and the Dashboard
/// sidebar, so "attached" reads identically everywhere. Attached is the one loud
/// signal — a filled accent dot with a soft glow ring; everything else is a quiet
/// hollow ring.

/// Status dot: filled accent + glow when attached, hollow ring when not.
struct StatusDot: View {
    let attached: Bool
    var size: CGFloat = 8

    var body: some View {
        Circle()
            .fill(attached ? Theme.accent : Color.clear)
            .frame(width: size, height: size)
            .overlay {
                if !attached {
                    Circle().strokeBorder(Color.secondary.opacity(0.45), lineWidth: 1.5)
                }
            }
            .background {
                if attached {
                    Circle()
                        .fill(Theme.accent.opacity(0.22))
                        .frame(width: size + 6, height: size + 6)
                }
            }
            .accessibilityLabel(attached ? "Attached" : "Detached")
    }
}

/// Quiet hover fill for custom (non-List) rows and buttons — one consistent
/// press/hover affordance across the popover and palette.
private struct HoverHighlight: ViewModifier {
    var radius: CGFloat = 6
    var fill: Color = Theme.hoverFill
    @State private var hovering = false

    func body(content: Content) -> some View {
        content
            .background(hovering ? fill : Color.clear,
                        in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .onHover { hovering = $0 }
    }
}

extension View {
    func hoverHighlight(radius: CGFloat = 6, fill: Color = Theme.hoverFill) -> some View {
        modifier(HoverHighlight(radius: radius, fill: fill))
    }
}

/// Uppercase state pill: `ATTACHED` (accent) vs `detached` (quiet).
struct StatePill: View {
    let attached: Bool

    var body: some View {
        Text(attached ? "ATTACHED" : "detached")
            .font(Theme.Font.pill)
            .tracking(attached ? 0.4 : 0.2)
            .foregroundStyle(attached ? Theme.accentInk : Color.secondary)
            .padding(.horizontal, 5)
            .padding(.vertical, 1.5)
            .background(
                attached ? Theme.accentSoft : Color.primary.opacity(0.05),
                in: RoundedRectangle(cornerRadius: 4, style: .continuous)
            )
    }
}
