import Foundation

/// Opens a fresh Ghostty window attached to a session. Used when a detached
/// session has no window to raise.
///
/// Ghostty exposes no scripting API and its `+new-window` CLI action is rejected
/// on macOS; `open -na Ghostty --args -e <cmd>` is the supported launch path.
/// The exact `-e` / single-instance behavior must be verified live.
enum GhosttyLauncher {
    static func launch(tmuxBinary: URL, attachingToSession sessionId: String) async throws {
        let open = URL(fileURLWithPath: "/usr/bin/open")
        let args = ["-na", "Ghostty", "--args", "-e", tmuxBinary.path, "attach", "-t", sessionId]
        _ = try await ProcessRunner.run(executable: open, arguments: args, timeout: 8)
    }
}
