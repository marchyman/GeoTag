// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SplitHView",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "SplitHView", targets: ["SplitHView"])
    ],
    targets: [
        .target(name: "SplitHView"),
        .testTarget(name: "SplitHViewTests", dependencies: ["SplitHView"])
    ]
)
