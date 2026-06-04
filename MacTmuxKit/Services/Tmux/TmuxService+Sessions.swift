import Foundation

/// Session-scoped mutating commands. Targets use the stable session id (`$N`).
extension TmuxService {
    /// Create a detached session so the user's current view doesn't change.
    func newSession(name: String, startDir: String?) async throws {
        var args = ["new-session", "-d", "-s", name]
        if let startDir, !startDir.isEmpty { args += ["-c", startDir] }
        try await run(args)
    }

    func renameSession(id: String, to newName: String) async throws {
        try await run(["rename-session", "-t", id, newName])
    }

    func killSession(id: String) async throws {
        try await run(["kill-session", "-t", id])
    }

    /// Kill every session except the one to keep.
    func killOtherSessions(keep id: String) async throws {
        try await run(["kill-session", "-a", "-t", id])
    }
}
