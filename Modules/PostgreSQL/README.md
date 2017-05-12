# PostgreSQL

[![Swift][swift-badge]][swift-url]
[![Zewo][zewo-badge]][zewo-url]
[![Platform][platform-badge]][platform-url]
[![License][mit-badge]][mit-url]
[![Slack][slack-badge]][slack-url]
[![Travis][travis-badge]][travis-url]
[![Codebeat][codebeat-badge]][codebeat-url]

**PostgreSQL** adapter for **Swift 3.0**.

Conforms to [SQL](https://github.com/Zewo/SQL), which provides a common interface and ORM. Documentation can be found there.

## Installation

- Linux

```bash
$ apt-get install libpq-dev
```

- OSX

```bash
$ brew install postgresql
```

- Add `PostgreSQL` to your `Package.swift`

```swift
import PackageDescription

let package = Package(
    dependencies: [
        .Package(url: "https://github.com/Zewo/PostgreSQL.git", majorVersion: 0, minor: 14)
    ]
)

```

- Build on OSX
```bash
$ swift build -Xcc -I/usr/local/include -Xlinker -L/usr/local/lib/
```

- Generate Xcode project
```bash
$ swift package generate-xcodeproj -Xcc -I/usr/local/include -Xlinker -L/usr/local/lib/ -Xswiftc -I/usr/local/include
```

- Build on Linux
```bash
$ swift build -Xcc -I/usr/include/postgresql
```

## Community

[![Slack](http://s13.postimg.org/ybwy92ktf/Slack.png)](http://slack.zewo.io)

Join us on [Slack](http://slack.zewo.io).

## License

**PostgreSQL** is released under the MIT license. See LICENSE for details.

[swift-badge]: https://img.shields.io/badge/Swift-3.0-orange.svg?style=flat
[swift-url]: https://swift.org
[zewo-badge]: https://img.shields.io/badge/Zewo-0.14-FF7565.svg?style=flat
[zewo-url]: http://zewo.io
[platform-badge]: https://img.shields.io/badge/Platform-Mac%20%26%20Linux-lightgray.svg?style=flat
[platform-url]: https://swift.org
[mit-badge]: https://img.shields.io/badge/License-MIT-blue.svg?style=flat
[mit-url]: https://tldrlegal.com/license/mit-license
[slack-image]: http://s13.postimg.org/ybwy92ktf/Slack.png
[slack-badge]: https://zewo-slackin.herokuapp.com/badge.svg
[slack-url]: http://slack.zewo.io
[travis-badge]: https://travis-ci.org/Zewo/PostgreSQL.svg?branch=master
[travis-url]: https://travis-ci.org/Zewo/PostgreSQL
[codebeat-badge]: https://codebeat.co/badges/2548b359-daf1-404b-b5ae-687b98c02101
[codebeat-url]: https://codebeat.co/projects/github-com-zewo-postgresql
