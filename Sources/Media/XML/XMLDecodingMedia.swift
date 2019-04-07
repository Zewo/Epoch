import Core
import Venice

extension XML : DecodingMedia {
    public static var mediaType: MediaType {
        return .xml
    }
    
    public init(from readable: Readable, deadline: Deadline) throws {
        self = try XMLParser.parse(readable, deadline: deadline)
    }
    
    public func keyCount() -> Int? {
        return 1
    }
    
    public func allKeys<Key>(keyedBy: Key.Type) -> [Key] where Key : CodingKey {
        return Key(stringValue: root.name).map({ [$0] }) ?? []
    }
    
    public func contains<Key>(_ key: Key) -> Bool where Key : CodingKey {
        return root.name == key.stringValue
    }
    
    public func keyedContainer() throws -> DecodingMedia {
        return self
    }
    
    public func unkeyedContainer() throws -> DecodingMedia {
        throw DecodingError.typeMismatch(DecodingMedia.self, DecodingError.Context())
    }
    
    public func singleValueContainer() throws -> DecodingMedia {
        throw DecodingError.typeMismatch(DecodingMedia.self, DecodingError.Context())
    }
    
    public func decode(_ type: DecodingMedia.Type, forKey key: CodingKey) throws -> DecodingMedia {
        
        return XMLMap.single(root) // change this (wrap root)
    }
    
    public func decodeIfPresent(
        _ type: DecodingMedia.Type,
        forKey key: CodingKey
    ) throws -> DecodingMedia? {
        guard root.name == key.stringValue else {
            return nil
        }
        
        return XMLMap.single(root) // change this (wrap root)
    }
    
    public func decodeNil() -> Bool {
        return false
    }
    
    public func decode(_ type: Bool.Type) throws -> Bool {
        throw DecodingError.typeMismatch(Bool.self, DecodingError.Context())
    }
    
    public func decode(_ type: Int.Type) throws -> Int {
        throw DecodingError.typeMismatch(Bool.self, DecodingError.Context())
    }
    
    public func decode(_ type: Int8.Type) throws -> Int8 {
        throw DecodingError.typeMismatch(Bool.self, DecodingError.Context())
    }
    
    public func decode(_ type: Int16.Type) throws -> Int16 {
        throw DecodingError.typeMismatch(Bool.self, DecodingError.Context())
    }
    
    public func decode(_ type: Int32.Type) throws -> Int32 {
        throw DecodingError.typeMismatch(Bool.self, DecodingError.Context())
    }
    
    public func decode(_ type: Int64.Type) throws -> Int64 {
        throw DecodingError.typeMismatch(Bool.self, DecodingError.Context())
    }
    
    public func decode(_ type: UInt.Type) throws -> UInt {
        throw DecodingError.typeMismatch(Bool.self, DecodingError.Context())
    }
    
    public func decode(_ type: UInt8.Type) throws -> UInt8 {
        throw DecodingError.typeMismatch(Bool.self, DecodingError.Context())
    }
    
    public func decode(_ type: UInt16.Type) throws -> UInt16 {
        throw DecodingError.typeMismatch(Bool.self, DecodingError.Context())
    }
    
    public func decode(_ type: UInt32.Type) throws -> UInt32 {
        throw DecodingError.typeMismatch(Bool.self, DecodingError.Context())
    }
    
    public func decode(_ type: UInt64.Type) throws -> UInt64 {
        throw DecodingError.typeMismatch(Bool.self, DecodingError.Context())
    }
    
    public func decode(_ type: Float.Type) throws -> Float {
        throw DecodingError.typeMismatch(Bool.self, DecodingError.Context())
    }
    
    public func decode(_ type: Double.Type) throws -> Double {
        throw DecodingError.typeMismatch(Bool.self, DecodingError.Context())
    }
    
    public func decode(_ type: String.Type) throws -> String {
        throw DecodingError.typeMismatch(Bool.self, DecodingError.Context())
    }
}

enum XMLMap {
    case single(XML.Element)
    case multiple([XML.Element])
}

extension XMLMap : DecodingMedia {
    static var mediaType: MediaType {
        return .xml
    }
    
    init(from readable: Readable, deadline: Deadline) throws {
        let xml = try XML(from: readable, deadline: deadline)
        self = .single(xml.root)
    }
    
    public func keyCount() -> Int? {
        switch self {
        case let .single(element):
            return Set(element.elements.map({ $0.name })).count
        case let .multiple(elements):
            return elements.count
        }
    }
    
    public func allKeys<Key>(keyedBy: Key.Type) -> [Key] where Key : CodingKey {
        switch self {
        case let .single(element):
            return Set(element.elements.map({ $0.name })).compactMap({ Key(stringValue: $0) })
        case let .multiple(elements):
            return elements.indices.compactMap({ Key(intValue: $0) })
        }
    }
    
    public func contains<Key>(_ key: Key) -> Bool where Key : CodingKey {
        switch self {
        case let .single(element):
            return !element.elements(named: key.stringValue).isEmpty
        case let .multiple(elements):
            return elements.indices.contains(key.intValue ?? -1)
        }
    }
    
    public func keyedContainer() throws -> DecodingMedia {
        switch self {
        case .single:
            return self
        default:
            throw DecodingError.typeMismatch(DecodingMedia.self, DecodingError.Context())
        }
    }
    
    public func unkeyedContainer() throws -> DecodingMedia {
        switch self {
        case .multiple:
            return self
        default:
            throw DecodingError.typeMismatch(DecodingMedia.self, DecodingError.Context())
        }
    }
    
    public func singleValueContainer() throws -> DecodingMedia {
        switch self {
        case .single:
            return self
        default:
            throw DecodingError.typeMismatch(DecodingMedia.self, DecodingError.Context())
        }
    }
    
    func decode(_ type: DecodingMedia.Type, forKey key: CodingKey) throws -> DecodingMedia {
        switch self {
        case let .single(element):
            let elements = element.elements(named: key.stringValue)
            
            guard elements.count == 1, let element = elements.first else {
                return XMLMap.multiple(elements)
            }
            
            return XMLMap.single(element)
        case let .multiple(elements):
            guard let index = key.intValue else {
                throw DecodingError.keyNotFound(key, DecodingError.Context())
            }
            
            guard elements.indices.contains(index) else {
                throw DecodingError.keyNotFound(key, DecodingError.Context())
            }
            
            return XMLMap.single(elements[index])
        }
    }
    
    public func decodeIfPresent(
        _ type: DecodingMedia.Type,
        forKey key: CodingKey
    ) throws -> DecodingMedia? {
        switch self {
        case let .single(element):
            let elements = element.elements(named: key.stringValue)
            
            guard elements.count == 1, let element = elements.first else {
                return XMLMap.multiple(elements)
            }
            
            return XMLMap.single(element)
        case let .multiple(elements):
            guard let index = key.intValue else {
                throw DecodingError.keyNotFound(key, DecodingError.Context())
            }
            
            guard elements.indices.contains(index) else {
                throw DecodingError.keyNotFound(key, DecodingError.Context())
            }
            
            return XMLMap.single(elements[index])
        }
    }
    
    public func decodeNil() -> Bool {
        return false
    }
    
    public func decode(_ type: Bool.Type) throws -> Bool {
        guard let bool = try Bool(contents(forType: type)) else {
            throw DecodingError.typeMismatch(Bool.self, DecodingError.Context())
        }
        
        return bool
    }
    
    public func decode(_ type: Int.Type) throws -> Int {
        guard let int = try Int(contents(forType: type)) else {
            throw DecodingError.typeMismatch(Int.self, DecodingError.Context())
        }
        
        return int
    }
    
    public func decode(_ type: Int8.Type) throws -> Int8 {
        guard let int8 = try Int8(contents(forType: type)) else {
            throw DecodingError.typeMismatch(Int8.self, DecodingError.Context())
        }
        
        return int8
    }
    
    public func decode(_ type: Int16.Type) throws -> Int16 {
        guard let int16 = try Int16(contents(forType: type)) else {
            throw DecodingError.typeMismatch(Int16.self, DecodingError.Context())
        }
        
        return int16
    }
    
    public func decode(_ type: Int32.Type) throws -> Int32 {
        guard let int32 = try Int32(contents(forType: type)) else {
            throw DecodingError.typeMismatch(Int32.self, DecodingError.Context())
        }
        
        return int32
    }
    
    public func decode(_ type: Int64.Type) throws -> Int64 {
        guard let int64 = try Int64(contents(forType: type)) else {
            throw DecodingError.typeMismatch(Int64.self, DecodingError.Context())
        }
        
        return int64
    }
    
    public func decode(_ type: UInt.Type) throws -> UInt {
        guard let uint = try UInt(contents(forType: type)) else {
            throw DecodingError.typeMismatch(UInt.self, DecodingError.Context())
        }
        
        return uint
    }
    
    public func decode(_ type: UInt8.Type) throws -> UInt8 {
        guard let uint8 = try UInt8(contents(forType: type)) else {
            throw DecodingError.typeMismatch(UInt8.self, DecodingError.Context())
        }
        
        return uint8
    }
    
    public func decode(_ type: UInt16.Type) throws -> UInt16 {
        guard let uint16 = try UInt16(contents(forType: type)) else {
            throw DecodingError.typeMismatch(UInt16.self, DecodingError.Context())
        }
        
        return uint16
    }
    
    public func decode(_ type: UInt32.Type) throws -> UInt32 {
        guard let uint32 = try UInt32(contents(forType: type)) else {
            throw DecodingError.typeMismatch(UInt32.self, DecodingError.Context())
        }
        
        return uint32
    }
    
    public func decode(_ type: UInt64.Type) throws -> UInt64 {
        guard let uint64 = try UInt64(contents(forType: type)) else {
            throw DecodingError.typeMismatch(UInt64.self, DecodingError.Context())
        }
        
        return uint64
    }
    
    public func decode(_ type: Float.Type) throws -> Float {
        guard let float = try Float(contents(forType: type)) else {
            throw DecodingError.typeMismatch(Float.self, DecodingError.Context())
        }
        
        return float
    }
    
    public func decode(_ type: Double.Type) throws -> Double {
        guard let double = try Double(contents(forType: type)) else {
            throw DecodingError.typeMismatch(Double.self, DecodingError.Context())
        }
        
        return double
    }
    
    public func decode(_ type: String.Type) throws -> String {
        return try contents(forType: type)
    }
    
    private func contents(forType: Any.Type) throws -> String {
        guard case let .single(element) = self else {
            throw DecodingError.typeMismatch(forType, DecodingError.Context())
        }
        
        return element.contents
    }
}
