import XCTest
@testable import TmuxKitCore

/// Tests for tree grouping + directional neighbor geometry, using the real
/// 4-pane layout of window @55 captured live:
///   layout: 186x49 split into a left column (86 wide) and right column (99 wide).
///   %89 left=0 top=0  86x34   (top-left)
///   %97 left=0 top=35 86x14   (bottom-left)
///   %91 left=87 top=0 99x26   (top-right)
///   %95 left=87 top=27 99x22  (bottom-right)
final class TmuxTreeTests: XCTestCase {
    private func pane(_ id: String, _ left: Int, _ top: Int, _ w: Int, _ h: Int) -> TmuxPane {
        TmuxPane(
            sessionId: "$47", windowId: "@55", id: id, index: 0, active: false,
            command: "zsh", pid: 1, width: w, height: h, path: "/", title: "",
            left: left, top: top
        )
    }

    private func tree() -> TmuxTree {
        let panes = [
            pane("%89", 0, 0, 86, 34),
            pane("%97", 0, 35, 86, 14),
            pane("%91", 87, 0, 99, 26),
            pane("%95", 87, 27, 99, 22),
        ]
        let windows = [
            TmuxWindow(sessionId: "$47", id: "@55", index: 0, name: "main",
                       active: true, paneCount: 4, layout: "")
        ]
        let sessions = [
            TmuxSession(id: "$47", name: "develop", attached: true, windowCount: 1,
                        created: .init(timeIntervalSince1970: 0),
                        activity: .init(timeIntervalSince1970: 0), path: "/")
        ]
        return TmuxTree(sessions: sessions, windows: windows, panes: panes)
    }

    func testGrouping() {
        let t = tree()
        XCTAssertEqual(t.windows(in: "$47").map(\.id), ["@55"])
        XCTAssertEqual(t.panes(in: "@55").map(\.id), ["%89", "%97", "%91", "%95"])
        XCTAssertTrue(t.panes(in: "@nope").isEmpty)
    }

    func testNeighbors() {
        let t = tree()
        let topLeft = t.panes(in: "@55").first { $0.id == "%89" }!

        // Right of top-left is the top-right pane (overlaps more than bottom-right).
        XCTAssertEqual(t.neighbor(of: topLeft, .right)?.id, "%91")
        // Down of top-left is the bottom-left pane.
        XCTAssertEqual(t.neighbor(of: topLeft, .down)?.id, "%97")
        // No pane to the left of, or above, the top-left pane.
        XCTAssertNil(t.neighbor(of: topLeft, .left))
        XCTAssertNil(t.neighbor(of: topLeft, .up))

        let bottomRight = t.panes(in: "@55").first { $0.id == "%95" }!
        XCTAssertEqual(t.neighbor(of: bottomRight, .up)?.id, "%91")
        XCTAssertEqual(t.neighbor(of: bottomRight, .left)?.id, "%97")
    }
}
