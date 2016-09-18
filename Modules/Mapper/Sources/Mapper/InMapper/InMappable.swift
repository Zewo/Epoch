public protocol InMappable {
    
    associatedtype Keys: IndexPathElement
    init<Map: InMapProtocol>(mapper: InMapper<Map, Keys>) throws
    
}

public protocol InMappableWithContext: InMappable {
    
    associatedtype Context
    associatedtype Keys: IndexPathElement
    
    init<Map: InMapProtocol>(mapper: ContextualInMapper<Map, Keys, Context>) throws
    
}

extension InMappableWithContext {
    
    public init<Map: InMapProtocol>(mapper: InMapper<Map, Keys>) throws {
        let contextual = ContextualInMapper<Map, Keys, Context>(of: mapper.inMap, context: nil)
        try self.init(mapper: contextual)
    }
    
}

extension InMappable {
    
    public init<Map: InMapProtocol>(from map: Map) throws {
        let mapper = InMapper<Map, Keys>(of: map)
        try self.init(mapper: mapper)
    }
    
}

extension InMappableWithContext {
    
    public init<Map: InMapProtocol>(from map: Map, withContext context: Context) throws {
        let mapper = ContextualInMapper<Map, Keys, Context>(of: map, context: context)
        try self.init(mapper: mapper)
    }
    
}
