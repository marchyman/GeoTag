// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "Coords",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "Coords", targets: ["Coords"])
    ],
    targets: [
        .target(name: "Coords"),
        .testTarget(name: "CoordsTests",
                    dependencies: ["Coords"])
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets {
    var settings = target.swiftSettings ?? []
    settings.append(.enableUpcomingFeature("InferIsolatedConformances"))
    settings.append(.enableUpcomingFeature("NonisolatedNonsendingByDefault"))
    target.swiftSettings = settings
}
