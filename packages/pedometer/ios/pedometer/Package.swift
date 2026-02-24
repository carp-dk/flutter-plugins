// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "pedometer",
    platforms: [
        .iOS("10.0")
    ],
    products: [
        .library(name: "pedometer", targets: ["pedometer"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "pedometer",
            dependencies: []
        )
    ]
)
