import Foundation

/// Finds the `tmux` executable. Order: explicit override → known install paths.
///
/// Path is intentionally NOT hardcoded: on this machine tmux is at
/// `/opt/homebrew/bin/tmux` (Apple Silicon Homebrew), but Intel Homebrew uses
/// `/usr/local/bin`, and some setups use `/usr/bin`. The chosen path is later
/// made user-overridable in Settings (Phase 6).
enum TmuxBinaryLocator {
    static let candidatePaths = [
        "/opt/homebrew/bin/tmux",
        "/usr/local/bin/tmux",
        "/usr/bin/tmux",
    ]

    /// Returns the first usable tmux executable URL, or nil if none is found.
    static func locate(override: String? = nil) -> URL? {
        let fm = FileManager.default
        if let override, !override.isEmpty, fm.isExecutableFile(atPath: override) {
            return URL(fileURLWithPath: override)
        }
        for path in candidatePaths where fm.isExecutableFile(atPath: path) {
            return URL(fileURLWithPath: path)
        }
        return nil
    }
}
