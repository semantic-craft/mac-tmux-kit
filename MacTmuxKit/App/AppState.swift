import Foundation
import AppKit
import Observation
import KeyboardShortcuts
import TmuxKitCore

/// What clicking a session row in the menu bar does (Settings → General).
enum SessionClickAction: String, CaseIterable {
    case switchAndFocus
    case openDashboard

    var title: String {
        switch self {
        case .switchAndFocus: "Switch and focus"
        case .openDashboard: "Open in Dashboard"
        }
    }
}

protocol UserDefaultsStoring: AnyObject {
    func stringArray(forKey defaultName: String) -> [String]?
    func set(_ value: Any?, forKey defaultName: String)
    @discardableResult func synchronize() -> Bool
}

extension UserDefaults: UserDefaultsStoring {}

/// A request to open the Dashboard focused on a specific session. The `token`
/// makes each request unique, so clicking the same session again still triggers
/// the Dashboard's selection update.
struct DashboardRequest: Equatable {
    let sessionId: String
    let token = UUID()
}

protocol TmuxStateReading: Sendable {
    func listSessions() async throws -> [TmuxSession]
    func listAllWindows() async throws -> [TmuxWindow]
    func listAllPanes() async throws -> [TmuxPane]
    func hostShort() async throws -> String
}

extension TmuxService: TmuxStateReading {}

protocol TmuxPaneCapturing: Sendable {
    func capturePane(paneId: String) async throws -> String
}

extension TmuxService: TmuxPaneCapturing {}

struct PanePreview: Equatable, Sendable {
    let content: String
    let errorMessage: String?

    var failed: Bool { errorMessage != nil }

    static let empty = PanePreview(content: "", errorMessage: nil)
}

/// Top-level observable state shared by every UI surface (menu bar, palette,
/// Dashboard). Owns the `TmuxService`, the session/window/pane data, and the
/// mutating action methods (a single implementation reused by buttons, context
/// menus, and — later — the command palette and hotkeys).
@MainActor
@Observable
final class AppState {
    private static let pinnedSessionNamesKey = "pinnedSessionNames"

    private(set) var sessions: [TmuxSession] = []
    private(set) var windows: [TmuxWindow] = []
    private(set) var panes: [TmuxPane] = []
    private(set) var pinnedSessionNames: Set<String>
    private(set) var statusMessage: String?
    private(set) var isLoading = false
    /// True when the last `refresh()` failed (server unreachable / binary missing), so the
    /// UI can tell a real "no sessions" empty state from an error. Cleared on a clean read.
    private(set) var lastRefreshFailed = false
    /// Server short host name, used to tell a default pane title from a user-set
    /// one (tmux seeds `pane_title` with the host). Refreshed with the tree.
    private(set) var hostShort = ""
    /// Transient confirmation for the last action (optimistic-UI feedback).
    private(set) var toast: ToastInfo?
    private var toastToken = UUID()
    /// Set when the user opens a session in the Dashboard from the menu bar.
    private(set) var dashboardRequest: DashboardRequest?

    let service: TmuxService?
    @ObservationIgnored private let stateReader: (any TmuxStateReading)?
    @ObservationIgnored private let paneCapturer: (any TmuxPaneCapturing)?
    @ObservationIgnored private let defaults: any UserDefaultsStoring
    let focusService = GhosttyFocusService()
    private var commandPalette: CommandPaletteController?
    private var dashboard: DashboardWindowController?
    private var console: ConsoleWindowController?
    private var cheatsheet: CheatsheetWindowController?
    private var autoRefreshTask: Task<Void, Never>?
    private var refreshAgain = false

    init(
        service: TmuxService? = nil,
        stateReader: (any TmuxStateReading)? = nil,
        paneCapturer: (any TmuxPaneCapturing)? = nil,
        defaults: any UserDefaultsStoring = UserDefaults.standard,
        preloadTheme: Bool = true
    ) {
        self.defaults = defaults
        self.pinnedSessionNames = Set(defaults.stringArray(forKey: Self.pinnedSessionNamesKey) ?? [])
        if let stateReader {
            self.service = service
            self.stateReader = stateReader
            self.paneCapturer = paneCapturer
        } else {
            let override = UserDefaults.standard.string(forKey: "tmuxBinaryPath")
            let located = service ?? TmuxBinaryLocator.locate(override: override).map { TmuxService(binary: $0) }
            self.service = located
            self.stateReader = located
            self.paneCapturer = located
        }
        // Resolve the Ghostty-derived theme off the main thread so the first view
        // render never blocks on the `ghostty +show-config` subprocess.
        if preloadTheme {
            Task.detached(priority: .utility) { _ = Theme.ghostty }
        }
    }

    var tmuxAvailable: Bool { stateReader != nil }
    var hasAXPermission: Bool { focusService.hasPermission }

    // MARK: - Command palette / hotkeys

    /// Register global hotkeys and build the palette/dashboard controllers. Called
    /// from `AppDelegate.applicationDidFinishLaunching` — not from `init` — so the
    /// Carbon hotkey registration runs after AppKit is ready.
    func registerHotkeys() {
        let palette = CommandPaletteController(appState: self)
        commandPalette = palette
        let dash = DashboardWindowController(appState: self)
        dashboard = dash
        console = ConsoleWindowController(appState: self)
        cheatsheet = CheatsheetWindowController()

        KeyboardShortcuts.onKeyDown(for: .toggleCommandPalette) { [weak palette] in
            palette?.toggle()
        }
        KeyboardShortcuts.onKeyDown(for: .toggleDashboard) { [weak dash] in
            dash?.show()
        }
        KeyboardShortcuts.onKeyDown(for: .switchRecentSession) { [weak self] in
            Task { await self?.switchToMostRecent() }
        }
    }

    /// Keep the menu-bar state current even when Tmux Kit has been running for
    /// days before a tmux server/session appears.
    func startAutoRefresh() {
        guard autoRefreshTask == nil else { return }
        autoRefreshTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                do {
                    try await Task.sleep(nanoseconds: 3_000_000_000)
                } catch {
                    break
                }
            }
        }
    }

    func stopAutoRefresh() {
        autoRefreshTask?.cancel()
        autoRefreshTask = nil
    }

    func showCommandPalette() { commandPalette?.show() }
    func showDashboard() { dashboard?.show() }
    func showConsole() { console?.show() }
    func showCheatsheet() { cheatsheet?.show() }

    /// Open the Dashboard focused on a specific session (menu-bar "Open in
    /// Dashboard" click action).
    func showDashboard(selecting sessionId: String) {
        dashboardRequest = DashboardRequest(sessionId: sessionId)
        dashboard?.show()
    }

    /// Menu-bar session-row click behavior, controlled by the `sessionClickAction`
    /// setting: switch + focus the session (default), or reveal it in the Dashboard.
    func activateFromMenuBar(_ s: TmuxSession) async {
        let stored = UserDefaults.standard.string(forKey: "sessionClickAction") ?? ""
        if SessionClickAction(rawValue: stored) == .openDashboard {
            showDashboard(selecting: s.id)
        } else {
            await switchTo(s)
        }
    }

    /// Switch + focus the most recently active session that isn't already attached
    /// (falls back to the most recent overall).
    func switchToMostRecent() async {
        if let target = sessions.first(where: { !$0.attached }) ?? sessions.first {
            await switchTo(target)
        }
    }
    var tree: TmuxTree { TmuxTree(sessions: sessions, windows: windows, panes: panes) }

    func session(id: String?) -> TmuxSession? { sessions.first { $0.id == id } }
    func pane(id: String?) -> TmuxPane? { panes.first { $0.id == id } }

    func activeWindow(in session: TmuxSession) -> TmuxWindow? {
        let sessionWindows = tree.windows(in: session.id)
        return sessionWindows.first { $0.active } ?? sessionWindows.first
    }

    func activePane(in window: TmuxWindow?) -> TmuxPane? {
        guard let window else { return nil }
        let windowPanes = tree.panes(in: window.id)
        return windowPanes.first { $0.active } ?? windowPanes.first
    }

    func activePane(in session: TmuxSession) -> TmuxPane? {
        activePane(in: activeWindow(in: session))
    }

    func previewPane(in sessionId: String?) -> TmuxPane? {
        guard let sessionId else { return nil }
        let sessionPanes = panes.filter { $0.sessionId == sessionId }
        return sessionPanes.first { $0.active } ?? sessionPanes.first
    }

    func paneCount(in session: TmuxSession) -> Int {
        panes.filter { $0.sessionId == session.id }.count
    }

    func isPinned(_ session: TmuxSession) -> Bool {
        pinnedSessionNames.contains(session.name)
    }

    func pinnedFirstSessions(limit: Int? = nil) -> [TmuxSession] {
        let ordered = sessions.sorted { lhs, rhs in
            let lhsPinned = isPinned(lhs)
            let rhsPinned = isPinned(rhs)
            if lhsPinned != rhsPinned { return lhsPinned && !rhsPinned }
            return lhs.activity > rhs.activity
        }
        guard let limit else { return ordered }
        return Array(ordered.prefix(limit))
    }

    func togglePin(_ session: TmuxSession) {
        isPinned(session) ? unpinSession(session) : pinSession(session)
    }

    func pinSession(_ session: TmuxSession) {
        guard !session.name.isEmpty else { return }
        pinnedSessionNames.insert(session.name)
        persistPinnedSessionNames()
    }

    func unpinSession(_ session: TmuxSession) {
        pinnedSessionNames.remove(session.name)
        persistPinnedSessionNames()
    }

    func sessionDisplayPath(_ session: TmuxSession) -> String {
        if let activePath = activePane(in: session)?.path, !activePath.isEmpty {
            return activePath
        }
        return session.path
    }

    func windowReadableName(_ window: TmuxWindow, activePane: TmuxPane?) -> String {
        let raw = window.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let activePane else { return raw.isEmpty ? "Window \(window.index)" : raw }
        let paneTitle = paneReadableName(activePane)
        if raw.isEmpty || raw == activePane.command || raw == activePane.title || raw == hostShort {
            return paneTitle
        }
        return raw
    }

    func paneReadableName(_ pane: TmuxPane) -> String {
        paneReadableTitle(title: pane.title, command: pane.command, host: hostShort, path: pane.path)
    }

    // MARK: - Refresh

    /// Reload sessions + windows + panes in parallel. Sessions sort most-active first.
    func refresh() async {
        guard let stateReader else {
            statusMessage = TmuxError.binaryNotFound.userMessage
            lastRefreshFailed = true
            return
        }
        guard !isLoading else {
            refreshAgain = true
            return
        }
        isLoading = true
        do {
            async let s = stateReader.listSessions()
            async let w = stateReader.listAllWindows()
            async let p = stateReader.listAllPanes()
            async let h = stateReader.hostShort()
            let (ss, ww, pp, hh) = try await (s, w, p, h)
            sessions = ss.sorted { $0.activity > $1.activity }
            windows = ww
            panes = pp
            hostShort = hh
            statusMessage = sessions.isEmpty ? "No tmux sessions." : nil
            lastRefreshFailed = false
        } catch {
            statusMessage = message(for: error)
            lastRefreshFailed = true
        }
        isLoading = false
        if refreshAgain {
            refreshAgain = false
            await refresh()
        }
    }

    /// Run a mutating action, then refresh. On success, optionally flash a
    /// confirmation toast; on failure, surface the error inline and as a toast.
    func run(success: String? = nil, _ work: @escaping (TmuxService) async throws -> Void) async {
        guard let service else { return }
        do {
            try await work(service)
            if let success { showToast(success, kind: .success) }
        } catch {
            let text = message(for: error)
            statusMessage = text
            showToast(text, kind: .failure)
        }
        await refresh()
    }

    /// Flash a transient toast, auto-dismissed after ~2s unless superseded.
    func showToast(_ text: String, kind: ToastInfo.Kind) {
        let info = ToastInfo(text: text, kind: kind)
        toast = info
        toastToken = info.id
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if toastToken == info.id { toast = nil }
        }
    }

    // MARK: - Session actions

    /// Switch to a session and bring its Ghostty window forward.
    /// - attached session: raise its existing window.
    /// - detached session: always open a NEW Ghostty window attached to it
    ///   (never hijacks an existing window), then raise it once it appears.
    func switchTo(_ s: TmuxSession) async {
        guard let service else { return }
        if s.attached {
            focusOrPrompt(session: s.name)
        } else {
            do {
                try await GhosttyLauncher.launch(tmuxBinary: service.binary, attachingToSession: s.id)
            } catch {
                statusMessage = message(for: error)
                await refresh()
                return
            }
            if focusService.hasPermission {
                // The new window needs a moment to attach and set its title.
                for _ in 0..<10 {
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    if focusService.focusWindow(forSession: s.name) { break }
                }
            } else {
                focusService.ensurePermission()
            }
        }
        await refresh()
    }

    private func focusOrPrompt(session name: String) {
        let focused = focusService.focusWindow(forSession: name)
        if !focused, !focusService.hasPermission {
            statusMessage = "Enable Accessibility for Tmux Kit to focus its window."
        }
    }

    func requestAXPermission() { focusService.ensurePermission() }

    func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    /// Set the running tmux server to title windows by session (`tmux:#S`), which
    /// makes Ghostty window focus-matching reliable. Opt-in (Settings → Focus).
    func installTitleFormat() async {
        await run {
            try await $0.run(["set-option", "-g", "set-titles", "on"])
            try await $0.run(["set-option", "-g", "set-titles-string", "tmux:#S"])
        }
    }
    func newSession(name: String, startDir: String?) async {
        await run(success: "Created session") { try await $0.newSession(name: name, startDir: startDir) }
    }
    func renameSession(_ s: TmuxSession, to name: String) async {
        await run(success: "Renamed session") { try await $0.renameSession(id: s.id, to: name) }
    }
    func killSession(_ s: TmuxSession) async {
        await run(success: "Killed session") { try await $0.killSession(id: s.id) }
    }
    func detachSession(_ s: TmuxSession) async {
        await run(success: "Detached session") { try await $0.detachSession(id: s.id) }
    }
    func killOtherSessions(keep s: TmuxSession) async {
        await run(success: "Killed other sessions") { try await $0.killOtherSessions(keep: s.id) }
    }

    // MARK: - Window actions

    func selectWindow(_ w: TmuxWindow) async {
        await run { try await $0.selectWindow(target: w.target) }
    }
    func renameWindow(_ w: TmuxWindow, to name: String) async {
        await run(success: "Renamed window") { try await $0.renameWindow(target: w.target, to: name) }
    }
    func killWindow(_ w: TmuxWindow) async {
        await run(success: "Killed window") { try await $0.killWindow(target: w.target) }
    }
    func newWindow(inSession id: String, name: String?, startDir: String?) async {
        await run(success: "Created window") { try await $0.newWindow(sessionId: id, name: name, startDir: startDir) }
    }

    // MARK: - Pane actions

    func split(_ p: TmuxPane, horizontal: Bool) async {
        await run(success: "Split pane") { try await $0.splitWindow(paneId: p.id, horizontal: horizontal, cwd: p.path) }
    }
    func breakPane(_ p: TmuxPane) async { await run(success: "Broke out pane") { try await $0.breakPane(paneId: p.id) } }

    /// The pane's user-set title, or "" when it is still the tmux default
    /// (used to seed the rename field).
    func paneCustomName(_ p: TmuxPane) -> String {
        paneCustomTitle(title: p.title, command: p.command, host: hostShort) ?? ""
    }

    /// Rename a pane by setting its `pane_title`.
    func renamePane(_ p: TmuxPane, to title: String) async {
        await run(success: title.isEmpty ? "Cleared pane title" : "Renamed pane") {
            try await $0.setPaneTitle(paneId: p.id, to: title)
        }
    }
    func killPane(_ p: TmuxPane) async { await run(success: "Killed pane") { try await $0.killPane(paneId: p.id) } }
    func killOtherPanes(_ p: TmuxPane) async { await run(success: "Killed other panes") { try await $0.killOtherPanes(paneId: p.id) } }
    func markPane(_ p: TmuxPane) async { await run { try await $0.markPane(paneId: p.id) } }
    func clearMarkedPane() async { await run { try await $0.clearMarkedPane() } }
    func clearHistory(_ p: TmuxPane) async { await run(success: "Cleared history") { try await $0.clearHistory(paneId: p.id) } }

    /// Swap a pane with its geometric neighbor in a direction (same window).
    func swap(_ p: TmuxPane, _ direction: PaneDirection) async {
        guard let neighbor = tree.neighbor(of: p, direction) else {
            statusMessage = "No adjacent pane in that direction."
            return
        }
        await run(success: "Swapped panes") { try await $0.swapPanes(source: p.id, target: neighbor.id) }
    }

    // MARK: - tmux-resurrect

    var resurrectScriptsDir: URL? {
        ResurrectLocator.scriptsDir(override: UserDefaults.standard.string(forKey: "resurrectScriptsPath"))
    }
    var resurrectAvailable: Bool { resurrectScriptsDir != nil }
    func resurrectLastSaved() -> Date? { ResurrectLocator.lastSaveDate() }

    /// Returns nil on success, else an error message.
    func resurrectSave() async -> String? {
        guard let service, let dir = resurrectScriptsDir else {
            let text = "tmux-resurrect not found."
            statusMessage = text
            showToast(text, kind: .failure)
            return text
        }
        do {
            try await service.resurrectSave(scriptsDir: dir)
            showToast("Saved layout", kind: .success)
            return nil
        } catch {
            let text = message(for: error)
            statusMessage = text
            showToast(text, kind: .failure)
            return text
        }
    }

    func resurrectRestore() async -> String? {
        guard let service, let dir = resurrectScriptsDir else {
            let text = "tmux-resurrect not found."
            statusMessage = text
            showToast(text, kind: .failure)
            return text
        }
        let result: String?
        let restoreProcesses = UserDefaults.standard.object(forKey: "resurrectRestoreProcesses") as? Bool ?? true
        do {
            try await service.resurrectRestore(scriptsDir: dir, restoreProcesses: restoreProcesses)
            showToast(restoreProcesses ? "Restored layout and commands" : "Restored layout", kind: .success)
            result = nil
        } catch {
            result = message(for: error)
            if let result {
                statusMessage = result
                showToast(result, kind: .failure)
            }
        }
        await refresh()
        return result
    }

    /// Run a raw tmux command from the console, then refresh (it may mutate).
    func runRaw(_ commandLine: String) async -> ProcessResult {
        guard let service else {
            return ProcessResult(stdout: "", stderr: TmuxError.binaryNotFound.userMessage, exitCode: -1)
        }
        let result = await service.runRaw(commandLine)
        await refresh()
        return result
    }

    // MARK: - Debug snapshot

    func debugSnapshot() async -> String {
        var liveSessions: [TmuxSession] = []
        var liveWindows: [TmuxWindow] = []
        var livePanes: [TmuxPane] = []
        var liveHost = ""
        var failures: [String] = []

        if let stateReader {
            do { liveSessions = try await stateReader.listSessions() }
            catch { failures.append("listSessions: \(message(for: error))") }
            do { liveWindows = try await stateReader.listAllWindows() }
            catch { failures.append("listAllWindows: \(message(for: error))") }
            do { livePanes = try await stateReader.listAllPanes() }
            catch { failures.append("listAllPanes: \(message(for: error))") }
            do { liveHost = try await stateReader.hostShort() }
            catch { failures.append("hostShort: \(message(for: error))") }
        } else {
            failures.append("tmux: \(TmuxError.binaryNotFound.userMessage)")
        }

        var lines: [String] = [
            "Tmux Kit Debug Snapshot",
            "generated: \(ISO8601DateFormatter().string(from: Date()))",
            "",
            "tmux",
            "  binary: \(service?.binary.path ?? "not found")",
            "  socket: \(service?.socket ?? TmuxService.resolveSocket())",
            "",
            "app state",
            "  tmux available: \(tmuxAvailable)",
            "  loading: \(isLoading)",
            "  last status: \(statusMessage.map(debugSingleLine) ?? "OK")",
            "  counts: sessions=\(sessions.count) windows=\(windows.count) panes=\(panes.count)",
            "",
            "fresh tmux read",
            "  host: \(liveHost.isEmpty ? "unknown" : debugSingleLine(liveHost))",
            "  counts: sessions=\(liveSessions.count) windows=\(liveWindows.count) panes=\(livePanes.count)",
        ]

        lines.append("  failures: \(failures.isEmpty ? "none" : "")")
        lines += failures.map { "    - \(debugSingleLine($0))" }
        lines.append("")
        lines.append("sessions")
        lines += debugSessionLines(sessions: liveSessions, windows: liveWindows, panes: livePanes)
        return lines.joined(separator: "\n")
    }

    @discardableResult
    func copyDebugSnapshot() async -> Bool {
        let snapshot = await debugSnapshot()
        NSPasteboard.general.clearContents()
        let copied = NSPasteboard.general.setString(snapshot, forType: .string)
        if copied {
            showToast("Copied debug snapshot", kind: .success)
        } else {
            let text = "Could not copy debug snapshot."
            statusMessage = text
            showToast(text, kind: .failure)
        }
        return copied
    }

    /// Capture a pane's visible content for the detail view.
    func capture(_ p: TmuxPane) async -> String {
        (await capturePreview(p)).content
    }

    func capturePreview(_ p: TmuxPane) async -> PanePreview {
        guard let paneCapturer else {
            return PanePreview(content: "", errorMessage: TmuxError.binaryNotFound.userMessage)
        }
        do {
            return PanePreview(content: try await paneCapturer.capturePane(paneId: p.id), errorMessage: nil)
        }
        catch { return PanePreview(content: "", errorMessage: message(for: error)) }
    }

    private func message(for error: Error) -> String {
        (error as? TmuxError)?.userMessage ?? error.localizedDescription
    }

    private func persistPinnedSessionNames() {
        defaults.set(Array(pinnedSessionNames).sorted(), forKey: Self.pinnedSessionNamesKey)
        defaults.synchronize()
    }

    private func debugSessionLines(
        sessions: [TmuxSession],
        windows: [TmuxWindow],
        panes: [TmuxPane]
    ) -> [String] {
        guard !sessions.isEmpty else { return ["  none"] }
        let windowsBySession = Dictionary(grouping: windows, by: \.sessionId)
        let panesByWindow = Dictionary(grouping: panes, by: \.windowId)

        return sessions.flatMap { session -> [String] in
            let sessionWindows = (windowsBySession[session.id] ?? []).sorted { $0.index < $1.index }
            var lines = [
                "  \(session.id) \(debugQuoted(session.name)) attached=\(session.attached) windows=\(session.windowCount)",
            ]
            if sessionWindows.isEmpty {
                lines.append("    windows: none")
            } else {
                for window in sessionWindows {
                    let windowPanes = (panesByWindow[window.id] ?? []).sorted { $0.index < $1.index }
                    lines.append("    \(window.id) index=\(window.index) active=\(window.active) name=\(debugQuoted(window.name)) panes=\(window.paneCount)")
                    for pane in windowPanes {
                        lines.append("      \(pane.id) index=\(pane.index) active=\(pane.active) command=\(debugQuoted(pane.command)) size=\(pane.width)x\(pane.height)")
                    }
                }
            }
            return lines
        }
    }

    private func debugQuoted(_ value: String) -> String {
        "\"\(debugSingleLine(value).replacingOccurrences(of: "\"", with: "\\\""))\""
    }

    private func debugSingleLine(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
    }
}
