import PackageDescription

#if os(OSX)
    let openSSLURL = "https://github.com/Zewo/COpenSSL-OSX.git"
#else
    let openSSLURL = "https://github.com/Zewo/COpenSSL.git"
#endif

let package = Package(
    name: "Zewo",
    dependencies: [
        .Package(url: "https://github.com/Zewo/HTTPServer.git", majorVersion: 0, minor: 2),
        .Package(url: "https://github.com/Zewo/HTTPClient.git", majorVersion: 0, minor: 2),
        .Package(url: "https://github.com/Zewo/HTTPSServer.git", majorVersion: 0, minor: 2),
        .Package(url: "https://github.com/Zewo/HTTPSClient.git", majorVersion: 0, minor: 2),
        .Package(url: "https://github.com/Zewo/HTTPFile.git", majorVersion: 0, minor: 2),
        .Package(url: "https://github.com/Zewo/TCP.git", majorVersion: 0, minor: 2),
        .Package(url: "https://github.com/Zewo/UDP.git", majorVersion: 0, minor: 2),
        .Package(url: "https://github.com/Zewo/OpenSSL.git", majorVersion: 0, minor: 2),
        .Package(url: "https://github.com/Zewo/Router.git", majorVersion: 0, minor: 2),
        .Package(url: "https://github.com/Zewo/JSON.git", majorVersion: 0, minor: 2),
        .Package(url: "https://github.com/Zewo/URLEncodedForm.git", majorVersion: 0, minor: 2),
        .Package(url: "https://github.com/Zewo/Base64.git", majorVersion: 0, minor: 2),
        .Package(url: "https://github.com/Zewo/ChannelStream.git", majorVersion: 0, minor: 2),
        .Package(url: "https://github.com/Zewo/LogMiddleware.git", majorVersion: 0, minor: 2),
        .Package(url: "https://github.com/Zewo/ContentNegotiationMiddleware.git", majorVersion: 0, minor: 2),
        .Package(url: "https://github.com/Zewo/SQL.git", majorVersion: 0, minor: 2),
        .Package(url: openSSLURL, majorVersion: 0, minor: 2),
        .Package(url: "https://github.com/Zewo/CLibvenice.git", majorVersion: 0, minor: 2),
        .Package(url: "https://github.com/Zewo/CHTTPParser.git", majorVersion: 0, minor: 2),
        .Package(url: "https://github.com/Zewo/CURIParser.git", majorVersion: 0, minor: 2)
    ]
)
