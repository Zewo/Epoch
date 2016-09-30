import PackageDescription

let package = Package(
    name: "Zewo",
    targets: [
        Target(name: "POSIX"),
        Target(name: "Reflection"),
        Target(name: "Core", dependencies: ["Reflection", "POSIX"]),
        Target(name: "OpenSSL", dependencies: ["Core"]),
        Target(name: "HTTP", dependencies: ["Core"]),

        Target(name: "Venice", dependencies: ["Core"]),
        Target(name: "IP", dependencies: ["Core"]),
        Target(name: "TCP", dependencies: ["IP", "OpenSSL"]),
        Target(name: "UDP", dependencies: ["IP"]),
        Target(name: "File", dependencies: ["Core"]),
        Target(name: "HTTPFile", dependencies: ["HTTP", "File"]),
        Target(name: "HTTPServer", dependencies: ["HTTPFile", "TCP", "Venice"]),
        Target(name: "HTTPClient", dependencies: ["HTTPFile", "TCP", "Venice"]),

        Target(name: "ExampleApplication", dependencies: ["HTTPServer"]),
    ],
    dependencies: [
        .Package(url: "https://github.com/Zewo/CLibvenice.git", majorVersion: 0, minor: 13),
        .Package(url: "https://github.com/Zewo/COpenSSL", majorVersion: 0, minor: 13),
        .Package(url: "https://github.com/Zewo/CPOSIX.git", majorVersion: 0, minor: 13),
        .Package(url: "https://github.com/Zewo/CHTTPParser.git", majorVersion: 0, minor: 13),
        .Package(url: "https://github.com/Zewo/CYAJL.git", majorVersion: 0, minor: 13),
    ]
)
