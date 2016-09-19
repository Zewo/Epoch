public protocol OutMappable {
    
    associatedtype Keys: IndexPathElement
    func outMap<Map: OutMap>(mapper: inout OutMapper<Map, Keys>) throws
    
}

public protocol OutMappableWithContext: OutMappable {
    
    associatedtype Keys: IndexPathElement
    associatedtype Context
    
    func outMap<Map: OutMap>(mapper: inout ContextualOutMapper<Map, Keys, Context>) throws
    
}

extension OutMappableWithContext {
    
    public func outMap<Map: OutMap>(mapper: inout OutMapper<Map, Keys>) throws {
        var contextual = ContextualOutMapper<Map, Keys, Context>(of: mapper.outMap, context: nil)
        try self.outMap(mapper: &contextual)
        mapper.outMap = contextual.outMap
    }
    
}

extension OutMappable {
    
    public func map<Map: OutMap>() throws -> Map {
        var mapper = OutMapper<Map, Keys>()
        try outMap(mapper: &mapper)
        return mapper.outMap
    }
    
}

extension OutMappableWithContext {
    
    public func map<Map: OutMap>(withContext context: Context) throws -> Map {
        var mapper = ContextualOutMapper<Map, Keys, Context>(of: Map.blank, context: context)
        try outMap(mapper: &mapper)
        return mapper.outMap
    }
    
}
