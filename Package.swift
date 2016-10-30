import PackageDescription

let package = Package(
    name: "SwiftServe",
    dependencies: [
        .Package(url: "https://github.com/drewag/SwiftPlusPlus.git", majorVersion: 1),
    ]
)
