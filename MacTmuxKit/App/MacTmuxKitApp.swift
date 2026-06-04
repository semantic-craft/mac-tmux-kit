import SwiftUI
import AppKit

/// App entry point.
///
/// Menu-bar-resident app (`LSUIElement`, no Dock icon). The menu-bar popover is
/// the quick session switcher; the Dashboard is a full 3-column browser opened
/// on demand. The command palette and global hotkeys attach in later phases.
@main
struct MacTmuxKitApp: App {
    // An AppDelegate owns AppState and registers the global hotkeys in
    // applicationDidFinishLaunching. A plain `@State = AppState()` is created
    // lazily on the first scene render — for a menu-bar app that's the first
    // popover open, which left Hyper+D and the palette hotkey dead until then.
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @AppStorage("showMenuBarIcon") private var showMenuBarIcon = true

    private var appState: AppState { delegate.appState }

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

/// Owns the shared `AppState` and registers global hotkeys at the right moment.
/// AppState is created when the delegate is instantiated (app launch), but the
/// Carbon hotkeys are registered in `applicationDidFinishLaunching` — registering
/// them earlier (e.g. in a `@State` initializer or App.init) silently fails
/// because AppKit's event machinery isn't ready yet.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()

    func applicationDidFinishLaunching(_ notification: Notification) {
        appState.registerHotkeys()
    }
}
