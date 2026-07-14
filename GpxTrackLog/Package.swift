// swift-tools-version: 6.3

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
                                .copy("TestTrack.GPX"),
                                .copy("MultiSeg.GPX")])
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets {
    var settings = target.swiftSettings ?? []
    settings.append(.enableUpcomingFeature("InferIsolatedConformances"))
    settings.append(.enableUpcomingFeature("NonisolatedNonsendingByDefault"))
    target.swiftSettings = settings
}
