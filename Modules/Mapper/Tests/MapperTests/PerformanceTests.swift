import XCTest
import Mapper

struct Primitive : Mappable {
    let int: Int
    let string: String
    let bool: Bool
    let double: Double
    
    enum MappingKeys : String, IndexPathElement {
        case int, string, bool, double
    }
    
    init<Source : InMap>(mapper: InMapper<Source, MappingKeys>) throws {
        self.int = try mapper.map(from: .int)
        self.string = try mapper.map(from: .string)
        self.bool = try mapper.map(from: .bool)
        self.double = try mapper.map(from: .double)
    }
    func outMap<Destination : OutMap>(mapper: inout OutMapper<Destination, Primitive.MappingKeys>) throws {
        try mapper.map(self.int, to: .int)
        try mapper.map(self.string, to: .string)
        try mapper.map(self.bool, to: .bool)
        try mapper.map(self.double, to: .double)
    }
}

struct PrimitiveWrap : InMappable {
    let primitive: Primitive
    let ints: [Int]
    
    enum MappingKeys : String, IndexPathElement {
        case primitive, ints
    }
    
    init<Source : InMap>(mapper: InMapper<Source, MappingKeys>) throws {
        self.primitive = try mapper.map(from: .primitive)
        self.ints = try mapper.map(from: .ints)
    }
}

struct UnsafePrimitive : InMappable {
    let int: Int
    let string: String
    let bool: Bool
    let double: Double
    
    typealias MappingKeys = Primitive.MappingKeys
    
    init<Source : InMap>(mapper: InMapper<Source, MappingKeys>) throws {
        self.int = try mapper.unsafe_map(from: .int)
        self.string = try mapper.unsafe_map(from: .string)
        self.bool = try mapper.unsafe_map(from: .bool)
        self.double = try mapper.unsafe_map(from: .double)
    }
}

struct DirectPrimitive {
    let int: Int
    let string: String
    let bool: Bool
    let double: Double
    
    init?(map: Map) {
        guard let int = map["int"].int,
            let string = map["string"].string,
            let bool = map["bool"].bool,
            let double = map["double"].double else {
                return nil
        }
        self.int = int
        self.string = string
        self.bool = bool
        self.double = double
    }
}

class PerformanceTests : XCTestCase {
    
    let dicts = (1 ... 100000).map({ ["int": Map($0), "string": Map(String($0)), "bool": Map($0 % 2 == 0), "double": Map(Double($0))] as Map })
    
    func testPerformancePrim() {
        measure {
            var prims = [Primitive]()
            for dict in self.dicts {
                let prim = try! Primitive(from: dict)
                prims.append(prim)
            }
        }
    }
    
    func testPerformanceUnsafe() {
        measure {
            var prims = [UnsafePrimitive]()
            for dict in self.dicts {
                let prim = try! UnsafePrimitive(from: dict)
                prims.append(prim)
            }
        }
    }
    
    func testPerformanceDirect() {
        measure {
            var prims = [DirectPrimitive]()
            for dict in self.dicts {
                let prim = DirectPrimitive(map: dict)!
                prims.append(prim)
            }
        }
    }
    
}
