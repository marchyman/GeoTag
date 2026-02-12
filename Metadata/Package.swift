// swift-tools-version: 6.2

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
    ]
)
