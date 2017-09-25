import PackageDescription

let package = Package(
    name: "SwiftServe",
    dependencies: [
        .Package(url: "https://github.com/drewag/Swiftlier.git", majorVersion: 4),
        .Package(url: "https://github.com/Zewo/PostgreSQL.git", majorVersion: 0, minor: 14),
        .Package(url: "https://github.com/drewag/text-transformers.git", majorVersion: 7),
        .Package(url: "https://github.com/drewag/command-line-parser.git", majorVersion: 2),
    ]
)
