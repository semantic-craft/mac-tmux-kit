import Foundation

/// A connected tmux client (a terminal currently attached to a session).
///
/// Note: `sessionName` is the session *name*, not its id — this is what
/// `#{client_session}` reports. Correlate to a `TmuxSession` by name.
public struct TmuxClient: Identifiable, Equatable, Hashable, Sendable {
    public let tty: String         // client_tty, e.g. "/dev/ttys009"
    public let sessionName: String // client_session (name, not id)
    public let pid: Int            // client_pid
    public let termName: String    // client_termname, e.g. "xterm-ghostty"

    public var id: String { tty }

    public init(tty: String, sessionName: String, pid: Int, termName: String) {
        self.tty = tty
        self.sessionName = sessionName
        self.pid = pid
        self.termName = termName
    }
}
