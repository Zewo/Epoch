# Mapper

[![Swift][swift-badge]][swift-url]
[![Zewo][zewo-badge]][zewo-url]
[![Platform][platform-badge]][platform-url]
[![License][mit-badge]][mit-url]
[![Slack][slack-badge]][slack-url]
[![Travis][travis-badge]][travis-url]
[![Codebeat][codebeat-badge]][codebeat-url]

**Mapper** is a tiny yet very powerful library which allows you to create custom strongly-typed instances from *any* kind of structured data (**JSON** and other data interchange formats, for example) with only a single initializer. And vice versa - with only a single method.

**Mapper** extensively uses power of Swift generics and protocols, dramatically reducing the boilerplate you have to write. With **Mapper**, mapping is a breeze.

The maing advantage of **Mapper** is that you don't need to write multiple initializers to support mapping from different formats (if you've done it before - you know what I mean), thus eliminating the boilerplate and leaving only the core logic you need. With **Mapper** your code is safe and expressive.

And while reducing boilerplate, **Mapper** is also amazingly fast. It doesn't use reflection, and generics allows the compiler to optimize code in the most effective way.

**Mapper** itself is just a core mapping logic without any implementations. To actually use **Mapper**, you also have to import one of Mapper-conforming libraries. You can find a current list of them [here](#conformers). If you want to support **Mapper** for your data types, checkout [Adopting Mapper](#adopting-mapper) short guide.

**Mapper** is deeply inspired by Lyft's [Mapper](https://github.com/lyft/mapper). You can learn more about the concept behind their idea in [this talk](https://realm.io/news/slug-keith-smiley-embrace-immutability/).

## Showcase

```swift
struct City : InMappable, OutMappable {
    let name: String
    let population: UInt
    
    init<Source : InMap>(mapper: InMapper<Source, Keys>) throws {
        self.name = try mapper.map(from: .name)
        self.population = try mapper.map(from: .population)
    }
    func outMap<Destination : OutMap>(mapper: inout OutMapper<Destination, City.Keys>) throws {
        try mapper.map(self.name, to: .name)
        try mapper.map(self.population, to: .population)
    }
    
    enum Keys : String, IndexPathElement {
        case name
        case population
    }
}

enum Gender : String {
    case male
    case female
}

// Mappable = InMappable & OutMappable
struct Person : Mappable {
    let name: String
    let gender: Gender
    let city: City
    let identifier: Int
    let isRegistered: Bool
    let biographyPoints: [String]
    
    init<Source : InMap>(mapper: InMapper<Source, Keys>) throws {
        self.name = try mapper.map(from: .name)
        self.gender = try mapper.map(from: .gender)
        self.city = try mapper.map(from: .city)
        self.identifier = try mapper.map(from: .identifier)
        self.isRegistered = try mapper.map(from: .registered)
        self.biographyPoints = try mapper.mapArray(from: .biographyPoints)
    }
    func outMap<Destination : OutMap>(mapper: inout OutMapper<Destination, Person.Keys>) throws {
        try mapper.map(self.name, to: .name)
        try mapper.map(self.gender, to: .gender)
        try mapper.map(self.city, to: .city)
        try mapper.map(self.identifier, to: .identifier)
        try mapper.map(self.isRegistered, to: .registered)
        try mapper.mapArray(self.biographyPoints, to: .biographyPoints)
    }
    
    enum Keys : String, IndexPathElement {
        case name
        case gender
        case city
        case identifier
        case registered
        case biographyPoints
    }
}

let jessy = Person(from: json)
let messi = Person(from: messagePack)
let michael = Person(from: mongoBSON)
// and so on...
```

## Usage

**Mapper** allows you to map data in both ways, and so it has two major parts: **in** mapping (for example, *JSON -> your model*) and **out** mapping (*your model -> JSON*). So the two main protocols of **Mapper** is `InMappable` and `OutMappable`.

One of the main advantages of **Mapper** is extreme type-safety. We want to get away from "stringy" API even in mappings, so we want you to create `Keys` enum inside each of your data model. That way you can boost your productivity and also avoid some painful typos:

```swift
struct Club : Mappable {
    
    let name: String
    let country: String
    let homeStadium: String
    let yearOfCreation: Int
    
    enum Keys : String, IndexPathElement {
        case name
        case country
        case homeStadium = "home-stadium"
        case yearOfCreation = "year-of-creation"
    }
    
    init<Source : InMap>(mapper: InMapper<Source, Keys>) throws {
        self.name = try mapper.map(from: .name)
        self.country = try mapper.map(from: .country)
        self.homeStadium = try mapper.map(from: .homeStadium)
        self.yearOfCreation = try mapper.map(from: .yearOfCreation)
    }
    
    func outMap<Destination : OutMap>(mapper: inout OutMapper<Destination, Keys>) throws {
        try mapper.map(self.name, to: .name)
        try mapper.map(self.country, to: .country)
        try mapper.map(self.homeStadium, to: .homeStadium)
        try mapper.map(self.yearOfCreation, to: .yearOfCreation)
    }
    
}
```

As you see, both mappers has two generic arguments: `Source`/`Destination`, which is the structured data format, and `Keys`, which is type-specific `Keys` defined for your model. 

---

**NOTE**: as you can see, `Keys` enum conforms to `IndexPathElement`, which is protocol defined by **Mapper**. Conformance is done automatically, but you should declare it. We also want to warn you that due to some unknown reasons, SourceKit is going crazy when you're starting writing `enum Keys : String, IndexPathElement { ...`, so we recommend you to first write your enum, and then declare `IndexPathElement` conformance.

---

This kind of behavior is expected by default, but you can substitute `Keys` with `String` if you don't want it:

```swift
struct Club : Mappable {
    
    let name: String
    let country: String
    let homeStadium: String
    let yearOfCreation: Int
    
    init<Source : InMap>(mapper: InMapper<Source, String>) throws {
        self.name = try mapper.map(from: "name")
        self.country = try mapper.map(from: "country")
        self.homeStadium = try mapper.map(from: "home-stadium")
        self.yearOfCreation = try mapper.map(from: "year-of-creation")
    }
    
    func outMap<Destination : OutMap>(mapper: inout OutMapper<Destination, String>) throws {
        try mapper.map(self.name, to: "name")
        try mapper.map(self.country, to: "county")
        try mapper.map(self.homeStadium, to: "home-stadium")
        try mapper.map(self.yearOfCreation, to: "year-of-creation")
    }
    
}
```

``` swift
import Mapper

struct User: Mappable {
    let id: Int
    let username: String
    let city: String?
    
    // Mappable requirement
    init(mapper: Mapper) throws {
        id = try mapper.map(from: "id")
        username = try mapper.map(from: "username")
        city = mapper.map(optionalFrom: "city")
    }
}

let content: StructuredData = [
    "id": 1654,
    "username": "fireringer",
    "city": "Houston"
]
let user = User.makeWith(structuredData: content) // User?
```

#### Basics

```swift
struct Club {
    let name: String
    let season: Int?
    let qualified: Bool
    
    enum Keys : String, IndexPathElement {
        case name
        case season
        case qualified
    }
}

extension Club : InMappable {
    init<Source : InMap>(mapper: InMapper<Source, Keys>) throws {
        self.name = try mapper.map(from: .name)
        self.season = try? mapper.map(from: .season)
        self.qualified = try mapper.map(from: .qualified)
    }
}

extension Club : OutMappable {
    func outMap<Destination : OutMap>(mapper: inout OutMapper<Destination, Club.Keys>) throws {
        try mapper.map(self.name, to: .name)
        try mapper.map(self.season ?? 0, to: .season)
        try mapper.map(self.qualified, to: .qualified)
    }
}
```

#### Mapping arrays

**Be careful!** If you use `map(from:)` instead of `mapArray(from:)`, mapping will fail. And if you get `wrongType` error, most likely that you've made that mistake.

```swift
struct Album: Mappable {
    let songs: [String]
    init(mapper: Mapper) throws {
        songs = try mapper.map(arrayFrom: "songs")
    }
}

struct Album: Mappable {
    let songs: [String]?
    init(mapper: Mapper) throws {
        songs = try mapper.map(optionalArrayFrom: "songs")
    }
}
```

#### Mapping enums
You can use **Mapper** for mapping enums with raw values. Right now you can use only `String`, `Int` and `Double` as raw value.

```swift
enum GuitarType: String {
    case acoustic
    case electric
}

struct Guitar: Mappable {
    let vendor: String
    let type: GuitarType
    
    init(mapper: Mapper) throws {
        vendor = try mapper.map(from: "vendor")
        type = try mapper.map(from: "type")
    }
}
```

#### Nested `Mappable` objects

```swift
struct League: Mappable {
    let name: String
    init(mapper: Mapper) throws {
        name = try mapper.map(from: "name")
    }
}

struct Club: Mappable {
    let name: String
    let league: League
    init(mapper: Mapper) throws {
        name = try mapper.map(from: "name")
        league = try mapper.map(from: "league")
    }
}
```

#### Using `StructuredDataInitializable`
`Mappable` is great for complex entities, but for the simplest one you can use `StructuredDataInitializable` protocol. `StructuredDataInitializable` objects can be initializaed from `StructuredData` itself, not from its `Mapper`. For example, **Mapper** uses `StructuredDataInitializable` to allow seamless `Int` conversion:

```swift
extension Int: StructuredDataInitializable {
    public init(structuredData value: StructuredData) throws {
        switch value {
        case .numberValue(let number):
            self.init(number)
        default:
            throw InitializableError.cantBindToNeededType
        }
    }
}
```

Now you can map `Int` using `from(_:)` just like anything else:

```swift
struct Generation: Mappable {
    let number: Int
    init(mapper: Mapper) throws {
        number = try mapper.map(from: "number")
    }
}
```

Conversion of `Int` is available in **Mapper** out of the box, and you can extend any other type to conform to `StructuredDataInitializable` yourself, for example, `NSDate`:

```swift
import Foundation
import Mapper

extension StructuredDataInitializable where Self: NSDate {
    public init(structuredData value: StructuredData) throws {
        switch value {
        case .numberValue(let number):
            self.init(timeIntervalSince1970: number)
        default:
            throw InitializableError.cantBindToNeededType
        }
    }
}

extension NSDate: StructuredDataInitializable { }
```

## Installation

- Add `Mapper` to your `Package.swift`

```swift
import PackageDescription

let package = Package(
    dependencies: [
        .Package(url: "https://github.com/Zewo/Mapper.git", majorVersion: 0, minor: 5),
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
[zewo-badge]: https://img.shields.io/badge/Zewo-edge-FF7565.svg?style=flat
[zewo-url]: http://zewo.io
[platform-badge]: https://img.shields.io/badge/Platforms-OS%20X%20--%20Linux-lightgray.svg?style=flat
[platform-url]: https://swift.org
[mit-badge]: https://img.shields.io/badge/License-MIT-blue.svg?style=flat
[mit-url]: https://tldrlegal.com/license/mit-license
[slack-image]: http://s13.postimg.org/ybwy92ktf/Slack.png
[slack-badge]: https://zewo-slackin.herokuapp.com/badge.svg
[slack-url]: http://slack.zewo.io
[travis-badge]: https://travis-ci.org/Zewo/Mapper.svg?branch=master
[travis-url]: https://travis-ci.org/Zewo/Mapper
[codebeat-badge]: https://codebeat.co/badges/d08bad48-c72e-49e3-a184-68a23063d461
[codebeat-url]: https://codebeat.co/projects/github-com-zewo-mapper