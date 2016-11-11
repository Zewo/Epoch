import XCTest
import Foundation
@testable import Mapper

struct Test1: InMappable {
    let int: Int
    let string: String
    let double: Double
    let bool: Bool
    init<Source : InMap>(mapper: InMapper<Source, MappingKeys>) throws {
        self.int = try mapper.map(from: .int)
        self.string = try mapper.map(from: .string)
        self.double = try mapper.map(from: .double)
        self.bool = try mapper.map(from: .bool)
    }
    enum MappingKeys: String, IndexPathElement {
        case int
        case string
        case double
        case bool
    }
}

struct Nest2: InMappable {
    let int: Int
    init<Source : InMap>(mapper: InMapper<Source, MappingKeys>) throws {
        self.int = try mapper.map(from: .int)
    }
    enum MappingKeys: String, IndexPathElement {
        case int
    }
}

struct Test2: InMappable {
    let string: String
    let ints: [Int]
    let nest: Nest2
    init<Source : InMap>(mapper: InMapper<Source, MappingKeys>) throws {
        self.string = try mapper.map(from: .string)
        self.ints = try mapper.map(from: .ints)
        self.nest = try mapper.map(from: .nest)
    }
    enum MappingKeys: String, IndexPathElement {
        case string
        case ints
        case nest
    }
}

struct Test3: InMappable {
    let rio: String
    init<Source : InMap>(mapper: InMapper<Source, MappingKeys>) throws {
        self.rio = try mapper.map(from: .rio)
    }
    enum MappingKeys: String, IndexPathElement {
        case rio = "rio-2016"
    }
}

struct Test4: InMappable {
    let ints: [Int]
    init<Source : InMap>(mapper: InMapper<Source, MappingKeys>) throws {
        self.ints = try mapper.map(from: .ints)
    }
    enum MappingKeys: String, IndexPathElement {
        case ints
    }
}

struct Test5: InMappable {
    let nests: [Nest2]
    init<Source : InMap>(mapper: InMapper<Source, MappingKeys>) throws {
        self.nests = try mapper.map(from: .nests)
    }
    enum MappingKeys: String, IndexPathElement {
        case nests
    }
}

enum StringEnum: String {
    case venice
    case annecy
    case quark
}

enum IntEnum: Int {
    case kharkiv = 1
    case kiev = 2
}

struct Test6: InMappable {
    let string: StringEnum
    let int: IntEnum
    init<Source : InMap>(mapper: InMapper<Source, MappingKeys>) throws {
        self.string = try mapper.map(from: .string)
        self.int = try mapper.map(from: .int)
    }
    enum MappingKeys: String, IndexPathElement {
        case string = "next-big-thing"
        case int = "city"
    }
}

struct Test7: InMappable {
    let strings: [StringEnum]
    let ints: [IntEnum]
    init<Source : InMap>(mapper: InMapper<Source, MappingKeys>) throws {
        self.strings = try mapper.map(from: .strings)
        self.ints = try mapper.map(from: .ints)
    }
    enum MappingKeys: String, IndexPathElement {
        case strings = "zewo-projects"
        case ints = "ukraine-capitals"
    }
}

struct Test8: InMappable {
    let string: StringEnum
    init<Source : InMap>(mapper: InMapper<Source, MappingKeys>) throws {
        self.string = try mapper.map(from: .string)
    }
    enum MappingKeys: String, IndexPathElement {
        case string = "project"
    }
}

enum TestContext {
    case apple
    case peach
    case orange
}

struct Nest3: InMappableWithContext {
    let int: Int
    typealias Context = TestContext
    init<Source : InMap>(mapper: ContextualInMapper<Source, String, Context>) throws {
        switch mapper.context {
        case .apple:
            int = try mapper.map(from: "apple-int")
        case .peach:
            int = try mapper.map(from: "peach-int")
        case .orange:
            int = try mapper.map(from: "orange-int")
        }
    }
}

struct Test9: InMappableWithContext {
    let nest: Nest3
    init<Source : InMap>(mapper: ContextualInMapper<Source, String, TestContext>) throws {
        self.nest = try mapper.map(from: "nest")
    }
}

struct Test10: InMappableWithContext {
    let nests: [Nest3]
    init<Source : InMap>(mapper: ContextualInMapper<Source, String, TestContext>) throws {
        self.nests = try mapper.map(from: "nests")
    }
}

struct Test11: BasicInMappable {
    let nest: Nest3
    let nests: [Nest3]
    init<Source : InMap>(mapper: BasicInMapper<Source>) throws {
        self.nest = try mapper.map(from: "nest", withContext: .peach)
        self.nests = try mapper.map(from: "nests", withContext: .orange)
    }
}

struct Test12: BasicInMappable {
    let hiddenFar: String
    init<Source : InMap>(mapper: BasicInMapper<Source>) throws {
        self.hiddenFar = try mapper.map(from: "deeper", "stillDeeper", "close", "gotcha")
    }
}

struct Test13: InMappable {
    let nests: [Nest2]
    init<Source : InMap>(mapper: PlainInMapper<Source>) throws {
        self.nests = try mapper.map()
    }
}

struct DictNest: BasicInMappable {
    let int: Int
    init<Source : InMap>(mapper: BasicInMapper<Source>) throws {
        self.int = try mapper.map(from: "int")
    }
}

struct DictTest: InMappable {
    let int: Int
    let string: String
    let double: Double
    let nest: DictNest
    let strings: [String]
    let nests: [DictNest]
    let null: Bool?
    init<Source : InMap>(mapper: InMapper<Source, String>) throws {
        self.int = try mapper.map(from: "int")
        self.string = try mapper.map(from: "here", "string")
        self.double = try mapper.map(from: "double")
        self.nest = try mapper.map(from: "nest")
        self.strings = try mapper.map(from: "strings")
        self.nests = try mapper.map(from: "nests")
        self.null = nil
    }
}

enum AdvancedEnum {
    case fire(rate: Int)
    case takeAim(when: TimeInterval)
    enum MappingKeys: String, IndexPathElement {
        case main
        case rate
        case timeInterval = "time-interval"
    }
}

extension AdvancedEnum: OutMappable {
    func outMap<Map : OutMap>(mapper: inout OutMapper<Map, MappingKeys>) throws {
        switch self {
        case .fire(rate: let rate):
            try mapper.map("fire", to: .main)
            try mapper.map(rate, to: .rate)
        case .takeAim(when: let time):
            try mapper.map("take-aim", to: .main)
            try mapper.map(time, to: .timeInterval)
        }
    }
}

extension AdvancedEnum: InMappable {
    init<Source : InMap>(mapper: InMapper<Source, MappingKeys>) throws {
        let main: String = try mapper.map(from: .main)
        switch main {
        case "fire":
            let rate: Int = try mapper.map(from: .rate)
            self = .fire(rate: rate)
        case "take-aim":
            let time: TimeInterval = try mapper.map(from: .timeInterval)
            self = .takeAim(when: time)
        default:
            throw InMapperError.userDefinedError
        }
    }
}

#if os(macOS)
    extension BasicInMappable where Self : NSDate {
        public init<Source : InMap>(mapper: BasicInMapper<Source>) throws {
            let interval: TimeInterval = try mapper.map()
            self.init(timeIntervalSince1970: interval)
        }
    }
    
    extension NSDate : BasicInMappable { }
    
    struct Test15 : InMappable {
        let date: NSDate
        
        enum MappingKeys : String, IndexPathElement {
            case date
        }
        
        init<Source : InMap>(mapper: InMapper<Source, MappingKeys>) throws {
            self.date = try mapper.map(from: .date)
        }
    }
#endif

public enum DateMappingContext {
    case timeIntervalSince1970
    case timeIntervalSinceReferenceDate
}

extension Date : InMappableWithContext {
    public typealias Context = DateMappingContext
    
    public init<Source : InMap>(mapper: PlainContextualInMapper<Source, Context>) throws {
        let interval: TimeInterval = try mapper.map()
        switch mapper.context {
        case .timeIntervalSince1970:
            self.init(timeIntervalSince1970: interval)
        case .timeIntervalSinceReferenceDate:
            self.init(timeIntervalSinceReferenceDate: interval)
        }
    }
}

class InMapperTests: XCTestCase {
    
    func testPrimitiveMapping() throws {
        let primitiveDict: Map = ["int": 5, "string": "String", "double": 7.8, "bool": true]
        let test = try Test1(from: primitiveDict)
        XCTAssertEqual(test.int, 5)
        XCTAssertEqual(test.string, "String")
        XCTAssertEqual(test.double, 7.8)
        XCTAssertEqual(test.bool, true)
    }
    
    func testBasicNesting() throws {
        let dict: Map = ["string": "Rio-2016", "ints": [2, 5, 4], "nest": ["int": 11]]
        let test = try Test2(from: dict)
        XCTAssertEqual(test.string, "Rio-2016")
        XCTAssertEqual(test.ints, [2, 5, 4])
        XCTAssertEqual(test.nest.int, 11)
    }
    
    func testFailNoValue() {
        let dict: Map = ["string": "Rio-2016"]
        XCTAssertThrowsError(try Test3(from: dict)) { error in
            guard let cError = error as? InMapperError, case .noValue = cError else {
                print(error)
                XCTFail("Wrong error thrown; must be .noValue")
                return
            }
        }
    }
    
    func testFailWrongType() {
        let dict: Map = ["rio-2016": 2016]
        XCTAssertThrowsError(try Test3(from: dict)) { error in
            guard let error = error as? InMapperError, case .wrongType = error else {
                XCTFail("Wrong error thrown; must be .wrongType")
                return
            }
        }
    }
    
    func testFailRepresentAsArray() {
        let dict: Map = ["ints": false]
        XCTAssertThrowsError(try Test4(from: dict)) { error in
            guard let error = error as? InMapperError, case .cannotRepresentAsArray = error else {
                XCTFail("Wrong error thrown; must be .cannotRepresentAsArray")
                return
            }
        }
    }
    
    func testArrayOfMappables() throws {
        let nests: [Map] = [3, 1, 4, 6, 19].map({ .dictionary(["int": .int($0)]) })
        let dict: Map = ["nests": .array(nests)]
        let test = try Test5(from: dict)
        XCTAssertEqual(test.nests.map({ $0.int }), [3, 1, 4, 6, 19])
    }
    
    func testEnumMapping() throws {
        let dict: Map = ["next-big-thing": "quark", "city": 1]
        let test = try Test6(from: dict)
        XCTAssertEqual(test.string, .quark)
        XCTAssertEqual(test.int, .kharkiv)
    }
    
    func testEnumArrayMapping() throws {
        let dict: Map = ["zewo-projects": ["venice", "annecy", "quark"], "ukraine-capitals": [1, 2]]
        let test = try Test7(from: dict)
        XCTAssertEqual(test.strings, [.venice, .annecy, .quark])
        XCTAssertEqual(test.ints, [.kharkiv, .kiev])
    }
    
    func testEnumFail() {
        let dict: Map = ["project": "swansea"]
        XCTAssertThrowsError(try Test8(from: dict)) { error in
            guard let error = error as? InMapperError, case .cannotInitializeFromRawValue = error else {
                XCTFail("Wrong error thrown; must be .cannotInitializeFromRawValue")
                return
            }
        }
    }
    
    func testBasicMappingWithContext() throws {
        let appleDict: Map = ["apple-int": 1]
        let apple = try Nest3(from: appleDict, withContext: .apple)
        XCTAssertEqual(apple.int, 1)
        let peachDict: Map = ["peach-int": 2]
        let peach = try Nest3(from: peachDict, withContext: .peach)
        XCTAssertEqual(peach.int, 2)
        let orangeDict: Map = ["orange-int": 3]
        let orange = try Nest3(from: orangeDict, withContext: .orange)
        XCTAssertEqual(orange.int, 3)
    }
    
    func testContextInference() throws {
        let peach: Map = ["nest": ["peach-int": 207]]
        _ = try Test9(from: peach, withContext: .peach)
    }
    
    func testArrayMappingWithContext() throws {
        let oranges: [Map] = [2, 0, 1, 6].map({ .dictionary(["orange-int": $0]) })
        let dict: Map = ["nests": .array(oranges)]
        _ = try Test10(from: dict, withContext: .orange)
    }
    
    func testUsingContext() throws {
        let dict: Map = ["nest": ["peach-int": 10], "nests": [["orange-int": 15]]]
        _ = try Test11(from: dict)
    }
    
    func testDeep() throws {
        let deepDict: Map = ["deeper": ["stillDeeper": ["close": ["gotcha": "Ukrainian Gold Medal"]]]]
        let deep = try Test12(from: deepDict)
        XCTAssertEqual(deep.hiddenFar, "Ukrainian Gold Medal")
    }
    
    func testFlatArray() throws {
        let dict: Map = [["int": 15], ["int": 21]]
        let test = try Test13(from: dict)
        XCTAssertEqual(test.nests.map({ $0.int }), [15, 21])
    }
    
//    func testStringAnyExhaustive() throws {
//        let stringDict: [String: Any] = ["string": "Quark"]
//        let nestDict: [String: Any] = ["int": 3]
//        let nestsDictArray: [[String: Any]] = sequence(first: 1, next: { if $0 < 6 { return $0 + 1 } else { return nil } }).map({ ["int": $0] })
//        let stringsArray: [Any] = ["rope", "summit"]
//        let hugeDict: [String: Any] = [
//            "int": Int(5),
//            "here": stringDict,
//            "double": Double(8.1),
//            "nest": nestDict,
//            "strings": stringsArray,
//            "nests": nestsDictArray,
//            ]
//        let result = try DictTest(from: hugeDict)
//        print(result)
//    }
    
    func testAdvancedEnum() throws {
        let fire = AdvancedEnum.fire(rate: 10)
        let fireMap: Map = try fire.map()
        let backFire = try AdvancedEnum(from: fireMap)
        if case .fire(let rate) = backFire {
            XCTAssertEqual(rate, 10)
        } else {
            print(backFire)
            XCTFail()
        }
    }
    
    func testExternalMappable() throws {
        #if os(macOS)
            let date = NSDate()
            let map: Map = [
                "date": Map(date.timeIntervalSince1970)
            ]
            let test = try Test15(from: map)
            XCTAssertEqual(test.date.timeIntervalSince1970, date.timeIntervalSince1970)
        #endif
    }
    
    func testDateMapping() throws {
        let dateMap = Map(5.0)
        let date1970 = try Date(from: dateMap, withContext: .timeIntervalSince1970)
        XCTAssertEqual(date1970, Date(timeIntervalSince1970: 5.0))
        
        let date2001 = try Date(from: dateMap, withContext: .timeIntervalSinceReferenceDate)
        XCTAssertEqual(date2001, Date(timeIntervalSinceReferenceDate: 5.0))
    }
    
}
