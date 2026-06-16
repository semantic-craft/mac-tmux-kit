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

    private var appState: AppState { delegate.appState }

    var body: some Scene {
        // The menu-bar icon and its popover are AppKit-owned (`NSStatusItem` +
        // `NSPopover`) so opening the popover does not depend on SwiftUI's
        // Control Center-hosted `MenuBarExtra(.window)` scene. Console,
        // Cheatsheet, Dashboard, and Command Palette are AppKit-managed windows.

        Settings {
            SettingsView()
                .environment(appState)
        }
    }
}

/// Owns the shared `AppState` and registers global hotkeys at the right moment.
/// AppState is created when the delegate is instantiated (app launch), but the
/// Carbon hotkeys are registered in `applicationDidFinishLaunching` — registering
/// them earlier (e.g. in a `@State` initializer or App.init) silently fails
/// because AppKit's event machinery isn't ready yet.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()
    private var statusItem: NSStatusItem?
    private let popover = NSPopover()
    private var defaultsObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        appState.registerHotkeys()
        appState.startAutoRefresh()
        AppActivationPolicy.applyDockPreference()
        configurePopover()
        configureStatusItem()
        defaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.configureStatusItem()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let defaultsObserver {
            NotificationCenter.default.removeObserver(defaultsObserver)
        }
        appState.stopAutoRefresh()
    }

    private var menuBarIconVisible: Bool {
        if UserDefaults.standard.object(forKey: "showMenuBarIcon") == nil { return true }
        return UserDefaults.standard.bool(forKey: "showMenuBarIcon")
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 390, height: 560)
        popover.animates = true
    }

    private func configureStatusItem() {
        if menuBarIconVisible {
            createStatusItemIfNeeded()
        } else {
            removeStatusItem()
        }
    }

    private func createStatusItemIfNeeded() {
        guard statusItem == nil else { return }
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            if let icon = NSImage(named: "MenuBarIcon") {
                icon.isTemplate = true
                button.image = icon
                button.imagePosition = .imageOnly
            } else {
                button.image = nil
                button.title = "tmux"
            }
            button.toolTip = "Tmux Kit"
            button.setAccessibilityLabel("Tmux Kit")
            button.target = self
            button.action = #selector(togglePopover(_:))
        }
        statusItem = item
    }

    private func removeStatusItem() {
        popover.performClose(nil)
        if let statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
            self.statusItem = nil
        }
    }

    @objc private func togglePopover(_ sender: Any?) {
        guard let button = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(sender)
            return
        }
        popover.contentViewController = NSHostingController(
            rootView: MenuBarPopoverView().environment(appState)
        )
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
        Task { await appState.refresh() }
    }
}
