import PackageDescription

let package = Package(
    name: "HTTP",
    dependencies: [
        .Package(url: "https://github.com/Zewo/Axis.git", majorVersion: 0, minor: 14),
        .Package(url: "https://github.com/Zewo/CHTTPParser.git", majorVersion: 0, minor: 14),
    ]
)
