// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "httpswitch-hap",
    products: [
        .executable(name: "httpswitch-hap", targets: ["httpswitch-hap"])
    ],
    dependencies: [
        .package(url: "https://github.com/bouke/HAP.git", .branch("master")),
    ],
    targets: [
        .target(name: "httpswitch-hap", dependencies: ["HAP"]),
    ]
)
