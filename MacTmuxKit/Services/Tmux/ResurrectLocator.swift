import Foundation

/// Locates the tmux-resurrect plugin scripts and last-save file. Like the tmux
/// binary path, these are NOT hardcoded — TPM, XDG, and Homebrew layouts differ.
enum ResurrectLocator {
    private static let scriptCandidates = [
        "~/.tmux/plugins/tmux-resurrect/scripts",
        "~/.local/share/tmux/plugins/tmux-resurrect/scripts",
        "~/.config/tmux/plugins/tmux-resurrect/scripts",
        "/opt/homebrew/share/tmux-resurrect/scripts",
        "/usr/local/share/tmux-resurrect/scripts",
    ]
    private static let lastSaveCandidates = [
        "~/.local/share/tmux/resurrect/last",
        "~/.tmux/resurrect/last",
    ]

    /// Directory containing save.sh / restore.sh, or nil if the plugin isn't found.
    static func scriptsDir(override: String? = nil) -> URL? {
        let fm = FileManager.default
        let candidates = (override.map { [$0] } ?? []) + scriptCandidates
        for raw in candidates where !raw.isEmpty {
            let dir = (raw as NSString).expandingTildeInPath
            if fm.fileExists(atPath: dir + "/save.sh") {
                return URL(fileURLWithPath: dir)
            }
        }
        return nil
    }

    /// Modification time of the most recent resurrect save, if any.
    static func lastSaveDate() -> Date? {
        let fm = FileManager.default
        for raw in lastSaveCandidates {
            let path = (raw as NSString).expandingTildeInPath
            if let attrs = try? fm.attributesOfItem(atPath: path),
               let date = attrs[.modificationDate] as? Date {
                return date
            }
        }
        return nil
    }
}
