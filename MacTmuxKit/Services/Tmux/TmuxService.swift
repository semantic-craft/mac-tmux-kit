import Foundation
import TmuxKitCore

/// High-level typed tmux API. Shells out to the tmux CLI via `ProcessRunner`
/// and parses `-F` output with `TmuxParser`. Targets always use stable IDs
/// (`$N`/`@N`/`%N`), never names.
///
/// Phase 1 covers read paths + `switch-client`. Mutating actions (new/kill/
/// rename/split/swap/break …) are added with the action registry in later phases.
final class TmuxService: Sendable {
    let binary: URL

    init(binary: URL) {
        self.binary = binary
    }

    // MARK: - Reads

    /// All sessions. Returns `[]` when no server is running (not an error).
    func listSessions() async throws -> [TmuxSession] {
        do {
            let out = try await run(["list-sessions", "-F", TmuxFormat.session])
            return TmuxParser.sessions(out)
        } catch TmuxError.serverNotRunning {
            return []
        }
    }

    /// All windows across all sessions (`list-windows -a`).
    func listAllWindows() async throws -> [TmuxWindow] {
        do {
            let out = try await run(["list-windows", "-a", "-F", TmuxFormat.window])
            return TmuxParser.windows(out)
        } catch TmuxError.serverNotRunning {
            return []
        }
    }

    /// All panes across all sessions (`list-panes -a`).
    func listAllPanes() async throws -> [TmuxPane] {
        do {
            let out = try await run(["list-panes", "-a", "-F", TmuxFormat.pane])
            return TmuxParser.panes(out)
        } catch TmuxError.serverNotRunning {
            return []
        }
    }

    /// Connected clients.
    func listClients() async throws -> [TmuxClient] {
        do {
            let out = try await run(["list-clients", "-F", TmuxFormat.client])
            return TmuxParser.clients(out)
        } catch TmuxError.serverNotRunning {
            return []
        }
    }

    // MARK: - Writes (Phase 1 subset)

    /// Switch the attached client to a session. Requires an attached client.
    func switchClient(toSession sessionId: String) async throws {
        _ = try await run(["switch-client", "-t", sessionId])
    }

    // MARK: - Invocation

    /// Run a tmux subcommand (internal so the per-domain extensions can use it).
    @discardableResult
    func run(_ args: [String]) async throws -> String {
        let result = try await ProcessRunner.run(executable: binary, arguments: args)
        guard result.exitCode == 0 else {
            throw TmuxError.classify(stderr: result.stderr, code: result.exitCode)
        }
        return result.stdout
    }
}
