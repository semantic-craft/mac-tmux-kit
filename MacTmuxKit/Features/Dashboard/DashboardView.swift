import SwiftUI

/// The 3-column Dashboard (Apple layout formula): sessions sidebar, window/pane
/// content, pane detail. Structural template follows maoyama/Changes.
struct DashboardView: View {
    @Environment(AppState.self) private var app
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedSessionId: String?
    @State private var selectedPaneId: String?
    @State private var previewReloadToken = UUID()

    var body: some View {
        NavigationSplitView {
            SessionSidebar(selectedSessionId: $selectedSessionId) {
                Task { await refreshPreview() }
            }
                .navigationSplitViewColumnWidth(min: 200, ideal: 230, max: 300)
        } content: {
            WindowPaneColumn(sessionId: selectedSessionId, selectedPaneId: $selectedPaneId)
                .navigationSplitViewColumnWidth(min: 260, ideal: 320)
        } detail: {
            PaneDetailColumn(sessionId: selectedSessionId, paneId: selectedPaneId, reloadToken: previewReloadToken)
                .navigationSplitViewColumnWidth(min: 320, ideal: 460)
        }
        .frame(minWidth: 860, minHeight: 500)
        .overlay(alignment: .bottom) {
            if let toast = app.toast {
                ToastView(info: toast)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.25), value: app.toast)
        .task {
            await refreshPreview()
        }
        .onChange(of: app.dashboardRequest) { _, _ in applySelection() }
        .onChange(of: selectedSessionId) { _, id in
            // Selecting a session reveals its active pane immediately.
            selectedPaneId = app.previewPane(in: id)?.id
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { app.showCommandPalette() } label: {
                    Image(systemName: "magnifyingglass")
                }
                .keyboardShortcut("k", modifiers: .command)
                .help("Command Palette (⌘K)")
            }
            ToolbarItem(placement: .primaryAction) {
                Button { app.showCheatsheet() } label: {
                    Image(systemName: "keyboard")
                }
                .keyboardShortcut("/", modifiers: .command)
                .help("tmux Cheatsheet (⌘/)")
            }
            ToolbarItem(placement: .primaryAction) {
                SettingsLink { Image(systemName: "gearshape") }
                    .help("Settings (⌘,)")
            }
        }
    }

    /// Apply a pending "open in Dashboard" request if present, otherwise open
    /// onto the most-recent session — so the window is never an empty shell.
    private func applySelection() {
        if let req = app.dashboardRequest {
            selectedSessionId = req.sessionId
            selectedPaneId = app.previewPane(in: req.sessionId)?.id
        } else if selectedSessionId == nil, let first = app.sessions.first {
            selectedSessionId = first.id
            selectedPaneId = app.previewPane(in: first.id)?.id
        } else if app.pane(id: selectedPaneId)?.sessionId != selectedSessionId {
            selectedPaneId = app.previewPane(in: selectedSessionId)?.id
        }
    }

    private func refreshPreview() async {
        await app.refresh()
        applySelection()
        previewReloadToken = UUID()
    }
}
