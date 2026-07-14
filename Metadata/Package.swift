// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "Metadata",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "Metadata", targets: ["Metadata"])
    ],
    dependencies: [
        .package(name: "Coords", path: "../Coords")
    ],
    targets: [
        .target(
            name: "Metadata",
            dependencies: [
                .product(name: "Coords", package: "Coords")
            ]
        ),
        .testTarget(
            name: "MetadataTests",
            dependencies: ["Metadata"]
        )
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets {
    var settings = target.swiftSettings ?? []
    settings.append(.enableUpcomingFeature("InferIsolatedConformances"))
    settings.append(.enableUpcomingFeature("NonisolatedNonsendingByDefault"))
    target.swiftSettings = settings
}
