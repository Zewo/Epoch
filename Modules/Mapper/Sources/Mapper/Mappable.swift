public typealias MapProtocol = InMap & OutMap
public typealias Mappable = InMappable & OutMappable

public protocol StringInMappable: InMappable {
    init<Map: InMap>(mapper: StringInMapper<Map>) throws
}

public struct Testi: InMappable {
    let stringi: String
    public init<Map : InMap>(mapper: InMapper<Map, Keys>) throws {
        self.stringi = try mapper.map(from: .stringi)
    }
    public enum Keys: String, IndexPathElement {
        case stringi
    }
}


