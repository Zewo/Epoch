# HTTPClient

[![Swift][swift-badge]][swift-url]
[![License][mit-badge]][mit-url]
[![Slack][slack-badge]][slack-url]
[![Travis][travis-badge]][travis-url]
[![Codecov][codecov-badge]][codecov-url]
[![Codebeat][codebeat-badge]][codebeat-url]

## Installation

```swift
import PackageDescription

let package = Package(
    dependencies: [
        .Package(url: "https://github.com/Zewo/HTTPClient.git", majorVersion: 0, minor: 14)
    ]
)
```

## Usage

### Creating a client

```swift
let client = try Client(url: "http://httpbin.org")
```

### Basic GET request

```swift
let response = try client.get("/get")
```

### POST request with JSON body

```swift
let content: Map = [
    "hello": "world",
    "numbers": [1, 2, 3, 4, 5]
]
let body = try JSONMapSerializer.serialize(content)
let response = try client.post("/post", body: body)
```

### Parsing response body

```swift
// converts response to a common type `Map` from pool of types
let contentNegotiation = ContentNegotiationMiddleware(mediaTypes: [.json, .urlEncodedForm], mode: .client)
let response = try client.get("/get", middleware: [contentNegotiation])
print(response.content)
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
[travis-badge]: https://travis-ci.org/Zewo/HTTPClient.svg?branch=master
[travis-url]: https://travis-ci.org/Zewo/HTTPClient
[codecov-badge]: https://codecov.io/gh/Zewo/HTTPClient/branch/master/graph/badge.svg
[codecov-url]: https://codecov.io/gh/Zewo/HTTPClient
[codebeat-badge]: https://codebeat.co/badges/bc032b4e-3a28-413e-a71c-c7467ce24499
[codebeat-url]: https://codebeat.co/projects/github-com-zewo-httpclient
