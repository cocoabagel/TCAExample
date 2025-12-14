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
                .package(product: "ComposableArchitecture")
            ]
        ),
        .target(
            name: "TCAExampleTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.tcaexample.app.tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["TCAExample/Tests/**"],
            dependencies: [
                .target(name: "TCAExample")
            ]
        )
    ]
)
