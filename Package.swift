// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "SwiftServe",
    products: [
        .library(name: "SwiftServe", targets: ["SwiftServe"]),
    ],
    dependencies: [
        .package(url: "https://github.com/drewag/swift-postgresql.git", from: "2.0.0"),
        .package(url: "https://github.com/drewag/command-line-parser.git", from: "2.0.0"),
        .package(url: "https://github.com/kylef/Stencil.git", from: "0.11.0"),
        .package(url: "https://github.com/PerfectlySoft/Perfect-Markdown.git", from: "3.0.0"),
    ],
    targets: [
        .target(name: "SwiftServe", dependencies: [
            "PostgreSQL", "CommandLineParser", "Stencil", "PerfectMarkdown",
        ], path: "Sources"),
        .testTarget(name: "SwiftServeTests", dependencies: ["SwiftServe"]),
    ]
)
