// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "SwiftServe",
    platforms: [
        .macOS(.v10_12),
    ],
    products: [
        .library(name: "SwiftServe", targets: ["SwiftServe"]),
    ],
    dependencies: [
        .package(url: "https://github.com/drewag/swift-postgresql.git", from: "5.0.0"),
        .package(url: "https://github.com/drewag/command-line-parser.git", from: "3.0.0"),
        .package(url: "https://github.com/drewag/Stencil.git", from: "0.11.0"),
        .package(url: "https://github.com/PerfectlySoft/Perfect-Markdown.git", from: "3.0.0"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.0.0"),
        .package(url: "https://github.com/drewag/Decree.git", from: "4.0.0"),
        .package(url: "https://github.com/drewag/SwiftlierCLI.git", from: "6.0.0"),
    ],
    targets: [
        .target(name: "SwiftServe", dependencies: [
            "PostgreSQL", "CommandLineParser", "Stencil", "PerfectMarkdown", "CryptoSwift", "Decree", "SwiftlierCLI",
        ], path: "Sources"),
        .testTarget(name: "SwiftServeTests", dependencies: ["SwiftServe"]),
    ]
)
