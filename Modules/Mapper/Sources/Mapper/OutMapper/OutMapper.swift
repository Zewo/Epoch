public protocol OutMapperProtocol {
    
    associatedtype Map: OutMap
    associatedtype IndexPath: IndexPathElement
    
    var outMap: Map { get set }
    init()
    
}

public enum OutMapperError: Error {
    case wrongType(Any.Type)
    case cannotRepresentArray
}

fileprivate extension OutMapperProtocol {
    
    func getMap<T>(from value: T) throws -> Map {
        if let map = Map.from(value) {
            return map
        } else {
            throw OutMapperError.wrongType(T.self)
        }
    }
    
    func arrayMap(of array: [Map]) throws -> Map {
        if let array = Map.fromArray(array) {
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
        return mapper.outMap
    }
    
}


extension OutMapperProtocol {
    
    public mutating func map<T>(_ value: T, to indexPath: IndexPath) throws {
        let map = try getMap(from: value)
        try outMap.set(map, at: indexPath)
    }
    
    public mutating func map<T: OutMappable>(_ value: T, to indexPath: IndexPath) throws {
        let new: Map = try value.map()
        try outMap.set(new, at: indexPath)
    }
    
    public mutating func map<T: RawRepresentable>(_ value: T, to indexPath: IndexPath) throws {
        try map(value.rawValue, to: indexPath)
    }
    
    public mutating func map<T: OutMappableWithContext>(_ value: T, to indexPath: IndexPath, usingContext context: T.Context) throws {
        let new = try value.map(withContext: context) as Map
        try outMap.set(new, at: indexPath)
    }
    
    public mutating func mapArray<T>(_ array: [T], to indexPath: IndexPath) throws {
        let maps = try array.map({ try self.getMap(from: $0) })
        let map = try arrayMap(of: maps)
        try outMap.set(map, at: indexPath)
    }
    
    public mutating func mapArray<T: OutMappable>(_ array: [T], to indexPath: IndexPath) throws {
        let maps: [Map] = try array.map({ try $0.map() })
        let map = try arrayMap(of: maps)
        try outMap.set(map, at: indexPath)
    }
    
    public mutating func mapArray<T: RawRepresentable>(_ array: [T], to indexPath: IndexPath) throws {
        try mapArray(array.map({ $0.rawValue }), to: indexPath)
    }
    
    public mutating func mapArray<T: OutMappableWithContext>(_ array: [T], to indexPath: IndexPath, usingContext context: T.Context) throws {
        let maps: [Map] = try array.map({ try $0.map(withContext: context) })
        let map = try arrayMap(of: maps)
        try outMap.set(map, at: indexPath)
    }
    
}

public struct OutMapper<Map: OutMap, Keys: IndexPathElement>: OutMapperProtocol {
    
    public typealias IndexPath = Keys
    public var outMap: Map
    
    public init() {
        self.outMap = Map.blank
    }
    
    public init(of map: Map) {
        self.outMap = map
    }
    
}

public struct ContextualOutMapper<Map: OutMap, Keys: IndexPathElement, Context>: OutMapperProtocol {
    
    public typealias IndexPath = Keys
    public var outMap: Map
    public let context: Context?
    
    public init() {
        self.outMap = Map.blank
        self.context = nil
    }
    
    public init(of map: Map = .blank, context: Context?) {
        self.outMap = map
        self.context = context
    }
    
    public mutating func map<T: OutMappableWithContext>(_ value: T, to indexPath: IndexPath) throws where T.Context == Context {
        let new: Map = try value.map(withContext: self.context)
        try outMap.set(new, at: indexPath)
    }
    
    public mutating func mapArray<T: OutMappableWithContext>(_ array: [T], to indexPath: IndexPath) throws where T.Context == Context {
        let maps: [Map] = try array.map({ try $0.map(withContext: context) })
        let map = try arrayMap(of: maps)
        try outMap.set(map, at: indexPath)
    }
    
}

public typealias StringOutMapper<Map: OutMap> = OutMapper<Map, String>
public typealias StringContextualOutMapper<Map: OutMap, Context> = ContextualOutMapper<Map, String, Context>
