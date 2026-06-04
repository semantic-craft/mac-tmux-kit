import AppKit

/// Reference-counted activation policy (pattern from macos-app-skills'
/// macos-patterns). The app is a menu-bar `.accessory` by default; while a real
/// window (the Dashboard) is open it becomes `.regular` so it shows in the Dock
/// and can be reached with Command-Tab, then reverts when the last one closes.
@MainActor
enum AppActivationPolicy {
    private static var count = 0

    static func enter() {
        count += 1
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
    }

    static func leave() {
        count = max(0, count - 1)
        guard count == 0 else { return }
        NSApp.setActivationPolicy(.accessory)
    }
}
