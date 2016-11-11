
/// Entity which can be mapped (initialized) from any structured data type.
public protocol InMappable {
    
    associatedtype MappingKeys : IndexPathElement
    
    /// Creates instance from instance of `Source` packed into mapper with type-specific `MappingKeys`.
    init<Source : InMap>(mapper: InMapper<Source, MappingKeys>) throws
    
}

public protocol BasicInMappable {
    
    init<Source : InMap>(mapper: BasicInMapper<Source>) throws
    
}

/// Entity which can be mapped (initialized) from any structured data type in multiple ways using user-determined context instance.
public protocol InMappableWithContext {
    
    associatedtype MappingContext
    associatedtype MappingKeys: IndexPathElement
    
    /// Creates instance from instance of `Source` packed into contextual mapper with type-specific `MappingKeys`.
    init<Source : InMap>(mapper: ContextualInMapper<Source, MappingKeys, MappingContext>) throws
    
}

extension InMappable {
    
    /// Creates instance from `source`.
    public init<Source : InMap>(from source: Source) throws {
        let mapper = InMapper<Source, MappingKeys>(of: source)
        try self.init(mapper: mapper)
    }
    
}

extension BasicInMappable {
    
    /// Creates instance from `source`.
    public init<Source : InMap>(from source: Source) throws {
        let mapper = BasicInMapper<Source>(of: source)
        try self.init(mapper: mapper)
    }
    
}

extension InMappableWithContext {
    
    /// Creates instance from `source` using given context.
    public init<Source : InMap>(from source: Source, withContext context: MappingContext) throws {
        let mapper = ContextualInMapper<Source, MappingKeys, MappingContext>(of: source, context: context)
        try self.init(mapper: mapper)
    }
    
}
