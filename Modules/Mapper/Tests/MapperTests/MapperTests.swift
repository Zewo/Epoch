import XCTest
@testable import Mapper

class MapperTests: XCTestCase {
    
}

struct Testi: InMappable {
    let stringi: String
    enum Keys: String, IndexPathElement {
        case stringi
    }
    init<Map : InMap>(mapper: InMapper<Map, Keys>) throws {
        self.stringi = try mapper.map(from: .stringi)
    }
}

enum Keys: IndexPathElement {
    case one
    case two
    var indexPathValue: IndexPathValue {
        switch self {
        case .one: return .key("one")
        case .two: return .index(2)
        }
    }
}

struct Testii : InMappable {
    let stringi: String
    init<Map : InMap>(mapper: InMapper<Map, IndexPathValue>) throws {
        self.stringi = try mapper.map(from: "level", 1)
    }
}

struct Nitesti : InMappable {
    let stringi: String
    init<Map : InMap>(mapper: InMapper<Map, Keys>) throws {
        self.stringi = try mapper.map(from: .stringi)
    }
    enum Keys : String, IndexPathElement {
        case stringi
    }
}


