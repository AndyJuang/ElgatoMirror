// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ElgatoMirror",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "ElgatoMirror",
            path: "Sources/ElgatoMirror"
        ),
    ]
)
