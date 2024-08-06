// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GpxTrackLog",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "GpxTrackLog", targets: ["GpxTrackLog"])
    ],
    targets: [
        .target(name: "GpxTrackLog"),
        .testTarget(name: "GpxTrackLogTests", dependencies: ["GpxTrackLog"])
    ]
)
