// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RunLogView",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "RunLogView", targets: ["RunLogView"])
    ],
    targets: [
        .target(name: "RunLogView"),
        .testTarget(name: "RunLogViewTests", dependencies: ["RunLogView"])
    ]
)
