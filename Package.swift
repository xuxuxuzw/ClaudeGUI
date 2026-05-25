// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClaudeGUI",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(path: "./LocalSwiftTerm")
    ],
    targets: [
        .executableTarget(
            name: "ClaudeGUI",
            dependencies: ["SwiftTerm"],
            path: "Sources/ClaudeGUI",
            resources: [
                .process("AppIcon.icns")
            ]
        )
    ]
)
