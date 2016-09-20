import XCTest
@testable import Mapper



class MapperTests: XCTestCase {
    
}

struct Some: StringInMappable {
    let int: Int
    init<Map : InMap>(mapper: InMapper<Map, String>) throws {
        self.int = try mapper.map(from: "int")
    }
}
