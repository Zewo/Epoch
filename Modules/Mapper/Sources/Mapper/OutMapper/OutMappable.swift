public protocol OutMappable {
    
    associatedtype Keys: IndexPathElement
    func outMap<Destination: OutMap>(mapper: inout OutMapper<Destination, Keys>) throws
    
}

public protocol OutMappableWithContext: OutMappable {
    
    associatedtype Keys: IndexPathElement
    associatedtype Context
    
    func outMap<Destination: OutMap>(mapper: inout ContextualOutMapper<Destination, Keys, Context>) throws
    
}

extension OutMappableWithContext {
    
    public func outMap<Destination: OutMap>(mapper: inout OutMapper<Destination, Keys>) throws {
        var contextual = ContextualOutMapper<Destination, Keys, Context>(of: mapper.destination, context: nil)
        try self.outMap(mapper: &contextual)
        mapper.destination = contextual.destination
    }
    
}

extension OutMappable {
    
    public func map<Destination: OutMap>() throws -> Destination {
        var mapper = OutMapper<Destination, Keys>()
        try outMap(mapper: &mapper)
        return mapper.destination
    }
    
}

extension OutMappableWithContext {
    
    public func map<Destination: OutMap>(withContext context: Context) throws -> Destination {
        var mapper = ContextualOutMapper<Destination, Keys, Context>(of: Destination.blank, context: context)
        try outMap(mapper: &mapper)
        return mapper.destination
    }
    
}
