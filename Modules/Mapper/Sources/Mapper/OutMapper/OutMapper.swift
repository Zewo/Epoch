
/// Object that maps strongly-typed instances to structured data instances.
public protocol OutMapperProtocol {
    
    associatedtype Destination: OutMap
    associatedtype IndexPath: IndexPathElement
    
    /// Destination of mapping (output).
    var destination: Destination { get set }
    
}

public protocol ContextualOutMapperProtocol : OutMapperProtocol {
    
    associatedtype Context
    var context: Context { get }
    
}

public enum OutMapperError : Error {
    case wrongType(Any.Type)
    case cannotRepresentArray
    case cannotSet(Error)
}

fileprivate extension OutMapperProtocol {
    
    func getMap<T>(from value: T) throws -> Destination {
        if let map = Destination.from(value) {
            return map
        } else {
            throw OutMapperError.wrongType(T.self)
        }
    }
    
    func arrayMap(of array: [Destination]) throws -> Destination {
        if let array = Destination.fromArray(array) {
            return array
        } else {
            throw OutMapperError.cannotRepresentArray
        }
    }
    
    func unwrap<T>(_ optional: T?) throws -> T {
        if let value = optional {
            return value
        } else {
            throw OutMapperError.wrongType(T.self)
        }
    }
    
    mutating func set(_ map: Destination, at indexPath: [IndexPath]) throws {
        let indexPathValues = indexPath.map({ $0.indexPathValue })
        do {
            try destination.set(map, at: indexPathValues)
        } catch {
            throw OutMapperError.cannotSet(error)
        }
    }
    
}

extension OutMapperProtocol {
    
    /// Maps given value to `indexPath`.
    ///
    /// - parameter value:     value that needs to be mapped.
    /// - parameter indexPath: path to set value to.
    ///
    /// - throws: `OutMapperError`.
    public mutating func unsafe_map<T>(_ value: T, to indexPath: IndexPath...) throws {
        let map = try getMap(from: value)
        try set(map, at: indexPath)
    }
    
    public mutating func map(_ int: Int, to indexPath: IndexPath...) throws {
        let map = try unwrap(Destination.from(int))
        try set(map, at: indexPath)
    }
    
    public mutating func map(_ double: Double, to indexPath: IndexPath...) throws {
        let map = try unwrap(Destination.from(double))
        try set(map, at: indexPath)
    }
    
    public mutating func map(_ bool: Bool, to indexPath: IndexPath...) throws {
        let map = try unwrap(Destination.from(bool))
        try set(map, at: indexPath)
    }
    
    public mutating func map(_ string: String, to indexPath: IndexPath...) throws {
        let map = try unwrap(Destination.from(string))
        try set(map, at: indexPath)
    }
    
    /// Maps given value to `indexPath`, where value is `OutMappable`.
    ///
    /// - parameter value:     `OutMappable` value that needs to be mapped.
    /// - parameter indexPath: path to set value to.
    ///
    /// - throws: `OutMapperError`.
    public mutating func map<T : OutMappable>(_ value: T, to indexPath: IndexPath...) throws {
        let new: Destination = try value.map()
        try set(new, at: indexPath)
    }
    
    /// Maps given value to `indexPath`, where value is `ExternalOutMappable`.
    ///
    /// - parameter value:     `ExternalOutMappable` value that needs to be mapped.
    /// - parameter indexPath: path to set value to.
    ///
    /// - throws: `OutMapperError`.
    public mutating func map<T : BasicOutMappable>(_ value: T, to indexPath: IndexPath...) throws {
        let new: Destination = try value.map()
        try set(new, at: indexPath)
    }
    
    /// Maps given value to `indexPath`, where value is `RawRepresentable` (in most cases - `enum` with raw type).
    ///
    /// - parameter value:     `RawRepresentable` value that needs to be mapped.
    /// - parameter indexPath: path to set value to.
    ///
    /// - throws: `OutMapperError`.
    public mutating func map<T : RawRepresentable>(_ value: T, to indexPath: IndexPath...) throws {
        let map = try getMap(from: value.rawValue)
        try set(map, at: indexPath)
    }
    
    /// Maps given value to `indexPath` using the defined context of value.
    ///
    /// - parameter value:     `OutMappableWithContext` value that needs to be mapped.
    /// - parameter indexPath: path to set value to.
    /// - parameter context: value-specific context, used to describe the way of mapping.
    ///
    /// - throws: `OutMapperError`.
    public mutating func map<T : OutMappableWithContext>(_ value: T, to indexPath: IndexPath..., withContext context: T.MappingContext) throws {
        let new = try value.map(withContext: context) as Destination
        try set(new, at: indexPath)
    }
    
    /// Maps given array of values to `indexPath`.
    ///
    /// - parameter array:     values that needs to be mapped.
    /// - parameter indexPath: path to set values to.
    ///
    /// - throws: `OutMapperError`.
    public mutating func unsafe_mapArray<T>(_ array: [T], to indexPath: IndexPath...) throws {
        let maps = try array.map({ try self.getMap(from: $0) })
        let map = try arrayMap(of: maps)
        try set(map, at: indexPath)
    }
    
    public mutating func map(_ array: [Int], to indexPath: IndexPath...) throws {
        let maps = try array.map({ try unwrap(Destination.from($0)) })
        let map = try arrayMap(of: maps)
        try set(map, at: indexPath)
    }
    
    public mutating func map(_ array: [Double], to indexPath: IndexPath...) throws {
        let maps = try array.map({ try unwrap(Destination.from($0)) })
        let map = try arrayMap(of: maps)
        try set(map, at: indexPath)
    }

    public mutating func map(_ array: [Bool], to indexPath: IndexPath...) throws {
        let maps = try array.map({ try unwrap(Destination.from($0)) })
        let map = try arrayMap(of: maps)
        try set(map, at: indexPath)
    }

    public mutating func map(_ array: [String], to indexPath: IndexPath...) throws {
        let maps = try array.map({ try unwrap(Destination.from($0)) })
        let map = try arrayMap(of: maps)
        try set(map, at: indexPath)
    }
    
    /// Maps given array of `OutMappable` values to `indexPath`.
    ///
    /// - parameter array:     `OutMappable` values that needs to be mapped.
    /// - parameter indexPath: path to set values to.
    ///
    /// - throws: `OutMapperError`.
    public mutating func map<T : OutMappable>(_ array: [T], to indexPath: IndexPath...) throws {
        let maps: [Destination] = try array.map({ try $0.map() })
        let map = try arrayMap(of: maps)
        try set(map, at: indexPath)
    }
    
    /// Maps given array of `ExternalOutMappable` values to `indexPath`.
    ///
    /// - parameter array:     `ExternalOutMappable` values that needs to be mapped.
    /// - parameter indexPath: path to set values to.
    ///
    /// - throws: `OutMapperError`.
    public mutating func map<T : BasicOutMappable>(_ array: [T], to indexPath: IndexPath...) throws {
        let maps: [Destination] = try array.map({ try $0.map() })
        let map = try arrayMap(of: maps)
        try set(map, at: indexPath)
    }
    
    /// Maps given array of `RawRepresentable` values to `indexPath`.
    ///
    /// - parameter array:     `RawRepresentable` values that needs to be mapped.
    /// - parameter indexPath: path to set values to.
    ///
    /// - throws: `OutMapperError`.
    public mutating func map<T : RawRepresentable>(_ array: [T], to indexPath: IndexPath...) throws {
        let maps = try array.map({ try self.getMap(from: $0.rawValue) })
        let map = try arrayMap(of: maps)
        try set(map, at: indexPath)
    }
    
    /// Maps given array of values to `indexPath` using the value-defined context.
    ///
    /// - parameter array:     `OutMappableWithContext` values that needs to be mapped.
    /// - parameter indexPath: path to set values to.
    /// - parameter context: values-specific context, used to describe the way of mapping.
    ///
    /// - throws: `OutMapperError`.
    public mutating func map<T : OutMappableWithContext>(_ array: [T], to indexPath: IndexPath..., withContext context: T.MappingContext) throws {
        let maps: [Destination] = try array.map({ try $0.map(withContext: context) })
        let map = try arrayMap(of: maps)
        try set(map, at: indexPath)
    }
    
}

extension ContextualOutMapperProtocol {
    
    /// Maps given value to `indexPath`, where value type has the same associated `Context`, automatically passing the context.
    ///
    /// - parameter value:     value that needs to be mapped.
    /// - parameter indexPath: path to set values to.
    ///
    /// - throws: `OutMapperError`.
    public mutating func map<T : OutMappableWithContext>(_ value: T, to indexPath: IndexPath...) throws where T.MappingContext == Context {
        let new: Destination = try value.map(withContext: self.context)
        try set(new, at: indexPath)
    }
    
    /// Maps given array of values to `indexPath`, where value type has the same associated `Context`, automatically passing the context.
    ///
    /// - parameter value:     values that needs to be mapped.
    /// - parameter indexPath: path to set values to.
    ///
    /// - throws: `OutMapperError`.
    public mutating func map<T : OutMappableWithContext>(_ array: [T], to indexPath: IndexPath...) throws where T.MappingContext == Context {
        let maps: [Destination] = try array.map({ try $0.map(withContext: context) })
        let map = try arrayMap(of: maps)
        try set(map, at: indexPath)
    }
    
}

/// Object that maps strongly-typed instances to structured data instances.
public struct OutMapper<Destination : OutMap, MappingKeys : IndexPathElement> : OutMapperProtocol {
    
    public typealias IndexPath = MappingKeys
    public var destination: Destination
    
    /// Creates `OutMapper` instance of blank `Destination`.
    public init() {
        self.destination = .blank
    }
    
    /// Creates `OutMapper` of `destination`.
    ///
    /// - parameter destination: `OutMap` to which data will be mapped.
    public init(of destination: Destination) {
        self.destination = destination
    }
    
}

public struct BasicOutMapper<Destination : OutMap> : OutMapperProtocol {
    
    public var destination: Destination
    public typealias IndexPath = IndexPathValue
    
    public init() {
        self.destination = .blank
    }
    
    public init(of destination: Destination) {
        self.destination = destination
    }
    
}

/// Object that maps strongly-typed instances to structured data instances using type-specific context.
public struct ContextualOutMapper<Destination : OutMap, MappingKeys : IndexPathElement, Context> : ContextualOutMapperProtocol {
    
    public typealias IndexPath = MappingKeys
    public var destination: Destination
    /// Context allows to map data in several different ways.
    public let context: Context
    
    /// Creates `OutMapper` of `destination` with `context`.
    ///
    /// - parameter destination: `OutMap` to which data will be mapped.
    /// - parameter context: value-specific context, used to describe the way of mapping.
    public init(of destination: Destination = .blank, context: Context) {
        self.destination = destination
        self.context = context
    }
    
}

/// Mapper for mapping without MappingKeys.
public typealias PlainOutMapper<Destination : OutMap> = OutMapper<Destination, NoKeys>
/// Contextual Mapper for mapping without MappingKeys.
public typealias PlainContextualOutMapper<Destination : OutMap, Context> = ContextualOutMapper<Destination, NoKeys, Context>
