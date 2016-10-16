import Mapper

public protocol MapInitializable {
    init(map: Map) throws
}

public protocol MapRepresentable : MapFallibleRepresentable {
    var map: Map { get }
}

public protocol MapFallibleRepresentable {
    func asMap() throws -> Map
}

extension MapRepresentable {
    public func asMap() throws -> Map {
        return map
    }
}

extension Map : MapRepresentable {
    public var map: Map {
        return self
    }
}

public protocol MapConvertible : MapInitializable, MapFallibleRepresentable {}

public enum Map {
    case null
    case bool(Bool)
    case double(Double)
    case int(Int)
    case string(String)
    case array([Map])
    case dictionary([String: Map])
}

// MARK: MapError

public enum MapError : Error {
    case incompatibleType
    case outOfBounds
    case valueNotFound
    case notMapInitializable(Any.Type)
    case notMapRepresentable(Any.Type)
    case notMapDictionaryKeyInitializable(Any.Type)
    case notMapDictionaryKeyRepresentable(Any.Type)
    case cannotInitialize(type: Any.Type, from: Any.Type)
}

// MARK: Parser/Serializer Protocols

extension Bool : MapRepresentable {
    public var map: Map {
        return .bool(self)
    }
}

extension Double : MapRepresentable {
    public var map: Map {
        return .double(self)
    }
}

extension Int : MapRepresentable {
    public var map: Map {
        return .int(self)
    }
}

extension String : MapRepresentable {
    public var map: Map {
        return .string(self)
    }
}

extension Optional where Wrapped : MapRepresentable {
    public var map: Map {
        switch self {
        case .some(let wrapped): return wrapped.map
        case .none: return .null
        }
    }
}

extension Array where Element : MapRepresentable {
    public var mapArray: [Map] {
        return self.map({$0.map})
    }
    
    public var map: Map {
        return .array(mapArray)
    }
}

public protocol MapDictionaryKeyRepresentable {
    var mapDictionaryKey: String { get }
}

extension String : MapDictionaryKeyRepresentable {
    public var mapDictionaryKey: String {
        return self
    }
}

extension Dictionary where Key : MapDictionaryKeyRepresentable, Value : MapRepresentable {
    public var mapDictionary: [String: Map] {
        var dictionary: [String: Map] = [:]
        
        for (key, value) in self.map({($0.0.mapDictionaryKey, $0.1.map)}) {
            dictionary[key] = value
        }
        
        return dictionary
    }
    
    public var map: Map {
        return .dictionary(mapDictionary)
    }
}

// MARK: MapFallibleRepresentable

extension Optional : MapFallibleRepresentable {
    public func asMap() throws -> Map {
        guard Wrapped.self is MapFallibleRepresentable.Type else {
            throw MapError.notMapRepresentable(Wrapped.self)
        }
        if case .some(let wrapped as MapFallibleRepresentable) = self {
            return try wrapped.asMap()
        }
        return .null
    }
}

extension Array : MapFallibleRepresentable {
    public func asMap() throws -> Map {
        guard Element.self is MapFallibleRepresentable.Type else {
            throw MapError.notMapRepresentable(Element.self)
        }
        var array: [Map] = []
        array.reserveCapacity(count)
        for element in self {
            let element = element as! MapFallibleRepresentable
            array.append(try element.asMap())
        }
        return .array(array)
    }
}

extension Dictionary : MapFallibleRepresentable {
    public func asMap() throws -> Map {
        guard Key.self is MapDictionaryKeyRepresentable.Type else {
            throw MapError.notMapDictionaryKeyRepresentable(Value.self)
        }
        guard Value.self is MapFallibleRepresentable.Type else {
            throw MapError.notMapRepresentable(Value.self)
        }
        var dictionary = [String: Map](minimumCapacity: count)
        for (key, value) in self {
            let value = value as! MapFallibleRepresentable
            let key = key as! MapDictionaryKeyRepresentable
            dictionary[key.mapDictionaryKey] = try value.asMap()
        }
        return .dictionary(dictionary)
    }
}

// MARK: Initializers

extension Map {
    public init<T: MapRepresentable>(_ value: T?) {
        self = value?.map ?? .null
    }
    
    public init<T: MapRepresentable>(_ values: [T]?) {
        if let values = values {
            self = .array(values.map({$0.map}))
        } else {
            self = .null
        }
    }
    
    public init<T: MapRepresentable>(_ values: [T?]?) {
        if let values = values {
            self = .array(values.map({$0?.map ?? .null}))
        } else {
            self = .null
        }
    }
    
    public init<T: MapRepresentable>(_ values: [String: T]?) {
        if let values = values {
            var dictionary: [String: Map] = [:]
            
            for (key, value) in values.map({($0.key, $0.value.map)}) {
                dictionary[key] = value
            }
            
            self = .dictionary(dictionary)
        } else {
            self = .null
        }
    }
    
    public init<T: MapRepresentable>(_ values: [String: T?]?) {
        if let values = values {
            var dictionary: [String: Map] = [:]
            
            for (key, value) in values.map({($0.key, $0.value?.map ?? .null)}) {
                dictionary[key] = value
            }
            
            self = .dictionary(dictionary)
        } else {
            self = .null
        }
    }
}

// MARK: is<Type>

extension Map {
    public var isNull: Bool {
        if case .null = self {
            return true
        }
        return false
    }
    
    public var isBool: Bool {
        if case .bool = self {
            return true
        }
        return false
    }
    
    public var isDouble: Bool {
        if case .double = self {
            return true
        }
        return false
    }
    
    public var isInt: Bool {
        if case .int = self {
            return true
        }
        return false
    }
    
    public var isString: Bool {
        if case .string = self {
            return true
        }
        return false
    }
    
    public var isArray: Bool {
        if case .array = self {
            return true
        }
        return false
    }
    
    public var isDictionary: Bool {
        if case .dictionary = self {
            return true
        }
        return false
    }
}

// MARK: as<type>?

extension Map {
    public var bool: Bool? {
        if case .bool(let value) = self {
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
    
    public var int: Int? {
        if case .int(let value) = self {
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
    
    public var array: [Map]? {
        return try? get()
    }
    
    public var dictionary: [String: Map]? {
        return try? get()
    }
}

// MARK: try as<type>()

extension Map {
    public func asBool(converting: Bool = false) throws -> Bool {
        guard converting else {
            return try get()
        }
        
        switch self {
        case .bool(let value):
            return value
            
        case .int(let value):
            return value != 0
            
        case .double(let value):
            return value != 0
            
        case .string(let value):
            switch value.lowercased() {
            case "true": return true
            case "false": return false
            default: throw MapError.incompatibleType
            }
            
        case .array(let value):
            return !value.isEmpty
            
        case .dictionary(let value):
            return !value.isEmpty
            
        case .null:
            return false
        }
    }
    
    public func asInt(converting: Bool = false) throws -> Int {
        guard converting else {
            return try get()
        }
        
        switch self {
        case .bool(let value):
            return value ? 1 : 0
            
        case .int(let value):
            return value
            
        case .double(let value):
            return Int(value)
            
        case .string(let value):
            if let int = Int(value) {
                return int
            }
            throw MapError.incompatibleType
            
        case .null:
            return 0
            
        default:
            throw MapError.incompatibleType
        }
    }
    
    public func asDouble(converting: Bool = false) throws -> Double {
        guard converting else {
            return try get()
        }
        
        switch self {
        case .bool(let value):
            return value ? 1.0 : 0.0
            
        case .int(let value):
            return Double(value)
            
        case .double(let value):
            return value
            
        case .string(let value):
            if let double = Double(value) {
                return double
            }
            throw MapError.incompatibleType
            
        case .null:
            return 0
            
        default:
            throw MapError.incompatibleType
        }
    }
    
    public func asString(converting: Bool = false) throws -> String {
        guard converting else {
            return try get()
        }
        
        switch self {
        case .bool(let value):
            return String(value)
            
        case .int(let value):
            return String(value)
            
        case .double(let value):
            return String(value)
            
        case .string(let value):
            return value
            
        case .array:
            throw MapError.incompatibleType
            
        case .dictionary:
            throw MapError.incompatibleType
            
        case .null:
            return "null"
        }
    }
    
    public func asArr(converting: Bool = false) throws -> [Map] {
        guard converting else {
            return try get()
        }
        
        switch self {
        case .array(let value):
            return value
            
        case .null:
            return []
            
        default:
            throw MapError.incompatibleType
        }
    }
    
    public func asDictionary(converting: Bool = false) throws -> [String: Map] {
        guard converting else {
            return try get()
        }
        
        switch self {
        case .dictionary(let value):
            return value
            
        case .null:
            return [:]
            
        default:
            throw MapError.incompatibleType
        }
    }
}

// MARK: IndexPath

public typealias IndexPath = [IndexPathElement]

extension IndexPathElement {
    var constructEmptyContainer: Map {
        switch indexPathValue {
        case .index: return []
        case .key: return [:]
        }
    }
}

// MARK: Get

extension Map {
    public func get<T : MapInitializable>(_ indexPath: IndexPathElement...) throws -> T {
        let map = try get(indexPath)
        return try T(map: map)
    }
    
    public func get<T>(_ indexPath: IndexPathElement...) throws -> T {
        if indexPath.isEmpty {
            switch self {
            case .bool(let value as T): return value
            case .int(let value as T): return value
            case .double(let value as T): return value
            case .string(let value as T): return value
            case .array(let value as T): return value
            case .dictionary(let value as T): return value
            default: throw MapError.incompatibleType
            }
        }
        return try get(indexPath).get()
    }
    
    public func get(_ indexPath: IndexPathElement...) throws -> Map {
        return try get(indexPath)
    }
    
    public func get(_ indexPath: IndexPath) throws -> Map {
        var value: Map = self
        
        for element in indexPath {
            switch element.indexPathValue {
            case .index(let index):
                let array = try value.asArr()
                if array.indices.contains(index) {
                    value = array[index]
                } else {
                    throw MapError.outOfBounds
                }
                
            case .key(let key):
                let dictionary = try value.asDictionary()
                if let newValue = dictionary[key] {
                    value = newValue
                } else {
                    throw MapError.valueNotFound
                }
            }
        }
        
        return value
    }
}

// MARK: Set

extension Map {
    public mutating func set<T : MapRepresentable>(_ value: T, for indexPath: IndexPathElement...) throws {
        try set(value, for: indexPath)
    }
    
    public mutating func set<T : MapRepresentable>(_ value: T, for indexPath: [IndexPathElement]) throws {
        try set(value, for: indexPath, merging: true)
    }
    
    fileprivate mutating func set<T : MapRepresentable>(_ value: T, for indexPath: [IndexPathElement], merging: Bool) throws {
        var indexPath = indexPath
        
        guard let first = indexPath.first else {
            return self = value.map
        }
        
        indexPath.removeFirst()
        
        if indexPath.isEmpty {
            switch first.indexPathValue {
            case .index(let index):
                if case .array(var array) = self {
                    if !array.indices.contains(index) {
                        throw MapError.outOfBounds
                    }
                    array[index] = value.map
                    self = .array(array)
                } else {
                    throw MapError.incompatibleType
                }
            case .key(let key):
                if case .dictionary(var dictionary) = self {
                    let newValue = value.map
                    if let existingDictionary = dictionary[key]?.dictionary,
                        let newDictionary = newValue.dictionary,
                        merging {
                        var combinedDictionary: [String: Map] = [:]
                        
                        for (key, value) in existingDictionary {
                            combinedDictionary[key] = value
                        }
                        
                        for (key, value) in newDictionary {
                            combinedDictionary[key] = value
                        }
                        
                        dictionary[key] = .dictionary(combinedDictionary)
                    } else {
                        dictionary[key] = newValue
                    }
                    self = .dictionary(dictionary)
                } else {
                    throw MapError.incompatibleType
                }
            }
        } else {
            var next = (try? self.get(first)) ?? first.constructEmptyContainer
            try next.set(value, for: indexPath)
            try self.set(next, for: [first])
        }
    }
}

// MARK: Remove

extension Map {
    public mutating func remove(_ indexPath: IndexPathElement...) throws {
        try self.remove(indexPath)
    }
    
    public mutating func remove(_ indexPath: [IndexPathElement]) throws {
        var indexPath = indexPath
        
        guard let first = indexPath.first else {
            return self = .null
        }
        
        indexPath.removeFirst()
        
        if indexPath.isEmpty {
            guard case .dictionary(var dictionary) = self, case .key(let key) = first.indexPathValue else {
                throw MapError.incompatibleType
            }
            
            dictionary[key] = nil
            self = .dictionary(dictionary)
        } else {
            guard var next = try? self.get(first) else {
                throw MapError.valueNotFound
            }
            try next.remove(indexPath)
            try self.set(next, for: [first], merging: false)
        }
    }
}

// MARK: Subscripts

extension Map {
    public subscript(indexPath: IndexPathElement...) -> Map {
        get {
            return self[indexPath]
        }
        
        set(value) {
            self[indexPath] = value
        }
    }
    
    public subscript(indexPath: [IndexPathElement]) -> Map {
        get {
            return (try? self.get(indexPath)) ?? nil
        }
        
        set(value) {
            do {
                try self.set(value, for: indexPath)
            } catch {
                fatalError(String(describing: error))
            }
        }
    }
}

// MARK: Equatable

extension Map : Equatable {}

public func == (lhs: Map, rhs: Map) -> Bool {
    switch (lhs, rhs) {
    case (.null, .null): return true
    case let (.int(l), .int(r)) where l == r: return true
    case let (.bool(l), .bool(r)) where l == r: return true
    case let (.string(l), .string(r)) where l == r: return true
    case let (.double(l), .double(r)) where l == r: return true
    case let (.array(l), .array(r)) where l == r: return true
    case let (.dictionary(l), .dictionary(r)) where l == r: return true
    default: return false
    }
}

// MARK: Literal Convertibles

extension Map : ExpressibleByNilLiteral {
    public init(nilLiteral value: Void) {
        self = .null
    }
}

extension Map : ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: BooleanLiteralType) {
        self = .bool(value)
    }
}

extension Map : ExpressibleByIntegerLiteral {
    public init(integerLiteral value: IntegerLiteralType) {
        self = .int(value)
    }
}

extension Map : ExpressibleByFloatLiteral {
    public init(floatLiteral value: FloatLiteralType) {
        self = .double(value)
    }
}

extension Map : ExpressibleByStringLiteral {
    public init(unicodeScalarLiteral value: String) {
        self = .string(value)
    }
    
    public init(extendedGraphemeClusterLiteral value: String) {
        self = .string(value)
    }
    
    public init(stringLiteral value: StringLiteralType) {
        self = .string(value)
    }
}

extension Map : ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Map...) {
        self = .array(elements)
    }
}

extension Map : ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, Map)...) {
        var dictionary = [String: Map](minimumCapacity: elements.count)
        
        for (key, value) in elements {
            dictionary[key] = value
        }
        
        self = .dictionary(dictionary)
    }
}

// MARK: CustomStringConvertible

extension Map : CustomStringConvertible {
    public var description: String {
        let escapeMapping: [Character: String] = [
            "\r": "\\r",
            "\n": "\\n",
            "\t": "\\t",
            "\\": "\\\\",
            "\"": "\\\"",
            
            "\u{2028}": "\\u2028",
            "\u{2029}": "\\u2029",
            
            "\r\n": "\\r\\n"
        ]
        
        func escape(_ source: String) -> String {
            var string = "\""
            
            for character in source.characters {
                if let escapedSymbol = escapeMapping[character] {
                    string.append(escapedSymbol)
                } else {
                    string.append(character)
                }
            }
            
            string.append("\"")
            return string
        }
        
        func serialize(map: Map) -> String {
            switch map {
            case .null: return "null"
            case .bool(let bool): return String(bool)
            case .double(let number): return String(number)
            case .int(let number): return String(number)
            case .string(let string): return escape(string)
            case .array(let array): return serialize(array: array)
            case .dictionary(let dictionary): return serialize(dictionary: dictionary)
            }
        }
        
        func serialize(array: [Map]) -> String {
            var string = "["
            
            for index in 0 ..< array.count {
                string += serialize(map: array[index])
                
                if index != array.count - 1 {
                    string += ","
                }
            }
            
            return string + "]"
        }
        
        func serialize(dictionary: [String: Map]) -> String {
            var string = "{"
            var index = 0
            
            for (key, value) in dictionary.sorted(by: {$0.0 < $1.0}) {
                string += escape(key) + ":" + serialize(map: value)
                
                if index != dictionary.count - 1 {
                    string += ","
                }
                
                index += 1
            }
            
            return string + "}"
        }
        
        return serialize(map: self)
    }
}

extension Map: InMap {
    
    public func get(at indexPath: IndexPathValue) -> Map? {
        return try? get(indexPath)
    }
        
    public func get<T>() -> T? {
        return try? get()
    }
    
    public func asArray() -> [Map]? {
        return try? asArr()
    }
    
}

extension Map: OutMap {
    
    mutating public func set(_ map: Map, at indexPath: IndexPathValue) throws {
        try self.set(map, for: [indexPath])
    }
    
    mutating public func set(_ map: Map, at indexPath: [IndexPathValue]) throws {
        try self.set(map, for: indexPath)
    }
    
    public static var blank: Map {
        return .dictionary([:])
    }
    
    public static func fromArray(_ array: [Map]) -> Map? {
        return .array(array)
    }
    
    public static func from<T>(_ value: T) -> Map? {
        if let value = value as? MapRepresentable {
            return value.map
        }
        return nil
    }
    
}
