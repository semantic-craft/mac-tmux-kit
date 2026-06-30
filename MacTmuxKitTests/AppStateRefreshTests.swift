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

    func testPreviewPaneUsesActivePane() async {
        let app = AppState(
            stateReader: FakeTmuxStateReader([
                .snapshot(.session(name: "work", panes: [
                    .pane(id: "%1", active: false),
                    .pane(id: "%2", active: true),
                ]))
            ]),
            preloadTheme: false
        )

        await app.refresh()

        XCTAssertEqual(app.previewPane(in: "$1")?.id, "%2")
    }

    func testPreviewPaneFallsBackToFirstPane() async {
        let app = AppState(
            stateReader: FakeTmuxStateReader([
                .snapshot(.session(name: "quiet", panes: [
                    .pane(id: "%3", active: false),
                    .pane(id: "%4", active: false),
                ]))
            ]),
            preloadTheme: false
        )

        await app.refresh()

        XCTAssertEqual(app.previewPane(in: "$1")?.id, "%3")
    }

    func testCapturePreviewContainsFailure() async {
        let reader = FakeTmuxStateReader(
            [.snapshot(.session(name: "broken", panes: [.pane(id: "%5", active: true)]))],
            captures: ["%5": .error(.noSuchTarget("can't find pane: %5"))]
        )
        let app = AppState(stateReader: reader, paneCapturer: reader, preloadTheme: false)

        await app.refresh()
        let preview = await app.capturePreview(app.previewPane(in: "$1")!)

        XCTAssertTrue(preview.failed)
        XCTAssertEqual(preview.content, "")
        XCTAssertEqual(preview.errorMessage, "can't find pane: %5")
    }

    func testPinnedSessionsLeadMenuBarOrdering() async {
        let defaults = FakeDefaults(pinnedSessionNames: ["alpha"])
        let app = AppState(
            stateReader: FakeTmuxStateReader([
                .snapshot(.sessions([
                    .session(id: "$1", name: "alpha", activity: 1),
                    .session(id: "$2", name: "beta", activity: 3),
                    .session(id: "$3", name: "gamma", activity: 2),
                ]))
            ]),
            defaults: defaults,
            preloadTheme: false
        )

        await app.refresh()

        XCTAssertEqual(app.sessions.map(\.name), ["beta", "gamma", "alpha"])
        XCTAssertEqual(app.pinnedFirstSessions(limit: 3).map(\.name), ["alpha", "beta", "gamma"])
    }

    func testPinnedSessionNamesPersistAcrossAppRestart() {
        let defaults = FakeDefaults()
        let firstLaunch = AppState(stateReader: FakeTmuxStateReader([.snapshot(.empty)]), defaults: defaults, preloadTheme: false)

        firstLaunch.pinSession(.session(id: "$1", name: "work", activity: 1))
        let restarted = AppState(stateReader: FakeTmuxStateReader([.snapshot(.empty)]), defaults: defaults, preloadTheme: false)

        XCTAssertTrue(restarted.pinnedSessionNames.contains("work"))
    }

    func testPinnedSessionNameMigratesAfterRename() async {
        let defaults = FakeDefaults(pinnedSessionNames: ["work"])
        let reader = FakeTmuxStateReader([
            .snapshot(.sessions([.session(id: "$1", name: "work", activity: 1)])),
            .snapshot(.sessions([.session(id: "$1", name: "client-a", activity: 2)])),
        ])
        let app = AppState(
            service: TmuxService(binary: URL(fileURLWithPath: "/usr/bin/true")),
            stateReader: reader,
            defaults: defaults,
            preloadTheme: false
        )

        await app.refresh()
        await app.renameSession(app.sessions[0], to: "client-a")

        XCTAssertFalse(app.pinnedSessionNames.contains("work"))
        XCTAssertTrue(app.pinnedSessionNames.contains("client-a"))

        let restarted = AppState(stateReader: FakeTmuxStateReader([.snapshot(.empty)]), defaults: defaults, preloadTheme: false)
        XCTAssertFalse(restarted.pinnedSessionNames.contains("work"))
        XCTAssertTrue(restarted.pinnedSessionNames.contains("client-a"))
    }

    func testUnpinnedSessionRenameDoesNotCreatePinnedName() async {
        let defaults = FakeDefaults()
        let reader = FakeTmuxStateReader([
            .snapshot(.sessions([.session(id: "$1", name: "work", activity: 1)])),
            .snapshot(.sessions([.session(id: "$1", name: "client-a", activity: 2)])),
        ])
        let app = AppState(
            service: TmuxService(binary: URL(fileURLWithPath: "/usr/bin/true")),
            stateReader: reader,
            defaults: defaults,
            preloadTheme: false
        )

        await app.refresh()
        await app.renameSession(app.sessions[0], to: "client-a")

        XCTAssertTrue(app.pinnedSessionNames.isEmpty)
    }

    func testUnknownPinnedNamesDoNotCreateLiveRows() async {
        let defaults = FakeDefaults(pinnedSessionNames: ["missing"])
        let app = AppState(
            stateReader: FakeTmuxStateReader([
                .snapshot(.sessions([
                    .session(id: "$1", name: "live", activity: 1),
                ]))
            ]),
            defaults: defaults,
            preloadTheme: false
        )

        await app.refresh()

        XCTAssertEqual(app.pinnedFirstSessions().map(\.name), ["live"])
    }

    func testRecreatedPinnedSessionNameIsPrioritized() async {
        let defaults = FakeDefaults(pinnedSessionNames: ["work"])
        let app = AppState(
            stateReader: FakeTmuxStateReader([
                .snapshot(.sessions([
                    .session(id: "$9", name: "other", activity: 9),
                    .session(id: "$42", name: "work", activity: 1),
                ]))
            ]),
            defaults: defaults,
            preloadTheme: false
        )

        await app.refresh()

        XCTAssertEqual(app.pinnedFirstSessions().first?.id, "$42")
    }

    func testDebugSnapshotContainsMetadataAndKnownSession() async {
        let app = AppState(
            service: TmuxService(binary: URL(fileURLWithPath: "/bin/tmux")),
            stateReader: FakeTmuxStateReader([
                .snapshot(.session(name: "taiwan", panes: [.pane(id: "%9", active: true)]))
            ]),
            preloadTheme: false
        )

        await app.refresh()
        let snapshot = await app.debugSnapshot()

        XCTAssertTrue(snapshot.contains("binary: /bin/tmux"))
        XCTAssertTrue(snapshot.contains("socket: "))
        XCTAssertTrue(snapshot.contains("counts: sessions=1 windows=1 panes=1"))
        XCTAssertTrue(snapshot.contains("$1 \"taiwan\""))
        XCTAssertTrue(snapshot.contains("@1 index=0 active=true name=\"shell\""))
        XCTAssertTrue(snapshot.contains("%9 index=9 active=true command=\"zsh\""))
    }

    func testDebugSnapshotIncludesReadFailures() async {
        let app = AppState(
            service: TmuxService(binary: URL(fileURLWithPath: "/bin/tmux")),
            stateReader: FakeTmuxStateReader([.error(.cli(stderr: "socket denied", code: 1))]),
            preloadTheme: false
        )

        let snapshot = await app.debugSnapshot()

        XCTAssertTrue(snapshot.contains("failures:"))
        XCTAssertTrue(snapshot.contains("listSessions: socket denied"))
        XCTAssertTrue(snapshot.contains("listAllWindows: socket denied"))
        XCTAssertTrue(snapshot.contains("listAllPanes: socket denied"))
        XCTAssertTrue(snapshot.contains("hostShort: socket denied"))
        XCTAssertTrue(snapshot.contains("sessions\n  none"))
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

    static func session(name: String, panes: [TmuxPane]) -> TmuxSnapshot {
        let session = TmuxSession(
            id: "$1",
            name: name,
            attached: false,
            windowCount: panes.isEmpty ? 0 : 1,
            created: Date(timeIntervalSince1970: 1),
            activity: Date(timeIntervalSince1970: 1),
            path: "/tmp"
        )
        let window = TmuxWindow(
            sessionId: "$1",
            id: "@1",
            index: 0,
            name: "shell",
            active: true,
            paneCount: panes.count,
            layout: ""
        )
        return TmuxSnapshot(sessions: [session], windows: panes.isEmpty ? [] : [window], panes: panes, hostShort: "mac")
    }

    static func sessions(_ sessions: [TmuxSession]) -> TmuxSnapshot {
        TmuxSnapshot(sessions: sessions, windows: [], panes: [], hostShort: "mac")
    }
}

private extension TmuxSession {
    static func session(id: String, name: String, activity: TimeInterval) -> TmuxSession {
        TmuxSession(
            id: id,
            name: name,
            attached: false,
            windowCount: 0,
            created: Date(timeIntervalSince1970: 1),
            activity: Date(timeIntervalSince1970: activity),
            path: "/tmp"
        )
    }
}

private extension TmuxPane {
    static func pane(id: String, active: Bool) -> TmuxPane {
        TmuxPane(
            sessionId: "$1",
            windowId: "@1",
            id: id,
            index: Int(id.dropFirst()) ?? 0,
            active: active,
            command: "zsh",
            pid: 123,
            width: 80,
            height: 24,
            path: "/tmp/project",
            title: "",
            left: 0,
            top: 0
        )
    }
}

private enum FakeResponse: Sendable {
    case snapshot(TmuxSnapshot)
    case error(TmuxError)
}

private enum FakeCapture: Sendable {
    case content(String)
    case error(TmuxError)
}

private actor FakeTmuxStateReader: TmuxStateReading, TmuxPaneCapturing {
    private let responses: [FakeResponse]
    private let captures: [String: FakeCapture]
    private let holdFirstSessionRead: Bool
    private var heldSessionRead: CheckedContinuation<Void, Never>?
    private(set) var sessionReadCount = 0

    init(
        _ responses: [FakeResponse],
        captures: [String: FakeCapture] = [:],
        holdFirstSessionRead: Bool = false
    ) {
        self.responses = responses
        self.captures = captures
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

    func capturePane(paneId: String) async throws -> String {
        switch captures[paneId] ?? .content("") {
        case .content(let content):
            return content
        case .error(let error):
            throw error
        }
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

private final class FakeDefaults: UserDefaultsStoring {
    private var arrays: [String: [String]]

    init(pinnedSessionNames: [String] = []) {
        arrays = pinnedSessionNames.isEmpty ? [:] : ["pinnedSessionNames": pinnedSessionNames]
    }

    func stringArray(forKey defaultName: String) -> [String]? {
        arrays[defaultName]
    }

    func set(_ value: Any?, forKey defaultName: String) {
        arrays[defaultName] = value as? [String]
    }

    func synchronize() -> Bool {
        true
    }
}
