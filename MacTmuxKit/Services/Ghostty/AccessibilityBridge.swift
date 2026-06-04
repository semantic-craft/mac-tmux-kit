import AppKit
import ApplicationServices

/// Thin wrapper over the Accessibility (AXUIElement) C API used to find and
/// raise another app's windows. Ghostty has no scripting interface, so window
/// focusing must go through Accessibility (requires the user to grant the app
/// Accessibility permission in System Settings).
enum AccessibilityBridge {
    /// Whether this process is trusted for Accessibility.
    static var isTrusted: Bool { AXIsProcessTrusted() }

    /// Ask the system to show the "grant Accessibility" prompt (once).
    static func promptForTrust() {
        // Literal key avoids Unmanaged<CFString> import differences across SDKs.
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    static func runningApp(bundleID: String) -> NSRunningApplication? {
        NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first
    }

    /// All windows of an app, paired with their AX titles.
    static func windows(ofAppWithBundleID bundleID: String) -> [(element: AXUIElement, title: String)] {
        guard let app = runningApp(bundleID: bundleID) else { return [] }
        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        var raw: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &raw) == .success,
              let windows = raw as? [AXUIElement] else {
            return []
        }
        return windows.map { (element: $0, title: title(of: $0)) }
    }

    static func title(of window: AXUIElement) -> String {
        var raw: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &raw) == .success else {
            return ""
        }
        return raw as? String ?? ""
    }

    /// Make a window main + focused and raise it above its siblings.
    static func raise(_ window: AXUIElement) {
        AXUIElementSetAttributeValue(window, kAXMainAttribute as CFString, kCFBooleanTrue)
        AXUIElementSetAttributeValue(window, kAXFocusedAttribute as CFString, kCFBooleanTrue)
        AXUIElementPerformAction(window, kAXRaiseAction as CFString)
    }
}
