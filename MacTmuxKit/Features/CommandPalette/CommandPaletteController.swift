import AppKit
import SwiftUI

/// Borderless floating panel that can take keyboard focus without forcing the
/// app to a regular activation state.
final class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

/// Owns the command-palette panel and shows/hides it. Closes on focus loss.
@MainActor
final class CommandPaletteController: NSObject, NSWindowDelegate {
    private var panel: NSPanel?
    private weak var appState: AppState?

    init(appState: AppState) {
        self.appState = appState
        super.init()
    }

    func toggle() {
        if let panel, panel.isVisible { close() } else { show() }
    }

    func show() {
        guard let appState else { return }
        let panel = panel ?? makePanel()
        self.panel = panel

        // Fresh content each time so the query/selection reset.
        let root = CommandPaletteView(dismiss: { [weak self] in self?.close() })
            .environment(appState)
        panel.contentViewController = NSHostingController(rootView: root)

        positionCenter(panel)
        NSApp.activate()
        panel.makeKeyAndOrderFront(nil)
    }

    func close() { panel?.orderOut(nil) }

    func windowDidResignKey(_ notification: Notification) { close() }

    private func positionCenter(_ panel: NSPanel) {
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        let size = panel.frame.size
        panel.setFrameOrigin(NSPoint(
            x: visible.midX - size.width / 2,
            y: visible.midY - size.height / 2 + 100
        ))
    }

    private func makePanel() -> NSPanel {
        let panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 380),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.delegate = self
        return panel
    }
}
