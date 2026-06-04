import Foundation

/// A tmux session. Identified by its stable id (`$N`), never its name.
public struct TmuxSession: Identifiable, Equatable, Hashable, Sendable {
    public let id: String          // session_id, e.g. "$47"
    public let name: String        // session_name
    public let attached: Bool      // session_attached (a client is connected)
    public let windowCount: Int    // session_windows
    public let created: Date       // session_created
    public let activity: Date      // session_activity (last activity)
    public let path: String        // session_path (working dir of the session)

    public init(
        id: String,
        name: String,
        attached: Bool,
        windowCount: Int,
        created: Date,
        activity: Date,
        path: String
    ) {
        self.id = id
        self.name = name
        self.attached = attached
        self.windowCount = windowCount
        self.created = created
        self.activity = activity
        self.path = path
    }
}
