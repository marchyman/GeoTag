// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AdjustTimeZoneView",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "AdjustTimeZoneView", targets: ["AdjustTimeZoneView"])
    ],
    targets: [
        .target(name: "AdjustTimeZoneView"),
        .testTarget(name: "AdjustTimeZoneViewTests",
                    dependencies: ["AdjustTimeZoneView"])
    ]
)
