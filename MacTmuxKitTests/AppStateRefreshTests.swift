import XCTest
import TmuxKitCore
@testable import MacTmuxKit

@MainActor
final class AppStateRefreshTests: XCTestCase {
    func testEmptyTmuxStateShowsEmptyMessage() async {
        let app = AppState(
            stateReader: FakeTmuxStateReader([.snapshot(.empty)]),
            preloadTheme: false
        )

        await app.refresh()

        XCTAssertTrue(app.sessions.isEmpty)
        XCTAssertEqual(app.statusMessage, "No tmux sessions.")
        XCTAssertFalse(app.isLoading)
    }

    func testTmuxAccessFailureShowsErrorMessage() async {
        let app = AppState(
            stateReader: FakeTmuxStateReader([.error(.cli(stderr: "socket denied", code: 1))]),
            preloadTheme: false
        )

        await app.refresh()

        XCTAssertTrue(app.sessions.isEmpty)
        XCTAssertEqual(app.statusMessage, "socket denied")
        XCTAssertNotEqual(app.statusMessage, "No tmux sessions.")
        XCTAssertFalse(app.isLoading)
    }

    func testRefreshRequestedWhileLoadingRunsFollowUpRefresh() async {
        let reader = FakeTmuxStateReader(
            [
                .snapshot(.session(name: "first", activity: 1)),
                .snapshot(.session(name: "second", activity: 2)),
            ],
            holdFirstSessionRead: true
        )
        let app = AppState(stateReader: reader, preloadTheme: false)

        let firstRefresh = Task { await app.refresh() }
        await reader.waitForHeldSessionRead()

        await app.refresh()
        await reader.releaseHeldSessionRead()
        await firstRefresh.value

        XCTAssertEqual(app.sessions.map(\.name), ["second"])
        let sessionReadCount = await reader.sessionReadCount
        XCTAssertEqual(sessionReadCount, 2)
        XCTAssertFalse(app.isLoading)
    }
}

private struct TmuxSnapshot: Sendable {
    var sessions: [TmuxSession]
    var windows: [TmuxWindow]
    var panes: [TmuxPane]
    var hostShort: String

    static let empty = TmuxSnapshot(sessions: [], windows: [], panes: [], hostShort: "mac")

    static func session(name: String, activity: TimeInterval) -> TmuxSnapshot {
        let session = TmuxSession(
            id: "$\(Int(activity))",
            name: name,
            attached: false,
            windowCount: 0,
            created: Date(timeIntervalSince1970: 1),
            activity: Date(timeIntervalSince1970: activity),
            path: "/tmp"
        )
        return TmuxSnapshot(sessions: [session], windows: [], panes: [], hostShort: "mac")
    }
}

private enum FakeResponse: Sendable {
    case snapshot(TmuxSnapshot)
    case error(TmuxError)
}

private actor FakeTmuxStateReader: TmuxStateReading {
    private let responses: [FakeResponse]
    private let holdFirstSessionRead: Bool
    private var heldSessionRead: CheckedContinuation<Void, Never>?
    private(set) var sessionReadCount = 0

    init(_ responses: [FakeResponse], holdFirstSessionRead: Bool = false) {
        self.responses = responses
        self.holdFirstSessionRead = holdFirstSessionRead
    }

    func waitForHeldSessionRead() async {
        while heldSessionRead == nil {
            try? await Task.sleep(nanoseconds: 1_000_000)
        }
    }

    func releaseHeldSessionRead() {
        heldSessionRead?.resume()
        heldSessionRead = nil
    }

    func listSessions() async throws -> [TmuxSession] {
        sessionReadCount += 1
        if holdFirstSessionRead, sessionReadCount == 1 {
            await withCheckedContinuation { continuation in
                heldSessionRead = continuation
            }
        }
        return try currentSnapshot().sessions
    }

    func listAllWindows() async throws -> [TmuxWindow] {
        try currentSnapshot().windows
    }

    func listAllPanes() async throws -> [TmuxPane] {
        try currentSnapshot().panes
    }

    func hostShort() async throws -> String {
        try currentSnapshot().hostShort
    }

    private func currentSnapshot() throws -> TmuxSnapshot {
        let index = min(max(sessionReadCount - 1, 0), responses.count - 1)
        switch responses[index] {
        case .snapshot(let snapshot):
            return snapshot
        case .error(let error):
            throw error
        }
    }
}
