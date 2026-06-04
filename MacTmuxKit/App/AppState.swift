import Foundation
import AppKit
import Observation
import KeyboardShortcuts
import TmuxKitCore

/// Top-level observable state shared by every UI surface (menu bar, palette,
/// Dashboard). Owns the `TmuxService`, the session/window/pane data, and the
/// mutating action methods (a single implementation reused by buttons, context
/// menus, and — later — the command palette and hotkeys).
@MainActor
@Observable
final class AppState {
    private(set) var sessions: [TmuxSession] = []
    private(set) var windows: [TmuxWindow] = []
    private(set) var panes: [TmuxPane] = []
    private(set) var statusMessage: String?
    private(set) var isLoading = false

    let service: TmuxService?
    let focusService = GhosttyFocusService()
    private var commandPalette: CommandPaletteController?

    init() {
        let override = UserDefaults.standard.string(forKey: "tmuxBinaryPath")
        service = TmuxBinaryLocator.locate(override: override).map { TmuxService(binary: $0) }
        setupHotkeys()
    }

    var tmuxAvailable: Bool { service != nil }
    var hasAXPermission: Bool { focusService.hasPermission }

    // MARK: - Command palette / hotkeys

    private func setupHotkeys() {
        let controller = CommandPaletteController(appState: self)
        commandPalette = controller
        KeyboardShortcuts.onKeyDown(for: .toggleCommandPalette) { [weak controller] in
            controller?.toggle()
        }
        KeyboardShortcuts.onKeyDown(for: .switchRecentSession) { [weak self] in
            Task { await self?.switchToMostRecent() }
        }
    }

    func showCommandPalette() { commandPalette?.show() }

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

    // MARK: - Refresh

    /// Reload sessions + windows + panes in parallel. Sessions sort most-active first.
    func refresh() async {
        guard let service else {
            statusMessage = TmuxError.binaryNotFound.userMessage
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            async let s = service.listSessions()
            async let w = service.listAllWindows()
            async let p = service.listAllPanes()
            let (ss, ww, pp) = try await (s, w, p)
            sessions = ss.sorted { $0.activity > $1.activity }
            windows = ww
            panes = pp
            statusMessage = sessions.isEmpty ? "No tmux sessions." : nil
        } catch {
            statusMessage = message(for: error)
        }
    }

    /// Run a mutating action, surface any error, then refresh.
    func run(_ work: @escaping (TmuxService) async throws -> Void) async {
        guard let service else { return }
        do { try await work(service) } catch { statusMessage = message(for: error) }
        await refresh()
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
        await run { try await $0.newSession(name: name, startDir: startDir) }
    }
    func renameSession(_ s: TmuxSession, to name: String) async {
        await run { try await $0.renameSession(id: s.id, to: name) }
    }
    func killSession(_ s: TmuxSession) async {
        await run { try await $0.killSession(id: s.id) }
    }
    func killOtherSessions(keep s: TmuxSession) async {
        await run { try await $0.killOtherSessions(keep: s.id) }
    }

    // MARK: - Window actions

    func selectWindow(_ w: TmuxWindow) async {
        await run { try await $0.selectWindow(target: w.target) }
    }
    func renameWindow(_ w: TmuxWindow, to name: String) async {
        await run { try await $0.renameWindow(target: w.target, to: name) }
    }
    func killWindow(_ w: TmuxWindow) async {
        await run { try await $0.killWindow(target: w.target) }
    }
    func newWindow(inSession id: String, name: String?, startDir: String?) async {
        await run { try await $0.newWindow(sessionId: id, name: name, startDir: startDir) }
    }

    // MARK: - Pane actions

    func split(_ p: TmuxPane, horizontal: Bool) async {
        await run { try await $0.splitWindow(paneId: p.id, horizontal: horizontal, cwd: p.path) }
    }
    func breakPane(_ p: TmuxPane) async { await run { try await $0.breakPane(paneId: p.id) } }
    func killPane(_ p: TmuxPane) async { await run { try await $0.killPane(paneId: p.id) } }
    func killOtherPanes(_ p: TmuxPane) async { await run { try await $0.killOtherPanes(paneId: p.id) } }
    func markPane(_ p: TmuxPane) async { await run { try await $0.markPane(paneId: p.id) } }
    func clearMarkedPane() async { await run { try await $0.clearMarkedPane() } }
    func clearHistory(_ p: TmuxPane) async { await run { try await $0.clearHistory(paneId: p.id) } }

    /// Swap a pane with its geometric neighbor in a direction (same window).
    func swap(_ p: TmuxPane, _ direction: PaneDirection) async {
        guard let neighbor = tree.neighbor(of: p, direction) else {
            statusMessage = "No adjacent pane in that direction."
            return
        }
        await run { try await $0.swapPanes(source: p.id, target: neighbor.id) }
    }

    // MARK: - tmux-resurrect

    var resurrectScriptsDir: URL? {
        ResurrectLocator.scriptsDir(override: UserDefaults.standard.string(forKey: "resurrectScriptsPath"))
    }
    var resurrectAvailable: Bool { resurrectScriptsDir != nil }
    func resurrectLastSaved() -> Date? { ResurrectLocator.lastSaveDate() }

    /// Returns nil on success, else an error message.
    func resurrectSave() async -> String? {
        guard let service, let dir = resurrectScriptsDir else { return "tmux-resurrect not found." }
        do { try await service.resurrectSave(scriptsDir: dir); return nil }
        catch { return message(for: error) }
    }

    func resurrectRestore() async -> String? {
        guard let service, let dir = resurrectScriptsDir else { return "tmux-resurrect not found." }
        let result: String?
        do { try await service.resurrectRestore(scriptsDir: dir); result = nil }
        catch { result = message(for: error) }
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

    /// Capture a pane's visible content for the detail view.
    func capture(_ p: TmuxPane) async -> String {
        guard let service else { return "" }
        do { return try await service.capturePane(paneId: p.id) }
        catch { return message(for: error) }
    }

    private func message(for error: Error) -> String {
        (error as? TmuxError)?.userMessage ?? error.localizedDescription
    }
}
