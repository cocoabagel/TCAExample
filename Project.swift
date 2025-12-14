import ProjectDescription

let project = Project(
    name: "TCAExample",
    organizationName: "TCAExample",
    packages: [
        .remote(
            url: "https://github.com/pointfreeco/swift-composable-architecture",
            requirement: .exact("1.23.1")
        )
    ],
    targets: [
        // MARK: - CounterFeature Framework
        .target(
            name: "CounterFeature",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.tcaexample.counterfeature",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["CounterFeature/Sources/**"],
            resources: ["CounterFeature/Resources/**"],
            dependencies: [
                .package(product: "ComposableArchitecture")
            ]
        ),
        .target(
            name: "CounterFeatureTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.tcaexample.counterfeature.tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["CounterFeature/Tests/**"],
            dependencies: [
                .target(name: "CounterFeature")
            ]
        ),
        // MARK: - TCAExample App
        .target(
            name: "TCAExample",
            destinations: .iOS,
            product: .app,
            bundleId: "com.tcaexample.app",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": [
                    "UIColorName": "",
                    "UIImageName": "",
                ],
                "CFBundleDisplayName": "TCAExample",
                "UISupportedInterfaceOrientations": [
                    "UIInterfaceOrientationPortrait",
                ],
            ]),
            sources: ["TCAExample/Sources/**"],
            resources: ["TCAExample/Resources/**"],
            dependencies: [
                .target(name: "CounterFeature")
            ]
        )
    ]
)
