// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Coords",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "Coords", targets: ["Coords"])
    ],
    targets: [
        .target(name: "Coords"),
        .testTarget(name: "CoordsTests",
                    dependencies: ["Coords"])
    ]
)
