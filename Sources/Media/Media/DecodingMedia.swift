import Core
import Venice

extension Decodable {
    public init<Map : DecodingMedia>(
        from map: Map,
        userInfo: [CodingUserInfoKey: Any] = [:]
    ) throws {
        let decoder = MediaDecoder<Map>(referencing: map, userInfo: userInfo)
        try self.init(from: decoder)
    }
}

extension DecodingMedia {
    public static func decode<T : Decodable>(
        _ type: T.Type,
        from readable: Readable,
        deadline: Deadline,
        userInfo: [CodingUserInfoKey: Any] = [:]
    ) throws -> T {
        let media = try self.init(from: readable, deadline: deadline)
        return try T(from: media, userInfo: userInfo)
    }
    
    public init(from buffer: UnsafeRawBufferPointer, deadline: Deadline) throws {
        let readable = ReadableBuffer(buffer)
        try self.init(from: readable, deadline: deadline)
    }
}

public protocol DecodingMedia {
    static var mediaType: MediaType { get }
    
    init(from readable: Readable, deadline: Deadline) throws
    
    func keyCount() -> Int?
    func allKeys<Key : CodingKey>(keyedBy: Key.Type) -> [Key]
    func contains<Key : CodingKey>(_ key: Key) -> Bool
    
    func keyedContainer() throws -> DecodingMedia
    func unkeyedContainer() throws -> DecodingMedia
    func singleValueContainer() throws -> DecodingMedia
    
    func decodeIfPresent(_ type: DecodingMedia.Type, forKey key: CodingKey) throws -> DecodingMedia?
    func decodeNil() -> Bool
    func decode(_ type: Bool.Type) throws -> Bool
    func decode(_ type: Int.Type) throws -> Int
    func decode(_ type: Int8.Type) throws -> Int8
    func decode(_ type: Int16.Type) throws -> Int16
    func decode(_ type: Int32.Type) throws -> Int32
    func decode(_ type: Int64.Type) throws -> Int64
    func decode(_ type: UInt.Type) throws -> UInt
    func decode(_ type: UInt8.Type) throws -> UInt8
    func decode(_ type: UInt16.Type) throws -> UInt16
    func decode(_ type: UInt32.Type) throws -> UInt32
    func decode(_ type: UInt64.Type) throws -> UInt64
    func decode(_ type: Float.Type) throws -> Float
    func decode(_ type: Double.Type) throws -> Double
    func decode(_ type: String.Type) throws -> String
    func decode<D : Decodable>(_ type: D.Type) throws -> D
    
    // Optional
    
    func keyedContainer(forKey key: CodingKey) throws -> DecodingMedia
    func unkeyedContainer(forKey key: CodingKey) throws -> DecodingMedia
    
    func decodeIfPresent(_ type: Bool.Type, forKey key: CodingKey) throws -> Bool?
    func decodeIfPresent(_ type: Int.Type, forKey key: CodingKey) throws -> Int?
    func decodeIfPresent(_ type: Int8.Type, forKey key: CodingKey) throws -> Int8?
    func decodeIfPresent(_ type: Int16.Type, forKey key: CodingKey) throws -> Int16?
    func decodeIfPresent(_ type: Int32.Type, forKey key: CodingKey) throws -> Int32?
    func decodeIfPresent(_ type: Int64.Type, forKey key: CodingKey) throws -> Int64?
    func decodeIfPresent(_ type: UInt.Type, forKey key: CodingKey) throws -> UInt?
    func decodeIfPresent(_ type: UInt8.Type, forKey key: CodingKey) throws -> UInt8?
    func decodeIfPresent(_ type: UInt16.Type, forKey key: CodingKey) throws -> UInt16?
    func decodeIfPresent(_ type: UInt32.Type, forKey key: CodingKey) throws -> UInt32?
    func decodeIfPresent(_ type: UInt64.Type, forKey key: CodingKey) throws -> UInt64?
    func decodeIfPresent(_ type: Float.Type, forKey key: CodingKey) throws -> Float?
    func decodeIfPresent(_ type: Double.Type, forKey key: CodingKey) throws -> Double?
    func decodeIfPresent(_ type: String.Type, forKey key: CodingKey) throws -> String?
    func decodeNilIfPresent(forKey key: CodingKey) throws -> Bool
    
    func decodeIfPresent(_ type: Bool.Type) throws -> Bool?
    func decodeIfPresent(_ type: Int.Type) throws -> Int?
    func decodeIfPresent(_ type: Int8.Type) throws -> Int8?
    func decodeIfPresent(_ type: Int16.Type) throws -> Int16?
    func decodeIfPresent(_ type: Int32.Type) throws -> Int32?
    func decodeIfPresent(_ type: Int64.Type) throws -> Int64?
    func decodeIfPresent(_ type: UInt.Type) throws -> UInt?
    func decodeIfPresent(_ type: UInt8.Type) throws -> UInt8?
    func decodeIfPresent(_ type: UInt16.Type) throws -> UInt16?
    func decodeIfPresent(_ type: UInt32.Type) throws -> UInt32?
    func decodeIfPresent(_ type: UInt64.Type) throws -> UInt64?
    func decodeIfPresent(_ type: Float.Type) throws -> Float?
    func decodeIfPresent(_ type: Double.Type) throws -> Double?
    func decodeIfPresent(_ type: String.Type) throws -> String?
}

extension DecodingMedia {
    public func keyedContainer(forKey key: CodingKey) throws -> DecodingMedia {
        guard let map = try decodeIfPresent(Self.self, forKey: key) else {
            throw DecodingError.keyNotFound(key, DecodingError.Context())
        }
        
        return try map.keyedContainer()
    }
    
    public func unkeyedContainer(forKey key: CodingKey) throws -> DecodingMedia {
        guard let map = try decodeIfPresent(Self.self, forKey: key) else {
            throw DecodingError.keyNotFound(key, DecodingError.Context())
        }
        
        return try map.unkeyedContainer()
    }
    
    public func decode<D : Decodable>(_ type: D.Type, forKey key: CodingKey) throws -> D {
        guard let map = try decodeIfPresent(Self.self, forKey: key) as? Self else {
            throw DecodingError.valueNotFound(type, DecodingError.Context())
        }

        return try D(from: map)
    }
    
    public func decode<D : Decodable>(_ type: D.Type) throws -> D {
        return try D(from: self)
    }

    
    public func decode(_ type: Bool.Type, forKey key: CodingKey) throws -> Bool {
        guard let map = try decodeIfPresent(Self.self, forKey: key) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context())
        }
        
        return try map.decode(type)
    }
    
    public func decode(_ type: Int.Type, forKey key: CodingKey) throws -> Int {
        guard let map = try decodeIfPresent(Self.self, forKey: key) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context())
        }
        
        return try map.decode(type)
    }
    
    public func decode(_ type: Int8.Type, forKey key: CodingKey) throws -> Int8 {
        guard let map = try decodeIfPresent(Self.self, forKey: key) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context())
        }
        
        return try map.decode(type)
    }
    
    public func decode(_ type: Int16.Type, forKey key: CodingKey) throws -> Int16 {
        guard let map = try decodeIfPresent(Self.self, forKey: key) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context())
        }
        
        return try map.decode(type)
    }
    
    public func decode(_ type: Int32.Type, forKey key: CodingKey) throws -> Int32 {
        guard let map = try decodeIfPresent(Self.self, forKey: key) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context())
        }
        
        return try map.decode(type)
    }
    
    public func decode(_ type: Int64.Type, forKey key: CodingKey) throws -> Int64 {
        guard let map = try decodeIfPresent(Self.self, forKey: key) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context())
        }
        
        return try map.decode(type)
    }
    
    public func decode(_ type: UInt.Type, forKey key: CodingKey) throws -> UInt {
        guard let map = try decodeIfPresent(Self.self, forKey: key) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context())
        }
        
        return try map.decode(type)
    }
    
    public func decode(_ type: UInt8.Type, forKey key: CodingKey) throws -> UInt8 {
        guard let map = try decodeIfPresent(Self.self, forKey: key) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context())
        }
        
        return try map.decode(type)
    }
    
    public func decode(_ type: UInt16.Type, forKey key: CodingKey) throws -> UInt16 {
        guard let map = try decodeIfPresent(Self.self, forKey: key) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context())
        }
        
        return try map.decode(type)
    }
    
    public func decode(_ type: UInt32.Type, forKey key: CodingKey) throws -> UInt32 {
        guard let map = try decodeIfPresent(Self.self, forKey: key) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context())
        }
        
        return try map.decode(type)
    }
    
    public func decode(_ type: UInt64.Type, forKey key: CodingKey) throws -> UInt64 {
        guard let map = try decodeIfPresent(Self.self, forKey: key) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context())
        }
        
        return try map.decode(type)
    }
    
    public func decode(_ type: Float.Type, forKey key: CodingKey) throws -> Float {
        guard let map = try decodeIfPresent(Self.self, forKey: key) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context())
        }
        
        return try map.decode(type)
    }
    
    public func decode(_ type: Double.Type, forKey key: CodingKey) throws -> Double {
        guard let map = try decodeIfPresent(Self.self, forKey: key) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context())
        }
        
        return try map.decode(type)
    }
    
    public func decode(_ type: String.Type, forKey key: CodingKey) throws -> String {
        guard let map = try decodeIfPresent(Self.self, forKey: key) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context())
        }
        
        return try map.decode(type)
    }
    
    public func decodeIfPresent(_ type: Bool.Type, forKey key: CodingKey) throws -> Bool? {
        guard let map = try decodeIfPresent(Self.self, forKey: key) else {
            return nil
        }
        
        return try map.decode(type)
    }
    
    public func decodeIfPresent(_ type: Int.Type, forKey key: CodingKey) throws -> Int? {
        guard let map = try decodeIfPresent(Self.self, forKey: key) else {
            return nil
        }
        
        return try map.decode(type)
    }
    
    public func decodeIfPresent(_ type: Int8.Type, forKey key: CodingKey) throws -> Int8? {
        guard let map = try decodeIfPresent(Self.self, forKey: key) else {
            return nil
        }
        
        return try map.decode(type)
    }
    
    public func decodeIfPresent(_ type: Int16.Type, forKey key: CodingKey) throws -> Int16? {
        guard let map = try decodeIfPresent(Self.self, forKey: key) else {
            return nil
        }
        
        return try map.decode(type)
    }
    
    public func decodeIfPresent(_ type: Int32.Type, forKey key: CodingKey) throws -> Int32? {
        guard let map = try decodeIfPresent(Self.self, forKey: key) else {
            return nil
        }
        
        return try map.decode(type)
    }
    
    public func decodeIfPresent(_ type: Int64.Type, forKey key: CodingKey) throws -> Int64? {
        guard let map = try decodeIfPresent(Self.self, forKey: key) else {
            return nil
        }
        
        return try map.decode(type)
    }
    
    public func decodeIfPresent(_ type: UInt.Type, forKey key: CodingKey) throws -> UInt? {
        guard let map = try decodeIfPresent(Self.self, forKey: key) else {
            return nil
        }
        
        return try map.decode(type)
    }
    
    public func decodeIfPresent(_ type: UInt8.Type, forKey key: CodingKey) throws -> UInt8? {
        guard let map = try decodeIfPresent(Self.self, forKey: key) else {
            return nil
        }
        
        return try map.decode(type)
    }
    
    public func decodeIfPresent(_ type: UInt16.Type, forKey key: CodingKey) throws -> UInt16? {
        guard let map = try decodeIfPresent(Self.self, forKey: key) else {
            return nil
        }
        
        return try map.decode(type)
    }
    
    public func decodeIfPresent(_ type: UInt32.Type, forKey key: CodingKey) throws -> UInt32? {
        guard let map = try decodeIfPresent(Self.self, forKey: key) else {
            return nil
        }
        
        return try map.decode(type)
    }
    
    public func decodeIfPresent(_ type: UInt64.Type, forKey key: CodingKey) throws -> UInt64? {
        guard let map = try decodeIfPresent(Self.self, forKey: key) else {
            return nil
        }
        
        return try map.decode(type)
    }
    
    public func decodeIfPresent(_ type: Float.Type, forKey key: CodingKey) throws -> Float? {
        guard let map = try decodeIfPresent(Self.self, forKey: key) else {
            return nil
        }
        
        return try map.decode(type)
    }
    
    public func decodeIfPresent(_ type: Double.Type, forKey key: CodingKey) throws -> Double? {
        guard let map = try decodeIfPresent(Self.self, forKey: key) else {
            return nil
        }
        
        return try map.decode(type)
    }
    
    public func decodeIfPresent(_ type: String.Type, forKey key: CodingKey) throws -> String? {
        guard let map = try decodeIfPresent(Self.self, forKey: key) else {
            return nil
        }
        
        return try map.decode(type)
    }
    
    public func decodeIfPresent(_ type: Bool.Type) throws -> Bool? {
        guard !decodeNil() else {
            return nil
        }
        
        return try decode(type)
    }
    
    public func decodeIfPresent(_ type: Int.Type) throws -> Int? {
        guard !decodeNil() else {
            return nil
        }
        
        return try decode(type)
    }
    
    public func decodeIfPresent(_ type: Int8.Type) throws -> Int8? {
        guard !decodeNil() else {
            return nil
        }
        
        return try decode(type)
    }
    
    public func decodeIfPresent(_ type: Int16.Type) throws -> Int16? {
        guard !decodeNil() else {
            return nil
        }
        
        return try decode(type)
    }
    
    public func decodeIfPresent(_ type: Int32.Type) throws -> Int32? {
        guard !decodeNil() else {
            return nil
        }
        
        return try decode(type)
    }
    
    public func decodeIfPresent(_ type: Int64.Type) throws -> Int64? {
        guard !decodeNil() else {
            return nil
        }
        
        return try decode(type)
    }
    
    public func decodeIfPresent(_ type: UInt.Type) throws -> UInt? {
        guard !decodeNil() else {
            return nil
        }
        
        return try decode(type)
    }
    
    public func decodeIfPresent(_ type: UInt8.Type) throws -> UInt8? {
        guard !decodeNil() else {
            return nil
        }
        
        return try decode(type)
    }
    
    public func decodeIfPresent(_ type: UInt16.Type) throws -> UInt16? {
        guard !decodeNil() else {
            return nil
        }
        
        return try decode(type)
    }
    
    public func decodeIfPresent(_ type: UInt32.Type) throws -> UInt32? {
        guard !decodeNil() else {
            return nil
        }
        
        return try decode(type)
    }
    
    public func decodeIfPresent(_ type: UInt64.Type) throws -> UInt64? {
        guard !decodeNil() else {
            return nil
        }
        
        return try decode(type)
    }
    
    public func decodeIfPresent(_ type: Float.Type) throws -> Float? {
        guard !decodeNil() else {
            return nil
        }
        
        return try decode(type)
    }
    
    public func decodeIfPresent(_ type: Double.Type) throws -> Double? {
        guard !decodeNil() else {
            return nil
        }
        
        return try decode(type)
    }
    
    public func decodeIfPresent(_ type: String.Type) throws -> String? {
        guard !decodeNil() else {
            return nil
        }
        
        return try decode(type)
    }
}
