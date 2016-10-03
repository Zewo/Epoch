import PackageDescription

let package = Package(
    name: "Zewo",
    targets: [
        Target(name: "POSIX"),
        Target(name: "Reflection"),
        Target(name: "Axis", dependencies: ["Reflection", "POSIX"]),
        Target(name: "OpenSSL", dependencies: ["Axis"]),
        Target(name: "HTTP", dependencies: ["Axis"]),

        Target(name: "Venice", dependencies: ["Axis"]),
        Target(name: "IP", dependencies: ["Axis"]),
        Target(name: "TCP", dependencies: ["IP", "OpenSSL"]),
        Target(name: "UDP", dependencies: ["IP"]),
        Target(name: "File", dependencies: ["Axis"]),
        Target(name: "HTTPFile", dependencies: ["HTTP", "File"]),
        Target(name: "HTTPServer", dependencies: ["HTTPFile", "TCP", "Venice"]),
        Target(name: "HTTPClient", dependencies: ["HTTPFile", "TCP", "Venice"]),

        Target(name: "ExampleApplication", dependencies: ["HTTPServer"]),
    ],
    dependencies: [
        .Package(url: "https://github.com/Zewo/CLibvenice.git", majorVersion: 0, minor: 14),
        .Package(url: "https://github.com/Zewo/COpenSSL", majorVersion: 0, minor: 14),
        .Package(url: "https://github.com/Zewo/CPOSIX.git", majorVersion: 0, minor: 14),
        .Package(url: "https://github.com/Zewo/CHTTPParser.git", majorVersion: 0, minor: 14),
        .Package(url: "https://github.com/Zewo/CYAJL.git", majorVersion: 0, minor: 14),
    ]
)
