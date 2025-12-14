// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "CounterFeature",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "CounterFeature",
            targets: ["CounterFeature"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture",
            exact: "1.23.1"
        )
    ],
    targets: [
        .target(
            name: "CounterFeature",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        ),
        .testTarget(
            name: "CounterFeatureTests",
            dependencies: ["CounterFeature"]
        )
    ]
)
