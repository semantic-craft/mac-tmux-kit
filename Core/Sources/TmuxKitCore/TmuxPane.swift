import Foundation

/// A tmux pane inside a window. Identified by its globally-unique stable id (`%N`),
/// which is valid across windows and sessions (so swap/break work cross-window).
public struct TmuxPane: Identifiable, Equatable, Hashable, Sendable {
    public let sessionId: String   // session_id
    public let windowId: String    // window_id
    public let id: String          // pane_id, e.g. "%89"
    public let index: Int          // pane_index (position within the window)
    public let active: Bool        // pane_active
    public let command: String     // pane_current_command
    public let pid: Int            // pane_pid
    public let width: Int          // pane_width (columns)
    public let height: Int         // pane_height (rows)
    public let path: String        // pane_current_path
    public let title: String       // pane_title
    public let left: Int           // pane_left (column offset within window)
    public let top: Int            // pane_top (row offset within window)

    public init(
        sessionId: String,
        windowId: String,
        id: String,
        index: Int,
        active: Bool,
        command: String,
        pid: Int,
        width: Int,
        height: Int,
        path: String,
        title: String,
        left: Int = 0,
        top: Int = 0
    ) {
        self.sessionId = sessionId
        self.windowId = windowId
        self.id = id
        self.index = index
        self.active = active
        self.command = command
        self.pid = pid
        self.width = width
        self.height = height
        self.path = path
        self.title = title
        self.left = left
        self.top = top
    }

    // Cell ranges used for geometric neighbor detection (directional swap).
    var right: Int { left + width }
    var bottom: Int { top + height }
}
