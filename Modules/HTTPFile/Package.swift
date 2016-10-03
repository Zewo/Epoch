import PackageDescription

let package = Package(
    name: "HTTPFile",
    dependencies: [
        .Package(url: "https://github.com/Zewo/HTTP.git", majorVersion: 0, minor: 14),
        .Package(url: "https://github.com/Zewo/File.git", majorVersion: 0, minor: 14),
    ]
)
