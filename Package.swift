// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CurrentLocation",
    platforms: [
        .iOS(.v17),
    ],
    products: [
        .library(
            name: "CurrentLocation",
            targets: ["CurrentLocation"]
        ),
    ],
    targets: [
        .target(
            name: "CurrentLocation",
            exclude: ["LocalConfig.swift.example"],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
    ]
)
