// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MapAndSearchViews",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "MapAndSearchViews", targets: ["MapAndSearchViews"])
    ],
    targets: [
        .target(name: "MapAndSearchViews"),
        .testTarget(name: "MapAndSearchViewsTests",
                    dependencies: ["MapAndSearchViews"])
    ]
)
