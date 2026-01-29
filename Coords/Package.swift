// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Coords",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "Coords", targets: ["Coords"])
    ],
    targets: [
        .target(name: "Coords"),
        .testTarget(name: "CoordsTests",
                    dependencies: ["Coords"])
    ]
)
