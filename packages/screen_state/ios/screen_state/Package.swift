// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "screen_state",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "screen-state", targets: ["screen_state"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "screen_state",
            dependencies: []
        )
    ]
)
