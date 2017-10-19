import XCTest
@testable import Media
import Foundation

struct Book : Codable {
    let author: String
    
    enum Key : String, CodingKey {
        case author = "Author"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        author = try container.decode(String.self, forKey: .author)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        try container.encode(author, forKey: .author)
    }
}

struct Catalog : Codable {
    let books: [Book]
    
    enum Key : String, CodingKey {
        case book = "Book"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        books = try container.decode([Book].self, forKey: .book)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        try container.encode(books, forKey: .book)
    }
}

struct Root : Codable {
    let catalog: Catalog
    
    enum Key : String, CodingKey {
        case catalog = "Catalog"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        catalog = try container.decode(Catalog.self, forKey: .catalog)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        try container.encode(catalog, forKey: .catalog)
    }
}

public class XMLTests: XCTestCase {
    func testXML() throws {
        let xml = XML(root:
            XML.Element(name: "Catalog", children: [
                XML.Element(name: "Book", attributes: ["id": "a"], children: [
                    XML.Element(name: "Author", children: ["Bob"]),
                ]),
                XML.Element(name: "Book", attributes: ["id": "b"], children: [
                    XML.Element(name: "Author", children: ["John"]),
                ]),
                XML.Element(name: "Book", attributes: ["id": "c"], children: [
                    XML.Element(name: "Author", children: ["Mark"]),
                ]),
            ])
        )
        
        var json: JSON = [
            "Catalog": [
                "Book": [
                    ["Author": "Bob"],
                    ["Author": "John"],
                    ["Author": "Mark"],
                ]
            ]
        ]
        
//        var root: Root
//
//        root = try Root(from: json)
//        print(root)
//        
//        root = try Root(from: xml)
//        print(root)
//
//        json = try JSON(from: root)
//        print(json)
    }
}

extension XMLTests {
    public static var allTests: [(String, (XMLTests) -> () throws -> Void)] {
        return [
            ("testXML", testXML),
        ]
    }
}
