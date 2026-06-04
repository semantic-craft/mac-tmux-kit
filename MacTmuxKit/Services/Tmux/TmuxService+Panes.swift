import Foundation

/// Pane-scoped commands. Pane ids (`%N`) are globally unique, so swap/break
/// work across windows and sessions.
extension TmuxService {
    /// Split a pane. `horizontal == true` puts the new pane to the right (`-h`);
    /// otherwise below (`-v`). Inherits the pane's working directory when given.
    func splitWindow(paneId: String, horizontal: Bool, cwd: String?) async throws {
        var args = ["split-window", horizontal ? "-h" : "-v", "-t", paneId]
        if let cwd, !cwd.isEmpty { args += ["-c", cwd] }
        try await run(args)
    }

    /// Promote a pane to a new window (window N+1 in its session).
    func breakPane(paneId: String) async throws {
        try await run(["break-pane", "-s", paneId])
    }

    func killPane(paneId: String) async throws {
        try await run(["kill-pane", "-t", paneId])
    }

    /// Kill every other pane in the pane's window, keeping this one.
    func killOtherPanes(paneId: String) async throws {
        try await run(["kill-pane", "-a", "-t", paneId])
    }

    func markPane(paneId: String) async throws {
        try await run(["select-pane", "-m", "-t", paneId])
    }

    func clearMarkedPane() async throws {
        try await run(["select-pane", "-M"])
    }

    /// Swap a pane with the currently marked pane.
    func swapWithMarked(paneId: String) async throws {
        try await run(["swap-pane", "-t", paneId])
    }

    /// Swap two specific panes without changing the active pane (`-d`).
    func swapPanes(source: String, target: String) async throws {
        try await run(["swap-pane", "-s", source, "-t", target, "-d"])
    }

    /// Make a pane active within its window.
    func selectPane(paneId: String) async throws {
        try await run(["select-pane", "-t", paneId])
    }

    /// Capture a pane's visible content (joined wrapped lines), trailing blank
    /// lines trimmed.
    func capturePane(paneId: String) async throws -> String {
        let raw = try await run(["capture-pane", "-p", "-J", "-t", paneId])
        // Trim trailing empty lines so the preview isn't a wall of blanks.
        var lines = raw.components(separatedBy: "\n")
        while let last = lines.last, last.trimmingCharacters(in: .whitespaces).isEmpty {
            lines.removeLast()
        }
        return lines.joined(separator: "\n")
    }

    func clearHistory(paneId: String) async throws {
        try await run(["clear-history", "-t", paneId])
    }
}
