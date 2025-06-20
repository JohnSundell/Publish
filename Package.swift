// swift-tools-version:6.1

/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import PackageDescription

let package = Package(
    name: "Publish",
    platforms: [.macOS(.v15), .iOS(.v16)],
    products: [
        .library(name: "Publish", targets: ["Publish"]),
        .library(name: "MarkdownParser", targets: ["MarkdownParser"]),
        .executable(name: "publish-cli", targets: ["PublishCLI"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/peterkovacs/plot",
            branch: "swift-6"
        ),
        .package(
            url: "https://github.com/peterkovacs/files",
            branch: "master"
        ),
        .package(
            url: "https://github.com/johnsundell/codextended.git",
            from: "0.1.0"
        ),
        .package(
            url: "https://github.com/johnsundell/shellout.git",
            from: "2.3.0"
        ),
        .package(
            url: "https://github.com/johnsundell/sweep.git",
            from: "0.4.0"
        ),
        .package(
            url: "https://github.com/johnsundell/collectionConcurrencyKit.git",
            from: "0.1.0"
        ),
        .package(url: "https://github.com/swiftlang/swift-markdown.git", from: "0.6.0"),
        .package(url: "https://github.com/pointfreeco/swift-parsing.git", from: "0.12.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.83.0"),
    ],
    targets: [
        .target(
            name: "Publish",
            dependencies: [
                .product(name: "Plot", package: "plot"),
                .product(name: "Files", package: "files"),
                .product(name: "Codextended", package: "codextended"),
                .product(name: "ShellOut", package: "shellout"),
                .product(name: "Sweep", package: "sweep"),
                .product(name: "CollectionConcurrencyKit", package: "collectionConcurrencyKit"),
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
                .product(name: "_NIOFileSystem", package: "swift-nio"),
                "MarkdownParser",
            ]
        ),
        .target(
            name: "MarkdownParser",
            dependencies: [
                .product(name: "Plot", package: "plot"),
                .product(name: "Markdown", package: "swift-markdown"),
                .product(name: "Parsing", package: "swift-parsing")
            ]
        ),
        .executableTarget(
            name: "PublishCLI",
            dependencies: ["PublishCLICore"]
        ),
        .target(
            name: "PublishCLICore",
            dependencies: ["Publish"]
        ),
        .testTarget(
            name: "PublishTests",
            dependencies: ["Publish", "PublishCLICore"],
            swiftSettings: [
//                .define("INCLUDE_CLI")
            ]
        ),
        .testTarget(
            name: "MarkdownParserTests",
            dependencies: ["MarkdownParser", "Publish"]
        )

    ]
)
