import PackageDescription

let package = Package(
    name: "Zewo",
    targets: [
        Target(name: "POSIX"),
        Target(name: "Reflection"),
        Target(name: "Axis", dependencies: ["Reflection", "POSIX", "Mapper"]),
        Target(name: "OpenSSL", dependencies: ["Axis"]),
        Target(name: "HTTP", dependencies: ["Axis"]),
        Target(name: "Mapper"),
        Target(name: "Venice", dependencies: ["Axis"]),
        Target(name: "IP", dependencies: ["Axis"]),
        Target(name: "TCP", dependencies: ["IP", "OpenSSL"]),
        Target(name: "UDP", dependencies: ["IP"]),
        Target(name: "File", dependencies: ["Axis"]),
        Target(name: "HTTPFile", dependencies: ["HTTP", "File"]),
        Target(name: "HTTPServer", dependencies: ["HTTPFile", "TCP", "Venice"]),
        Target(name: "HTTPClient", dependencies: ["HTTPFile", "TCP", "Venice"]),
        Target(name: "WebSocket", dependencies: ["Axis"]),
        Target(name: "WebSocketServer", dependencies: ["WebSocket", "HTTP"]),
        Target(name: "WebSocketClient", dependencies: ["WebSocket", "HTTPClient"]),

        Target(name: "ExampleApplication", dependencies: ["HTTPServer", "HTTPClient"]),
    ],
    dependencies: [
        .Package(url: "https://github.com/Zewo/CLibdill.git", majorVersion: 1),
        .Package(url: "https://github.com/Zewo/COpenSSL", majorVersion: 0, minor: 14),
        .Package(url: "https://github.com/Zewo/CPOSIX.git", majorVersion: 0, minor: 14),
        .Package(url: "https://github.com/Zewo/CHTTPParser.git", majorVersion: 0, minor: 14),
        .Package(url: "https://github.com/Zewo/CYAJL.git", majorVersion: 0, minor: 14),
    ]
)
