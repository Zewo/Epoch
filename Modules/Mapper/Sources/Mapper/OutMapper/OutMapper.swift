
/// Object that maps strongly-typed instances to structured data instances.
public protocol OutMapperProtocol {
    
    associatedtype Destination: OutMap
    associatedtype IndexPath: IndexPathElement
    
    /// Destination of mapping (output).
    var destination: Destination { get set }
    init()
    
}

public enum OutMapperError : Error {
    case wrongType(Any.Type)
    case cannotRepresentArray
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
    
}

fileprivate extension OutMappableWithContext {
    
    func map<Map : OutMap>(withContext context: Context?) throws -> Map {
        var mapper = ContextualOutMapper<Map, Keys, Context>(of: .blank, context: context)
        try outMap(mapper: &mapper)
        return mapper.destination
    }
    
}


extension OutMapperProtocol {
    
    
    /// Maps given value to `indexPath`.
    ///
    /// - parameter value:     value that needs to be mapped.
    /// - parameter indexPath: path to set value to.
    ///
    /// - throws: `OutMapperError`.
    public mutating func map<T>(_ value: T, to indexPath: IndexPath...) throws {
        let map = try getMap(from: value)
        try destination.set(map, at: indexPath)
    }
    
    /// Maps given value to `indexPath`, where value is `OutMappable`.
    ///
    /// - parameter value:     `OutMappable` value that needs to be mapped.
    /// - parameter indexPath: path to set value to.
    ///
    /// - throws: `OutMapperError`.
    public mutating func map<T : OutMappable>(_ value: T, to indexPath: IndexPath...) throws {
        let new: Destination = try value.map()
        try destination.set(new, at: indexPath)
    }
    
    /// Maps given value to `indexPath`, where value is `ExternalOutMappable`.
    ///
    /// - parameter value:     `ExternalOutMappable` value that needs to be mapped.
    /// - parameter indexPath: path to set value to.
    ///
    /// - throws: `OutMapperError`.
    public mutating func map<T : ExternalOutMappable>(_ value: T, to indexPath: IndexPath...) throws {
        let new: Destination = try value.map()
        try destination.set(new, at: indexPath)
    }
    
    /// Maps given value to `indexPath`, where value is `RawRepresentable` (in most cases - `enum` with raw type).
    ///
    /// - parameter value:     `RawRepresentable` value that needs to be mapped.
    /// - parameter indexPath: path to set value to.
    ///
    /// - throws: `OutMapperError`.
    public mutating func map<T : RawRepresentable>(_ value: T, to indexPath: IndexPath...) throws {
        let map = try getMap(from: value.rawValue)
        try destination.set(map, at: indexPath)
    }
    
    /// Maps given value to `indexPath` using the defined context of value.
    ///
    /// - parameter value:     `OutMappableWithContext` value that needs to be mapped.
    /// - parameter indexPath: path to set value to.
    /// - parameter context: value-specific context, used to describe the way of mapping.
    ///
    /// - throws: `OutMapperError`.
    public mutating func map<T : OutMappableWithContext>(_ value: T, to indexPath: IndexPath..., usingContext context: T.Context) throws {
        let new = try value.map(withContext: context) as Destination
        try destination.set(new, at: indexPath)
    }
    
    /// Maps given array of values to `indexPath`.
    ///
    /// - parameter array:     values that needs to be mapped.
    /// - parameter indexPath: path to set values to.
    ///
    /// - throws: `OutMapperError`.
    public mutating func mapArray<T>(_ array: [T], to indexPath: IndexPath...) throws {
        let maps = try array.map({ try self.getMap(from: $0) })
        let map = try arrayMap(of: maps)
        try destination.set(map, at: indexPath)
    }

    /// Maps given array of `OutMappable` values to `indexPath`.
    ///
    /// - parameter array:     `OutMappable` values that needs to be mapped.
    /// - parameter indexPath: path to set values to.
    ///
    /// - throws: `OutMapperError`.
    public mutating func mapArray<T : OutMappable>(_ array: [T], to indexPath: IndexPath...) throws {
        let maps: [Destination] = try array.map({ try $0.map() })
        let map = try arrayMap(of: maps)
        try destination.set(map, at: indexPath)
    }
    
    /// Maps given array of `ExternalOutMappable` values to `indexPath`.
    ///
    /// - parameter array:     `ExternalOutMappable` values that needs to be mapped.
    /// - parameter indexPath: path to set values to.
    ///
    /// - throws: `OutMapperError`.
    public mutating func mapArray<T : ExternalOutMappable>(_ array: [T], to indexPath: IndexPath...) throws {
        let maps: [Destination] = try array.map({ try $0.map() })
        let map = try arrayMap(of: maps)
        try destination.set(map, at: indexPath)
    }
    
    /// Maps given array of `RawRepresentable` values to `indexPath`.
    ///
    /// - parameter array:     `RawRepresentable` values that needs to be mapped.
    /// - parameter indexPath: path to set values to.
    ///
    /// - throws: `OutMapperError`.
    public mutating func mapArray<T : RawRepresentable>(_ array: [T], to indexPath: IndexPath...) throws {
        let maps = try array.map({ try self.getMap(from: $0.rawValue) })
        let map = try arrayMap(of: maps)
        try destination.set(map, at: indexPath)
    }
    
    /// Maps given array of values to `indexPath` using the value-defined context.
    ///
    /// - parameter array:     `OutMappableWithContext` values that needs to be mapped.
    /// - parameter indexPath: path to set values to.
    /// - parameter context: values-specific context, used to describe the way of mapping.
    ///
    /// - throws: `OutMapperError`.
    public mutating func mapArray<T : OutMappableWithContext>(_ array: [T], to indexPath: IndexPath..., usingContext context: T.Context) throws {
        let maps: [Destination] = try array.map({ try $0.map(withContext: context) })
        let map = try arrayMap(of: maps)
        try destination.set(map, at: indexPath)
    }
    
}

/// Object that maps strongly-typed instances to structured data instances.
public struct OutMapper<Destination : OutMap, Keys : IndexPathElement> : OutMapperProtocol {
    
    public typealias IndexPath = Keys
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

public struct ExternalOutMapper<Destination : OutMap> : OutMapperProtocol {
    
    public typealias IndexPath = IndexPathValue
    public var destination: Destination
    
    public init() {
        self.destination = .blank
    }
    
    public init(of destination: Destination) {
        self.destination = destination
    }
    
}

/// Object that maps strongly-typed instances to structured data instances using type-specific context.
public struct ContextualOutMapper<Destination : OutMap, Keys : IndexPathElement, Context> : OutMapperProtocol {
    
    public typealias IndexPath = Keys
    public var destination: Destination
    /// Context allows to map data in several different ways.
    public let context: Context?
    
    /// Creates `OutMapper` instance of blank `Destination`.
    public init() {
        self.destination = Destination.blank
        self.context = nil
    }
    
    /// Creates `OutMapper` of `destination` with `context`.
    ///
    /// - parameter destination: `OutMap` to which data will be mapped.
    /// - parameter context: value-specific context, used to describe the way of mapping.
    public init(of destination: Destination = .blank, context: Context?) {
        self.destination = destination
        self.context = context
    }
    
    
    /// Maps given value to `indexPath`, where value type has the same associated `Context`, automatically passing the context.
    ///
    /// - parameter value:     value that needs to be mapped.
    /// - parameter indexPath: path to set values to.
    ///
    /// - throws: `OutMapperError`.
    public mutating func map<T : OutMappableWithContext>(_ value: T, to indexPath: IndexPath...) throws where T.Context == Context {
        let new: Destination = try value.map(withContext: self.context)
        try destination.set(new, at: indexPath)
    }

    /// Maps given array of values to `indexPath`, where value type has the same associated `Context`, automatically passing the context.
    ///
    /// - parameter value:     values that needs to be mapped.
    /// - parameter indexPath: path to set values to.
    ///
    /// - throws: `OutMapperError`.
    public mutating func mapArray<T : OutMappableWithContext>(_ array: [T], to indexPath: IndexPath...) throws where T.Context == Context {
        let maps: [Destination] = try array.map({ try $0.map(withContext: context) })
        let map = try arrayMap(of: maps)
        try destination.set(map, at: indexPath)
    }
    
}

/// Mapper which use string as keys.
public typealias StringOutMapper<Destination : OutMap> = OutMapper<Destination, String>
/// Mapper which use string as keys.
public typealias StringContextualOutMapper<Destination : OutMap, Context> = ContextualOutMapper<Destination, String, Context>

/// Mapper for mapping without keys.
public typealias PlainOutMapper<Destination : OutMap> = OutMapper<Destination, NoKeys>
