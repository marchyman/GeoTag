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
        .package(name: "ImageData", path: "../ImageData"),
        .package(name: "Imagetool", path: "../Imagetool"),
        .package(name: "Metadata", path: "../Metadata")
    ],
    targets: [
        .target(name: "Exiftool",
                dependencies: ["Coords", "Metadata"],
                resources: [.copy("ExifTool")]),
        .testTarget(name: "ExiftoolTests",
                    dependencies: [
                        "Exiftool", "Coords",
                        "ImageData", "Imagetool", "Metadata"
                    ],
                    resources: [
                        .copy("nowrite.typ"),
                        .copy("262M1559.DNG"),
                        .copy("262M1559.xmp"),
                        .copy("IMG_5654.HEIC")
                    ],
                    swiftSettings: [
                        .define("DEBUG", .when(configuration: .debug))
                    ])
    ]
)
