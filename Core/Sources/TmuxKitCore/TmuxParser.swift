import Foundation

/// Pure parser: turns `tmux -F` output (newline records, 0x1F fields) into models.
///
/// Field order matches `TmuxFormat.*Fields`. Records with too few fields are
/// skipped (defensive against format/version drift). Empty fields are preserved.
public enum TmuxParser {
    public static func sessions(_ raw: String) -> [TmuxSession] {
        records(raw).compactMap { f in
            guard f.count >= TmuxFormat.sessionFields.count else { return nil }
            return TmuxSession(
                id: f[0],
                name: f[1],
                attached: f[2] == "1",
                windowCount: Int(f[3]) ?? 0,
                created: date(f[4]),
                activity: date(f[5]),
                path: f[6]
            )
        }
    }

    public static func windows(_ raw: String) -> [TmuxWindow] {
        records(raw).compactMap { f in
            guard f.count >= TmuxFormat.windowFields.count else { return nil }
            return TmuxWindow(
                sessionId: f[0],
                id: f[1],
                index: Int(f[2]) ?? 0,
                name: f[3],
                active: f[4] == "1",
                paneCount: Int(f[5]) ?? 0,
                layout: f[6]
            )
        }
    }

    public static func panes(_ raw: String) -> [TmuxPane] {
        records(raw).compactMap { f in
            guard f.count >= TmuxFormat.paneFields.count else { return nil }
            return TmuxPane(
                sessionId: f[0],
                windowId: f[1],
                id: f[2],
                index: Int(f[3]) ?? 0,
                active: f[4] == "1",
                command: f[5],
                pid: Int(f[6]) ?? 0,
                width: Int(f[7]) ?? 0,
                height: Int(f[8]) ?? 0,
                path: f[9],
                title: f[10],
                left: Int(f[11]) ?? 0,
                top: Int(f[12]) ?? 0
            )
        }
    }

    public static func clients(_ raw: String) -> [TmuxClient] {
        records(raw).compactMap { f in
            guard f.count >= TmuxFormat.clientFields.count else { return nil }
            return TmuxClient(
                tty: f[0],
                sessionName: f[1],
                pid: Int(f[2]) ?? 0,
                termName: f[3]
            )
        }
    }

    // MARK: - Helpers

    /// Split raw output into records (non-empty lines) of fields.
    static func records(_ raw: String) -> [[String]] {
        raw.split(separator: "\n", omittingEmptySubsequences: true).map { line in
            line.split(
                separator: TmuxFormat.unitSeparator,
                omittingEmptySubsequences: false
            ).map(String.init)
        }
    }

    static func date(_ s: String) -> Date {
        Date(timeIntervalSince1970: TimeInterval(s) ?? 0)
    }
}
