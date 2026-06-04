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
    case general, keybindings, focus
    var id: Self { self }
    var title: String {
        switch self {
        case .general: "General"
        case .keybindings: "Keybindings"
        case .focus: "Focus"
        }
    }
    var icon: String {
        switch self {
        case .general: "gearshape"
        case .keybindings: "command"
        case .focus: "scope"
        }
    }
}

// MARK: - General

private struct GeneralPane: View {
    @AppStorage("tmuxBinaryPath") private var tmuxOverride = ""
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
            Section("Global") {
                KeyboardShortcuts.Recorder("Command palette", name: .toggleCommandPalette)
            }
            Section {
                Text("Press a shortcut to record it. The palette opens over any app.")
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
                            .foregroundStyle(granted ? .green : .orange)
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
