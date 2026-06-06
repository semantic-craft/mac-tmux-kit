import AppKit

/// Reference-counted activation policy (pattern from macos-app-skills'
/// macos-patterns). The app is a menu-bar `.accessory` by default; while a real
/// window (the Dashboard) is open it becomes `.regular` so it shows in the Dock
/// and can be reached with Command-Tab, then reverts when the last one closes.
///
/// The user can also force a permanent Dock presence via the "Show Dock icon"
/// setting (`showDockIcon`); when on, the app stays `.regular` even with no
/// window open.
@MainActor
enum AppActivationPolicy {
    private static var count = 0
    private static var showDock: Bool { UserDefaults.standard.bool(forKey: "showDockIcon") }

    static func enter() {
        count += 1
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
    }

    static func leave() {
        count = max(0, count - 1)
        // Keep the Dock icon if the user pinned it on, or if a window is still open.
        guard count == 0, !showDock else { return }
        NSApp.setActivationPolicy(.accessory)
    }

    /// Apply the persisted "Show Dock icon" preference. Call at launch and
    /// whenever the toggle changes.
    static func applyDockPreference() {
        if showDock {
            NSApp.setActivationPolicy(.regular)
        } else if count == 0 {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
