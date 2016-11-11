
/// Object that maps structured data instances to strongly-typed instances.
public protocol InMapperProtocol {
    
    associatedtype Source: InMap
    associatedtype IndexPath: IndexPathElement
    
    /// Source of mapping (input).
    var source: Source { get }
    
}

public protocol ContextualInMapperProtocol : InMapperProtocol {
    
    associatedtype Context
    var context: Context { get }
    
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
        let indexPathValues = indexPath.map({ $0.indexPathValue })
        if let value = source.get(at: indexPathValues) {
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
    
    func unwrap<T>(_ optional: T?) throws -> T {
        if let value = optional {
            return value
        } else {
            throw InMapperError.wrongType(T.self)
        }
    }
    
    func array(from source: Source) throws -> [Source] {
        if let array = source.asArray() {
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
    public func unsafe_map<T>(from indexPath: IndexPath...) throws -> T {
        let leveled = try dive(to: indexPath)
        return try get(from: leveled)
    }
    
    /// Returns value at `indexPath` represented as `Int`.
    ///
    /// - parameter indexPath: path to desired value.
    ///
    /// - throws: `InMapperError`.
    ///
    /// - returns: value at `indexPath` represented as `Int`.
    public func map(from indexPath: IndexPath...) throws -> Int {
        let leveled = try dive(to: indexPath)
        return try unwrap(leveled.int)
    }
    
    /// Returns value at `indexPath` represented as `Double`.
    ///
    /// - parameter indexPath: path to desired value.
    ///
    /// - throws: `InMapperError`.
    ///
    /// - returns: value at `indexPath` represented as `Double`.
    public func map(from indexPath: IndexPath...) throws -> Double {
        let leveled = try dive(to: indexPath)
        return try unwrap(leveled.double)
    }
    
    /// Returns value at `indexPath` represented as `Bool`.
    ///
    /// - parameter indexPath: path to desired value.
    ///
    /// - throws: `InMapperError`.
    ///
    /// - returns: value at `indexPath` represented as `Bool`.
    public func map(from indexPath: IndexPath...) throws -> Bool {
        let leveled = try dive(to: indexPath)
        return try unwrap(leveled.bool)
    }
    
    /// Returns value at `indexPath` represented as `String`.
    ///
    /// - parameter indexPath: path to desired value.
    ///
    /// - throws: `InMapperError`.
    ///
    /// - returns: value at `indexPath` represented as `String`.
    public func map(from indexPath: IndexPath...) throws -> String {
        let leveled = try dive(to: indexPath)
        return try unwrap(leveled.string)
    }
    
    /// Returns value at `indexPath` represented as `T`, when `T` itself is `InMappable`.
    ///
    /// - parameter indexPath: path to desired value.
    ///
    /// - throws: `InMapperError`.
    ///
    /// - returns: value at `indexPath` represented as `T`.
    public func map<T : InMappable>(from indexPath: IndexPath...) throws -> T {
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
    public func map<T : InMappableWithContext>(from indexPath: IndexPath..., withContext context: T.MappingContext) throws -> T {
        let leveled = try dive(to: indexPath)
        return try T(mapper: ContextualInMapper(of: leveled, context: context))
    }
    
    /// Returns value at `indexPath` represented as `T`, when `T` itself is `BasicInMappable`.
    ///
    /// - parameter indexPath: path to desired value.
    ///
    /// - throws: `InMapperError`.
    ///
    /// - returns: value at `indexPath` represented as `T`.
    public func map<T : BasicInMappable>(from indexPath: IndexPath...) throws -> T {
        let leveled = try dive(to: indexPath)
        return try T(mapper: BasicInMapper(of: leveled))
    }
        
    /// Returns value at `indexPath` represented as `T`, when `T` is `RawRepresentable` (in most cases - `enum` with raw type).
    ///
    /// - parameter indexPath: path to desired value.
    ///
    /// - throws: `InMapperError`.
    ///
    /// - returns: value at `indexPath` represented as `T`.
    public func map<T : RawRepresentable>(from indexPath: IndexPath...) throws -> T {
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
    public func unsafe_mapArray<T>(from indexPath: IndexPath...) throws -> [T] {
        let leveled = try dive(to: indexPath)
        let array = try self.array(from: leveled)
        return try array.map({ try get(from: $0) })
    }
    
    /// Returns array of values at `indexPath` represented as `Int`.
    ///
    /// - parameter indexPath: path to desired value.
    ///
    /// - throws: `InMapperError`.
    ///
    /// - returns: array of values at `indexPath` represented as `Int`.
    public func map(from indexPath: IndexPath...) throws -> [Int] {
        let leveled = try dive(to: indexPath)
        let array = try self.array(from: leveled)
        return try array.map({ try unwrap($0.int) })
    }
    
    /// Returns array of values at `indexPath` represented as `Double`.
    ///
    /// - parameter indexPath: path to desired value.
    ///
    /// - throws: `InMapperError`.
    ///
    /// - returns: array of values at `indexPath` represented as `Double`.
    public func map(from indexPath: IndexPath...) throws -> [Double] {
        let leveled = try dive(to: indexPath)
        let array = try self.array(from: leveled)
        return try array.map({ try unwrap($0.double) })
    }
    
    /// Returns array of values at `indexPath` represented as `Bool`.
    ///
    /// - parameter indexPath: path to desired value.
    ///
    /// - throws: `InMapperError`.
    ///
    /// - returns: array of values at `indexPath` represented as `Bool`.
    public func map(from indexPath: IndexPath...) throws -> [Bool] {
        let leveled = try dive(to: indexPath)
        let array = try self.array(from: leveled)
        return try array.map({ try unwrap($0.bool) })
    }
    
    /// Returns array of values at `indexPath` represented as `String`.
    ///
    /// - parameter indexPath: path to desired value.
    ///
    /// - throws: `InMapperError`.
    ///
    /// - returns: array of values at `indexPath` represented as `String`.
    public func map(from indexPath: IndexPath...) throws -> [String] {
        let leveled = try dive(to: indexPath)
        let array = try self.array(from: leveled)
        return try array.map({ try unwrap($0.string) })
    }
    
    /// Returns array of values at `indexPath` represented as `T`, when `T` itself is `InMappable`.
    ///
    /// - parameter indexPath: path to desired value.
    ///
    /// - throws: `InMapperError`.
    ///
    /// - returns: array of values at `indexPath` represented as `T`.
    public func map<T : InMappable>(from indexPath: IndexPath...) throws -> [T] {
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
    public func map<T : InMappableWithContext>(from indexPath: IndexPath..., withContext context: T.MappingContext) throws -> [T] {
        let leveled = try dive(to: indexPath)
        let array = try self.array(from: leveled)
        return try array.map({ try T(mapper: ContextualInMapper(of: $0, context: context)) })
    }
    
    /// Returns array of values at `indexPath` represented as `T`, when `T` itself is `BasicInMappable`.
    ///
    /// - parameter indexPath: path to desired value.
    ///
    /// - throws: `InMapperError`.
    ///
    /// - returns: array of values at `indexPath` represented as `T`.
    public func map<T : BasicInMappable>(from indexPath: IndexPath...) throws -> [T] {
        let leveled = try dive(to: indexPath)
        let array = try self.array(from: leveled)
        return try array.map({ try T(mapper: BasicInMapper(of: $0)) })
    }
    
    /// Returns array of values at `indexPath` represented as `T`, when `T` is `RawRepresentable` (in most cases - `enum` with raw type).
    ///
    /// - parameter indexPath: path to desired value.
    ///
    /// - throws: `InMapperError`.
    ///
    /// - returns: array of values at `indexPath` represented as `T`.
    public func map<T : RawRepresentable>(from indexPath: IndexPath...) throws -> [T] {
        let leveled = try dive(to: indexPath)
        let array = try self.array(from: leveled)
        return try array.map({ try self.rawRepresent($0) })
    }
    
}

extension ContextualInMapperProtocol {
    
    /// Returns value at `indexPath` represented as `T` which has the same associated `Context`, automatically passing the context.
    ///
    /// - parameter indexPath: path to desired value.
    ///
    /// - throws: `InMapperError`.
    ///
    /// - returns: value at `indexPath` represented as `T`.
    public func map<T : InMappableWithContext>(from indexPath: IndexPath...) throws -> T where T.MappingContext == Context {
        let leveled = try dive(to: indexPath)
        return try T(mapper: ContextualInMapper<Source, T.MappingKeys, T.MappingContext>(of: leveled, context: self.context))
    }
    
    /// Returns array of values at `indexPath` represented as `T` which has the same associated `Context`, automatically passing the context.
    ///
    /// - parameter indexPath: path to desired value.
    ///
    /// - throws: `InMapperError`.
    ///
    /// - returns: array of values at `indexPath` represented as `T`.
    public func map<T : InMappableWithContext>(from indexPath: IndexPath...) throws -> [T] where T.MappingContext == Context {
        let leveled = try dive(to: indexPath)
        let array = try self.array(from: leveled)
        return try array.map({ try T(mapper: ContextualInMapper<Source, T.MappingKeys, T.MappingContext>(of: $0, context: self.context)) })
    }
    
}

/// Object that maps structured data instances to strongly-typed instances.
public struct InMapper<Source : InMap, MappingKeys : IndexPathElement> : InMapperProtocol {
    
    public let source: Source
    public typealias IndexPath = MappingKeys
    
    /// Creates mapper for given `source`.
    ///
    /// - parameter source: source of mapping.
    public init(of source: Source) {
        self.source = source
    }
    
}

public struct BasicInMapper<Source : InMap> : InMapperProtocol {
    
    public let source: Source
    public typealias IndexPath = IndexPathValue
    
    public init(of source: Source) {
        self.source = source
    }
    
}

/// Object that maps structured data instances to strongly-typed instances using type-specific context.
public struct ContextualInMapper<Source : InMap, MappingKeys : IndexPathElement, Context> : ContextualInMapperProtocol {
    
    public let source: Source
    /// Context is used to determine the way of mapping, so it allows to map instance in several different ways.
    public let context: Context
    public typealias IndexPath = MappingKeys
    
    
    /// Creates mapper for given `source` and `context`.
    ///
    /// - parameter source:  source of mapping.
    /// - parameter context: context for mapping describal.
    public init(of source: Source, context: Context) {
        self.source = source
        self.context = context
    }
    
}

/// Mapper for mapping without MappingKeys.
public typealias PlainInMapper<Source : InMap> = InMapper<Source, NoKeys>
/// Contextual Mapper for mapping without MappingKeys.
public typealias PlainContextualInMapper<Source : InMap, Context> = ContextualInMapper<Source, NoKeys, Context>
