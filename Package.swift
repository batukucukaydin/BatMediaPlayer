// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "BatMediaPlayer",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "BatMediaPlayer",
            path: "Sources/BatMediaPlayer"
        )
    ]
)
