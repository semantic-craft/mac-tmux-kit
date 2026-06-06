import SwiftUI
import ServiceManagement
import KeyboardShortcuts

/// Settings window: a sidebar of tabs + grouped Forms with the liquid-glass
/// formula from macos-app-skills (`.formStyle(.grouped)` +
/// `.scrollContentBackground(.hidden)`).
struct SettingsView: View {
    @Environment(AppState.self) private var app
    @State private var tab: SettingsTab = .general

    var body: some View {
        NavigationSplitView {
            List(SettingsTab.allCases, selection: $tab) { item in
                Label(item.title, systemImage: item.icon).tag(item)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 180, ideal: 190, max: 220)
            .toolbar(removing: .sidebarToggle)
        } detail: {
            Group {
                switch tab {
                case .general: GeneralPane()
                case .keybindings: KeybindingsPane()
                case .focus: FocusPane()
                case .backup: BackupPane()
                }
            }
            .navigationTitle(tab.title)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(minWidth: 640, minHeight: 460)
        .onAppear { AppActivationPolicy.enter() }
        .onDisappear { AppActivationPolicy.leave() }
    }
}

enum SettingsTab: String, CaseIterable, Identifiable {
    case general, keybindings, focus, backup
    var id: Self { self }
    var title: String {
        switch self {
        case .general: "General"
        case .keybindings: "Keybindings"
        case .focus: "Focus"
        case .backup: "Backup"
        }
    }
    var icon: String {
        switch self {
        case .general: "gearshape"
        case .keybindings: "command"
        case .focus: "scope"
        case .backup: "tray.and.arrow.down"
        }
    }
}

// MARK: - General

private struct GeneralPane: View {
    @AppStorage("tmuxBinaryPath") private var tmuxOverride = ""
    @AppStorage("showMenuBarIcon") private var showMenuBarIcon = true
    @AppStorage("sessionClickAction") private var sessionClickAction = SessionClickAction.switchAndFocus
    @AppStorage("showDockIcon") private var showDockIcon = false
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    private var detectedPath: String {
        TmuxBinaryLocator.locate(override: tmuxOverride.isEmpty ? nil : tmuxOverride)?.path
            ?? "Not found"
    }

    var body: some View {
        Form {
            Section("tmux") {
                LabeledContent("Detected", value: detectedPath)
                TextField("Override path", text: $tmuxOverride, prompt: Text("Auto-detect"))
                Text("Leave blank to auto-detect. Changes apply on next launch.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("Sessions") {
                Picker("Clicking a session", selection: $sessionClickAction) {
                    ForEach(SessionClickAction.allCases, id: \.self) { action in
                        Text(action.title).tag(action)
                    }
                }
                Text("What happens when you click a session in the menu bar.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("Menu bar") {
                Toggle("Show menu bar icon", isOn: $showMenuBarIcon)
                Toggle("Show Dock icon", isOn: $showDockIcon)
                    .onChange(of: showDockIcon) { _, _ in AppActivationPolicy.applyDockPreference() }
                Text("When hidden, summon the app with your global shortcuts: Dashboard (⌘⌃⌥⇧D) and Command palette (⌥⌘T). Set them under Keybindings.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("Startup") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, on in setLaunchAtLogin(on) }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    }

    private func setLaunchAtLogin(_ on: Bool) {
        do {
            if on { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
        } catch {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}

// MARK: - Keybindings

private struct KeybindingsPane: View {
    var body: some View {
        Form {
            Section("Global shortcuts") {
                KeyboardShortcuts.Recorder("Command palette", name: .toggleCommandPalette)
                KeyboardShortcuts.Recorder("Open Dashboard", name: .toggleDashboard)
                KeyboardShortcuts.Recorder("Switch to recent session", name: .switchRecentSession)
            }
            Section {
                Text("Click a field and press a key combination to record it. These work over any app.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Focus

private struct FocusPane: View {
    @Environment(AppState.self) private var app
    @State private var granted = AccessibilityBridge.isTrusted

    var body: some View {
        Form {
            Section("Accessibility") {
                LabeledContent("Permission") {
                    HStack(spacing: 6) {
                        Image(systemName: granted
                            ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(granted ? Theme.success : Theme.warning)
                        Text(granted ? "Granted" : "Not granted")
                    }
                }
                Button("Open Accessibility Settings") { app.openAccessibilitySettings() }
                Text("Required to bring the Ghostty window forward when you switch sessions.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("tmux window titles") {
                Button("Install recommended title format") {
                    Task { await app.installTitleFormat() }
                }
                Text("Sets the running server to title windows as \"tmux:<session>\", which makes window focusing reliable.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .task {
            // Live-poll so the status flips to "Granted" without reopening.
            while !Task.isCancelled {
                granted = AccessibilityBridge.isTrusted
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }
}

// MARK: - Backup (tmux-resurrect)

private struct BackupPane: View {
    @Environment(AppState.self) private var app
    @AppStorage("resurrectScriptsPath") private var override = ""
    @State private var status = ""
    @State private var working = false
    @State private var confirmRestore = false

    var body: some View {
        Form {
            Section("tmux-resurrect") {
                LabeledContent("Scripts", value: app.resurrectScriptsDir?.path ?? "Not found")
                LabeledContent("Last saved", value: lastSavedText)
                TextField("Scripts path override", text: $override, prompt: Text("Auto-detect"))
            }
            Section {
                HStack(spacing: 10) {
                    Button("Save layout now") { perform { await app.resurrectSave() } }
                        .disabled(!app.resurrectAvailable || working)
                    Button("Restore last layout") { confirmRestore = true }
                        .disabled(!app.resurrectAvailable || working)
                    if working { ProgressView().controlSize(.small) }
                }
                if !status.isEmpty {
                    Text(status).font(.caption).foregroundStyle(.secondary)
                }
                if !app.resurrectAvailable {
                    Text("Install the tmux-resurrect plugin, or set its scripts path above.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .confirmationDialog("Restore last saved layout?", isPresented: $confirmRestore) {
            Button("Restore", role: .destructive) { perform { await app.resurrectRestore() } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This recreates the saved sessions, windows, and panes.")
        }
    }

    private var lastSavedText: String {
        guard let date = app.resurrectLastSaved() else { return "Never" }
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }

    private func perform(_ op: @escaping () async -> String?) {
        working = true
        status = ""
        Task {
            let error = await op()
            working = false
            status = error ?? "Done."
        }
    }
}
