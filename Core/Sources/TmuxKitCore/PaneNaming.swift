import Foundation

/// The user-set pane title, or `nil` when the title is just tmux's default.
///
/// tmux seeds every `pane_title` with the host name (and some shells set it to
/// the running command), so a title only counts as a real, user-chosen name
/// when it is non-empty and differs from both the host and the command.
public func paneCustomTitle(title: String, command: String, host: String) -> String? {
    let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty, trimmed != host, trimmed != command else { return nil }
    return trimmed
}

/// The label to show for a pane: its custom title when set, else its command.
public func paneDisplayName(title: String, command: String, host: String) -> String {
    paneCustomTitle(title: title, command: command, host: host) ?? command
}
