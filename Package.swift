// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "KeyClack",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "KeyClack",
            targets: ["KeyClack"]
        )
    ],
    targets: [
        .executableTarget(
            name: "KeyClack",
            path: "Sources/KeyClack"
        )
    ]
)
