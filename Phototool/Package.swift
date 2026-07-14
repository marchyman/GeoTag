// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "Phototool",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "Phototool", targets: ["Phototool"])
    ],
    dependencies: [
        .package(name: "Coords", path: "../Coords"),
        .package(name: "Metadata", path: "../Metadata")
    ],
    targets: [
        .target(name: "Phototool",
                dependencies: [
                    .product(name: "Coords", package: "Coords"),
                    .product(name: "Metadata", package: "Metadata")
                ]),
        .testTarget(name: "PhototoolTests",
                    dependencies: ["Phototool"])
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets {
    var settings = target.swiftSettings ?? []
    settings.append(.enableUpcomingFeature("InferIsolatedConformances"))
    settings.append(.enableUpcomingFeature("NonisolatedNonsendingByDefault"))
    target.swiftSettings = settings
}
