import AppKit

/// Finds the Ghostty window currently showing a tmux session and raises it.
///
/// Matching relies on tmux `set-titles` making the terminal window title reflect
/// the session. With the default `set-titles-string "#S: ..."` the title is
/// `"<session>: <cwd>"`; with the recommended `"tmux:#S"` it is `"tmux:<session>"`.
/// Both are handled. Window-level focus is reliable; tab-level focus within one
/// Ghostty window is a known limitation (see plan).
@MainActor
final class GhosttyFocusService {
    static let bundleID = "com.mitchellh.ghostty"

    private var didPrompt = false

    var hasPermission: Bool { AccessibilityBridge.isTrusted }

    /// Trigger the system Accessibility prompt once per launch.
    func ensurePermission() {
        guard !AccessibilityBridge.isTrusted, !didPrompt else { return }
        didPrompt = true
        AccessibilityBridge.promptForTrust()
    }

    /// Raise the Ghostty window showing `sessionName`. Returns false if no
    /// permission, no Ghostty, or no matching window.
    @discardableResult
    func focusWindow(forSession sessionName: String) -> Bool {
        guard AccessibilityBridge.isTrusted else {
            ensurePermission()
            return false
        }
        let windows = AccessibilityBridge.windows(ofAppWithBundleID: Self.bundleID)
        guard let match = bestMatch(in: windows, session: sessionName) else { return false }
        AccessibilityBridge.raise(match)
        AccessibilityBridge.runningApp(bundleID: Self.bundleID)?.activate()
        return true
    }

    // MARK: - Matching

    private func bestMatch(
        in windows: [(element: AXUIElement, title: String)],
        session: String
    ) -> AXUIElement? {
        if let strict = windows.first(where: { strictMatch(title: $0.title, session: session) }) {
            return strict.element
        }
        // Fall back to a contains-match only when it's unambiguous.
        let containing = windows.filter { $0.title.contains(session) }
        return containing.count == 1 ? containing.first?.element : nil
    }

    private func strictMatch(title: String, session: String) -> Bool {
        title == session
            || title.hasPrefix("\(session):")
            || title.hasPrefix("\(session) ")
            || title.hasPrefix("tmux:\(session)")
    }
}
