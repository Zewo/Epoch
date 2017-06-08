// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "Zewo",
    targets: [
        Target(name: "CHTTPParser"),
        Target(name: "CYAJL"),
        Target(name: "CArgon2"),
        
        Target(name: "Core"),
        Target(name: "Content", dependencies: ["CYAJL", "Core"]),
        Target(name: "Crypto", dependencies: ["Core", "CArgon2"]),
        Target(name: "IO", dependencies: ["Core"]),
        Target(name: "JWT", dependencies: ["Crypto", "Content"]),
        Target(name: "HTTP", dependencies: ["Content", "IO", "CHTTPParser"]),
    ],
    dependencies: [
        .Package(url: "https://github.com/Zewo/Venice.git", majorVersion: 0, minor: 19),
        .Package(url: "https://github.com/Zewo/CLibtls.git", majorVersion: 2),
        .Package(url: "https://github.com/Zewo/CBtls.git", majorVersion: 0, minor: 5),
    ]
)
