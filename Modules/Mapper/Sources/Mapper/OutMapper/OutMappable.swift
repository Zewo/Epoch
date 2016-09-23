/// Entity which can be mapped to any structured data type.
public protocol OutMappable {
    
    associatedtype Keys : IndexPathElement
    
    /// Maps instance data to `mapper`.
    ///
    /// - parameter mapper: wraps the actual structured data instance.
    ///
    /// - throws: `OutMapperError`.
    func outMap<Destination : OutMap>(mapper: inout OutMapper<Destination, Keys>) throws
    
}

/// Entity which can be mapped to any structured data type in multiple ways using user-determined context instance.
public protocol OutMappableWithContext : OutMappable {
    
    associatedtype Keys : IndexPathElement
    
    /// Context allows user to map data in different ways.
    associatedtype Context
    
    
    /// Maps instance data to contextual `mapper`.
    ///
    /// - parameter mapper: wraps the actual structured data instance.
    ///
    /// - throws: `OutMapperError`
    func outMap<Destination : OutMap>(mapper: inout ContextualOutMapper<Destination, Keys, Context>) throws
    
}

extension OutMappableWithContext {
    
    public func outMap<Destination : OutMap>(mapper: inout OutMapper<Destination, Keys>) throws {
        var contextual = ContextualOutMapper<Destination, Keys, Context>(of: mapper.destination, context: nil)
        try self.outMap(mapper: &contextual)
        mapper.destination = contextual.destination
    }
    
}

extension OutMappable {
    
    
    /// Maps `self` to `Destination` structured data instance.
    ///
    /// - parameter destination: instance to map to. Leave it .blank if you want to create your instance from scratch.
    ///
    /// - throws: `OutMapperError`.
    ///
    /// - returns: structured data instance created from `self`.
    public func map<Destination : OutMap>(to destination: Destination = .blank) throws -> Destination {
        var mapper = OutMapper<Destination, Keys>(of: destination)
        try outMap(mapper: &mapper)
        return mapper.destination
    }
    
}

extension OutMappableWithContext {
    
    /// Maps `self` to `Destination` structured data instance using `context`.
    ///
    /// - parameter destination: instance to map to. Leave it .blank if you want to create your instance from scratch.
    /// - parameter context:     use `context` to describe the way of mapping.
    ///
    /// - throws: `OutMapperError`.
    ///
    /// - returns: structured data instance created from `self`.
    public func map<Destination : OutMap>(to destination: Destination = .blank, withContext context: Context) throws -> Destination {
        var mapper = ContextualOutMapper<Destination, Keys, Context>(of: destination, context: context)
        try outMap(mapper: &mapper)
        return mapper.destination
    }
    
}
