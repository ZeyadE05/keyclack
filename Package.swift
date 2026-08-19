// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Klack",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "Klack",
            targets: ["Klack"]
        )
    ],
    targets: [
        .executableTarget(
            name: "Klack",
            path: "Sources/Klack"
        )
    ]
)
