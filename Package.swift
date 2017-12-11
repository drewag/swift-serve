import PackageDescription

let package = Package(
    name: "SwiftServe",
    dependencies: [
        .Package(url: "https://github.com/drewag/swift-postgresql", majorVersion: 0),
        .Package(url: "https://github.com/drewag/text-transformers.git", majorVersion: 7),
        .Package(url: "https://github.com/drewag/command-line-parser.git", majorVersion: 2),
    ]
)
