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

    func resurrectRestore(scriptsDir: URL, restoreProcesses: Bool = false) async throws {
        let bootstrapSession = "__mactmuxkit_restore_\(UUID().uuidString.prefix(8))"
        let createdBootstrap = try await ensureServerForRestore(bootstrapSession: bootstrapSession)
        let previousProcesses = restoreProcesses ? try await currentResurrectProcessesOption() : nil
        if restoreProcesses {
            try await run(["set-option", "-g", "@resurrect-processes", ":all:"])
        }
        do {
            try await runShellScript(scriptsDir.appendingPathComponent("restore.sh").path, timeout: 30)
            if restoreProcesses {
                await restoreResurrectProcessesOption(previousProcesses)
            }
            if createdBootstrap {
                _ = try? await run(["kill-session", "-t", bootstrapSession])
            }
        } catch {
            if restoreProcesses {
                await restoreResurrectProcessesOption(previousProcesses)
            }
            if createdBootstrap {
                _ = try? await run(["kill-session", "-t", bootstrapSession])
            }
            throw error
        }
    }

    /// `tmux run-shell <arg>` runs the arg through /bin/sh, so the path is
    /// shell-quoted to survive spaces.
    private func runShellScript(_ path: String, timeout: TimeInterval = 5) async throws {
        _ = try await run(["run-shell", Self.shellQuote(path)], timeout: timeout)
    }

    /// tmux-resurrect restores by running inside a tmux server. After a crash or
    /// reboot there may be no server yet, so create one disposable session first.
    private func ensureServerForRestore(bootstrapSession: String) async throws -> Bool {
        do {
            _ = try await run(["list-sessions", "-F", "#S"])
            return false
        } catch TmuxError.serverNotRunning {
            _ = try await run(["new-session", "-d", "-s", bootstrapSession, "-c", NSHomeDirectory()])
            return true
        }
    }

    private func currentResurrectProcessesOption() async throws -> String? {
        let value = try await run(["show-option", "-gqv", "@resurrect-processes"])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    private func restoreResurrectProcessesOption(_ value: String?) async {
        if let value {
            _ = try? await run(["set-option", "-g", "@resurrect-processes", value])
        } else {
            _ = try? await run(["set-option", "-gu", "@resurrect-processes"])
        }
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
