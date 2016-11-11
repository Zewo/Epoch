# Reflection

[![Swift][swift-badge]][swift-url]
[![License][mit-badge]][mit-url]
[![Slack][slack-badge]][slack-url]
[![Travis][travis-badge]][travis-url]
[![Codecov][codecov-badge]][codecov-url]
[![Codebeat][codebeat-badge]][codebeat-url]

**Reflection** provides an API for advanced reflection at runtime including dynamic construction of types.

## Usage

```swift
import Reflection

struct Person {
  var firstName: String
  var lastName: String
  var age: Int
}

// Reflects the instance properties of type `Person`
let properties = try properties(Person)

var person = Person(firstName: "John", lastName: "Smith", age: 35)

// Retrieves the value of `person.firstName`
let firstName: String = try get("firstName", from: person)

// Sets the value of `person.age`
try set(36, key: "age", for: &person)

// Creates a `Person` from a dictionary
let friend: Person = try construct(dictionary: ["firstName" : "Sarah",
                                                "lastName" : "Gates",
                                                "age" : 28])


```

## Installation

```swift
import PackageDescription

let package = Package(
    dependencies: [
        .Package(url: "https://github.com/Zewo/Reflection.git", majorVersion: 0, minor: 14),
    ]
)
```

## Advanced Usage

```swift
// `Reflection` can be extended for higher-level packages to do mapping and serializing.
// Here is a simple `Mappable` protocol that allows deserializing of arbitrary nested structures.

import Reflection

typealias MappableDictionary = [String : Any]

enum Error : ErrorProtocol {
    case missingRequiredValue(key: String)
}

protocol Mappable {
    init(dictionary: MappableDictionary) throws
}

extension Mappable {

    init(dictionary: MappableDictionary) throws {
        self = try construct { property in
            if let value = dictionary[property.key] {
                if let type = property.type as? Mappable.Type, let value = value as? MappableDictionary {
                    return try type.init(dictionary: value)
                } else {
                    return value
                }
            } else {
                throw Error.missingRequiredValue(key: property.key)
            }
        }
    }

}

struct Person : Mappable {
    var firstName: String
    var lastName: String
    var age: Int
    var phoneNumber: PhoneNumber
}

struct PhoneNumber : Mappable {
    var number: String
    var type: String
}

let dictionary = [
    "firstName" : "Jane",
    "lastName" : "Miller",
    "age" : 54,
    "phoneNumber" : [
        "number" : "924-555-0294",
        "type" : "work"
    ] as MappableDictionary
] as MappableDictionary

let person = try Person(dictionary: dictionary)

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
[travis-badge]: https://travis-ci.org/Zewo/Reflection.svg?branch=master
[travis-url]: https://travis-ci.org/Zewo/Reflection
[codecov-badge]: https://codecov.io/gh/Zewo/Reflection/branch/master/graph/badge.svg
[codecov-url]: https://codecov.io/gh/Zewo/Reflection
[codebeat-badge]: https://codebeat.co/badges/85f3c10b-6574-4956-8c58-bb6ad3ea1268
[codebeat-url]: https://codebeat.co/projects/github-com-zewo-reflection
