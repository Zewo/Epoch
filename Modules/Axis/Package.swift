import PackageDescription

let package = Package(
    name: "Core",
        dependencies: [
        .Package(url: "https://github.com/Zewo/POSIX.git", majorVersion: 0, minor: 13),
        .Package(url: "https://github.com/Zewo/Reflection.git", majorVersion: 0, minor: 13),
    ]
)
