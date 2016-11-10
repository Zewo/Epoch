import XCTest
import Foundation
@testable import Mapper

extension Test1: OutMappable {
    func outMap<Map : OutMap>(mapper: inout OutMapper<Map, MappingKeys>) throws {
        try mapper.map(self.int, to: .int)
        try mapper.map(self.double, to: .double)
        try mapper.map(self.string, to: .string)
        try mapper.map(self.bool, to: .bool)
    }
}

extension Nest2: OutMappable {
    func outMap<Map : OutMap>(mapper: inout OutMapper<Map, MappingKeys>) throws {
        try mapper.map(self.int, to: .int)
    }
}

extension Test2: OutMappable {
    func outMap<Map : OutMap>(mapper: inout OutMapper<Map, MappingKeys>) throws {
        try mapper.map(self.string, to: .string)
        try mapper.map(self.ints, to: .ints)
        try mapper.map(self.nest, to: .nest)
    }
}

struct Test14: BasicOutMappable {
    let array: [Int]
    func outMap<Map : OutMap>(mapper: inout BasicOutMapper<Map>) throws {
        try mapper.map(self.array, to: "array")
    }
}

extension Test5: OutMappable {
    func outMap<Map : OutMap>(mapper: inout OutMapper<Map, MappingKeys>) throws {
        try mapper.map(self.nests, to: .nests)
    }
}

extension Test6: OutMappable {
    func outMap<Map : OutMap>(mapper: inout OutMapper<Map, MappingKeys>) throws {
        try mapper.map(self.string, to: .string)
        try mapper.map(self.int, to: .int)
    }
}

extension Test7: OutMappable {
    func outMap<Map : OutMap>(mapper: inout OutMapper<Map, MappingKeys>) throws {
        try mapper.map(self.strings, to: .strings)
        try mapper.map(self.ints, to: .ints)
    }
}

extension Nest3: OutMappableWithContext {
    func outMap<Map : OutMap>(mapper: inout ContextualOutMapper<Map, String, TestContext>) throws {
        switch mapper.context {
        case .apple:
            try mapper.map(self.int, to: "apple-int")
        case .peach:
            try mapper.map(self.int, to: "peach-int")
        case .orange:
            try mapper.map(self.int, to: "orange-int")
        }
    }
}

extension Test9: OutMappableWithContext {
    func outMap<Map : OutMap>(mapper: inout ContextualOutMapper<Map, String, TestContext>) throws {
        try mapper.map(self.nest, to: "nest")
    }
}

extension Test10: OutMappableWithContext {
    func outMap<Map : OutMap>(mapper: inout ContextualOutMapper<Map, String, TestContext>) throws {
        try mapper.map(self.nests, to: "nests")
    }
}

extension Test11: BasicOutMappable {
    func outMap<Map : OutMap>(mapper: inout BasicOutMapper<Map>) throws {
        try mapper.map(self.nest, to: "nest", withContext: .peach)
        try mapper.map(self.nests, to: "nests", withContext: .orange)
    }
}

struct OutDictNest: BasicOutMappable {
    let int: Int
    func outMap<Map : OutMap>(mapper: inout BasicOutMapper<Map>) throws {
        try mapper.map(self.int, to: "int")
    }
}

struct OutDictTest: BasicOutMappable {
    let int: Int
    let string: String
    let nest: OutDictNest
    let strings: [String]
    let nests: [OutDictNest]
    func outMap<Map : OutMap>(mapper: inout BasicOutMapper<Map>) throws {
        try mapper.map(int, to: "int")
        try mapper.map(string, to: "string")
        try mapper.map(nest, to: "nest")
        try mapper.map(strings, to: "strings")
        try mapper.map(nests, to: "nests")
    }
}

#if os(macOS)
    extension BasicOutMappable where Self : NSDate {
        public func outMap<Destination : OutMap>(mapper: inout BasicOutMapper<Destination>) throws {
            try mapper.map(self.timeIntervalSince1970)
        }
    }
    
    extension NSDate : BasicOutMappable { }
    
    extension Test15 : OutMappable {
        func outMap<Destination : OutMap>(mapper: inout OutMapper<Destination, Test15.MappingKeys>) throws {
            try mapper.map(self.date, to: .date)
        }
    }
#endif

extension Date : OutMappableWithContext {
    public func outMap<Destination : OutMap>(mapper: inout PlainContextualOutMapper<Destination, DateMappingContext>) throws {
        switch mapper.context {
        case .timeIntervalSince1970:
            try mapper.map(self.timeIntervalSince1970)
        case .timeIntervalSinceReferenceDate:
            try mapper.map(self.timeIntervalSinceReferenceDate)
        }
    }
}

class OutMapperTests: XCTestCase {
    
    func testPrimitiveTypesMapping() throws {
        let map: Map = ["int": 15, "double": 32.0, "string": "Hello", "bool": true]
        let test = try Test1(from: map)
        let unmap = try test.map() as Map
        XCTAssertEqual(map, unmap)
    }
    
    func testBasicNesting() throws {
        let dict: Map = ["string": "Rio-2016", "ints": [2, 5, 4], "nest": ["int": 11]]
        let test = try Test2(from: dict)
        let back: Map = try test.map()
        XCTAssertEqual(dict, back)
    }
    
//    func testFailWrongType() {
//        let test = Test14(array: [1, 2, 3, 4, 5])
//        XCTAssertThrowsError(try test.map() as Map) { error in
//            guard let error = error as? OutMapperError, case .wrongType = error else {
//                XCTFail("Wrong error thrown; must be .wrongType")
//                return
//            }
//        }
//    }
    
    func testArrayOfMappables() throws {
        let nests: [Map] = [3, 1, 4, 6, 19].map({ .dictionary(["int": .int($0)]) })
        let dict: Map = ["nests": .array(nests)]
        let test = try Test5(from: dict)
        let back = try test.map() as Map
        XCTAssertEqual(dict, back)
    }
    
    func testEnumMappng() throws {
        let dict: Map = ["next-big-thing": "quark", "city": 1]
        let test = try Test6(from: dict)
        let back = try test.map() as Map
        XCTAssertEqual(dict, back)
    }
    
    func testEnumArrayMapping() throws {
        let dict: Map = ["zewo-projects": ["venice", "annecy", "quark"], "ukraine-capitals": [1, 2]]
        let test = try Test7(from: dict)
        let back = try test.map() as Map
        XCTAssertEqual(dict, back)
    }
    
    func testBasicMappingWithContext() throws {
        let appleDict: Map = ["apple-int": 1]
        let apple = try Nest3(from: appleDict, withContext: .apple)
        XCTAssertEqual(appleDict, try apple.map(withContext: .apple))
        let peachDict: Map = ["peach-int": 2]
        let peach = try Nest3(from: peachDict, withContext: .peach)
        XCTAssertEqual(peachDict, try peach.map(withContext: .peach))
        let orangeDict: Map = ["orange-int": 3]
        let orange = try Nest3(from: orangeDict, withContext: .orange)
        XCTAssertEqual(orangeDict, try orange.map(withContext: .orange))
    }
    
    func testContextInference() throws {
        let peachDict: Map = ["nest": ["peach-int": 207]]
        let peach = try Test9(from: peachDict, withContext: .peach)
        XCTAssertEqual(peachDict, try peach.map(withContext: .peach))
    }
    
    func testArrayMappingWithContext() throws {
        let orangesDict: [Map] = [2, 0, 1, 6].map({ .dictionary(["orange-int": $0]) })
        let dict: Map = ["nests": .array(orangesDict)]
        let oranges = try Test10(from: dict, withContext: .orange)
        let back = try oranges.map(withContext: .orange) as Map
        XCTAssertEqual(dict, back)
    }
    
    func testUsingContext() throws {
        let dict: Map = ["nest": ["peach-int": 10], "nests": [["orange-int": 15]]]
        let test = try Test11(from: dict)
        XCTAssertEqual(dict, try test.map())
    }
    
    func testExternalMappable() throws {
        #if os(macOS)
            let date = NSDate()
            let dict: Map = [
                "date": Map(date.timeIntervalSince1970)
            ]
            let test = try Test15(from: dict)
            let back = try test.map() as Map
            let backDate: TimeInterval = back["date"].double!
            XCTAssertEqual(date.timeIntervalSince1970, backDate)
        #endif
    }
    
    func testDateMapping() throws {
        let date1970 = Date.init(timeIntervalSince1970: 5.0)
        let date1970Map: Map = try date1970.map(withContext: .timeIntervalSince1970)
        XCTAssertEqual(date1970Map.double!, 5.0)
        
        let date2001 = Date.init(timeIntervalSinceReferenceDate: 5.0)
        let date2001Map: Map = try date2001.map(withContext: .timeIntervalSinceReferenceDate)
        XCTAssertEqual(date2001Map.double!, 5.0)
    }
    
//    func testStringAnyExhaustive() throws {
//        // expected
//        let nestDict: [String: Any] = ["int": 3]
//        let nestsDictArray: [[String: Any]] = sequence(first: 1, next: { if $0 < 6 { return $0 + 1 } else { return nil } }).map({ ["int": $0] })
//        let stringsArray: [Any] = ["rope", "summit"]
//        let hugeDict: [String: Any] = [
//            "int": Int(5),
//            "string": "Quark",
//            "nest": nestDict,
//            "strings": stringsArray,
//            "nests": nestsDictArray,
//            ]
//        //
//        let nest = OutDictNest(int: 3)
//        let nests = sequence(first: 1, next: { if $0 < 6 { return $0 + 1 } else { return nil } }).map({ OutDictNest(int: $0) })
//        let test = OutDictTest(int: 5, string: "Quark", nest: nest, strings: ["rope", "summit"], nests: nests)
//        let back = try test.map() as [String: Any]
//        XCTAssertEqual(back as NSDictionary, hugeDict as NSDictionary)
//    }
    
}
