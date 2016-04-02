# Zewo

[![Swift][swift-badge]][swift-url]
[![Platform][platform-badge]][platform-url]
[![License][mit-badge]][mit-url]
[![Slack][slack-badge]][slack-url]

**Zewo** is a set of libraries for server side development. With **Zewo** you can write your web app, REST API, command line tool, database driver, etc. Our goal is to create an ecosystem around the modules and tools we provide so you can focus on developing your application or library, instead of doing everything from scratch.

Currently, we have around 50+ packages. This list grows very fast so it might be outdated. To be sure just check our [organization](https://github.com/Zewo).

# Quick Links

- [Documentation](#whats-next)
- [Getting started](#getting-started)
- [Umbrella Package](#umbrella-package)
- [Contributing](#contributing)
- [Packages](#zewo-packages)
- [Community](#community)

# Getting started

## Installation

Before we start we need to install some tools and dependencies.

>You can skip swiftenv step and some swiftenv instructions below if you already have `DEVELOPMENT-SNAPSHOT-2016-02-08-a` in your `PATH`, but we highly recommend look at it.

## Swiftenv

[Swiftenv](https://github.com/kylef/swiftenv) allows you to easily install, and switch between multiple versions of Swift.
You can install swiftenv following official [instructions](https://github.com/kylef/swiftenv#installation)
>note: if you use homebrew add `--HEAD` option as the stable version has some issues.

## OS X

### Install Xcode 7.3+

[Xcode](https://developer.apple.com/xcode/) is apple's software development IDE.

- [Xcode Download](https://developer.apple.com/xcode/download/)

### Install Homebrew

[Homebrew](http://brew.sh/) is a package manager for OS X.

```sh
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

### Install Zewo

This brew formula installs all **Zewo** dependencies.

```sh
brew install zewo/tap/zewo
```

## Linux

### Install Clang and ICU

```sh
sudo apt-get install clang libicu-dev
```

### Install Zewo

```sh
echo "deb [trusted=yes] http://apt.zewo.io/deb ./" | sudo tee --append /etc/apt/sources.list
sudo apt-get update
sudo apt-get install zewo
```

## Create your first Zewo web application

First we need to create a directory for our app.

```sh
mkdir hello && cd hello
```

Then we install Swift Development Snapshot from **February 8, 2016**.

```sh
swiftenv install DEVELOPMENT-SNAPSHOT-2016-02-08-a
swiftenv local DEVELOPMENT-SNAPSHOT-2016-02-08-a
```

Now we initialize the project with Swift Package Manager (**SPM**).

```sh
swift build --init
```

This command will create the basic structure for our app.

```
.
├── Package.swift
├── Sources
│   └── main.swift
└── Tests
```

Open `Package.swift` with your favorite editor and add `HTTPServer`, `Router` as dependencies.

```swift
import PackageDescription

let package = Package(
    name: "hello",
    dependencies: [
        .Package(url: "https://github.com/Zewo/HTTPServer.git", majorVersion: 0, minor: 3),
        .Package(url: "https://github.com/Zewo/Router.git", majorVersion: 0, minor: 3),
    ]
)
```

### Do your magic

Open `main.swift` and make it look like this:

```swift
import HTTPServer
import Router

let router = Router { route in
    route.get("/hello") { _ in
        return Response(body: "hello world")
    }
}

try Server(responder: router).start()
```

This code:

- Creates an HTTP server that listens on port `8080` by default.
- Configures a router which will route `/hello` to a responder that responds with `"hello world"`.
- Mounts a logger middleware on the server that will log every request/response pair to the standard error stream (stderr) by default.

### Build and run

Now let's build the app.

```sh
swift build
```

After it compiles, run it.

```sh
.build/debug/hello
```

Now open your favorite browser and go to http://localhost:8080/hello. You should see `hello world` in your browser's window. 😊

## What's next?

Zewo has a **lot** of [modules](#zewo-packages), check out our [organization](https://github.com/Zewo) for more. You can also take a look at our [documentation](http://docs.zewo.io/index.html) which is growing every day. If you have any doubts you can reach us at our [slack](http://slack.zewo.io). We're very active and always ready to help.

See also:

- [Developing with Xcode](http://docs.zewo.io/Xcode.html)
- [Developing with Docker](http://docs.zewo.io/Docker.html)

## Umbrella Package

To make your life easier we provide the **Zewo** umbrella package which resides in this repository. This package provides the most important modules so you don't have to add all of them one by one.

```swift
import PackageDescription

let package = Package(
    dependencies: [
        .Package(url: "https://github.com/Zewo/Zewo.git", majorVersion: 0, minor: 3)
    ]
)
```

## Contributing

Hey! Like Zewo? Awesome! We could actually really use your help!

Open source isn't just writing code. Zewo could use your help with any of the
following:

- Finding (and reporting!) bugs.
- New feature suggestions.
- Answering questions on issues.
- Documentation improvements.
- Reviewing pull requests.
- Helping to manage issue priorities.
- Fixing bugs/new features.

If any of that sounds cool to you, send a pull request! After a few
contributions, we'll add you to the organization team so you can merge pull requests and help steer the ship :ship:

Please note that this project is released with a Contributor Code of Conduct. By participating in this project you agree to abide by [its terms](CODEOFCONDUCT.md).

### Issues

Because we have lots of modules we use the [main repo](https://github.com/Zewo/Zewo) (this one) to track all our tasks, bugs, features, etc. using [Github issues](https://github.com/Zewo/Zewo/issues/new).

Some of us use [ZenHub](https://www.zenhub.io/) to manage the issues. Unfortunately ZenHub only supports Google Chrome and Firefox, but looks like they're working on [Safari support](https://github.com/ZenHubIO/support/issues/53).

## Zewo Packages

- [Base64](https://github.com/Zewo/Base64)
- [BasicAuthMiddleware](https://github.com/Zewo/BasicAuthMiddleware)
- [ChannelStream](https://github.com/Zewo/ChannelStream)
- [CHTTPParser](https://github.com/Zewo/CHTTPParser)
- [CLibpq](https://github.com/Zewo/CLibpq)
- [CLibpq-OSX](https://github.com/Zewo/CLibpq-OSX)
- [CLibvenice](https://github.com/Zewo/CLibvenice)
- [CMySQL](https://github.com/Zewo/CMySQL)
- [CMySQL-OSX](https://github.com/Zewo/CMySQL-OSX)
- [ContentNegotiationMiddleware](https://github.com/Zewo/ContentNegotiationMiddleware)
- [COpenSSL](https://github.com/Zewo/COpenSSL)
- [COpenSSL-OSX](https://github.com/Zewo/COpenSSL-OSX)
- [CURIParser](https://github.com/Zewo/CURIParser)
- [CZeroMQ](https://github.com/Zewo/CZeroMQ)
- [Data](https://github.com/Zewo/Data)
- [Event](https://github.com/Zewo/Event)
- [File](https://github.com/Zewo/File)
- [HTTP](https://github.com/Zewo/HTTP)
- [http_parser](https://github.com/Zewo/http_parser)
- [HTTPClient](https://github.com/Zewo/HTTPClient)
- [HTTPServer](https://github.com/Zewo/HTTPServer)
- [HTTPFile](https://github.com/Zewo/HTTPFile)
- [HTTPSClient](https://github.com/Zewo/HTTPSClient)
- [HTTPSServer](https://github.com/Zewo/HTTPSServer)
- [InterchangeData](https://github.com/Zewo/InterchangeData)
- [IP](https://github.com/Zewo/IP)
- [JSON](https://github.com/Zewo/JSON)
- [JSONMediaType](https://github.com/Zewo/JSONMediaType)
- [libvenice](https://github.com/Zewo/libvenice)
- [Log](https://github.com/Zewo/Log)
- [LogMiddleware](https://github.com/Zewo/LogMiddleware)
- [MediaType](https://github.com/Zewo/MediaType)
- [Mustache](https://github.com/Zewo/Mustache)
- [MySQL](https://github.com/Zewo/MySQL)
- [OpenSSL](https://github.com/Zewo/OpenSSL)
- [POSIXRegex](https://github.com/Zewo/POSIXRegex)
- [PostgreSQL](https://github.com/Zewo/PostgreSQL)
- [RegexRouteMatcher](https://github.com/Zewo/RegexRouteMatcher)
- [Router](https://github.com/Zewo/Router)
- [Sideburns](https://github.com/Zewo/Sideburns)
- [SQL](https://github.com/Zewo/SQL)
- [Stream](https://github.com/Zewo/Stream)
- [String](https://github.com/Zewo/String)
- [System](https://github.com/Zewo/System)
- [TCP](https://github.com/Zewo/TCP)
- [TCPSSL](https://github.com/Zewo/TCPSSL)
- [TrieRouteMatcher](https://github.com/Zewo/TrieRouteMatcher)
- [UDP](https://github.com/Zewo/UDP)
- [URI](https://github.com/Zewo/URI)
- [uri_parser](https://github.com/Zewo/uri_parser)
- [URLEncodedForm](https://github.com/Zewo/URLEncodedForm)
- [Venice](https://github.com/Zewo/Venice)
- [WebSocket](https://github.com/Zewo/WebSocket)
- [Zewo](https://github.com/Zewo/Zewo)

## External Packages

- [Redis](https://github.com/rabc/swift-redis/)
- [MiniRouter](https://github.com/paulofaria/MiniRouter)

### Code

If you want to contribute with code you should use our development tool [zewo-dev](https://github.com/Zewo/zewo-dev). It makes it much easier to deal with the multitude of packages we maintain.

## Community

[![Slack][slack-image]][slack-url]

The entire Zewo code base is licensed under MIT. By contributing to Zewo you are contributing to an open and engaged community of brilliant Swift programmers. Join us on [Slack](http://slack.zewo.io) to get to know us!

License
-------

**Zewo** is released under the MIT license. See [LICENSE](https://raw.githubusercontent.com/Zewo/Zewo/master/LICENSE) for details.

[swift-badge]: https://img.shields.io/badge/Swift-3.0-orange.svg?style=flat
[swift-url]: https://swift.org
[platform-badge]: https://img.shields.io/badge/Platform-Mac%20%26%20Linux-lightgray.svg?style=flat
[platform-url]: https://swift.org
[mit-badge]: https://img.shields.io/badge/License-MIT-blue.svg?style=flat
[mit-url]: https://tldrlegal.com/license/mit-license
[slack-image]: http://s13.postimg.org/ybwy92ktf/Slack.png
[slack-badge]: https://zewo-slackin.herokuapp.com/badge.svg
[slack-url]: http://slack.zewo.io
