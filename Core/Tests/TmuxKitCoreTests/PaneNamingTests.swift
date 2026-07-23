import XCTest
@testable import TmuxKitCore

/// tmux defaults every `pane_title` to the host name, so a title only counts as
/// a user-set name when it is non-empty and differs from the host and command.
final class PaneNamingTests: XCTestCase {
    private let host = "example-mac"

    func testDefaultHostTitleIsNotCustom() {
        XCTAssertNil(paneCustomTitle(title: host, command: "bash", host: host))
        XCTAssertEqual(paneDisplayName(title: host, command: "bash", host: host), "bash")
    }

    func testEmptyTitleFallsBackToCommand() {
        XCTAssertNil(paneCustomTitle(title: "", command: "ping", host: host))
        XCTAssertEqual(paneDisplayName(title: "", command: "ping", host: host), "ping")
    }

    func testTitleEqualToCommandIsNotCustom() {
        XCTAssertNil(paneCustomTitle(title: "vim", command: "vim", host: host))
        XCTAssertEqual(paneDisplayName(title: "vim", command: "vim", host: host), "vim")
    }

    func testCustomTitleIsUsed() {
        XCTAssertEqual(paneCustomTitle(title: "api server", command: "node", host: host), "api server")
        XCTAssertEqual(paneDisplayName(title: "api server", command: "node", host: host), "api server")
    }

    func testCustomTitleIsTrimmed() {
        XCTAssertEqual(paneCustomTitle(title: "  logs  ", command: "tail", host: host), "logs")
        XCTAssertEqual(paneDisplayName(title: "  logs  ", command: "tail", host: host), "logs")
    }

    func testWhitespaceOnlyTitleIsNotCustom() {
        XCTAssertNil(paneCustomTitle(title: "   ", command: "bash", host: host))
        XCTAssertEqual(paneDisplayName(title: "   ", command: "bash", host: host), "bash")
    }

    func testReadableTitlePrefersCustomTitle() {
        XCTAssertEqual(
            paneReadableTitle(
                title: "api-driver",
                command: "2.1.177",
                host: host,
                path: "/Users/example/Projects/demo-app"
            ),
            "api-driver"
        )
        XCTAssertEqual(
            paneReadableSubtitle(
                title: "api-driver",
                command: "2.1.177",
                host: host,
                path: "/Users/example/Projects/demo-app"
            ),
            "demo-app · 2.1.177"
        )
    }

    func testReadableTitleUsesFolderWhenTitleIsDefaultHost() {
        XCTAssertEqual(
            paneReadableTitle(
                title: host,
                command: "2.1.177",
                host: host,
                path: "/Users/example/Projects/sample-service"
            ),
            "sample-service"
        )
        XCTAssertEqual(
            paneReadableSubtitle(
                title: host,
                command: "2.1.177",
                host: host,
                path: "/Users/example/Projects/sample-service"
            ),
            "2.1.177"
        )
    }

    func testReadableTitleFallsBackToCommandWithoutPath() {
        XCTAssertEqual(
            paneReadableTitle(title: host, command: "bash", host: host, path: ""),
            "bash"
        )
        XCTAssertNil(paneReadableSubtitle(title: host, command: "bash", host: host, path: ""))
    }
}
