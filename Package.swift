// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AeroBar",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "AeroBar", targets: ["AeroBar"])
    ],
    targets: [
        .executableTarget(
            name: "AeroBar",
            path: "Sources/AeroBar"
        )
    ]
)
