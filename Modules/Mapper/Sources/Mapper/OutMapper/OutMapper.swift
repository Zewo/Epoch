public protocol OutMapperProtocol {
    
    associatedtype Destination: OutMap
    associatedtype IndexPath: IndexPathElement
    
    var destination: Destination { get set }
    init()
    
}

public enum OutMapperError: Error {
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
    
    func map<Map: OutMap>(withContext context: Context?) throws -> Map {
        var mapper = ContextualOutMapper<Map, Keys, Context>(of: .blank, context: context)
        try outMap(mapper: &mapper)
        return mapper.destination
    }
    
}


extension OutMapperProtocol {
    
    public mutating func map<T>(_ value: T, to indexPath: IndexPath) throws {
        let map = try getMap(from: value)
        try destination.set(map, at: indexPath)
    }
    
    public mutating func map<T: OutMappable>(_ value: T, to indexPath: IndexPath) throws {
        let new: Destination = try value.map()
        try destination.set(new, at: indexPath)
    }
    
    public mutating func map<T: RawRepresentable>(_ value: T, to indexPath: IndexPath) throws {
        try map(value.rawValue, to: indexPath)
    }
    
    public mutating func map<T: OutMappableWithContext>(_ value: T, to indexPath: IndexPath, usingContext context: T.Context) throws {
        let new = try value.map(withContext: context) as Destination
        try destination.set(new, at: indexPath)
    }
    
    public mutating func mapArray<T>(_ array: [T], to indexPath: IndexPath) throws {
        let maps = try array.map({ try self.getMap(from: $0) })
        let map = try arrayMap(of: maps)
        try destination.set(map, at: indexPath)
    }
    
    public mutating func mapArray<T: OutMappable>(_ array: [T], to indexPath: IndexPath) throws {
        let maps: [Destination] = try array.map({ try $0.map() })
        let map = try arrayMap(of: maps)
        try destination.set(map, at: indexPath)
    }
    
    public mutating func mapArray<T: RawRepresentable>(_ array: [T], to indexPath: IndexPath) throws {
        try mapArray(array.map({ $0.rawValue }), to: indexPath)
    }
    
    public mutating func mapArray<T: OutMappableWithContext>(_ array: [T], to indexPath: IndexPath, usingContext context: T.Context) throws {
        let maps: [Destination] = try array.map({ try $0.map(withContext: context) })
        let map = try arrayMap(of: maps)
        try destination.set(map, at: indexPath)
    }
    
}

public struct OutMapper<Destination: OutMap, Keys: IndexPathElement>: OutMapperProtocol {
    
    public typealias IndexPath = Keys
    public var destination: Destination
    
    public init() {
        self.destination = Destination.blank
    }
    
    public init(of destination: Destination) {
        self.destination = destination
    }
    
}

public struct ContextualOutMapper<Destination: OutMap, Keys: IndexPathElement, Context>: OutMapperProtocol {
    
    public typealias IndexPath = Keys
    public var destination: Destination
    public let context: Context?
    
    public init() {
        self.destination = Destination.blank
        self.context = nil
    }
    
    public init(of destination: Destination = .blank, context: Context?) {
        self.destination = destination
        self.context = context
    }
    
    public mutating func map<T: OutMappableWithContext>(_ value: T, to indexPath: IndexPath) throws where T.Context == Context {
        let new: Destination = try value.map(withContext: self.context)
        try destination.set(new, at: indexPath)
    }
    
    public mutating func mapArray<T: OutMappableWithContext>(_ array: [T], to indexPath: IndexPath) throws where T.Context == Context {
        let maps: [Destination] = try array.map({ try $0.map(withContext: context) })
        let map = try arrayMap(of: maps)
        try destination.set(map, at: indexPath)
    }
    
}

public typealias StringOutMapper<Map: OutMap> = OutMapper<Map, String>
public typealias StringContextualOutMapper<Map: OutMap, Context> = ContextualOutMapper<Map, String, Context>
