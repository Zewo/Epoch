import Mapper

// MARK: - Context

enum SuperContext {
    case json
    case mongo
    case gordon
}

struct SuperheroHelper {
    
    let name: String
    let id: Int
    
    enum MappingKeys : String, IndexPathElement {
        case name
        case id, identifier, g_id
    }
        
}

extension SuperheroHelper : InMappableWithContext {
    init<Source : InMap>(mapper: ContextualInMapper<Source, MappingKeys, SuperContext>) throws {
        self.name = try mapper.map(from: .name)
        switch mapper.context {
        case .json:
            self.id = try mapper.map(from: .id)
        case .mongo:
            self.id = try mapper.map(from: .identifier)
        case .gordon:
            self.id = try mapper.map(from: .g_id)
        }
    }
}

extension SuperheroHelper : OutMappableWithContext {
    func outMap<Destination : OutMap>(mapper: inout ContextualOutMapper<Destination, SuperheroHelper.MappingKeys, SuperContext>) throws {
        try mapper.map(self.name, to: .name)
        switch mapper.context {
        case .json:
            try mapper.map(self.id, to: .id)
        case .mongo:
            try mapper.map(self.id, to: .identifier)
        case .gordon:
            try mapper.map(self.id, to: .g_id)
        }
    }
}

struct Superhero {
    
    let name: String
    let helper: SuperheroHelper
    
    enum MappingKeys : String, IndexPathElement {
        case name, helper
    }
    
    typealias Context = SuperContext
    
}

extension Superhero : InMappableWithContext {
    init<Source : InMap>(mapper: ContextualInMapper<Source, MappingKeys, Context>) throws {
        self.name = try mapper.map(from: .name)
        self.helper = try mapper.map(from: .helper)
    }
}

extension Superhero : OutMappableWithContext {
    func outMap<Destination : OutMap>(mapper: inout ContextualOutMapper<Destination, Superhero.MappingKeys, SuperContext>) throws {
        try mapper.map(self.name, to: .name)
        try mapper.map(self.helper, to: .helper)
    }
}

// MARK: - Adoption

public enum MapperMap {
    case int(Int)
    case double(Double)
    case string(String)
    case bool(Bool)
    case array([MapperMap])
    case dictionary([String: MapperMap])
}

extension MapperMap : InMap {
    
    public func get(at indexPath: IndexPathValue) -> MapperMap? {
        switch (indexPath, self) {
        case (.key(let key), .dictionary(let dict)):
            return dict[key]
        case (.index(let index), .array(let array)):
            if array.indices.contains(index) {
                return array[index]
            }
            return nil
        default:
            return nil
        }
    }
    
    public func get<T>() -> T? {
        switch self {
        case .int(let int as T):
            return int
        case .double(let double as T):
            return double
        case .string(let string as T):
            return string
        case .bool(let bool as T):
            return bool
        case .array(let array as T):
            return array
        case .dictionary(let dict as T):
            return dict
        default:
            return nil
        }
    }
    
    public var int: Int? {
        if case .int(let value) = self {
            return value
        }
        return nil
    }
    
    public var double: Double? {
        if case .double(let value) = self {
            return value
        }
        return nil
    }
    
    public var bool: Bool? {
        if case .bool(let value) = self {
            return value
        }
        return nil
    }
    
    public var string: String? {
        if case .string(let value) = self {
            return value
        }
        return nil
    }
    
    public func asArray() -> [MapperMap]? {
        if case .array(let array) = self {
            return array
        }
        return nil
    }
    
}

public enum MapperNeomap {
    case bool(Bool)
    case int32(Int32)
    case uint(UInt)
    case uint8(UInt8)
    case string(String)
    case float(Float)
    case array([MapperNeomap])
    case dictionary([String: MapperNeomap])
}

extension MapperNeomap {
    public func get<T>() -> T? {
        switch self {
        case .bool(let value as T):         return value
        case .int32(let value as T):        return value
        case .uint(let value as T):         return value
        case .uint8(let value as T):        return value
        case .string(let value as T):       return value
        case .float(let value as T):        return value
        case .array(let value as T):        return value
        case .dictionary(let value as T):   return value
        default:
            return nil
        }
    }
    
    public var int: Int? {
        switch self {
        case .int32(let value):     return Int(value)
        case .uint(let value):      return Int(value)
        case .uint8(let value):     return Int(value)
        default:
            return nil
        }
    }
    
    public var double: Double? {
        if case .float(let value) = self {
            return Double(value)
        }
        return nil
    }
    
    public var bool: Bool? {
        if case .bool(let value) = self {
            return value
        }
        return nil
    }
    
    public var string: String? {
        if case .string(let value) = self {
            return value
        }
        return nil
    }
}

enum MapperMapOutMapError : Error {
    case incompatibleType
}

extension MapperMap : OutMap {
    
    public static var blank: MapperMap {
        return .dictionary([:])
    }
    
    public mutating func set(_ map: MapperMap, at indexPath: IndexPathValue) throws {
        switch (indexPath, self) {
        case (.key(let key), .dictionary(var dict)):
            dict[key] = map
            self = .dictionary(dict)
        case (.index(let index), .array(var array)):
            array[index] = map
            self = .array(array)
        default:
            throw MapperMapOutMapError.incompatibleType
        }
    }
    
    public static func fromArray(_ array: [MapperMap]) -> MapperMap? {
        return .array(array)
    }
    
    public static func from<T>(_ value: T) -> MapperMap? {
        if let int = value as? Int {
            return .int(int)
        }
        if let double = value as? Double {
            return .double(double)
        }
        if let string = value as? String {
            return .string(string)
        }
        if let bool = value as? Bool {
            return .bool(bool)
        }
        if let array = value as? [MapperMap] {
            return .array(array)
        }
        if let dict = value as? [String: MapperMap] {
            return .dictionary(dict)
        }
        return nil
    }
    
    public static func from(_ int: Int) -> MapperMap? {
        return MapperMap.int(int)
    }
    
    public static func from(_ double: Double) -> MapperMap? {
        return MapperMap.double(double)
    }
    
    public static func from(_ bool: Bool) -> MapperMap? {
        return MapperMap.bool(bool)
    }
    
    public static func from(_ string: String) -> MapperMap? {
        return MapperMap.string(string)
    }
    
}

extension MapperNeomap {
    
    public static func from<T>(_ value: T) -> MapperNeomap? {
        if let string = value as? String {
            return .string(string)
        }
        if let bool = value as? Bool {
            return .bool(bool)
        }
        if let i32 = value as? Int32 {
            return .int32(i32)
        }
        if let uint = value as? UInt {
            return .uint(uint)
        }
        if let uint8 = value as? UInt8 {
            return .uint8(uint8)
        }
        if let float = value as? Float {
            return .float(float)
        }
        if let array = value as? [MapperNeomap] {
            return .array(array)
        }
        if let dict = value as? [String: MapperNeomap] {
            return .dictionary(dict)
        }
        return nil
    }
    
    public static func from(_ int: Int) -> MapperNeomap? {
        return .int32(Int32(int))
    }
    
    public static func from(_ double: Double) -> MapperNeomap? {
        return .float(Float(double))
    }
    
    public static func from(_ bool: Bool) -> MapperNeomap? {
        return .bool(bool)
    }
    
    public static func from(_ string: String) -> MapperNeomap? {
        return .string(string)
    }
    
}
