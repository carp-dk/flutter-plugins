// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "light",
    platforms: [
        .iOS("14.0")
    ],
    products: [
        .library(name: "light", targets: ["light"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "light",
            dependencies: []
        )
    ]
)
