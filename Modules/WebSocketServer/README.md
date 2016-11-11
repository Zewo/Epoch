# WebSocketServer

[![Swift][swift-badge]][swift-url]
[![Zewo][zewo-badge]][zewo-url]
[![Platform][platform-badge]][platform-url]
[![License][mit-badge]][mit-url]
[![Slack][slack-badge]][slack-url]
[![Travis][travis-badge]][travis-url]
[![Codebeat][codebeat-badge]][codebeat-url]

## Overview

**WebSocketServer** is an [S4-Compatible](https://github.com/open-swift/s4) [`Responder`](https://github.com/open-swift/S4/blob/master/Sources/Responder.swift) and [`Middleware`](https://github.com/open-swift/S4/blob/master/Sources/Middleware.swift) that establishes a WebSocket connection for each request.

## Installation

```swift
import PackageDescription

let package = Package(
    dependencies: [
        .Package(url: "https://github.com/Zewo/WebSocketServer.git", majorVersion: 0, minor: 14),
    ]
)
```

## Usage

In both of these examples, the [HTTPServer](https://github.com/Zewo/HTTPServer) module is used.

`WebSocketServer` can be used as a responder or a middleware:

```swift
import WebSocketServer
import HTTPServer

let server = WebSocketServer { req, ws in
    print("Connected!")
    ws.onText { text in
        print("text: \(text)")
        try ws.send(text)
    }
    ws.onClose {(code, reason) in
        print("\(code): \(reason)")
    }
}

try Server(responder: server).start()
```

It can also be created directly from a request:

```swift
import WebSocketServer
import HTTPServer

try Server { request in
    return try request.webSocket { req, ws in
        print("connected")

        ws.onBinary { data in
            print("data: \(data)")
            try ws.send(data)
        }
        ws.onText { text in
            print("data: \(text)")
            try ws.send(text)
        }
    }
}.start()
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
[zewo-badge]: https://img.shields.io/badge/Zewo-0.14-FF7565.svg?style=flat
[zewo-url]: http://zewo.io
[platform-badge]: https://img.shields.io/badge/Platforms-OS%20X%20--%20Linux-lightgray.svg?style=flat
[platform-url]: https://swift.org
[mit-badge]: https://img.shields.io/badge/License-MIT-blue.svg?style=flat
[mit-url]: https://tldrlegal.com/license/mit-license
[slack-image]: http://s13.postimg.org/ybwy92ktf/Slack.png
[slack-badge]: https://zewo-slackin.herokuapp.com/badge.svg
[slack-url]: http://slack.zewo.io
[travis-badge]: https://travis-ci.org/Zewo/WebSocketServer.svg?branch=master
[travis-url]: https://travis-ci.org/Zewo/WebSocketServer
[codebeat-badge]: https://codebeat.co/badges/cabe1795-6f5e-4fe6-85ab-5b68f1596efd
[codebeat-url]: https://codebeat.co/projects/github-com-zewo-websocketserver
