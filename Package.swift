// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "kontonummer-swift",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        .library(name: "Kontonummer", targets: ["Kontonummer"]),
    ],
    targets: [
        .target(name: "Kontonummer"),
        .testTarget(
            name: "KontonummerTests",
            dependencies: ["Kontonummer"]
        ),
    ]
)
