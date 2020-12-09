// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "NSFoundationCoding",
    products: [
        .library(
            name: "NSFoundationCoding",
            targets: ["NSFoundationCoding"]
        ),
    ],
    targets: [
        .target(
            name: "NSFoundationCoding",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "NSFoundationCodingTests",
            dependencies: ["NSFoundationCoding"],
            path: "Tests"
        ),
    ]
)
