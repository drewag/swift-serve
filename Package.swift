import PackageDescription

let package = Package(
    name: "SwiftServe",
    dependencies: [
        .Package(url: "https://github.com/drewag/swift-postgresql.git", majorVersion: 0),
        .Package(url: "https://github.com/drewag/command-line-parser.git", majorVersion: 2),
        .Package(url: "https://github.com/kylef/Stencil.git", majorVersion: 0, minor: 11),
        .Package(url: "https://github.com/PerfectlySoft/Perfect-Markdown.git", majorVersion: 3),
    ]
)
