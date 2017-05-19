// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "Zewo",
    targets: [
        Target(name: "CHTTPParser"),
        Target(name: "CYAJL"),
        Target(name: "CDsock"),
        
        Target(name: "Core", dependencies: ["CYAJL"]),
        Target(name: "IO", dependencies: ["Core", "CDsock"]),
        Target(name: "HTTP", dependencies: ["IO", "CHTTPParser"]),
    ],
    dependencies: [
        .Package(url: "https://github.com/Zewo/Venice.git", majorVersion: 0, minor: 17),
    ]
)
