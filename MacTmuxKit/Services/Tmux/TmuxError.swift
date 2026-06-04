import Foundation

/// Typed tmux failures, classified from stderr so the UI can react meaningfully
/// (e.g. render a friendly empty state for `.serverNotRunning` instead of an error).
enum TmuxError: Error, Equatable {
    case binaryNotFound
    case serverNotRunning
    case noSuchTarget(String)
    case noClient
    case timedOut
    case cli(stderr: String, code: Int32)

    /// Classify a failed tmux invocation from its stderr + exit code.
    static func classify(stderr: String, code: Int32) -> TmuxError {
        let s = stderr.lowercased()
        if s.contains("no server running") || s.contains("error connecting to") {
            return .serverNotRunning
        }
        if s.contains("no current client") || s.contains("no client") {
            return .noClient
        }
        if s.contains("can't find session") || s.contains("can't find window")
            || s.contains("can't find pane") {
            return .noSuchTarget(stderr.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return .cli(stderr: stderr.trimmingCharacters(in: .whitespacesAndNewlines), code: code)
    }

    /// Short, user-facing message.
    var userMessage: String {
        switch self {
        case .binaryNotFound:
            return "tmux executable not found. Set its path in Settings."
        case .serverNotRunning:
            return "No tmux server running."
        case .noSuchTarget(let detail):
            return detail.isEmpty ? "Target not found." : detail
        case .noClient:
            return "No tmux client attached. Open a terminal and attach first."
        case .timedOut:
            return "tmux command timed out."
        case .cli(let stderr, let code):
            return stderr.isEmpty ? "tmux failed (exit \(code))." : stderr
        }
    }
}
