import PackageDescription

let package = Package(
    name: "Zewo",
    targets: [
        Target(name: "CHTTPParser"),
        Target(name: "CYAJL"),
        Target(name: "CPOSIX"),
        Target(name: "POSIX", dependencies: ["CPOSIX"]),
        Target(name: "Core", dependencies: ["CYAJL"]),
        Target(name: "IO", dependencies: ["Core", "POSIX"]),
        Target(name: "HTTP", dependencies: ["CHTTPParser", "IO"]),
        Target(name: "Example", dependencies: ["HTTP"]),
    ],
    dependencies: [
        .Package(url: "https://github.com/Zewo/Venice.git", majorVersion: 0, minor: 17),
    ]
)
