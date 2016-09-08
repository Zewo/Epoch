<p align="center">
    <a href="http://zewo.io"><img src="https://raw.githubusercontent.com/Zewo/Zewo/master/Images/zewo.png" alt="Zewo"/></a>
</p>

<p align="center">
    <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-3.0-orange.svg?style=flat" alt="Swift" /></a>
    <a href="https://swift.org"><img src="https://img.shields.io/badge/Platforms-OS%20X%20--%20Linux-lightgray.svg?style=flat" alt="Platform" /></a>
    <a href="https://tldrlegal.com/license/mit-license"><img src="https://img.shields.io/badge/License-MIT-blue.svg?style=flat" alt="License" /></a>
    <a href="http://slack.zewo.io"><img src="https://zewo-slackin.herokuapp.com/badge.svg" alt="Slack" /></a>
    <a href="https://travis-ci.org/Zewo/Zewo"><img src="https://travis-ci.org/Zewo/Zewo.svg?branch=master" alt="Travis" /></a>
    <a href="#backers"><img src="https://opencollective.com/zewo/backers/badge.svg"></a>
    <a href="#sponsors"><img src="https://opencollective.com/zewo/sponsors/badge.svg"></a>
</p>

<p align="center">
    <a href="#getting-started">Getting Started</a>
  • <a href="#contributing">Contributing</a>
  • <a href="#umbrella-package">Umbrella Package</a>
  • <a href="#zewo-packages">Zewo Packages</a>
</p>

# Zewo
**Zewo** is a set of libraries for server side development. With **Zewo** you can write your web app, REST API, command line tool, database driver, etc. Our goal is to create an ecosystem around the modules and tools we provide so you can focus on developing your application or library, instead of doing everything from scratch.

Currently, we have around 50+ packages. This list grows very fast so it might be outdated. To be sure just check our [organization](https://github.com/Zewo).

# Getting started
## Swiftenv
[Swiftenv](https://github.com/kylef/swiftenv) allows you to easily install, and switch between multiple versions of Swift. You can install swiftenv following official [instructions](https://github.com/kylef/swiftenv#installation).

> ⚠️ With homebrew use `brew install kylef/formulae/swiftenv --HEAD`.

Once you have it, install the Swift Development Snapshot from **May 9, 2016**.

```sh
swiftenv install DEVELOPMENT-SNAPSHOT-2016-05-09-a
```

## Create your first Zewo web application
First we need to create a directory for our app.

```sh
mkdir hello && cd hello
```

Now we select the 05-09 toolchain with Swiftenv and initialize the project with Swift Package Manager (**SPM**).

```sh
swiftenv local DEVELOPMENT-SNAPSHOT-2016-05-09-a
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
        .Package(url: "https://github.com/VeniceX/HTTPServer.git", majorVersion: 0, minor: 7),
        .Package(url: "https://github.com/Zewo/Router.git", majorVersion: 0, minor: 7),
    ]
)
```

### Do your magic
Open `main.swift` and make it look like this:

```swift
import HTTPServer
import Router

let app = Router { route in
    route.get("/hello") { request in
        return Response(body: "Hello, world!")
    }
}

try Server(app).start()
```

This code:
- Creates an HTTP server that listens on port `8080` by default.
- Configures a router which will route `/hello` to a responder that responds with `"hello world"`.

### Build and run
Now let's build the app.

```sh
swift build
```

After it compiles, run it.

```sh
.build/debug/hello
```

Now open your favorite browser and go to [http://localhost:8080/hello](http://localhost:8080/hello). You should see `hello world` in your browser's window. 😊

### Xcode
Using an IDE can be a huge boost to productivity. Luckily, **SPM** has Xcode project generation support built in!

To generate your Zewo Xcode project simply run:
```sh
swift build -X
```

In some cases, the generated Xcode project produces linking errors during the build process. If that happens to be the case, run the following commands instead:
```sh
swift build
swift build -Xlinker -L$(pwd)/.build/debug -X
```

## What's next?
Zewo has a **lot** of [modules](#zewo-packages), check out our [organization](https://github.com/Zewo) for more. You can also take a look at our [documentation](http://docs.zewo.io/index.html) which is growing every day. If you have any doubts you can reach us at our [slack](http://slack.zewo.io). We're very active and always ready to help.

See also:
- [Deploying with Docker](http://docs.zewo.io/Docker.html)

## Umbrella Package
To make your life easier we provide the **Zewo** umbrella package which resides in this repository. This package provides the most important modules so you don't have to add all of them one by one.

```swift
import PackageDescription

let package = Package(
    dependencies: [
        .Package(url: "https://github.com/Zewo/Zewo.git", majorVersion: 0, minor: 7)
    ]
)
```

## Contributing
Hey! Like Zewo? Awesome! We could actually really use your help!

Open source isn't just writing code. Zewo could use your help with any of the following:
- Finding (and reporting!) bugs.
- New feature suggestions.
- Answering questions on issues.
- Documentation improvements.
- Reviewing pull requests.
- Helping to manage issue priorities.
- Fixing bugs/new features.

If any of that sounds cool to you, send a pull request! After a few [contributions](CONTRIBUTING.md), we'll add you to the organization team so you can merge pull requests and help steer the ship :ship:

Please note that this project is released with a Contributor Code of Conduct. By participating in this project you agree to abide by [its terms](CODEOFCONDUCT.md).

### Issues
Because we have lots of modules we use the [main repo](https://github.com/Zewo/Zewo) (this one) to track all our tasks, bugs, features, etc. using [Github issues](https://github.com/Zewo/Zewo/issues/new).

Some of us use [ZenHub](https://www.zenhub.io/) to manage the issues. Unfortunately ZenHub only supports Google Chrome and Firefox, but looks like they're working on [Safari support](https://github.com/ZenHubIO/support/issues/53).

## Zewo Packages
- [Base64](https://github.com/Zewo/Base64)
- [BasicAuthMiddleware](https://github.com/Zewo/BasicAuthMiddleware)
- [CHTTPParser](https://github.com/Zewo/CHTTPParser)
- [CLibpq](https://github.com/Zewo/CLibpq)
- [CLibXML2](https://github.com/Zewo/CLibXML2)
- [CMySQL](https://github.com/Zewo/CMySQL)
- [ContentNegotiationMiddleware](https://github.com/Zewo/ContentNegotiationMiddleware)
- [COpenSSL](https://github.com/Zewo/COpenSSL)
- [CURIParser](https://github.com/Zewo/CURIParser)
- [CZeroMQ](https://github.com/Zewo/CZeroMQ)
- [Event](https://github.com/Zewo/Event)
- [Flux](https://github.com/Zewo/Flux)
- [HTTP](https://github.com/Zewo/HTTP)
- [HTTPJSON](https://github.com/Zewo/HTTPJSON)
- [HTTPParser](https://github.com/Zewo/HTTPParser)
- [HTTPSerializer](https://github.com/Zewo/HTTPSerializer)
- [JSON](https://github.com/Zewo/JSON)
- [JSONMediaType](https://github.com/Zewo/JSONMediaType)
- [Log](https://github.com/Zewo/Log)
- [LogMiddleware](https://github.com/Zewo/LogMiddleware)
- [Mapper](https://github.com/Zewo/Mapper)
- [MediaType](https://github.com/Zewo/MediaType)
- [MessagePack](https://github.com/Zewo/MessagePack)
- [Mustache](https://github.com/Zewo/Mustache)
- [MySQL](https://github.com/Zewo/MySQL)
- [OpenSSL](https://github.com/Zewo/OpenSSL)
- [PathParameterMiddleware](https://github.com/Zewo/PathParameterMiddleware)
- [POSIX](https://github.com/Zewo/POSIX)
- [POSIXRegex](https://github.com/Zewo/POSIXRegex)
- [PostgreSQL](https://github.com/Zewo/PostgreSQL)
- [RecoveryMiddleware](https://github.com/Zewo/RecoveryMiddleware)
- [Reflection](https://github.com/Zewo/Reflection)
- [RegexRouteMatcher](https://github.com/Zewo/RegexRouteMatcher)
- [Resource](https://github.com/Zewo/Resource)
- [Router](https://github.com/Zewo/Router)
- [Sideburns](https://github.com/Zewo/Sideburns)
- [SQL](https://github.com/Zewo/SQL)
- [String](https://github.com/Zewo/String)
- [StructuredData](https://github.com/Zewo/StructuredData)
- [TrieRouteMatcher](https://github.com/Zewo/TrieRouteMatcher)
- [URI](https://github.com/Zewo/URI)
- [URLEncodedForm](https://github.com/Zewo/URLEncodedForm)
- [URLEncodedFormMediaType](https://github.com/Zewo/URLEncodedFormMediaType)
- [WebSocket](https://github.com/Zewo/WebSocket)
- [XML](https://github.com/Zewo/XML)
- [ZeroMQ](https://github.com/Zewo/ZeroMQ)

## VeniceX Packages
- [ChannelStream](https://github.com/VeniceX/ChannelStream)
- [CLibvenice](https://github.com/VeniceX/CLibvenice)
- [File](https://github.com/VeniceX/File)
- [HTTPClient](https://github.com/VeniceX/HTTPClient)
- [HTTPFile](https://github.com/VeniceX/HTTPFile)
- [HTTPSClient](https://github.com/VeniceX/HTTPSClient)
- [HTTPServer](https://github.com/VeniceX/HTTPServer)
- [HTTPSServer](https://github.com/VeniceX/HTTPSServer)
- [IP](https://github.com/VeniceX/IP)
- [TCP](https://github.com/VeniceX/TCP)
- [TCPSSL](https://github.com/VeniceX/TCPSSL)
- [UDP](https://github.com/VeniceX/UDP)
- [Venice](https://github.com/VeniceX/Venice)

## Other Packages
- [MiniRouter](https://github.com/paulofaria/MiniRouter)

## Community
[![Slack][slack-image]][slack-url]

The entire Zewo code base is licensed under MIT. By contributing to Zewo you are contributing to an open and engaged community of brilliant Swift programmers. Join us on [Slack](http://slack.zewo.io) to get to know us!

## Backers
Support us with a monthly donation and help us continue our activities. [[Become a backer](https://opencollective.com/zewo#backer)]

<a href="https://opencollective.com/zewo/backer/0/website" target="_blank"><img src="https://opencollective.com/zewo/backer/0/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/1/website" target="_blank"><img src="https://opencollective.com/zewo/backer/1/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/2/website" target="_blank"><img src="https://opencollective.com/zewo/backer/2/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/3/website" target="_blank"><img src="https://opencollective.com/zewo/backer/3/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/4/website" target="_blank"><img src="https://opencollective.com/zewo/backer/4/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/5/website" target="_blank"><img src="https://opencollective.com/zewo/backer/5/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/6/website" target="_blank"><img src="https://opencollective.com/zewo/backer/6/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/7/website" target="_blank"><img src="https://opencollective.com/zewo/backer/7/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/8/website" target="_blank"><img src="https://opencollective.com/zewo/backer/8/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/9/website" target="_blank"><img src="https://opencollective.com/zewo/backer/9/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/10/website" target="_blank"><img src="https://opencollective.com/zewo/backer/10/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/11/website" target="_blank"><img src="https://opencollective.com/zewo/backer/11/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/12/website" target="_blank"><img src="https://opencollective.com/zewo/backer/12/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/13/website" target="_blank"><img src="https://opencollective.com/zewo/backer/13/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/14/website" target="_blank"><img src="https://opencollective.com/zewo/backer/14/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/15/website" target="_blank"><img src="https://opencollective.com/zewo/backer/15/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/16/website" target="_blank"><img src="https://opencollective.com/zewo/backer/16/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/17/website" target="_blank"><img src="https://opencollective.com/zewo/backer/17/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/18/website" target="_blank"><img src="https://opencollective.com/zewo/backer/18/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/19/website" target="_blank"><img src="https://opencollective.com/zewo/backer/19/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/20/website" target="_blank"><img src="https://opencollective.com/zewo/backer/20/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/21/website" target="_blank"><img src="https://opencollective.com/zewo/backer/21/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/22/website" target="_blank"><img src="https://opencollective.com/zewo/backer/22/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/23/website" target="_blank"><img src="https://opencollective.com/zewo/backer/23/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/24/website" target="_blank"><img src="https://opencollective.com/zewo/backer/24/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/25/website" target="_blank"><img src="https://opencollective.com/zewo/backer/25/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/26/website" target="_blank"><img src="https://opencollective.com/zewo/backer/26/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/27/website" target="_blank"><img src="https://opencollective.com/zewo/backer/27/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/28/website" target="_blank"><img src="https://opencollective.com/zewo/backer/28/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/29/website" target="_blank"><img src="https://opencollective.com/zewo/backer/29/avatar.svg"></a>

## Sponsors
Become a sponsor and get your logo on our website Zewo.io and on our README on Github with a link to your site. [[Become a sponsor](https://opencollective.com/zewo#sponsor)]

<a href="https://opencollective.com/zewo/sponsor/0/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/0/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/1/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/1/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/2/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/2/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/3/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/3/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/4/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/4/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/5/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/5/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/6/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/6/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/7/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/7/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/8/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/8/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/9/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/9/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/10/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/10/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/11/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/11/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/12/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/12/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/13/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/13/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/14/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/14/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/15/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/15/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/16/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/16/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/17/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/17/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/18/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/18/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/19/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/19/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/20/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/20/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/21/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/21/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/22/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/22/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/23/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/23/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/24/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/24/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/25/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/25/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/26/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/26/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/27/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/27/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/28/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/28/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/29/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/29/avatar.svg"></a>

## License
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
[travis-badge]: https://travis-ci.org/Zewo/Zewo.svg?branch=master
[travis-url]: https://travis-ci.org/Zewo/Zewo
