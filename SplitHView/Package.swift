// swift-tools-version: 6.3

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
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets {
    var settings = target.swiftSettings ?? []
    settings.append(.enableUpcomingFeature("InferIsolatedConformances"))
    settings.append(.enableUpcomingFeature("NonisolatedNonsendingByDefault"))
    target.swiftSettings = settings
}
