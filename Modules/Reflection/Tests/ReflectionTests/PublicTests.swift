import XCTest
import Reflection

struct Person : Equatable {
    var firstName: String
    var lastName: String
    var age: Int

    init(firstName: String, lastName: String, age: Int) {
        self.firstName = firstName
        self.lastName = lastName
        self.age = age
    }
}

func == (lhs: Person, rhs: Person) -> Bool {
    return lhs.firstName == rhs.firstName && lhs.lastName == rhs.lastName && lhs.age == rhs.age
}

class ReferencePerson : Equatable {
    var firstName: String
    var lastName: String
    var age: Int

    required init() {
        self.firstName = ""
        self.lastName = ""
        self.age = 0
    }

    init(firstName: String, lastName: String, age: Int) {
        self.firstName = firstName
        self.lastName = lastName
        self.age = age
    }
}

class SubclassedPerson : ReferencePerson {}

func == (lhs: ReferencePerson, rhs: ReferencePerson) -> Bool {
    return lhs.firstName == rhs.firstName && lhs.lastName == rhs.lastName && lhs.age == rhs.age
}

public class PublicTests : XCTestCase {
    
    func testConstructType() throws {
        for _ in 0..<1000 {
            let person: Person = try construct {
                (["firstName": "Brad", "lastName": "Hilton", "age": 27] as [String : Any])[$0.key]!
            }
            let other = Person(firstName: "Brad", lastName: "Hilton", age: 27)
            XCTAssert(person == other)
        }
    }
    
    func testConstructAnyType() throws {
        for _ in 0..<1000 {
            let type: Any.Type = Person.self
            let person: Any = try construct(type) {
                (["firstName": "Brad", "lastName": "Hilton", "age": 27] as [String : Any])[$0.key]!
            }
            let other = Person(firstName: "Brad", lastName: "Hilton", age: 27)
            XCTAssert(person as! Person == other)
        }
    }

    func testConstructFlags() throws {
        struct Flags {
            let x: Bool
            let y: Bool?
            let z: (Bool, Bool)
        }
        let flags: Flags = try construct(dictionary: [
            "x": false,
            "y": nil as Optional<Bool>,
            "z": (true, false)
        ] as [String : Any])
        XCTAssert(!flags.x)
        XCTAssert(flags.y == nil)
        XCTAssert(flags.z == (true, false))
    }

    func testConstructObject() throws {
        struct Object {
            let flag: Bool
            let pair: (UInt8, UInt8)
            let float: Float?
            let integer: Int
            let string: String
        }
        let object: Object = try construct(dictionary: [
           "flag": true,
           "pair": (UInt8(1), UInt8(2)),
           "float": Optional(Float(89.0)),
           "integer": 123,
           "string": "Hello, world"
        ] as [String : Any])
        XCTAssert(object.flag)
        XCTAssert(object.pair == (1, 2))
        XCTAssert(object.float == 89.0)
        XCTAssert(object.integer == 123)
        XCTAssert(object.string == "Hello, world")
    }

    func testPropertiesForInstance() throws {
        var props: [Property] = []
        let person = Person(firstName: "Brad", lastName: "Hilton", age: 27)
        props = try properties(person)
        guard props.count == 3 else {
            XCTFail("Unexpected number of properties"); return
        }
        guard let firstName = props[0].value as? String, let lastName = props[1].value as? String, let age = props[2].value as? Int else {
            XCTFail("Unexpected properties"); return
        }
        XCTAssert(person.firstName == firstName)
        XCTAssert(person.lastName == lastName)
        XCTAssert(person.age == age)
    }

    func testSetValueForKeyOfInstance() throws {
        var person = Person(firstName: "Brad", lastName: "Hilton", age: 27)
        try set("Lawrence", key: "firstName", for: &person)
        XCTAssert(person.firstName == "Lawrence")
    }

    func testValueForKeyOfInstance() throws {
        let person = Person(firstName: "Brad", lastName: "Hilton", age: 29)
        let firstName: String = try get("firstName", from: person)
        XCTAssert(person.firstName == firstName)
        let referencePerson = ReferencePerson(firstName: "Brad", lastName: "Hilton", age: 29)
        let referenceFirstName: String = try get("firstName", from: referencePerson)
        XCTAssert(referencePerson.firstName == referenceFirstName)
        func testAnonymousValue(value: Any) throws {
            let firstName: String = try get("firstName", from: value)
            XCTAssert(person.firstName == firstName)
        }
        try testAnonymousValue(value: person)
        try testAnonymousValue(value: referencePerson)
    }

    func testValueIs() {
        XCTAssert(Reflection.value("John", is: String.self))
        XCTAssert(Reflection.value(89, is: Int.self))
        XCTAssert(Reflection.value(["Larry"], is: Array<String>.self))
        XCTAssert(!Reflection.value("John", is: Array<String>.self))
        XCTAssert(!Reflection.value(89, is: String.self))
        XCTAssert(!Reflection.value(["Larry"], is: Int.self))
        let person = Person(firstName: "Hillary", lastName: "Mason", age: 32)
        let referencePerson = ReferencePerson()
        let subclassedPerson = SubclassedPerson()
        XCTAssert(Reflection.value(person, is: Person.self))
        XCTAssert(Reflection.value(referencePerson, is: ReferencePerson.self))
        XCTAssert(!Reflection.value(person, is: ReferencePerson.self))
        XCTAssert(!Reflection.value(referencePerson, is: Person.self))
        XCTAssert(Reflection.value(subclassedPerson, is: SubclassedPerson.self))
        XCTAssert(Reflection.value(subclassedPerson, is: ReferencePerson.self))
        XCTAssert(!Reflection.value(referencePerson, is: SubclassedPerson.self))
    }

    func testMemoryProperties() {
        func testMemoryProperties<T>(_ type: T.Type) {
            XCTAssert(alignof(T.self as Any.Type) == MemoryLayout<T>.alignment)
            XCTAssert(sizeof(T.self as Any.Type) == MemoryLayout<T>.size)
            XCTAssert(strideof(T.self as Any.Type) == MemoryLayout<T>.stride)
        }
        testMemoryProperties(Bool.self)
        testMemoryProperties(UInt8.self)
        testMemoryProperties(UInt16.self)
        testMemoryProperties(UInt32.self)
        testMemoryProperties(Float.self)
        testMemoryProperties(Double.self)
        testMemoryProperties(String.self)
        testMemoryProperties(Array<Int>.self)
    }
    
    func testCString() {
        do {
            let firstName = "Brad".withCString { return String(cString: $0) }
            let lastName = "Hill".withCString { return String(cString: $0) }
            let indirectStorage = ["firstName" : firstName, "lastName" : lastName]
            var person: Person = try construct(dictionary: [
                "firstName": firstName,
                "lastName": "Hilton",
                "age": 27
                ])
            try set(lastName, key: "lastName", for: &person)
            XCTAssert(indirectStorage["firstName"]! == person.firstName)
            XCTAssert(indirectStorage["lastName"]! == person.lastName)
        } catch {}
    }
    
    func testConstructionErrors() {
        do {
            let _: Person = try construct(dictionary: [:])
            XCTFail()
        } catch let constructionErrors as ConstructionErrors {
            let expectedErrors: [ReflectionError] = [
                .requiredValueMissing(key: "firstName"),
                .requiredValueMissing(key: "lastName"),
                .requiredValueMissing(key: "age")
            ]
            XCTAssertEqual(constructionErrors.errors.flatMap { $0 as? ReflectionError }, expectedErrors)
        } catch {
            XCTFail()
        }
    }
    
}

extension PublicTests {
    public static var allTests: [(String, (PublicTests) -> () throws -> Void)] {
        return [
            ("testConstructType", testConstructType),
            ("testConstructFlags", testConstructFlags),
            ("testConstructObject", testConstructObject),
            ("testPropertiesForInstance", testPropertiesForInstance),
            ("testSetValueForKeyOfInstance", testSetValueForKeyOfInstance),
            ("testValueForKeyOfInstance", testValueForKeyOfInstance),
            ("testValueIs", testValueIs),
            ("testMemoryProperties", testMemoryProperties),
            ("testCString", testCString)
        ]
    }
}
