public typealias MapProtocol = InMap & OutMap
public typealias Mappable = InMappable & OutMappable

public protocol StringInMappable: InMappable {
    init<Map: InMap>(mapper: StringInMapper<Map>) throws
}
