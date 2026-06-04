import SwiftUI

/// The 3-column Dashboard (Apple layout formula): sessions sidebar, window/pane
/// content, pane detail. Structural template follows maoyama/Changes.
struct DashboardView: View {
    @Environment(AppState.self) private var app
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedSessionId: String?
    @State private var selectedPaneId: String?

    var body: some View {
        NavigationSplitView {
            SessionSidebar(selectedSessionId: $selectedSessionId)
                .navigationSplitViewColumnWidth(min: 200, ideal: 230, max: 300)
        } content: {
            WindowPaneColumn(sessionId: selectedSessionId, selectedPaneId: $selectedPaneId)
                .navigationSplitViewColumnWidth(min: 260, ideal: 320)
        } detail: {
            PaneDetailColumn(paneId: selectedPaneId)
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
        .task { await app.refresh() }
        .onChange(of: selectedSessionId) { _, _ in selectedPaneId = nil }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                SettingsLink { Image(systemName: "gearshape") }
                    .help("Settings (⌘,)")
            }
        }
    }
}
