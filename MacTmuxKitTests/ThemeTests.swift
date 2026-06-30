import XCTest
import SwiftUI
import AppKit
@testable import MacTmuxKit

final class ThemeTests: XCTestCase {
    /// `accentInk` must be a genuinely darker shade of the accent — it's the legible
    /// accent text/icon color on light chrome, so if `darkened` stops darkening, blue
    /// labels would wash out against the frosted panel.
    func testAccentInkIsDarkerThanAccent() {
        XCTAssertLessThan(luminance(Theme.accentInk), luminance(Theme.accent))
    }

    private func luminance(_ color: Color) -> CGFloat {
        let c = NSColor(color).usingColorSpace(.sRGB) ?? NSColor(color)
        return 0.299 * c.redComponent + 0.587 * c.greenComponent + 0.114 * c.blueComponent
    }
}
