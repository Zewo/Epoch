# SQL

[![Swift][swift-badge]][swift-url]
[![Zewo][zewo-badge]][zewo-url]
[![Platform][platform-badge]][platform-url]
[![License][mit-badge]][mit-url]
[![Slack][slack-badge]][slack-url]
[![Travis][travis-badge]][travis-url]
[![Codebeat][codebeat-badge]][codebeat-url]

**SQL** provides

- [x] Base conformance for SQL database adapters
- [x] Typesafe table representations and queries (select, insert, join, etc.)
- [x] A powerful, _non-intrusive_ ORM

## Installation

The SQL module is bundled with the SQL adapters of Zewo

* [Postgres](https://github.com/Zewo/PostgreSQL)
* [MySQL](https://github.com/zewo/MySQL)

```swift
import PackageDescription

let package = Package(
    dependencies: [
        .Package(url: "https://github.com/Zewo/SQL.git", majorVersion: 0, minor: 14),
    ]
)
```

## Usage

Use this package with one of the supported drivers listed above.

### Connecting to a database

```swift
let info = Connection.ConnectionInfo(uri: URL("postgres://localhost:5432/database_name")!)!
let connection = PostgreSQL.Connection(info: info)
try connection.open()
```

### Executing raw queries

```swift
try connection.execute("SELECT * FROM artists")
let result = try connection.execute("SELECT * FROM artists WHERE name = %@", parameters: "Josh Rouse")
```

### Getting results from queries
```swift
let result = try connection.execute("SELECT * FROM artists")

for row in result {
	let name: String = try row.value("name")
	let genre: String? = try row.value("genre")
	print(name)
}
```

In the above example, an error will be thrown if `name` and `genre` is not present in the rows returned. An error will also be thrown if a `name` is `NULL` in any row, as the inferred type is non-optional. Note how `genre` will allow for a `NULL` value.

### Tables

You can define tables as such:

```swift
struct Artist : TableProtocol {
    enum Field : String, TableField {
        static let tableName = "artists"

        case id
        case name
        case genre
    }
}
```

```swift
Artist.select(where: Artist.Field.name == "Josh Rouse")
Artist.insert([.name : "AC/DC"])
Artist.update([.name : "AC/DC"]).filtered(Artist.Field.genre == "Rock")
Artist.delete(where: Artist.Field.genre == "Rock")
```

```swift
try connection.execute(Artist.select(where: Artist.Field.name == "Josh Rouse"))
```

### Models
Models provide more ORM-like functionality than tables. You can define models like so:

```swift
struct Artist {
    var name: String
    var genre: String
}

extension Artist : ModelProtocol {
    // Just like `Table`
    enum Field: String, ModelField {
        // notice how we define the "id" field
        // but don't have it as a property
        case id
        case name
        case genre

        // Specify a table name
        static let tableName = "artists"

        // Specify which field is primary
        static let primaryKey = Field.id
    }

    // Specify what type the primary key is (usually int or string)
    typealias PrimaryKey = Int

    // The values returned here will be persisted
    // primary key is inserted automatically
    func serialize() -> [Field : ValueConvertible?] {
        return [
            .name: name,
            .genre: genre
        ]
    }

    // Provide an initializer for the model taking a row
    // a little generic but dont let it scare you
    init<Row: RowProtocol>(row: TableRow<Artist, Row>) throws {
        try self.init(
            name: row.value(.name),
            genre: row.value(.genre)
        )
    }
}
```

```swift
// note how we operate on Entity<Artist> rather than just Artist.
// there also exists a type PersistedEntity<Artist>, which has a primary key
// and methods such as refresh and update
let rockArtists = try Entity<Artist>.fetch(where: Artist.Field.genre == "Rock", connection: connection)

for var artist in rockArtists {
    artist.model.genre = "Rock 'n Roll"
    // since artist is of type PersistedEntity<Artist> (has a primary key),
    // we can save it, replacing the previous record
    artist.save(connection: connection)
}

let newArtist = Artist(name: "Elijah Blake", genre: "Hip-hop")
let persistedArtist = try Entity(model: newArtist).create(connection: connection)
print("id of new artist: \(persistedArtist.primaryKey)")
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
[travis-badge]: https://travis-ci.org/Zewo/SQL.svg?branch=master
[travis-url]: https://travis-ci.org/Zewo/SQL
[codebeat-badge]: https://codebeat.co/badges/2548b359-daf1-404b-b5ae-687b98c02101
[codebeat-url]: https://codebeat.co/projects/github-com-zewo-sql
