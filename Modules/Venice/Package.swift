import PackageDescription

let package = Package(
    name: "Venice",
    dependencies: [
        .Package(url: "https://github.com/Zewo/Axis.git", majorVersion: 0, minor: 14),
        .Package(url: "https://github.com/Zewo/CLibvenice.git", majorVersion: 0, minor: 14),
    ]
)
