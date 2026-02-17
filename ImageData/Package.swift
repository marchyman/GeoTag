// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "ImageData",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "ImageData", targets: ["ImageData"])
    ],
    dependencies: [
        .package(name: "Coords", path: "../Coords"),
        .package(name: "Exiftool", path: "../Exiftool"),
        .package(name: "Imagetool", path: "../Imagetool"),
        .package(name: "Phototool", path: "../Phototool"),
        .package(name: "Metadata", path: "../Metadata")
    ],
    targets: [
        .target(
            name: "ImageData",
            dependencies: [
                .product(name: "Coords", package: "Coords"),
                .product(name: "Exiftool", package: "Exiftool"),
                .product(name: "Imagetool", package: "Imagetool"),
                .product(name: "Phototool", package: "Phototool"),
                .product(name: "Metadata", package: "Metadata")
            ]
        ),
        .testTarget(
            name: "ImageDataTests",
            dependencies: ["ImageData"]
        )
    ]
)
