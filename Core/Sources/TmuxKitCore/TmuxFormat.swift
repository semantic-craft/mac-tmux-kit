import Foundation

/// tmux `-F` format strings and the field delimiter.
///
/// Single source of truth for field *order*: `TmuxParser` indexes by the same
/// order these arrays declare, so the producing format string and the parser
/// can never drift. Records are newline-delimited; fields are delimited by the
/// ASCII Unit Separator (0x1F), which never appears in session/window names,
/// paths, or `window_layout` (which itself contains commas, braces, brackets).
public enum TmuxFormat {
    /// ASCII Unit Separator — the field delimiter.
    public static let unitSeparator: Character = "\u{1F}"
    private static let us = String(unitSeparator)

    public static let sessionFields = [
        "session_id", "session_name", "session_attached", "session_windows",
        "session_created", "session_activity", "session_path",
    ]

    public static let windowFields = [
        "session_id", "window_id", "window_index", "window_name",
        "window_active", "window_panes", "window_layout",
    ]

    public static let paneFields = [
        "session_id", "window_id", "pane_id", "pane_index", "pane_active",
        "pane_current_command", "pane_pid", "pane_width", "pane_height",
        "pane_current_path", "pane_title", "pane_left", "pane_top",
    ]

    public static let clientFields = [
        "client_tty", "client_session", "client_pid", "client_termname",
    ]

    public static var session: String { formatString(sessionFields) }
    public static var window: String { formatString(windowFields) }
    public static var pane: String { formatString(paneFields) }
    public static var client: String { formatString(clientFields) }

    /// Build a `-F` format string from a field list, e.g. `#{a}<US>#{b}`.
    public static func formatString(_ fields: [String]) -> String {
        fields.map { "#{\($0)}" }.joined(separator: us)
    }
}
