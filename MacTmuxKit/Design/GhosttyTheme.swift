import SwiftUI
import os

/// The colors Tmux Kit borrows from the user's terminal so the GUI matches
/// whatever Ghostty theme they run: the captured-pane canvas, the status colors,
/// the accent, and the selection fill. Roles are mapped from the standard ANSI
/// slots, so this generalizes across themes (light or dark).
struct GhosttyPalette {
    let background: Color   // Ghostty `background`            → terminal canvas
    let foreground: Color   // Ghostty `foreground`            → terminal text
    let selection: Color    // Ghostty `selection-background`  → selected-row fill
    let red: Color          // ANSI 1 → danger
    let green: Color        // ANSI 2 → accent / attached / success
    let yellow: Color       // ANSI 3 → warning
    let blue: Color         // ANSI 4 → alternate accent (available)

    /// Baked Flexoki Light — the user's theme when this was written, and a safe
    /// default when Ghostty isn't installed or its config can't be read.
    static let flexokiFallback = GhosttyPalette(
        background: Color(hex: 0xFFFCF0),
        foreground: Color(hex: 0x100F0F),
        selection: Color(hex: 0xCECDC3),
        red: Color(hex: 0xAF3029),
        green: Color(hex: 0x66800B),
        yellow: Color(hex: 0xAD8301),
        blue: Color(hex: 0x205EA6)
    )
}

/// Reads the user's live Ghostty theme by running `ghostty +show-config` and
/// mapping its resolved colors onto a `GhosttyPalette`. Best-effort: any failure
/// (Ghostty absent, non-zero exit, unparseable output, missing core colors)
/// returns nil and the caller falls back to `GhosttyPalette.flexokiFallback`.
enum GhosttyTheme {
    private static let log = Logger(subsystem: "com.gakalone.MacTmuxKit", category: "theme")

    /// `+show-config` is a headless CLI action — it prints the resolved config and
    /// exits without opening a terminal window.
    static let candidatePaths = [
        "/Applications/Ghostty.app/Contents/MacOS/ghostty",
        "\(NSHomeDirectory())/Applications/Ghostty.app/Contents/MacOS/ghostty",
        "/opt/homebrew/bin/ghostty",
        "/usr/local/bin/ghostty",
    ]

    static func resolve() -> GhosttyPalette? {
        guard let bin = locate() else {
            log.notice("Ghostty binary not found; using baked Flexoki theme")
            return nil
        }
        guard let config = showConfig(bin) else {
            log.notice("ghostty +show-config failed; using baked Flexoki theme")
            return nil
        }
        return parse(config)
    }

    // MARK: - Steps

    private static func locate() -> URL? {
        let fm = FileManager.default
        for path in candidatePaths where fm.isExecutableFile(atPath: path) {
            return URL(fileURLWithPath: path)
        }
        return nil
    }

    private static func showConfig(_ binary: URL) -> String? {
        let process = Process()
        process.executableURL = binary
        process.arguments = ["+show-config"]
        let outPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
        } catch {
            return nil
        }
        // Drain fully before waiting so a large config can't deadlock the pipe.
        let data = outPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return nil }
        return String(decoding: data, as: UTF8.self)
    }

    private static func parse(_ config: String) -> GhosttyPalette? {
        var background: Color?
        var foreground: Color?
        var selection: Color?
        var palette: [Int: Color] = [:]

        for rawLine in config.split(separator: "\n") {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard let eq = line.firstIndex(of: "=") else { continue }
            let key = line[..<eq].trimmingCharacters(in: .whitespaces)
            let value = line[line.index(after: eq)...].trimmingCharacters(in: .whitespaces)

            switch key {
            case "background": background = color(value)
            case "foreground": foreground = color(value)
            case "selection-background": selection = color(value)
            case "palette":
                // value looks like "1=#af3029"
                guard let split = value.firstIndex(of: "=") else { continue }
                let index = Int(value[..<split].trimmingCharacters(in: .whitespaces))
                let hex = value[value.index(after: split)...].trimmingCharacters(in: .whitespaces)
                if let index, let parsed = color(hex) { palette[index] = parsed }
            default: break
            }
        }

        guard let bg = background, let fg = foreground,
              let red = palette[1], let green = palette[2],
              let yellow = palette[3], let blue = palette[4] else {
            log.notice("Ghostty config missing core colors; using baked Flexoki theme")
            return nil
        }
        log.notice("Ghostty theme resolved from live config")
        return GhosttyPalette(
            background: bg,
            foreground: fg,
            selection: selection ?? GhosttyPalette.flexokiFallback.selection,
            red: red, green: green, yellow: yellow, blue: blue
        )
    }

    /// Parse a Ghostty color value into a `Color`. Accepts `#rrggbb`, `rrggbb`,
    /// and `rgb:rr/gg/bb`; returns nil for color names or other formats.
    private static func color(_ string: String) -> Color? {
        var hex = string
        if hex.hasPrefix("rgb:") {
            let parts = hex.dropFirst(4).split(separator: "/")
            guard parts.count == 3 else { return nil }
            hex = parts.map { String($0.prefix(2)) }.joined()
        }
        if hex.hasPrefix("#") { hex.removeFirst() }
        guard hex.count == 6, let rgb = UInt32(hex, radix: 16) else { return nil }
        return Color(hex: rgb)
    }
}
