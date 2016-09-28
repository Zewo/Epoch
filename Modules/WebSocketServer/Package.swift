import PackageDescription

let package = Package(
    name: "WebSocketServer",
    dependencies: [
        .Package(url: "https://github.com/Zewo/WebSocket.git", majorVersion: 0, minor: 13),
        .Package(url: "https://github.com/Zewo/HTTP.git", majorVersion: 0, minor: 13),
    ]
)
