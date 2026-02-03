// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Imagetool",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "Imagetool", targets: ["Imagetool"])
    ],
    dependencies: [
        .package(name: "Coords", path: "../Coords"),
        .package(name: "Metadata", path: "../Metadata")
    ],
    targets: [
        .target(name: "Imagetool",
                dependencies: [
                    .product(name: "Coords", package: "Coords"),
                    .product(name: "Metadata", package: "Metadata")
                ]),
        .testTarget(name: "ImagetoolTests",
                    dependencies: ["Imagetool"],
                    resources: [
                        .copy("nometadata.RAF"),
                        .copy("nolocation.jpg"),
                        .copy("location.jpg"),
                        .copy("status.DNG"),
                        .copy("noelevation.jpg"),
                        .copy("alldata.jpg")
                    ])
    ]
)
