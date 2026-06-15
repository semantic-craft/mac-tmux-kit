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

/// A human-oriented pane title for dense lists.
///
/// For agent-heavy tmux layouts the foreground command can be identical in every
/// pane (for example, a tool version string), while the working directory is the
/// useful signal. Prefer a user-set title, then the current folder, and fall back
/// to the command only when there is no path.
public func paneReadableTitle(title: String, command: String, host: String, path: String) -> String {
    if let custom = paneCustomTitle(title: title, command: command, host: host) {
        return custom
    }
    if let folder = pathLastComponent(path), !folder.isEmpty {
        return folder
    }
    let trimmedCommand = command.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmedCommand.isEmpty ? "pane" : trimmedCommand
}

/// Secondary pane context to show below `paneReadableTitle`.
public func paneReadableSubtitle(title: String, command: String, host: String, path: String) -> String? {
    let primary = paneReadableTitle(title: title, command: command, host: host, path: path)
    var parts: [String] = []

    if paneCustomTitle(title: title, command: command, host: host) != nil,
       let folder = pathLastComponent(path),
       !folder.isEmpty,
       folder != primary {
        parts.append(folder)
    }

    let trimmedCommand = command.trimmingCharacters(in: .whitespacesAndNewlines)
    if !trimmedCommand.isEmpty, trimmedCommand != primary {
        parts.append(trimmedCommand)
    }

    return parts.isEmpty ? nil : parts.joined(separator: " · ")
}

/// Last path component for display, preserving `~` for unknown/empty paths.
public func pathLastComponent(_ path: String) -> String? {
    let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }
    return URL(fileURLWithPath: trimmed).lastPathComponent
}
