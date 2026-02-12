// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "GpxTrackLog",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "GpxTrackLog", targets: ["GpxTrackLog"])
    ],
    targets: [
        .target(name: "GpxTrackLog"),
        .testTarget(name: "GpxTrackLogTests",
                    dependencies: ["GpxTrackLog"],
                    resources: [.copy("BadTrack.GPX"),
                                .copy("NoTrack.GPX"),
                                .copy("TestTrack.GPX")])
    ]
)
