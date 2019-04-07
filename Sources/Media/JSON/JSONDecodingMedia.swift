import Core
import Venice

extension JSON : DecodingMedia {
    public init(from readable: Readable, deadline: Deadline) throws {
        let parser = JSONParser()
        let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 4096, alignment: MemoryLayout<UInt8>.alignment)
        
        defer {
            buffer.deallocate()
        }
        
        while true {
            let read = try readable.read(buffer, deadline: deadline)
            
            guard !read.isEmpty else {
                break
            }
            
            guard let json = try parser.parse(read) else {
                continue
            }
            
            self = json
            return
        }
        
        self = try parser.finish()
    }
    
    public func keyCount() -> Int? {
        if case let .object(object) = self {
            return object.keys.count
        }
        
        if case let .array(array) = self {
            return array.count
        }
        
        return nil
    }
    
    public func allKeys<Key>(keyedBy: Key.Type) -> [Key] where Key : CodingKey {
        if case let .object(object) = self {
            return object.keys.compactMap({ Key(stringValue: $0) })
        }
        
        if case let .array(array) = self {
            return array.indices.compactMap({ Key(intValue: $0) })
        }
        
        return []
    }
    
    public func contains<Key>(_ key: Key) -> Bool where Key : CodingKey {
        guard let map = try? decodeIfPresent(type(of: self), forKey: key) else {
            return false
        }
        
        return map != nil
    }
    
    public func keyedContainer() throws -> DecodingMedia {
        guard isObject else {
            throw DecodingError.typeMismatch(type(of: self), DecodingError.Context())
        }
        
        return self
    }
    
    public func unkeyedContainer() throws -> DecodingMedia {
        guard isArray else {
            throw DecodingError.typeMismatch(type(of: self), DecodingError.Context())
        }
        
        return self
    }
    
    public func singleValueContainer() throws -> DecodingMedia {
        if isObject {
            throw DecodingError.typeMismatch(type(of: self), DecodingError.Context())
        }
        
        if isArray {
            throw DecodingError.typeMismatch(type(of: self), DecodingError.Context())
        }
        
        return self
    }
    
    public func decode(_ type: DecodingMedia.Type, forKey key: CodingKey) throws -> DecodingMedia {
        if let index = key.intValue {
            guard case let .array(array) = self else {
                throw DecodingError.typeMismatch(
                    [JSON].self,
                    DecodingError.Context(codingPath: [key])
                )
            }
            
            guard array.indices.contains(index) else {
                throw DecodingError.valueNotFound(
                    JSON.self,
                    DecodingError.Context(codingPath: [key])
                )
            }
            
            return array[index]
        } else {
            guard case let .object(object) = self else {
                throw DecodingError.typeMismatch(
                    [String: JSON].self,
                    DecodingError.Context(codingPath: [key])
                )
            }
            
            guard let newValue = object[key.stringValue] else {
                throw DecodingError.valueNotFound(
                    JSON.self,
                    DecodingError.Context(codingPath: [key])
                )
            }
            
            return newValue
        }
    }
    
    public func decodeIfPresent(
        _ type: DecodingMedia.Type,
        forKey key: CodingKey
    ) throws -> DecodingMedia? {
        if let index = key.intValue {
            guard case let .array(array) = self else {
                throw DecodingError.typeMismatch(
                    [JSON].self,
                    DecodingError.Context(codingPath: [key])
                )
            }
            
            guard array.indices.contains(index) else {
                throw DecodingError.valueNotFound(
                    JSON.self,
                    DecodingError.Context(codingPath: [key])
                )
            }
            
            return array[index]

        } else {
            guard case let .object(object) = self else {
                throw DecodingError.typeMismatch(
                    [String: JSON].self,
                    DecodingError.Context(codingPath: [key])
                )
            }
            
            guard let newValue = object[key.stringValue] else {
                throw DecodingError.valueNotFound(
                    JSON.self,
                    DecodingError.Context(codingPath: [key])
                )
            }
            
            return newValue

        }
    }
    
    public func decodeNil() -> Bool {
        return isNull
    }
    
    public func decode(_ type: Bool.Type) throws -> Bool {
        if case .null = self {
            throw DecodingError.valueNotFound(
                Bool.self,
                DecodingError.Context()
            )
        }
        
        guard case let .bool(bool) = self else {
            throw DecodingError.typeMismatch(
                Bool.self,
                DecodingError.Context()
            )
        }
        
        return bool
    }
    
    public func decode(_ type: Int.Type) throws -> Int {
        if case .null = self {
            throw DecodingError.valueNotFound(
                Int.self,
                DecodingError.Context()
            )
        }
        
        if case let .int(int) = self {
            return int
        }
        
        if case let .double(double) = self, let int = Int(exactly: double) {
            return int
        }
        
        throw DecodingError.typeMismatch(
            Int.self,
            DecodingError.Context()
        )
    }
    
    public func decode(_ type: Int8.Type) throws -> Int8 {
        if case .null = self {
            throw DecodingError.valueNotFound(
                Int8.self,
                DecodingError.Context()
            )
        }
        
        if case let .int(int) = self, let int8 = Int8(exactly: int) {
            return int8
        }
        
        if case let .double(double) = self, let int8 = Int8(exactly: double) {
            return int8
        }
        
        throw DecodingError.typeMismatch(
            Int8.self,
            DecodingError.Context()
        )
    }
    
    public func decode(_ type: Int16.Type) throws -> Int16 {
        if case .null = self {
            throw DecodingError.valueNotFound(
                Int16.self,
                DecodingError.Context()
            )
        }
        
        if case let .int(int) = self, let int16 = Int16(exactly: int) {
            return int16
        }
        
        if case let .double(double) = self, let int16 = Int16(exactly: double) {
            return int16
        }
        
        throw DecodingError.typeMismatch(
            Int16.self,
            DecodingError.Context()
        )
    }
    
    public func decode(_ type: Int32.Type) throws -> Int32 {
        if case .null = self {
            throw DecodingError.valueNotFound(
                Int32.self,
                DecodingError.Context()
            )
        }
        
        if case let .int(int) = self, let int32 = Int32(exactly: int) {
            return int32
        }
        
        if case let .double(double) = self, let int32 = Int32(exactly: double) {
            return int32
        }
        
        throw DecodingError.typeMismatch(
            Int32.self,
            DecodingError.Context()
        )
    }
    
    public func decode(_ type: Int64.Type) throws -> Int64 {
        if case .null = self {
            throw DecodingError.valueNotFound(
                Int64.self,
                DecodingError.Context()
            )
        }
        
        if case let .int(int) = self, let int64 = Int64(exactly: int) {
            return int64
        }
        
        if case let .double(double) = self, let int64 = Int64(exactly: double) {
            return int64
        }
        
        throw DecodingError.typeMismatch(
            Int64.self,
            DecodingError.Context()
        )
    }
    
    public func decode(_ type: UInt.Type) throws -> UInt {
        if case .null = self {
            throw DecodingError.valueNotFound(
                UInt.self,
                DecodingError.Context()
            )
        }
        
        if case let .int(int) = self, let uint = UInt(exactly: int) {
            return uint
        }
        
        if case let .double(double) = self, let uint = UInt(exactly: double) {
            return uint
        }
        
        throw DecodingError.typeMismatch(
            UInt.self,
            DecodingError.Context()
        )
    }
    
    public func decode(_ type: UInt8.Type) throws -> UInt8 {
        if case .null = self {
            throw DecodingError.valueNotFound(
                UInt8.self,
                DecodingError.Context()
            )
        }
        
        if case let .int(int) = self, let uint8 = UInt8(exactly: int) {
            return uint8
        }

        if case let .double(double) = self, let uint8 = UInt8(exactly: double) {
            return uint8
        }
        
        throw DecodingError.typeMismatch(
            UInt8.self,
            DecodingError.Context()
        )
    }
    
    public func decode(_ type: UInt16.Type) throws -> UInt16 {
        if case .null = self {
            throw DecodingError.valueNotFound(
                UInt16.self,
                DecodingError.Context()
            )
        }
        
        if case let .int(int) = self, let uint16 = UInt16(exactly: int) {
            return uint16
        }
        
        if case let .double(double) = self, let uint16 = UInt16(exactly: double) {
            return uint16
        }
        
        throw DecodingError.typeMismatch(
            UInt16.self,
            DecodingError.Context()
        )
    }
    
    public func decode(_ type: UInt32.Type) throws -> UInt32 {
        if case .null = self {
            throw DecodingError.valueNotFound(
                UInt32.self,
                DecodingError.Context()
            )
        }
        
        if case let .int(int) = self, let uint32 = UInt32(exactly: int) {
            return uint32
        }
        
        if case let .double(double) = self, let uint32 = UInt32(exactly: double) {
            return uint32
        }
        
        throw DecodingError.typeMismatch(
            UInt32.self,
            DecodingError.Context()
        )
    }
    
    public func decode(_ type: UInt64.Type) throws -> UInt64 {
        if case .null = self {
            throw DecodingError.valueNotFound(
                UInt64.self,
                DecodingError.Context()
            )
        }
        
        if case let .int(int) = self, let uint64 = UInt64(exactly: int) {
            return uint64
        }
        
        if case let .double(double) = self, let uint64 = UInt64(exactly: double) {
            return uint64
        }
        
        throw DecodingError.typeMismatch(
            UInt64.self,
            DecodingError.Context()
        )
    }
    
    public func decode(_ type: Float.Type) throws -> Float {
        if case .null = self {
            throw DecodingError.valueNotFound(
                Float.self,
                DecodingError.Context()
            )
        }
        
        if case let .int(int) = self, let float = Float(exactly: int) {
            return float
        }
        
        if case let .double(double) = self, let float = Float(exactly: double) {
            return float
        }
        
        throw DecodingError.typeMismatch(
            Float.self,
            DecodingError.Context()
        )
    }
    
    public func decode(_ type: Double.Type) throws -> Double {
        if case .null = self {
            throw DecodingError.valueNotFound(
                Double.self,
                DecodingError.Context()
            )
        }
        
        if case let .int(int) = self, let double = Double(exactly: int) {
            return double
        }
        
        if case let .double(double) = self {
            return double
        }
        
        throw DecodingError.typeMismatch(
            Double.self,
            DecodingError.Context()
        )
    }
    
    public func decode(_ type: String.Type) throws -> String {
        if case .null = self {
            throw DecodingError.valueNotFound(
                String.self,
                DecodingError.Context()
            )
        }
        
        guard case let .string(string) = self else {
            throw DecodingError.typeMismatch(
                String.self,
                DecodingError.Context()
            )
        }
        
        return string
    }
}
