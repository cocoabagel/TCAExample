// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "ProFeature",
    platforms: [.iOS(.v26), .macOS(.v15)],
    products: [
        .library(
            name: "ProFeature",
            targets: ["ProFeature"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", exact: "1.23.1"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.17.0"),
    ],
    targets: [
        .target(
            name: "ProFeature",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]
        ),
        .testTarget(
            name: "ProFeatureTests",
            dependencies: [
                "ProFeature",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ]
        ),
    ]
)
