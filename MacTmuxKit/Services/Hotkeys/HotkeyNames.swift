import KeyboardShortcuts

/// User-rebindable global hotkeys. KeyboardShortcuts persists overrides to
/// UserDefaults and supplies a `Recorder` view for the Settings keybindings tab.
/// (KeyboardShortcuts uses Carbon hotkeys, so this needs no Accessibility grant.)
extension KeyboardShortcuts.Name {
    static let toggleCommandPalette = Self(
        "toggleCommandPalette",
        default: .init(.t, modifiers: [.command, .option])
    )
}
