import PackageDescription

let package = Package(
    name: "SwiftServe",
    dependencies: [
        .Package(url: "https://github.com/drewag/SwiftPlusPlus.git", majorVersion: 1),
        .Package(url: "https://github.com/Zewo/SQL.git", majorVersion: 0, minor: 14),
        .Package(url: "git@github.com:drewag/text-transformers.git", majorVersion: 6),
    ]
)
