// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Phototool",
    platforms: [.macOS(.v15)],
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
    ]
)
