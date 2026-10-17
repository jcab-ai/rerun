// swift-tools-version:5.10
import PackageDescription

// RerunCore is plain Foundation + SQLite so its tests also run on Linux CI.
// RerunUI and the app executable are SwiftUI/AppKit and only exist on macOS.

var products: [Product] = [
    .library(name: "RerunCore", targets: ["RerunCore"]),
]

var targets: [Target] = [
    .systemLibrary(
        name: "CSQLite",
        path: "Sources/CSQLite",
        pkgConfig: "sqlite3",
        providers: [.apt(["libsqlite3-dev"])]
    ),
    .target(
        name: "RerunCore",
        dependencies: [.target(name: "CSQLite", condition: .when(platforms: [.linux]))]
    ),
    .testTarget(name: "RerunCoreTests", dependencies: ["RerunCore"]),
]

#if os(macOS)
products += [
    .library(name: "RerunUI", targets: ["RerunUI"]),
    // `swift run rerun-dev` launches the app without an .app bundle (see README).
    .executable(name: "rerun-dev", targets: ["RerunDevApp"]),
]
targets += [
    .target(
        name: "RerunUI",
        dependencies: ["RerunCore"],
        resources: [.copy("Resources/Fonts")]
    ),
    .executableTarget(name: "RerunDevApp", dependencies: ["RerunCore", "RerunUI"], path: "App"),
    .testTarget(name: "RerunUITests", dependencies: ["RerunCore", "RerunUI"]),
]
#endif

let package = Package(
    name: "Rerun",
    platforms: [.macOS(.v14)],
    products: products,
    targets: targets
)
