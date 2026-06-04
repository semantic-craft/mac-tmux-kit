import SwiftUI

/// App entry point.
///
/// Menu-bar-resident app (`LSUIElement`, no Dock icon). The menu-bar popover is
/// the quick session switcher; the Dashboard is a full 3-column browser opened
/// on demand. The command palette and global hotkeys attach in later phases.
@main
struct MacTmuxKitApp: App {
    @State private var appState = AppState()
    @AppStorage("showMenuBarIcon") private var showMenuBarIcon = true

    var body: some Scene {
        MenuBarExtra("Tmux Kit", systemImage: "terminal", isInserted: $showMenuBarIcon) {
            MenuBarPopoverView()
                .environment(appState)
        }
        .menuBarExtraStyle(.window)

        // Dashboard is an AppKit window (DashboardWindowController) so the global
        // hotkey can summon it even when the menu-bar icon is hidden.

        Window("tmux Console", id: WindowID.console) {
            ConsoleView()
                .environment(appState)
        }
        .windowResizability(.contentMinSize)

        Window("tmux Cheatsheet", id: WindowID.cheatsheet) {
            CheatsheetView()
        }
        .windowResizability(.contentMinSize)

        Settings {
            SettingsView()
                .environment(appState)
        }
    }
}

/// Stable identifiers for `openWindow`. (The Dashboard is an AppKit window, not
/// a scene, so it isn't here.)
enum WindowID {
    static let console = "console"
    static let cheatsheet = "cheatsheet"
}
