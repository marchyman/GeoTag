// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SplitHView",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "SplitHView", targets: ["SplitHView"])
    ],
    targets: [
        .target(name: "SplitHView"),
        .testTarget(name: "SplitHViewTests", dependencies: ["SplitHView"])
    ]
)
