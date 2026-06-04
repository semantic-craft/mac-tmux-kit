import SwiftUI

/// Design tokens for Tmux Kit — one source of truth for color, type, and metrics.
///
/// Borrowed language (researched from the Open Design system library):
/// - **Linear**: structural restraint — a single brand accent, hairline borders
///   drawn in white-opacity, hierarchy carried by luminance not hue.
/// - **Your terminal**: the captured-pane view mirrors the user's actual Ghostty
///   theme (currently Flexoki Light — paper #fffcf0 / ink #100f0f), so the in-app
///   preview looks identical to the real terminal.
/// - **Vercel / Geist**: a monospaced "developer console" voice for every
///   technical label (counts, dimensions, ids, pids).
///
/// Native-first: text tiers and chrome stay on macOS semantic colors and system
/// materials, so light/dark mode and the vibrancy sidebar keep working. Only the
/// brand accent and the mono label voice are opinionated.
enum Theme {

    // MARK: - Brand accent
    //
    // The single identity color, sourced from the user's Ghostty theme
    // (`theme = "Flexoki Light"`). Swap THIS ONE LINE to restyle:
    //   • Flexoki green (current): 0x66800B — the terminal palette's green.
    //   • Flexoki blue: 0x205EA6 — a calmer, distinct brand accent.
    static let accent = Color(hex: 0x66800B)
    /// Selected-row fill — Ghostty's own `selection-background`, so a highlighted
    /// row matches a text selection in the real terminal.
    static let accentSoft = Color(hex: 0xCECDC3)

    // MARK: - Status (state only, never decoration)
    static let attached = accent
    static let success = Color(hex: 0x66800B)   // Flexoki green
    static let warning = Color(hex: 0xAD8301)   // Flexoki yellow
    static let danger = Color(hex: 0xAF3029)    // Flexoki red

    // MARK: - Structure (Linear's thin luminance-borders)
    static let hairline = Color.primary.opacity(0.08)
    /// Subtle fill for hovered custom rows (Linear's near-zero white wash).
    static let hoverFill = Color.primary.opacity(0.07)

    // MARK: - Terminal canvas (mirrors the user's Ghostty theme: Flexoki Light)
    /// Captured-pane background = Ghostty `background`. Pinned (not system-adaptive)
    /// so the pane preview looks identical to the real terminal in any app mode.
    static let terminalBackground = Color(hex: 0xFFFCF0)   // Flexoki paper
    /// Captured-pane text = Ghostty `foreground`.
    static let terminalText = Color(hex: 0x100F0F)         // Flexoki ink

    // MARK: - Metrics
    enum Radius {
        static let card: CGFloat = 6
        static let row: CGFloat = 7
        static let panel: CGFloat = 12
    }

    // MARK: - Typography
    //
    // Named roles (Linear/Vercel discipline). Technical labels are monospaced —
    // the "developer console" voice that connects a GUI to its terminal subject.
    enum Font {
        static let rowTitle = SwiftUI.Font.system(size: 13, weight: .medium)
        static let rowTitlePlain = SwiftUI.Font.system(size: 13)
        static let rowSubtitle = SwiftUI.Font.system(size: 11)
        static let sectionHeader = SwiftUI.Font.system(size: 11, weight: .semibold)
        static let body = SwiftUI.Font.system(size: 13)
        static let bodyEmphasis = SwiftUI.Font.system(size: 13, weight: .semibold)
        static let detailTitle = SwiftUI.Font.system(size: 15, weight: .semibold)
        static let paletteField = SwiftUI.Font.system(size: 16)
        static let paletteRow = SwiftUI.Font.system(size: 14)

        /// Monospaced technical label — counts, ids, pids (e.g. `3w`, `%5`, `pid 412`).
        static let metric = SwiftUI.Font.system(size: 11, design: .monospaced).monospacedDigit()
        /// Smaller monospaced technical label — pane dimensions, secondary counts.
        static let metricSmall = SwiftUI.Font.system(size: 10, design: .monospaced).monospacedDigit()
        /// Captured-pane terminal content, and console stdout/stderr.
        static let terminal = SwiftUI.Font.system(size: 12, design: .monospaced)
        /// The Console command input — a touch larger than output.
        static let terminalInput = SwiftUI.Font.system(size: 13, design: .monospaced)
    }
}

extension Color {
    /// Hex-literal initializer, e.g. `Color(hex: 0x3ECF8E)`.
    init(hex: UInt32, alpha: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
