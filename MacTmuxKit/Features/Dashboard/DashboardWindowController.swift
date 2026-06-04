import AppKit
import SwiftUI

/// Hosts the Dashboard in an AppKit-managed window so it can be summoned by a
/// global hotkey reliably — independent of whether the menu-bar icon is shown
/// (a SwiftUI `Window` scene can only be opened from inside the scene graph).
@MainActor
final class DashboardWindowController: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
        super.init()
    }

    func show() {
        if window == nil { window = makeWindow() }
        AppActivationPolicy.enter()
        window?.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        AppActivationPolicy.leave()
    }

    private func makeWindow() -> NSWindow {
        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 980, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        w.title = "Tmux Kit"
        w.isReleasedWhenClosed = false
        w.minSize = NSSize(width: 860, height: 500)
        w.center()
        w.setFrameAutosaveName("TmuxKitDashboard")
        w.contentViewController = NSHostingController(
            rootView: DashboardView().environment(appState)
        )
        w.delegate = self
        return w
    }
}
