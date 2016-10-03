import PackageDescription

let package = Package(
    name: "UDP",
    dependencies: [
        .Package(url: "https://github.com/Zewo/POSIX.git", majorVersion: 0, minor: 14),
        .Package(url: "https://github.com/Zewo/IP.git", majorVersion: 0, minor: 14),
        // test-only dependencies (not yet available in swiftpm: SE-0019)
        .Package(url: "https://github.com/Zewo/Venice.git", majorVersion: 0, minor: 14),
    ]
)
