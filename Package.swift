// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Datograph",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "Datograph"),
        .testTarget(name: "DatographTests", dependencies: ["Datograph"]),
    ]
)
