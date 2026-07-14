// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "SplitVView",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "SplitVView", targets: ["SplitVView"])
    ],
    targets: [
        .target(name: "SplitVView"),
        .testTarget(name: "SplitVViewTests", dependencies: ["SplitVView"])
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets {
    var settings = target.swiftSettings ?? []
    settings.append(.enableUpcomingFeature("InferIsolatedConformances"))
    settings.append(.enableUpcomingFeature("NonisolatedNonsendingByDefault"))
    target.swiftSettings = settings
}
