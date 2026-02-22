// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "RunLogView",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "RunLogView", targets: ["RunLogView"])
    ],
    targets: [
        .target(name: "RunLogView"),
        .testTarget(name: "RunLogViewTests", dependencies: ["RunLogView"])
    ]
)
