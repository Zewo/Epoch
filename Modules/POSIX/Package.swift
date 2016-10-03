import PackageDescription

let package = Package(
    name: "POSIX",
    dependencies: [
        .Package(url: "https://github.com/Zewo/CPOSIX.git", majorVersion: 0, minor: 14),
    ]
)
