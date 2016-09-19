import PackageDescription

let package = Package(
    name: "RethinkDB",
    dependencies: [
        .Package(url: "https://github.com/Zewo/TCP.git", majorVersion: 0, minor: 13),
    ]
)
