import SwiftUI

/// App entry point.
///
/// Menu-bar-resident app (`LSUIElement`, no Dock icon). The menu-bar popover is
/// the quick session switcher; the Dashboard is a full 3-column browser opened
/// on demand. The command palette and global hotkeys attach in later phases.
@main
struct MacTmuxKitApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("Tmux Kit", systemImage: "terminal") {
            MenuBarPopoverView()
                .environment(appState)
        }
        .menuBarExtraStyle(.window)

        Window("Tmux Kit", id: WindowID.dashboard) {
            DashboardView()
                .environment(appState)
        }
        .windowResizability(.contentMinSize)

        Settings {
            SettingsView()
                .environment(appState)
        }
    }
}

/// Stable identifiers for `openWindow`.
enum WindowID {
    static let dashboard = "dashboard"
}
