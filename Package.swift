// swift-tools-version:5.5

/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import PackageDescription

let package = Package(
    name: "Publish",
    platforms: [.macOS(.v12)],
    products: [
        .library(name: "Publish", targets: ["Publish"]),
        .library(name: "MarkdownParser", targets: ["MarkdownParser"]),
        .executable(name: "publish-cli", targets: ["PublishCLI"])
    ],
    dependencies: [
        .package(
            name: "Plot",
            url: "https://github.com/johnsundell/plot.git",
            from: "0.9.0"
        ),
        .package(
            name: "Files",
            url: "https://github.com/johnsundell/files.git",
            from: "4.0.0"
        ),
        .package(
            name: "Codextended",
            url: "https://github.com/johnsundell/codextended.git",
            from: "0.1.0"
        ),
        .package(
            name: "ShellOut",
            url: "https://github.com/johnsundell/shellout.git",
            from: "2.3.0"
        ),
        .package(
            name: "Sweep",
            url: "https://github.com/johnsundell/sweep.git",
            from: "0.4.0"
        ),
        .package(
            name: "CollectionConcurrencyKit",
            url: "https://github.com/johnsundell/collectionConcurrencyKit.git",
            from: "0.1.0"
        ),
        .package(url: "https://github.com/apple/swift-markdown.git", .branch("main")),
        .package(url: "https://github.com/pointfreeco/swift-parsing.git", from: "0.12.0"),
    ],
    targets: [
        .target(
            name: "Publish",
            dependencies: [
                "MarkdownParser", "Plot", "Files", "Codextended",
                "ShellOut", "Sweep", "CollectionConcurrencyKit",
            ]
        ),
        .target(
            name: "MarkdownParser",
            dependencies: [
                "Plot",
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
            dependencies: ["Publish", "PublishCLICore"]
        ),
        .testTarget(
            name: "MarkdownParserTests",
            dependencies: ["MarkdownParser", "Publish"]
        )

    ]
)
