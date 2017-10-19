import Core
import Venice

extension EncodingMedia {
    public init(from encodable: Encodable, userInfo: [CodingUserInfoKey: Any] = [:]) throws {
        let encoder = MediaEncoder<Self>(userInfo: userInfo)
        try encodable.encode(to: encoder)
        self = try encoder.topLevelMap()
    }
    
    public static func encode<T : Encodable>(
        _ value: T,
        to writable: Writable,
        deadline: Deadline,
        userInfo: [CodingUserInfoKey: Any] = [:]
    ) throws {
        let media = try self.init(from: value, userInfo: userInfo)
        try media.encode(to: writable, deadline: deadline)
    }
}

public protocol EncodingMedia {
    static var mediaType: MediaType { get }
    
    func encode(to writable: Writable, deadline: Deadline) throws
    
    func topLevel() throws -> EncodingMedia
    
    static func makeKeyedContainer() throws -> EncodingMedia
    static func makeUnkeyedContainer() throws -> EncodingMedia
    
    mutating func encode(_ value: EncodingMedia, forKey key: CodingKey) throws
    mutating func encode(_ value: EncodingMedia) throws
    
    static func encodeNil() throws -> EncodingMedia
    static func encode(_ value: Bool) throws -> EncodingMedia
    static func encode(_ value: Int) throws -> EncodingMedia
    static func encode(_ value: Int8) throws -> EncodingMedia
    static func encode(_ value: Int16) throws -> EncodingMedia
    static func encode(_ value: Int32) throws -> EncodingMedia
    static func encode(_ value: Int64) throws -> EncodingMedia
    static func encode(_ value: UInt) throws -> EncodingMedia
    static func encode(_ value: UInt8) throws -> EncodingMedia
    static func encode(_ value: UInt16) throws -> EncodingMedia
    static func encode(_ value: UInt32) throws -> EncodingMedia
    static func encode(_ value: UInt64) throws -> EncodingMedia
    static func encode(_ value: Float) throws -> EncodingMedia
    static func encode(_ value: Double) throws -> EncodingMedia
    static func encode(_ value: String) throws -> EncodingMedia
    
    // Optional
    
    static func makeKeyedContainer(forKey key: CodingKey) throws -> EncodingMedia
    static func makeUnkeyedContainer(forKey key: CodingKey) throws -> EncodingMedia
    
    mutating func encode(_ value: Bool, forKey key: CodingKey) throws
    mutating func encode(_ value: Int, forKey key: CodingKey) throws
    mutating func encode(_ value: Int8, forKey key: CodingKey) throws
    mutating func encode(_ value: Int16, forKey key: CodingKey) throws
    mutating func encode(_ value: Int32, forKey key: CodingKey) throws
    mutating func encode(_ value: Int64, forKey key: CodingKey) throws
    mutating func encode(_ value: UInt, forKey key: CodingKey) throws
    mutating func encode(_ value: UInt8, forKey key: CodingKey) throws
    mutating func encode(_ value: UInt16, forKey key: CodingKey) throws
    mutating func encode(_ value: UInt32, forKey key: CodingKey) throws
    mutating func encode(_ value: UInt64, forKey key: CodingKey) throws
    mutating func encode(_ value: Float, forKey key: CodingKey) throws
    mutating func encode(_ value: Double, forKey key: CodingKey) throws
    mutating func encode(_ value: String, forKey key: CodingKey) throws
    mutating func encodeNil(forKey key: CodingKey) throws
    
    mutating func encode(_ value: Bool) throws
    mutating func encode(_ value: Int) throws
    mutating func encode(_ value: Int8) throws
    mutating func encode(_ value: Int16) throws
    mutating func encode(_ value: Int32) throws
    mutating func encode(_ value: Int64) throws
    mutating func encode(_ value: UInt) throws
    mutating func encode(_ value: UInt8) throws
    mutating func encode(_ value: UInt16) throws
    mutating func encode(_ value: UInt32) throws
    mutating func encode(_ value: UInt64) throws
    mutating func encode(_ value: Float) throws
    mutating func encode(_ value: Double) throws
    mutating func encode(_ value: String) throws
    mutating func encodeNil() throws
}

extension EncodingMedia {
    public static func makeKeyedContainer(forKey key: CodingKey) throws -> EncodingMedia {
        return try makeKeyedContainer()
    }
    
    public static func makeUnkeyedContainer(forKey key: CodingKey) throws -> EncodingMedia {
        return try makeKeyedContainer()
    }
    
    public mutating func encode(_ value: Bool, forKey key: CodingKey) throws {
        try encode(Self.encode(value), forKey: key)
    }
    
    public mutating func encode(_ value: Int, forKey key: CodingKey) throws {
        try encode(Self.encode(value), forKey: key)
    }
    
    public mutating func encode(_ value: Int8, forKey key: CodingKey) throws {
        try encode(Self.encode(value), forKey: key)
    }
    
    public mutating func encode(_ value: Int16, forKey key: CodingKey) throws {
        try encode(Self.encode(value), forKey: key)
    }
    
    public mutating func encode(_ value: Int32, forKey key: CodingKey) throws {
        try encode(Self.encode(value), forKey: key)
    }
    
    public mutating func encode(_ value: Int64, forKey key: CodingKey) throws {
        try encode(Self.encode(value), forKey: key)
    }
    
    public mutating func encode(_ value: UInt, forKey key: CodingKey) throws {
        try encode(Self.encode(value), forKey: key)
    }
    
    public mutating func encode(_ value: UInt8, forKey key: CodingKey) throws {
        try encode(Self.encode(value), forKey: key)
    }
    
    public mutating func encode(_ value: UInt16, forKey key: CodingKey) throws {
        try encode(Self.encode(value), forKey: key)
    }
    
    public mutating func encode(_ value: UInt32, forKey key: CodingKey) throws {
        try encode(Self.encode(value), forKey: key)
    }
    
    public mutating func encode(_ value: UInt64, forKey key: CodingKey) throws {
        try encode(Self.encode(value), forKey: key)
    }
    
    public mutating func encode(_ value: Float, forKey key: CodingKey) throws {
        try encode(Self.encode(value), forKey: key)
    }
    
    public mutating func encode(_ value: Double, forKey key: CodingKey) throws {
        try encode(Self.encode(value), forKey: key)
    }
    
    public mutating func encode(_ value: String, forKey key: CodingKey) throws {
        try encode(Self.encode(value), forKey: key)
    }
    
    public mutating func encode(_ value: Bool) throws {
        try encode(Self.encode(value))
    }
    
    public mutating func encode(_ value: Int) throws {
        try encode(Self.encode(value))
    }
    
    public mutating func encode(_ value: Int8) throws {
        try encode(Self.encode(value))
    }
    
    public mutating func encode(_ value: Int16) throws {
        try encode(Self.encode(value))
    }
    
    public mutating func encode(_ value: Int32) throws {
        try encode(Self.encode(value))
    }
    
    public mutating func encode(_ value: Int64) throws {
        try encode(Self.encode(value))
    }
    
    public mutating func encode(_ value: UInt) throws {
        try encode(Self.encode(value))
    }
    
    public mutating func encode(_ value: UInt8) throws {
        try encode(Self.encode(value))
    }
    
    public mutating func encode(_ value: UInt16) throws {
        try encode(Self.encode(value))
    }
    
    public mutating func encode(_ value: UInt32) throws {
        try encode(Self.encode(value))
    }
    
    public mutating func encode(_ value: UInt64) throws {
        try encode(Self.encode(value))
    }
    
    public mutating func encode(_ value: Float) throws {
        try encode(Self.encode(value))
    }
    
    public mutating func encode(_ value: Double) throws {
        try encode(Self.encode(value))
    }
    
    public mutating func encode(_ value: String) throws {
        try encode(Self.encode(value))
    }
}
