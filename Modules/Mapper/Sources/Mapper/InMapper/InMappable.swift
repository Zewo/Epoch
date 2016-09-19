public protocol InMappable {
    
    associatedtype Keys: IndexPathElement
    init<Source: InMap>(mapper: InMapper<Source, Keys>) throws
    
}

public protocol InMappableWithContext: InMappable {
    
    associatedtype Context
    associatedtype Keys: IndexPathElement
    
    init<Source: InMap>(mapper: ContextualInMapper<Source, Keys, Context>) throws
    
}

extension InMappableWithContext {
    
    public init<Source: InMap>(mapper: InMapper<Source, Keys>) throws {
        let contextual = ContextualInMapper<Source, Keys, Context>(of: mapper.source, context: nil)
        try self.init(mapper: contextual)
    }
    
}

extension InMappable {
    
    public init<Source: InMap>(from source: Source) throws {
        let mapper = InMapper<Source, Keys>(of: source)
        try self.init(mapper: mapper)
    }
    
}

extension InMappableWithContext {
    
    public init<Source: InMap>(from source: Source, withContext context: Context) throws {
        let mapper = ContextualInMapper<Source, Keys, Context>(of: source, context: context)
        try self.init(mapper: mapper)
    }
    
}
