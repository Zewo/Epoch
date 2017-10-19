struct MediaUnkeyedDecodingContainer<Map : DecodingMedia> : UnkeyedDecodingContainer {
    let decoder: MediaDecoder<Map>
    let map: DecodingMedia
    var codingPath: [CodingKey]
    var currentIndex: Int
    
    init(referencing decoder: MediaDecoder<Map>, wrapping map: DecodingMedia) {
        self.decoder = decoder
        self.map = map
        self.codingPath = decoder.codingPath
        self.currentIndex = 0
    }
    
    var count: Int? {
        return map.keyCount()
    }
    
    var isAtEnd: Bool {
        guard let count = map.keyCount() else {
            return true
        }
        
        return currentIndex >= count
    }
    
    mutating func decodeNil() throws -> Bool {
        try self.assertNotAtEnd(
            forType: Decoder.self,
            message: "value not found"
        )
        
        guard map.decodeNil() else { return false }
        
        currentIndex += 1
        
        return true
    }

    
    mutating func decode(_ type: Int.Type) throws -> Int {
        return try decode(type)
    }
    
    mutating func decode(_ type: Int8.Type) throws -> Int8 {
        return try decode(type)
    }
    
    mutating func decode(_ type: Int16.Type) throws -> Int16 {
        return try decode(type)
    }
    
    mutating func decode(_ type: Int32.Type) throws -> Int32 {
        return try decode(type)
    }
    
    mutating func decode(_ type: Int64.Type) throws -> Int64 {
        return try decode(type)
    }
    
    mutating func decode(_ type: UInt.Type) throws -> UInt {
        return try decode(type)
    }
    
    mutating func decode(_ type: UInt8.Type) throws -> UInt8 {
        return try decode(type)
    }
    
    mutating func decode(_ type: UInt16.Type) throws -> UInt16 {
        return try decode(type)
    }
    
    mutating func decode(_ type: UInt32.Type) throws -> UInt32 {
        return try decode(type)
    }
    
    mutating func decode(_ type: UInt64.Type) throws -> UInt64 {
        return try decode(type)
    }
    
    mutating func decode(_ type: Float.Type) throws -> Float {
        return try decode(type)
    }
    
    mutating func decode(_ type: Double.Type) throws -> Double {
        return try decode(type)
    }
    
    mutating func decode(_ type: String.Type) throws -> String {
        return try decode(type)
    }
    
    mutating func decode<T : Decodable>(_ type: T.Type) throws -> T {
        try self.assertNotAtEnd(
            forType: Decoder.self,
            message: "value not found"
        )
        
        guard let value = try map.decodeIfPresent(Map.self, forKey: currentIndex) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath))
        }
        
        let decoded: T = try value.decode(type)
        currentIndex += 1
        return decoded
    }
    
    mutating func nestedContainer<NestedKey>(
        keyedBy type: NestedKey.Type
        ) throws -> KeyedDecodingContainer<NestedKey> {
        try assertNotAtEnd(
            forType: KeyedDecodingContainer<NestedKey>.self,
            message: "Cannot get nested keyed container -- unkeyed container is at end."
        )
        
        let container = MediaKeyedDecodingContainer<NestedKey, Map>(
            referencing: decoder,
            wrapping: try map.keyedContainer(forKey: currentIndex)
        )
        
        currentIndex += 1
        return KeyedDecodingContainer(container)
    }
    
    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        try assertNotAtEnd(
            forType: UnkeyedDecodingContainer.self,
            message: "Cannot get nested unkeyed container -- unkeyed container is at end."
        )
        
        let container = MediaUnkeyedDecodingContainer(
            referencing: decoder,
            wrapping: try map.unkeyedContainer(forKey: currentIndex)
        )
        
        currentIndex += 1
        return container
    }
    
    mutating func superDecoder() throws -> Decoder {
        try assertNotAtEnd(
            forType: Decoder.self,
            message: "Cannot get superDecoder() -- unkeyed container is at end."
        )
        
        guard let value = try map.decodeIfPresent(Map.self, forKey: currentIndex) else {
            let context = DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Cannot get superDecoder() -- value not found for key \(currentIndex)."
            )
            
            throw DecodingError.keyNotFound(currentIndex, context)
        }
        
        currentIndex += 1
        
        return MediaDecoder<Map>(
            referencing: value,
            at: decoder.codingPath,
            userInfo: decoder.userInfo
        )
    }
    
    private func assertNotAtEnd(forType type: Any.Type, message: String) throws {
        guard !isAtEnd else {
            let context = DecodingError.Context(
                codingPath: codingPath,
                debugDescription: message
            )
            
            throw DecodingError.valueNotFound(type, context)
        }
    }
}
