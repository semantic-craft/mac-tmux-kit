import KeyboardShortcuts

/// User-rebindable global hotkeys. KeyboardShortcuts persists overrides to
/// UserDefaults and supplies a `Recorder` view for the Settings keybindings tab.
/// (KeyboardShortcuts uses Carbon hotkeys, so this needs no Accessibility grant.)
extension KeyboardShortcuts.Name {
    // No default bindings — the app ships with global hotkeys unset so it never
    // claims a shortcut the user wants for something else. Set them under
    // Settings → Keybindings. (Existing installs are cleared once at launch; see
    // AppState.clearDefaultHotkeysOnce.)
    static let toggleCommandPalette = Self("toggleCommandPalette")

    /// Switch + focus the most recently active other session.
    static let switchRecentSession = Self("switchRecentSession")

    /// Open / focus the Dashboard window.
    static let toggleDashboard = Self("toggleDashboard")
}
