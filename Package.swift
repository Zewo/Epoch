import PackageDescription

let package = Package(
    name: "Zewo",
    targets: [
        Target(name: "CDNS"),
        Target(name: "CHTTPParser"),
        Target(name: "CYAJL"),
        
        Target(name: "POSIX"),
        Target(name: "Core", dependencies: ["CYAJL"]),
        Target(name: "IO", dependencies: ["CDNS", "Core", "POSIX"]),
        Target(name: "HTTP", dependencies: ["CHTTPParser", "IO"]),
    ],
    dependencies: [
        .Package(url: "https://github.com/Zewo/Venice.git", majorVersion: 0, minor: 15),
    ]
)
