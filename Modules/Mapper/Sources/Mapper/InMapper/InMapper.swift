
/// Object that maps structured data instances to strongly-typed instances.
public protocol InMapperProtocol {
    
    associatedtype Source: InMap
    associatedtype IndexPath: IndexPathElement
    
    /// Source of mapping (input).
    var source: Source { get }

}

public enum InMapperError : Error {
    case noValue(forIndexPath: [IndexPathElement])
    
    /// Thrown if source at given key cannot be represented as a desired type.
    /// Often happens when using `mapper.map` instead of `mapper.mapArray`.
    case wrongType(Any.Type)
    case cannotInitializeFromRawValue(Any)
    case cannotRepresentAsArray
    case userDefinedError
}

fileprivate extension InMapperProtocol {
    
    func dive(to indexPath: [IndexPath]) throws -> Source {
        if let value = source.get(at: indexPath) {
            return value
        } else {
            throw InMapperError.noValue(forIndexPath: indexPath)
        }
    }
    
    func get<T>(from source: Source) throws -> T {
        if let value: T = source.get() {
            return value
        } else {
            throw InMapperError.wrongType(T.self)
        }
    }
    
    func array(from source: Source) throws -> [Source] {
        if let array = source.asArray {
            return array
        } else {
            throw InMapperError.cannotRepresentAsArray
        }
    }
    
    func rawRepresent<T : RawRepresentable>(_ source: Source) throws -> T {
        let raw: T.RawValue = try get(from: source)
        if let value = T(rawValue: raw) {
            return value
        } else {
            throw InMapperError.cannotInitializeFromRawValue(raw)
        }
    }
    
}

extension InMapperProtocol {
    
    /// Returns value at `indexPath` represented as `T`.
    ///
    /// - parameter indexPath: path to desired value.
    ///
    /// - throws: `InMapperError`.
    ///
    /// - returns: value at `indexPath` represented as `T`.
    public func map<T>(from indexPath: IndexPath...) throws -> T {
        #if MAPPER_ARRAY_WARN
            if T is Sequence {
                print("`map` used instead of `mapArray` when mapping \(indexPath)")
            }
        #endif
        let leveled = try dive(to: indexPath)
        return try get(from: leveled)
    }
    
    /// Returns value at `indexPath` represented as `T`, when `T` itself is `InMappable`.
    ///
    /// - parameter indexPath: path to desired value.
    ///
    /// - throws: `InMapperError`.
    ///
    /// - returns: value at `indexPath` represented as `T`.
    public func map<T : InMappable>(from indexPath: IndexPath...) throws -> T {
        #if MAPPER_ARRAY_WARN
            if T is Sequence {
                print("`map` used instead of `mapArray` when mapping \(indexPath)")
            }
        #endif
        let leveled = try dive(to: indexPath)
        return try T(mapper: InMapper(of: leveled))
    }
    
    /// Returns value at `indexPath` represented as `T` using the defined context of `T`.
    ///
    /// - parameter indexPath: path to desired value.
    /// - parameter context: `T`-specific context, used to describe the way of mapping.
    ///
    /// - throws: `InMapperError`.
    ///
    /// - returns: value at `indexPath` represented as `T`.
    public func map<T : InMappableWithContext>(from indexPath: IndexPath..., usingContext context: T.Context) throws -> T {
        #if MAPPER_ARRAY_WARN
            if T is Sequence {
                print("`map` used instead of `mapArray` when mapping \(indexPath)")
            }
        #endif
        let leveled = try dive(to: indexPath)
        return try T(mapper: ContextualInMapper(of: leveled, context: context))
    }
    
    public func map<T : ExternalInMappable>(from indexPath: IndexPath...) throws -> T {
        let leveled = try dive(to: indexPath)
        return try T(mapper: ExternalInMapper(of: leveled))
    }
    
    /// Returns value at `indexPath` represented as `T`, when `T` is `RawRepresentable` (in most cases - `enum` with raw type).
    ///
    /// - parameter indexPath: path to desired value.
    ///
    /// - throws: `InMapperError`.
    ///
    /// - returns: value at `indexPath` represented as `T`.
    public func map<T : RawRepresentable>(from indexPath: IndexPath...) throws -> T {
        #if MAPPER_ARRAY_WARN
            if T is Sequence {
                print("`map` used instead of `mapArray` when mapping \(indexPath)")
            }
        #endif
        let leveled = try dive(to: indexPath)
        return try rawRepresent(leveled)
    }
    
    
    /// Returns array of values at `indexPath` represented as `T`.
    ///
    /// - parameter indexPath: path to desired value.
    ///
    /// - throws: `InMapperError`.
    ///
    /// - returns: array of values at `indexPath` represented as `T`.
    public func mapArray<T>(from indexPath: IndexPath...) throws -> [T] {
        let leveled = try dive(to: indexPath)
        let array = try self.array(from: leveled)
        return try array.map({ try get(from: $0) })
    }
    
    /// Returns array of values at `indexPath` represented as `T`, when `T` itself is `InMappable`.
    ///
    /// - parameter indexPath: path to desired value.
    ///
    /// - throws: `InMapperError`.
    ///
    /// - returns: array of values at `indexPath` represented as `T`.
    public func mapArray<T : InMappable>(from indexPath: IndexPath...) throws -> [T] {
        let leveled = try dive(to: indexPath)
        let array = try self.array(from: leveled)
        return try array.map({ try T(mapper: InMapper(of: $0)) })
    }
    
    /// Returns array of values at `indexPath` represented as `T` using the defined context of `T`.
    ///
    /// - parameter indexPath: path to desired value.
    /// - parameter context: `T`-specific context, used to describe the way of mapping.
    ///
    /// - throws: `InMapperError`.
    ///
    /// - returns: array of values at `indexPath` represented as `T`.
    public func mapArray<T : InMappableWithContext>(from indexPath: IndexPath..., usingContext context: T.Context) throws -> [T] {
        let leveled = try dive(to: indexPath)
        let array = try self.array(from: leveled)
        return try array.map({ try T(mapper: ContextualInMapper(of: $0, context: context)) })
    }
    
    public func mapArray<T : ExternalInMappable>(from indexPath: IndexPath...) throws -> [T] {
        let leveled = try dive(to: indexPath)
        let array = try self.array(from: leveled)
        return try array.map({ try T(mapper: ExternalInMapper(of: $0)) })
    }
    
    /// Returns array of values at `indexPath` represented as `T`, when `T` is `RawRepresentable` (in most cases - `enum` with raw type).
    ///
    /// - parameter indexPath: path to desired value.
    ///
    /// - throws: `InMapperError`.
    ///
    /// - returns: array of values at `indexPath` represented as `T`.
    public func mapArray<T : RawRepresentable>(from indexPath: IndexPath...) throws -> [T] {
        let leveled = try dive(to: indexPath)
        let array = try self.array(from: leveled)
        return try array.map({ try self.rawRepresent($0) })
    }
    
}

/// Object that maps structured data instances to strongly-typed instances.
public struct InMapper<Source : InMap, Keys : IndexPathElement> : InMapperProtocol {
    
    public let source: Source
    public typealias IndexPath = Keys
    
    /// Creates mapper for given `source`.
    ///
    /// - parameter source: source of mapping.
    public init(of source: Source) {
        self.source = source
    }
    
}

public struct ExternalInMapper<Source : InMap> : InMapperProtocol {
    
    public typealias IndexPath = IndexPathValue
    public let source: Source
    
    public init(of source: Source) {
        self.source = source
    }
    
}

/// Object that maps structured data instances to strongly-typed instances using type-specific context.
public struct ContextualInMapper<Source : InMap, Keys : IndexPathElement, Context> : InMapperProtocol {
    
    public let source: Source
    /// Context is used to determine the way of mapping, so it allows to map instance in several different ways.
    public let context: Context?
    public typealias IndexPath = Keys
    
    
    /// Creates mapper for given `source` and `context`.
    ///
    /// - parameter source:  source of mapping.
    /// - parameter context: context for mapping describal.
    public init(of source: Source, context: Context?) {
        self.source = source
        self.context = context
    }
    
    
    /// Returns value at `indexPath` represented as `T` which has the same associated `Context`, automatically passing the context.
    ///
    /// - parameter indexPath: path to desired value.
    ///
    /// - throws: `InMapperError`.
    ///
    /// - returns: value at `indexPath` represented as `T`.
    public func map<T : InMappableWithContext>(from indexPath: IndexPath...) throws -> T where T.Context == Context {
        #if MAPPER_ARRAY_WARN
            if T is Sequence {
                print("`map` used instead of `mapArray` when mapping \(indexPath)")
            }
        #endif
            let leveled = try dive(to: indexPath)
            return try T(mapper: ContextualInMapper<Source, T.Keys, T.Context>(of: leveled, context: self.context))
    }
    
    /// Returns array of values at `indexPath` represented as `T` which has the same associated `Context`, automatically passing the context.
    ///
    /// - parameter indexPath: path to desired value.
    ///
    /// - throws: `InMapperError`.
    ///
    /// - returns: array of values at `indexPath` represented as `T`.
    public func mapArray<T : InMappableWithContext>(from indexPath: IndexPath...) throws -> [T] where T.Context == Context {
            let leveled = try dive(to: indexPath)
            let array = try self.array(from: leveled)
            return try array.map({ try T(mapper: ContextualInMapper<Source, T.Keys, T.Context>(of: $0, context: self.context)) })
    }
    
}

/// Mapper which use string as keys.
public typealias StringInMapper<Source : InMap> = InMapper<Source, String>
/// Mapper which use string as keys.
public typealias StringContextualInMapper<Source : InMap, Context> = ContextualInMapper<Source, String, Context>

public typealias FlatInMapper<Source : InMap> = InMapper<Source, NoKeys>
