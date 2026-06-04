import SwiftUI

/// Design tokens for Tmux Kit — one source of truth for color, type, and metrics.
///
/// Borrowed language (researched from the Open Design system library):
/// - **Linear**: structural restraint — a single brand accent, hairline borders
///   drawn in white-opacity, hierarchy carried by luminance not hue.
/// - **Your terminal**: colors are read live from the user's Ghostty theme at
///   launch (`ghostty +show-config`, see GhosttyTheme) — the captured-pane view,
///   accent, status, and selection all track whatever terminal theme they run,
///   falling back to baked Flexoki Light.
/// - **Vercel / Geist**: a monospaced "developer console" voice for every
///   technical label (counts, dimensions, ids, pids).
///
/// Native-first: text tiers and chrome stay on macOS semantic colors and system
/// materials, so light/dark mode and the vibrancy sidebar keep working. Only the
/// brand accent and the mono label voice are opinionated.
enum Theme {

    // MARK: - Palette (resolved from the user's live Ghostty theme)
    //
    // Read once at launch from `ghostty +show-config` (see GhosttyTheme), so the
    // GUI tracks whatever terminal theme the user runs — light or dark. Falls back
    // to baked Flexoki Light when Ghostty isn't installed or readable. The whole
    // identity is just the ANSI-slot → role mapping below; `ghostty.blue` is the
    // obvious alternate accent.
    static let ghostty = GhosttyTheme.resolve() ?? .flexokiFallback

    /// Brand accent — the terminal's green (active pane/window, attached, focus).
    static var accent: Color { ghostty.green }
    /// Selected-row fill — Ghostty's own `selection-background`, so a highlighted
    /// row matches a text selection in the real terminal.
    static var accentSoft: Color { ghostty.selection }

    // MARK: - Status (state only, never decoration)
    static var attached: Color { ghostty.green }
    static var success: Color { ghostty.green }
    static var warning: Color { ghostty.yellow }
    static var danger: Color { ghostty.red }

    // MARK: - Structure (Linear's thin luminance-borders)
    static let hairline = Color.primary.opacity(0.08)
    /// Subtle fill for hovered custom rows (Linear's near-zero white wash).
    static let hoverFill = Color.primary.opacity(0.07)

    // MARK: - Terminal canvas (= the user's Ghostty bg/fg, so preview == terminal)
    /// Captured-pane background = Ghostty `background`. Pinned (not system-adaptive)
    /// so the pane preview looks identical to the real terminal in any app mode.
    static var terminalBackground: Color { ghostty.background }
    /// Captured-pane text = Ghostty `foreground`.
    static var terminalText: Color { ghostty.foreground }

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
