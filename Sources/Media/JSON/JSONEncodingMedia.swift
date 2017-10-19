import Core
import Venice

extension JSON : EncodingMedia {
    public func encode(to writable: Writable, deadline: Deadline) throws {
        let serializer = JSONSerializer()
        
        try serializer.serialize(self) { buffer in
            try writable.write(buffer, deadline: deadline)
        }
    }
    
    public func topLevel() throws -> EncodingMedia {
        if isObject {
            return self
        }
        
        if isArray {
            return self
        }
        
        throw EncodingError.invalidValue(self, EncodingError.Context())
    }
    
    public static func makeKeyedContainer() throws -> EncodingMedia {
        return JSON.object([:])
    }
    
    public static func makeUnkeyedContainer() throws -> EncodingMedia {
        return JSON.array([])
    }
    
    public mutating func encode(_ value: EncodingMedia, forKey key: CodingKey) throws {
        guard case var .object(object) = self else {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [key]))
        }
        
        guard let json = value as? JSON else {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [key]))
        }
        
        object[key.stringValue] = json
        self = .object(object)
    }
    
    public mutating func encode(_ value: EncodingMedia) throws {
        guard case var .array(array) = self else {
            throw EncodingError.invalidValue(value, EncodingError.Context())
        }
        
        guard let json = value as? JSON else {
            throw EncodingError.invalidValue(value, EncodingError.Context())
        }
        
        array.append(json)
        self = .array(array)
    }

    public mutating func encodeNil() throws {
        guard case var .array(array) = self else {
            throw EncodingError.invalidValue(JSON.null, EncodingError.Context())
        }
        
        array.append(JSON.null)
        self = .array(array)
    }
    
    public mutating func encodeNil(forKey key: CodingKey) throws {
        guard case var .object(object) = self else {
            throw EncodingError.invalidValue(JSON.null, EncodingError.Context())
        }
        
        object[key.stringValue] = JSON.null
        self = .object(object)
    }

    public static func encodeNil() throws -> EncodingMedia {
        return JSON.null
    }
    
    public static func encode(_ value: Bool) throws -> EncodingMedia {
        return JSON.bool(value)
    }
    
    public static func encode(_ value: Int) throws -> EncodingMedia {
        return JSON.int(value)
    }
    
    public static func encode(_ value: Int8) throws -> EncodingMedia {
        guard let int = Int(exactly: value) else {
            throw EncodingError.invalidValue(value, EncodingError.Context())
        }
        
        return JSON.int(int)
    }
    
    public static func encode(_ value: Int16) throws -> EncodingMedia {
        guard let int = Int(exactly: value) else {
            throw EncodingError.invalidValue(value, EncodingError.Context())
        }
        
        return JSON.int(int)
    }
    
    public static func encode(_ value: Int32) throws -> EncodingMedia {
        guard let int = Int(exactly: value) else {
            throw EncodingError.invalidValue(value, EncodingError.Context())
        }
        
        return JSON.int(int)
    }
    
    public static func encode(_ value: Int64) throws -> EncodingMedia {
        guard let int = Int(exactly: value) else {
            throw EncodingError.invalidValue(value, EncodingError.Context())
        }
        
        return JSON.int(int)
    }
    
    public static func encode(_ value: UInt) throws -> EncodingMedia {
        guard let int = Int(exactly: value) else {
            throw EncodingError.invalidValue(value, EncodingError.Context())
        }
        
        return JSON.int(int)
    }
    
    public static func encode(_ value: UInt8) throws -> EncodingMedia {
        guard let int = Int(exactly: value) else {
            throw EncodingError.invalidValue(value, EncodingError.Context())
        }
        
        return JSON.int(int)
    }
    
    public static func encode(_ value: UInt16) throws -> EncodingMedia {
        guard let int = Int(exactly: value) else {
            throw EncodingError.invalidValue(value, EncodingError.Context())
        }
        
        return JSON.int(int)
    }
    
    public static func encode(_ value: UInt32) throws -> EncodingMedia {
        guard let int = Int(exactly: value) else {
            throw EncodingError.invalidValue(value, EncodingError.Context())
        }
        
        return JSON.int(int)
    }
    
    public static func encode(_ value: UInt64) throws -> EncodingMedia {
        guard let int = Int(exactly: value) else {
            throw EncodingError.invalidValue(value, EncodingError.Context())
        }
        
        return JSON.int(int)
    }
    
    public static func encode(_ value: Float) throws -> EncodingMedia {
        guard let double = Double(exactly: value) else {
            throw EncodingError.invalidValue(value, EncodingError.Context())
        }
        
        return JSON.double(double)
    }
    
    public static func encode(_ value: Double) throws -> EncodingMedia {
        return JSON.double(value)
    }
    
    public static func encode(_ value: String) throws -> EncodingMedia {
        return JSON.string(value)
    }
}
