// swift-tools-version: 6.0
import PackageDescription

// Pure, side-effect-free core: domain models, tmux `-F` format strings, and the
// string->model parser. No Process, no AppKit — so it runs under `swift test`
// with zero signing and no window server. The app target depends on this.
let package = Package(
    name: "TmuxKitCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "TmuxKitCore", targets: ["TmuxKitCore"]),
    ],
    targets: [
        .target(name: "TmuxKitCore"),
        .testTarget(name: "TmuxKitCoreTests", dependencies: ["TmuxKitCore"]),
    ]
)
