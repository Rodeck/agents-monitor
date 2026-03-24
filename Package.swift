// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AgentsMonitor",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "AgentsMonitor",
            path: "AgentsMonitor",
            exclude: ["Resources/Info.plist"]
        )
    ]
)
