import PackageDescription

let package = Package(
    name: "WebSocketClient",
    dependencies: [
        .Package(url: "https://github.com/Zewo/WebSocket.git", majorVersion: 0, minor: 13),
        .Package(url: "https://github.com/Zewo/HTTPClient.git", majorVersion: 0, minor: 13),
    ]
)
