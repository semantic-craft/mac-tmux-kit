import Foundation

/// Server-level / arbitrary-command execution.
extension TmuxService {
    /// Run a raw tmux command line entered by the user. The line is tokenized
    /// with quote awareness and passed as an argument array — NOT through a
    /// shell — so there is no shell-injection surface. Returns stdout/stderr/exit
    /// without throwing so the console can show failures.
    func runRaw(_ commandLine: String) async -> ProcessResult {
        let args = Self.tokenize(commandLine)
        guard !args.isEmpty else {
            return ProcessResult(stdout: "", stderr: "Empty command", exitCode: -1)
        }
        do {
            return try await ProcessRunner.run(executable: binary, arguments: ["-S", socket] + args, timeout: 10)
        } catch {
            return ProcessResult(stdout: "", stderr: String(describing: error), exitCode: -1)
        }
    }

    // MARK: - tmux-resurrect

    func resurrectSave(scriptsDir: URL) async throws {
        try await runShellScript(scriptsDir.appendingPathComponent("save.sh").path)
    }

    func resurrectRestore(scriptsDir: URL) async throws {
        try await runShellScript(scriptsDir.appendingPathComponent("restore.sh").path)
    }

    /// `tmux run-shell <arg>` runs the arg through /bin/sh, so the path is
    /// shell-quoted to survive spaces.
    private func runShellScript(_ path: String) async throws {
        _ = try await run(["run-shell", Self.shellQuote(path)])
    }

    static func shellQuote(_ s: String) -> String {
        "'" + s.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    /// Split a command line into tokens, honoring single and double quotes.
    static func tokenize(_ line: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        var quote: Character?
        var hasToken = false
        for ch in line {
            if let q = quote {
                if ch == q { quote = nil } else { current.append(ch) }
            } else if ch == "\"" || ch == "'" {
                quote = ch
                hasToken = true
            } else if ch == " " || ch == "\t" {
                if hasToken { tokens.append(current); current = ""; hasToken = false }
            } else {
                current.append(ch)
                hasToken = true
            }
        }
        if hasToken { tokens.append(current) }
        return tokens
    }
}
