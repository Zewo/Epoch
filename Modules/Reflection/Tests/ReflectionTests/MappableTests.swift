import XCTest
import Reflection

typealias MappableDictionary = [String: Any]

enum MappableError : Error {
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
                throw MappableError.missingRequiredValue(key: property.key)
            }
        }
    }
}

public class MappableTests : XCTestCase {
    func testMappable() throws {
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

        XCTAssertEqual(person.firstName, "Jane")
        XCTAssertEqual(person.lastName, "Miller")
        XCTAssertEqual(person.age, 54)
        XCTAssertEqual(person.phoneNumber.number, "924-555-0294")
        XCTAssertEqual(person.phoneNumber.type, "work")
    }
}

extension MappableTests {
    public static var allTests: [(String, (MappableTests) -> () throws -> Void)] {
        return [
            ("testMappable", testMappable)
        ]
    }
}
