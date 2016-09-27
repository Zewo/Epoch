import PackageDescription

let package = Package(
    name: "Zewo",
    targets: [
        Target(name: "POSIX"),
        Target(name: "Reflection"),
        Target(name: "Core", dependencies: ["Reflection"]),
        Target(name: "OpenSSL", dependencies: ["Core"]),
        Target(name: "HTTP", dependencies: ["Core"]),

        Target(name: "Venice", dependencies: ["Core", "POSIX"]),
        Target(name: "IP", dependencies: ["Core", "Venice", "POSIX"]),
        Target(name: "TCP", dependencies: ["IP", "OpenSSL", "Venice", "POSIX"]),
        Target(name: "File", dependencies: ["Core", "POSIX"]),
        Target(name: "HTTPFile", dependencies: ["HTTP", "File"]),
        Target(name: "HTTPServer", dependencies: ["HTTPFile", "TCP", "Venice"]),
        Target(name: "HTTPClient", dependencies: ["HTTPFile", "TCP", "Venice"]),

        Target(name: "ExampleApplication", dependencies: ["HTTPServer"]),
    ],
    dependencies: [
        .Package(url: "https://github.com/Zewo/CLibvenice.git", majorVersion: 0, minor: 13),
        .Package(url: "https://github.com/Zewo/CDNS.git", majorVersion: 0, minor: 13),
        .Package(url: "https://github.com/Zewo/COpenSSL", majorVersion: 0, minor: 13),
        .Package(url: "https://github.com/Zewo/CPOSIX.git", majorVersion: 0, minor: 13),
        .Package(url: "https://github.com/Zewo/CHTTPParser.git", majorVersion: 0, minor: 13),
    ]
)
