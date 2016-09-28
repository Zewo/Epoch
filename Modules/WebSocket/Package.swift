import PackageDescription

let package = Package(
    name: "WebSocket",
    dependencies: [
        .Package(url: "https://github.com/Zewo/Core.git",  majorVersion: 0, minor: 13),
    ]
)
