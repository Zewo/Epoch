import PackageDescription

let package = Package(
    name: "OpenSSL",
    dependencies: [
        .Package(url: "https://github.com/Zewo/Axis.git", majorVersion: 0, minor: 14),
        .Package(url: "https://github.com/Zewo/COpenSSL.git", majorVersion: 0, minor: 14)
    ]
)
