// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "Zewo",
    products: [
        .library(name: "Zewo", targets: ["CYAJL", "CHTTPParser", "Core", "IO", "Media", "HTTP", "Zewo"])
    ],
    dependencies: [
        .package(url: "https://github.com/Zewo/CLibdill.git", .branch("master")),
        .package(url: "https://github.com/Zewo/Venice.git", .branch("master")),
        .package(url: "https://github.com/Zewo/CLibreSSL.git", from: "3.1.0"),
    ],
    targets: [
        .target(name: "CYAJL"),
        .target(name: "CHTTPParser"),
        .target(name: "CBtls", dependencies: ["CLibdill"]),
        
        .target(name: "Core", dependencies: ["Venice"]),
        .target(name: "IO", dependencies: ["Core","CLibdill","CBtls"]),
        .target(name: "Media", dependencies: ["Core", "CYAJL"]),
        .target(name: "HTTP", dependencies: ["Media", "IO", "CHTTPParser"]),
        .target(name: "Zewo", dependencies: ["Core", "IO", "Media", "HTTP"]),
        
        .testTarget(name: "CoreTests", dependencies: ["Core"]),
        .testTarget(name: "IOTests", dependencies: ["IO"]),
        .testTarget(name: "MediaTests", dependencies: ["Media"]),
        .testTarget(name: "HTTPTests", dependencies: ["HTTP"]),
    ]
)
