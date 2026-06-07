import Foundation

/// Result of running an external process.
struct ProcessResult: Sendable {
    let stdout: String
    let stderr: String
    let exitCode: Int32
}

enum ProcessRunnerError: Error {
    case launchFailed(String)
}

/// Minimal async wrapper around `Process`.
///
/// stdout and stderr are drained concurrently (each on its own detached task)
/// so a large stream on one pipe can never deadlock the other. A timeout task
/// terminates the process if it overruns, which closes the pipes and unblocks
/// the readers. Arguments are passed as an array — never interpolated into a
/// shell string — so names/paths with spaces or metacharacters are safe.
enum ProcessRunner {
    static func run(
        executable: URL,
        arguments: [String],
        timeout: TimeInterval = 5
    ) async throws -> ProcessResult {
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        // A login/Finder-launched GUI app inherits a minimal PATH; ensure common
        // CLI locations (incl. Homebrew) are present for tmux and any helpers it runs.
        var environment = ProcessInfo.processInfo.environment
        let toolPaths = "/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        environment["PATH"] = environment["PATH"].map { "\(toolPaths):\($0)" } ?? toolPaths
        process.environment = environment

        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe

        do {
            try process.run()
        } catch {
            throw ProcessRunnerError.launchFailed(error.localizedDescription)
        }

        let outHandle = outPipe.fileHandleForReading
        let errHandle = errPipe.fileHandleForReading
        async let outData: Data = Task.detached { outHandle.readDataToEndOfFile() }.value
        async let errData: Data = Task.detached { errHandle.readDataToEndOfFile() }.value

        let timeoutTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            if process.isRunning { process.terminate() }
        }

        let out = await outData
        let err = await errData
        process.waitUntilExit()
        timeoutTask.cancel()

        return ProcessResult(
            stdout: String(decoding: out, as: UTF8.self),
            stderr: String(decoding: err, as: UTF8.self),
            exitCode: process.terminationStatus
        )
    }
}
