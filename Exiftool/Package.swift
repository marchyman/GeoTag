// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Exiftool",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "Exiftool", targets: ["Exiftool"])
    ],
    dependencies: [
        .package(name: "Coords", path: "../Coords")
    ],
    targets: [
        .target(name: "Exiftool",
                dependencies: [
                    .product(name: "Coords", package: "Coords")
                ],
                resources: [.copy("ExifTool")]),
        .testTarget(name: "ExiftoolTests",
                    dependencies: ["Exiftool"],
                    resources: [.copy("nowrite.typ"),
                                .copy("262M1559.DNG"),
                                .copy("262M1559.xmp"),
                                .copy("IMG_5654.HEIC")])
    ]
)
