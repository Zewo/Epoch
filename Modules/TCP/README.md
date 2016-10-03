# TCP

[![Swift][swift-badge]][swift-url]
[![License][mit-badge]][mit-url]
[![Slack][slack-badge]][slack-url]
[![Travis][travis-badge]][travis-url]
[![Codecov][codecov-badge]][codecov-url]
[![Codebeat][codebeat-badge]][codebeat-url]

## Features

- [x] TCPConnection
- [x] TCPServer

##Usage

```swift
co {
    do {
        // create an echo server on localhost:8080
        let server = try TCPServer(host: "127.0.0.1", port: 8080)
        while true {
            // waits for an incoming connection, receives 1024 bytes, sends them back
            let connection = try server.accept()
            let data = try connection.receive(upTo: 1024)
            try connection.send(data)
        }
    } catch {
        print(error)
    }
}

nap(for: 100.milliseconds)

// create a connection to server at localhost:8080
let connection = try TCPConnection(host: "0.0.0.0", port: 8080)
// opens the connection, sends "hello"
try connection.open()
try connection.send("hello")
// waits for a message, prints it out
let data =  try connection.receive(upTo: 1024)
print(data)
```

## Installation

```swift
import PackageDescription

let package = Package(
    dependencies: [
        .Package(url: "https://github.com/VeniceX/Zewo.git", majorVersion: 0, minor: 14)
    ]
)
```

## Support

If you need any help you can join our [Slack](http://slack.zewo.io) and go to the **#help** channel. Or you can create a Github [issue](https://github.com/Zewo/Zewo/issues/new) in our main repository. When stating your issue be sure to add enough details, specify what module is causing the problem and reproduction steps.

## Community

[![Slack][slack-image]][slack-url]

The entire Zewo code base is licensed under MIT. By contributing to Zewo you are contributing to an open and engaged community of brilliant Swift programmers. Join us on [Slack](http://slack.zewo.io) to get to know us!

## License

This project is released under the MIT license. See [LICENSE](LICENSE) for details.

[swift-badge]: https://img.shields.io/badge/Swift-3.0-orange.svg?style=flat
[swift-url]: https://swift.org
[mit-badge]: https://img.shields.io/badge/License-MIT-blue.svg?style=flat
[mit-url]: https://tldrlegal.com/license/mit-license
[slack-image]: http://s13.postimg.org/ybwy92ktf/Slack.png
[slack-badge]: https://zewo-slackin.herokuapp.com/badge.svg
[slack-url]: http://slack.zewo.io
[travis-badge]: https://travis-ci.org/Zewo/TCP.svg?branch=master
[travis-url]: https://travis-ci.org/Zewo/TCP
[codecov-badge]: https://codecov.io/gh/Zewo/TCP/branch/master/graph/badge.svg
[codecov-url]: https://codecov.io/gh/Zewo/TCP
[codebeat-badge]: https://codebeat.co/badges/ee0a363b-234e-4513-a735-288b24c6bbdd
[codebeat-url]: https://codebeat.co/projects/github-com-zewo-tcp
