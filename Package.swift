// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TraceLog",
    platforms: [
        .iOS(.v16),
        .macOS(.v11)
    ],
    products: [
        .library(name: "TraceLogCore", targets: ["TraceLogCore"])
    ],
    targets: [
        .target(
            name: "TraceLogCore",
            path: "TraceLogCore",
            sources: ["Models", "Services"]
        )
    ]
)
