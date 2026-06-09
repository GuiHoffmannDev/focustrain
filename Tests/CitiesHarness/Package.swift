// swift-tools-version: 6.0
import PackageDescription

// Standalone test harness for FocusTrain's cities layer. It lives OUTSIDE
// FocusTrain/ so the app's Xcode synced file group never picks it up, and it
// compiles the real app sources via symlinks in Sources/CitiesKit (no copies,
// no drift). Run from this directory with `swift test`.
let package = Package(
    name: "CitiesHarness",
    platforms: [.macOS(.v13)],
    targets: [
        .target(
            name: "CitiesKit",
            linkerSettings: [.linkedLibrary("sqlite3")]
        ),
        .testTarget(
            name: "CitiesKitTests",
            dependencies: ["CitiesKit"]
        ),
    ]
)
