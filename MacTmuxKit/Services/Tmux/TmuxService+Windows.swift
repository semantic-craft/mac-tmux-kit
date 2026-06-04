import Foundation

/// Window-scoped mutating commands. Window targets use `sessionId:index`
/// (e.g. `$47:1`) because window names may contain `:`/`.`.
extension TmuxService {
    /// Make a window current within its session (takes effect on next attach).
    func selectWindow(target: String) async throws {
        try await run(["select-window", "-t", target])
    }

    func renameWindow(target: String, to newName: String) async throws {
        try await run(["rename-window", "-t", target, newName])
    }

    func killWindow(target: String) async throws {
        try await run(["kill-window", "-t", target])
    }

    /// Create a detached window in a session (doesn't change its current window).
    func newWindow(sessionId: String, name: String?, startDir: String?) async throws {
        var args = ["new-window", "-d", "-t", "\(sessionId):"]
        if let name, !name.isEmpty { args += ["-n", name] }
        if let startDir, !startDir.isEmpty { args += ["-c", startDir] }
        try await run(args)
    }
}
