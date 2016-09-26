import Foundation

public typealias MapProtocol = InMap & OutMap
public typealias Mappable = InMappable & OutMappable

public protocol StringInMappable : InMappable {
    init<Source : InMap>(mapper: StringInMapper<Source>) throws
}

public protocol StringOutMappable : OutMappable {
    func outMap<Destination : OutMap>(mapper: inout StringOutMapper<Destination>) throws
}
