import Foundation

public enum PaneDirection: Sendable {
    case left, right, up, down
}

/// Assembled session → window → pane hierarchy, grouped for fast lookup.
/// Pure value type — built from parsed lists, no I/O.
public struct TmuxTree: Sendable {
    public let sessions: [TmuxSession]
    private let windowsBySession: [String: [TmuxWindow]]
    private let panesByWindow: [String: [TmuxPane]]

    public init(sessions: [TmuxSession], windows: [TmuxWindow], panes: [TmuxPane]) {
        self.sessions = sessions
        self.windowsBySession = Dictionary(grouping: windows, by: \.sessionId)
        self.panesByWindow = Dictionary(grouping: panes, by: \.windowId)
    }

    /// Windows in a session, ordered by index.
    public func windows(in sessionId: String) -> [TmuxWindow] {
        (windowsBySession[sessionId] ?? []).sorted { $0.index < $1.index }
    }

    /// Panes in a window, ordered by index.
    public func panes(in windowId: String) -> [TmuxPane] {
        (panesByWindow[windowId] ?? []).sorted { $0.index < $1.index }
    }

    /// Find the adjacent pane in a direction within the same window, using cell
    /// geometry. A neighbor must lie on the requested side and overlap on the
    /// perpendicular axis. Ties break toward the largest overlap (and, for the
    /// near side, the closest edge). Returns nil at the window boundary.
    public func neighbor(of pane: TmuxPane, _ direction: PaneDirection) -> TmuxPane? {
        let others = panes(in: pane.windowId).filter { $0.id != pane.id }
        func vOverlap(_ p: TmuxPane) -> Int { Self.overlap(pane.top, pane.bottom, p.top, p.bottom) }
        func hOverlap(_ p: TmuxPane) -> Int { Self.overlap(pane.left, pane.right, p.left, p.right) }

        switch direction {
        case .right:
            return others
                .filter { $0.left > pane.left && vOverlap($0) > 0 }
                .min { lhs, rhs in (lhs.left, -vOverlap(lhs)) < (rhs.left, -vOverlap(rhs)) }
        case .left:
            return others
                .filter { $0.left < pane.left && vOverlap($0) > 0 }
                .min { lhs, rhs in (-lhs.left, -vOverlap(lhs)) < (-rhs.left, -vOverlap(rhs)) }
        case .down:
            return others
                .filter { $0.top > pane.top && hOverlap($0) > 0 }
                .min { lhs, rhs in (lhs.top, -hOverlap(lhs)) < (rhs.top, -hOverlap(rhs)) }
        case .up:
            return others
                .filter { $0.top < pane.top && hOverlap($0) > 0 }
                .min { lhs, rhs in (-lhs.top, -hOverlap(lhs)) < (-rhs.top, -hOverlap(rhs)) }
        }
    }

    /// Length of the 1-D overlap between [a0,a1) and [b0,b1).
    static func overlap(_ a0: Int, _ a1: Int, _ b0: Int, _ b1: Int) -> Int {
        max(0, min(a1, b1) - max(a0, b0))
    }
}
