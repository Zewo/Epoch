import PackageDescription

let package = Package(
    name: "Zewo",
    targets: [
        Target(name: "CDNS"),
        Target(name: "CPOSIX"),
        Target(name: "CHTTPParser"),
        Target(name: "CYAJL"),
        
        Target(name: "POSIX", dependencies: ["CPOSIX"]),
        Target(name: "Core", dependencies: ["CYAJL"]),
        Target(name: "Networking", dependencies: ["CDNS", "Core", "POSIX"]),
        Target(name: "HTTP", dependencies: ["CHTTPParser", "Networking"]),
    ],
    dependencies: [
        .Package(url: "https://github.com/formbound/Venice.git", majorVersion: 0),
    ]
)
