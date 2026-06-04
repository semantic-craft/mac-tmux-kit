import XCTest
@testable import TmuxKitCore

/// Parser tests built from REAL captured tmux output (see plan §验证策略).
/// Fixtures are assembled by joining fields with the 0x1F unit separator so the
/// test source stays readable.
final class TmuxParserTests: XCTestCase {
    private let us = String(TmuxFormat.unitSeparator)

    private func row(_ fields: [String]) -> String { fields.joined(separator: us) }
    private func block(_ rows: [[String]]) -> String { rows.map(row).joined(separator: "\n") }

    // MARK: - Sessions

    func testParseSessions() {
        let raw = block([
            ["$47", "develop", "1", "3", "1780476888", "1780545950", "/Users/x/Projects/web-app"],
            ["$46", "api", "0", "1", "1780407831", "1780407831", "/Users/x/.cache/api-preview"],
            ["$33", "docs", "0", "2", "1780355028", "1780460485", "/Users/x/Documents/笔记_示例_中文"],
        ])

        let sessions = TmuxParser.sessions(raw)

        XCTAssertEqual(sessions.count, 3)
        XCTAssertEqual(sessions[0].id, "$47")
        XCTAssertEqual(sessions[0].name, "develop")
        XCTAssertTrue(sessions[0].attached)
        XCTAssertEqual(sessions[0].windowCount, 3)
        XCTAssertEqual(sessions[0].created, Date(timeIntervalSince1970: 1780476888))
        XCTAssertEqual(sessions[0].activity, Date(timeIntervalSince1970: 1780545950))

        XCTAssertFalse(sessions[1].attached)
        // Chinese characters in the path survive intact.
        XCTAssertEqual(sessions[2].path, "/Users/x/Documents/笔记_示例_中文")
    }

    // MARK: - Windows

    func testParseWindowsPreservesLayoutAndDottedNames() {
        // window_layout contains commas, braces, brackets — this is exactly why a
        // comma/tab separator would break and the 0x1F separator is required.
        let layout = "8de0,186x49,0,0{86x49,0,0[86x34,0,0,89,86x14,0,35,97],99x49,87,0[99x26,87,0,91]}"
        let raw = block([
            ["$47", "@55", "0", "2.1.162", "1", "4", layout],
            ["$47", "@57", "1", "BTT", "0", "1", "69f6,186x49,0,0,93"],
        ])

        let windows = TmuxParser.windows(raw)

        XCTAssertEqual(windows.count, 2)
        XCTAssertEqual(windows[0].id, "@55")
        XCTAssertEqual(windows[0].index, 0)
        XCTAssertEqual(windows[0].name, "2.1.162")        // dotted name survives
        XCTAssertTrue(windows[0].active)
        XCTAssertEqual(windows[0].paneCount, 4)
        XCTAssertEqual(windows[0].layout, layout)         // layout intact, commas and all
        XCTAssertEqual(windows[0].target, "$47:0")
        XCTAssertEqual(windows[1].name, "BTT")
    }

    // MARK: - Panes

    func testParsePanes() {
        let raw = block([
            ["$47", "@55", "%97", "1", "1", "2.1.162", "99143", "86", "14", "/Users/x/Projects/mac-tmux-kit", "tmux-pane", "0", "35"],
            ["$33", "@53", "%87", "0", "0", "nvim", "97963", "109", "53", "/Users/x/Documents/草稿_示例", "", "0", "0"],
        ])

        let panes = TmuxParser.panes(raw)

        XCTAssertEqual(panes.count, 2)
        XCTAssertEqual(panes[0].id, "%97")
        XCTAssertEqual(panes[0].windowId, "@55")
        XCTAssertEqual(panes[0].index, 1)
        XCTAssertTrue(panes[0].active)
        XCTAssertEqual(panes[0].command, "2.1.162")
        XCTAssertEqual(panes[0].pid, 99143)
        XCTAssertEqual(panes[0].width, 86)
        XCTAssertEqual(panes[0].height, 14)
        XCTAssertEqual(panes[0].path, "/Users/x/Projects/mac-tmux-kit")
        XCTAssertEqual(panes[0].left, 0)
        XCTAssertEqual(panes[0].top, 35)
        // Empty title field is preserved, not dropped.
        XCTAssertEqual(panes[1].title, "")
        XCTAssertFalse(panes[1].active)
    }

    // MARK: - Clients

    func testParseClients() {
        let raw = row(["/dev/ttys009", "develop", "87142", "xterm-ghostty"])
        let clients = TmuxParser.clients(raw)

        XCTAssertEqual(clients.count, 1)
        XCTAssertEqual(clients[0].tty, "/dev/ttys009")
        XCTAssertEqual(clients[0].sessionName, "develop")  // name, not id
        XCTAssertEqual(clients[0].pid, 87142)
        XCTAssertEqual(clients[0].termName, "xterm-ghostty")
    }

    // MARK: - Edge cases

    func testEmptyInputYieldsEmpty() {
        XCTAssertTrue(TmuxParser.sessions("").isEmpty)
        XCTAssertTrue(TmuxParser.windows("\n").isEmpty)
        // Whitespace-only lines have too few fields → skipped, not crashed.
        XCTAssertTrue(TmuxParser.panes("   \n  ").isEmpty)
    }

    func testSkipsMalformedRecords() {
        // A line with too few fields must be skipped, not crash.
        let raw = block([
            ["$47", "develop", "1", "3", "1780476888", "1780545950", "/Users/x"],
            ["$bad", "only-two"],
        ])
        let sessions = TmuxParser.sessions(raw)
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions[0].id, "$47")
    }
}
