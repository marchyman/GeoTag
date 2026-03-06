// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Imagetool",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "Imagetool", targets: ["Imagetool"])
    ],
    dependencies: [
        .package(name: "Coords", path: "../Coords"),
        .package(name: "Exiftool", path: "../Exiftool"),
        .package(name: "Metadata", path: "../Metadata")
    ],
    targets: [
        .target(name: "Imagetool",
                dependencies: [
                    .product(name: "Coords", package: "Coords"),
                    .product(name: "Exiftool", package: "Exiftool"),
                    .product(name: "Metadata", package: "Metadata")
                ]),
        .testTarget(name: "ImagetoolTests",
                    dependencies: ["Imagetool"],
                    resources: [
                        .copy("nometadata.RAF"),
                        .copy("nolocation.jpg"),
                        .copy("location.jpg"),
                        .copy("status.DNG"),
                        .copy("toosmall.jpg"),
                        .copy("noelevation.jpg"),
                        .copy("alldata.jpg"),
                        .copy("262M1559.DNG"),
                        .copy("262M1559.xmp")
                    ])
    ]
)
