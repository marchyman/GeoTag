// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Exiftool",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "Exiftool", targets: ["Exiftool"])
    ],
    dependencies: [
        .package(name: "Coords", path: "../Coords"),
        .package(name: "Metadata", path: "../Metadata"),
        .package(name: "ImageData", path: "../ImageData")
    ],
    targets: [
        .target(name: "Exiftool",
                dependencies: [
                    .product(name: "Coords", package: "Coords"),
                    .product(name: "Metadata", package: "Metadata")
                ],
                resources: [.copy("ExifTool")],
                swiftSettings: [
                    .define("DEBUG", .when(configuration: .debug)),
                ]),
        .testTarget(name: "ExiftoolTests",
                    dependencies: ["Exiftool", "ImageData"],
                    resources: [.copy("nowrite.typ"),
                                .copy("262M1559.DNG"),
                                .copy("262M1559.xmp"),
                                .copy("IMG_5654.HEIC")])
    ]
)
