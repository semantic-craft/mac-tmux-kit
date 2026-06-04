import Foundation

/// A tmux window inside a session. Identified by its stable id (`@N`).
///
/// Targeting note: tmux window targets use `sessionId:windowIndex` (e.g. `$47:1`),
/// because window *names* may contain `:`/`.` and collide with target syntax.
public struct TmuxWindow: Identifiable, Equatable, Hashable, Sendable {
    public let sessionId: String   // session_id, e.g. "$47"
    public let id: String          // window_id, e.g. "@55"
    public let index: Int          // window_index (position within the session)
    public let name: String        // window_name
    public let active: Bool        // window_active
    public let paneCount: Int      // window_panes
    public let layout: String      // window_layout (contains commas/braces — keep raw)

    public init(
        sessionId: String,
        id: String,
        index: Int,
        name: String,
        active: Bool,
        paneCount: Int,
        layout: String
    ) {
        self.sessionId = sessionId
        self.id = id
        self.index = index
        self.name = name
        self.active = active
        self.paneCount = paneCount
        self.layout = layout
    }

    /// tmux target string for window-scoped commands: `sessionId:windowIndex`.
    public var target: String { "\(sessionId):\(index)" }
}
