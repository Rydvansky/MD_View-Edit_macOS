// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MDViewEditMacOS",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "MDViewEditMacOS", targets: ["MDViewEditMacOS"])
    ],
    targets: [
        .executableTarget(name: "MDViewEditMacOS")
    ]
)
