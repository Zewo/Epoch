# POSIXRegex

[![Swift][swift-badge]][swift-url]
[![Zewo][zewo-badge]][zewo-url]
[![Platform][platform-badge]][platform-url]
[![License][mit-badge]][mit-url]
[![Slack][slack-badge]][slack-url]
[![Travis][travis-badge]][travis-url]
[![Codebeat][codebeat-badge]][codebeat-url]

**POSIXRegex** provides POSIX Regular Expressions for **Swift 3.0**.

## Features

- [x] Matches
- [x] Groups
- [x] Replace

## Usage

```swift
import POSIXRegex

let regex = try Regex(pattern: "hello")
regex.matches("hello") // true
regex.matches("bye") // false

let regex = try Regex(pattern: "(hello)")
regex.groups("hello") // ["hello"]
regex.groups("bye") // []

let regex = try Regex(pattern: "(hello) (world)")
let groups = regex.groups("hello world") // ["hello", "world"]

let regex = try Regex(pattern: "hello")
regex.replace("hello world", withTemplate: "bye") // "bye world"
```

## Installation

- Add `POSIXRegex` to your `Package.swift`

```swift
import PackageDescription

let package = Package(
    dependencies: [
        .Package(url: "https://github.com/Zewo/POSIXRegex.git", majorVersion: 0, minor: 12),
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
[zewo-badge]: https://img.shields.io/badge/Zewo-0.5-FF7565.svg?style=flat
[zewo-url]: http://zewo.io
[platform-badge]: https://img.shields.io/badge/Platforms-OS%20X%20--%20Linux-lightgray.svg?style=flat
[platform-url]: https://swift.org
[mit-badge]: https://img.shields.io/badge/License-MIT-blue.svg?style=flat
[mit-url]: https://tldrlegal.com/license/mit-license
[slack-image]: http://s13.postimg.org/ybwy92ktf/Slack.png
[slack-badge]: https://zewo-slackin.herokuapp.com/badge.svg
[slack-url]: http://slack.zewo.io
[travis-badge]: https://travis-ci.org/Zewo/POSIXRegex.svg?branch=master
[travis-url]: https://travis-ci.org/Zewo/POSIXRegex
[codebeat-badge]: https://codebeat.co/badges/306a1e43-e6b5-4da3-b239-e36c3bec5bda
[codebeat-url]: https://codebeat.co/projects/github-com-zewo-posixregex
