import Foundation

/// One cheatsheet entry. `keys` is the copyable shortcut or command string.
struct CheatItem: Identifiable, Hashable {
    let section: String
    let title: String
    let keys: String
    var note: String = ""
    var id: String { section + "/" + title }
}

/// Stock tmux defaults (prefix = C-b unless rebound). Grouped by section.
enum Cheatsheet {
    static let sections = [
        "Sessions", "Windows", "Panes", "Copy mode", "Misc", "Command mode", "Resurrect", "Config",
    ]

    static let items: [CheatItem] = [
        // Sessions
        .init(section: "Sessions", title: "Detach", keys: "prefix d"),
        .init(section: "Sessions", title: "List / switch sessions", keys: "prefix s"),
        .init(section: "Sessions", title: "Previous session", keys: "prefix ("),
        .init(section: "Sessions", title: "Next session", keys: "prefix )"),
        .init(section: "Sessions", title: "Rename session", keys: "prefix $"),
        .init(section: "Sessions", title: "New session (shell)", keys: "tmux new -s name"),
        .init(section: "Sessions", title: "Attach (shell)", keys: "tmux attach -t name"),
        .init(section: "Sessions", title: "Kill server (shell)", keys: "tmux kill-server"),

        // Windows
        .init(section: "Windows", title: "New window", keys: "prefix c"),
        .init(section: "Windows", title: "Next window", keys: "prefix n"),
        .init(section: "Windows", title: "Previous window", keys: "prefix p"),
        .init(section: "Windows", title: "Last window", keys: "prefix l"),
        .init(section: "Windows", title: "Select window 0-9", keys: "prefix 0…9"),
        .init(section: "Windows", title: "Window chooser", keys: "prefix w"),
        .init(section: "Windows", title: "Rename window", keys: "prefix ,"),
        .init(section: "Windows", title: "Kill window", keys: "prefix &"),
        .init(section: "Windows", title: "Find window", keys: "prefix f"),

        // Panes
        .init(section: "Panes", title: "Split horizontal", keys: "prefix %", note: "left/right"),
        .init(section: "Panes", title: "Split vertical", keys: "prefix \"", note: "top/bottom"),
        .init(section: "Panes", title: "Move between panes", keys: "prefix ←↑↓→"),
        .init(section: "Panes", title: "Cycle panes", keys: "prefix o"),
        .init(section: "Panes", title: "Show pane numbers", keys: "prefix q"),
        .init(section: "Panes", title: "Zoom / unzoom pane", keys: "prefix z"),
        .init(section: "Panes", title: "Swap with next", keys: "prefix }"),
        .init(section: "Panes", title: "Swap with previous", keys: "prefix {"),
        .init(section: "Panes", title: "Break pane to window", keys: "prefix !"),
        .init(section: "Panes", title: "Toggle layouts", keys: "prefix space"),
        .init(section: "Panes", title: "Resize pane", keys: "prefix C-←↑↓→"),
        .init(section: "Panes", title: "Kill pane", keys: "prefix x"),

        // Copy mode (vi)
        .init(section: "Copy mode", title: "Enter copy mode", keys: "prefix ["),
        .init(section: "Copy mode", title: "Paste buffer", keys: "prefix ]"),
        .init(section: "Copy mode", title: "Start selection (vi)", keys: "v"),
        .init(section: "Copy mode", title: "Copy selection (vi)", keys: "y"),
        .init(section: "Copy mode", title: "Quit copy mode", keys: "q"),
        .init(section: "Copy mode", title: "Search forward", keys: "/"),
        .init(section: "Copy mode", title: "Search backward", keys: "?"),

        // Misc
        .init(section: "Misc", title: "List key bindings", keys: "prefix ?"),
        .init(section: "Misc", title: "Command prompt", keys: "prefix :"),
        .init(section: "Misc", title: "Reload config", keys: "prefix :source-file ~/.tmux.conf"),
        .init(section: "Misc", title: "Show clock", keys: "prefix t"),

        // Command mode (prefix :)
        .init(section: "Command mode", title: "Kill all other sessions", keys: "kill-session -a"),
        .init(section: "Command mode", title: "Move window", keys: "move-window -t name:idx"),
        .init(section: "Command mode", title: "Swap window", keys: "swap-window -t idx"),
        .init(section: "Command mode", title: "Toggle mouse", keys: "set -g mouse on"),
        .init(section: "Command mode", title: "Respawn pane", keys: "respawn-pane -k"),
        .init(section: "Command mode", title: "Display panes", keys: "display-panes"),

        // Resurrect (tmux-resurrect plugin)
        .init(section: "Resurrect", title: "Save layout", keys: "prefix C-s"),
        .init(section: "Resurrect", title: "Restore layout", keys: "prefix C-r"),

        // Config
        .init(section: "Config", title: "User config", keys: "~/.tmux.conf"),
        .init(section: "Config", title: "Plugins dir", keys: "~/.tmux/plugins/"),
    ]
}
