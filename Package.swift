// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MDView",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-markdown.git", branch: "main"),
    ],
    targets: [
        .executableTarget(
            name: "MDView",
            dependencies: [.product(name: "Markdown", package: "swift-markdown")],
            swiftSettings: [.unsafeFlags(["-Osize"])]
        ),
    ]
)
