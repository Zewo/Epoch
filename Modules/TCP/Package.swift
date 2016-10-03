import PackageDescription

let package = Package(
    name: "TCP",
    dependencies: [
        .Package(url: "https://github.com/Zewo/IP.git", majorVersion: 0, minor: 14),
        .Package(url: "https://github.com/Zewo/Venice.git", majorVersion: 0, minor: 14),
        .Package(url: "https://github.com/Zewo/OpenSSL.git", majorVersion: 0, minor: 14),
    ]
)
