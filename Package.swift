// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "MediaDownloader",
    products: [
        .library(
            name: "MediaDownloaderCore",
            targets: ["MediaDownloaderCore"]
        ),
        .executable(
            name: "MediaDownloaderApp",
            targets: ["MediaDownloaderApp"]
        )
    ],
    targets: [
        .target(
            name: "MediaDownloaderCore"
        ),
        .executableTarget(
            name: "MediaDownloaderApp",
            dependencies: ["MediaDownloaderCore"],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "MediaDownloaderCoreTests",
            dependencies: ["MediaDownloaderCore"]
        )
    ],
    swiftLanguageModes: [.v6]
)
