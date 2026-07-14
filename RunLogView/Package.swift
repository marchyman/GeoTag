// swift-tools-version: 6.3

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
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets {
    var settings = target.swiftSettings ?? []
    settings.append(.enableUpcomingFeature("InferIsolatedConformances"))
    settings.append(.enableUpcomingFeature("NonisolatedNonsendingByDefault"))
    target.swiftSettings = settings
}
