// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SplitVView",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "SplitVView", targets: ["SplitVView"])
    ],
    targets: [
        .target(name: "SplitVView"),
        .testTarget(name: "SplitVViewTests", dependencies: ["SplitVView"])
    ]
)
