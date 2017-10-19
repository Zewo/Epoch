struct MediaKeyedDecodingContainer<K : CodingKey, Map : DecodingMedia> : KeyedDecodingContainerProtocol {
    typealias Key = K
    
    let decoder: MediaDecoder<Map>
    let map: DecodingMedia
    var codingPath: [CodingKey]
    
    init(referencing decoder: MediaDecoder<Map>, wrapping map: DecodingMedia) {
        self.decoder = decoder
        self.map = map
        self.codingPath = decoder.codingPath
    }
    
    var allKeys: [Key] {
        return map.allKeys(keyedBy: Key.self)
    }
    
    func contains(_ key: Key) -> Bool {
        return map.contains(key)
    }
    
    func decodeNil(forKey key: K) throws -> Bool {
        return try map.decodeNilIfPresent(forKey: key)
    }
    
    func decode<T : Decodable>(_ type: T.Type, forKey key: Key) throws -> T {
        return try map.decode(type, forKey: key)
    }
    
    func nestedContainer<NestedKey>(
        keyedBy type: NestedKey.Type,
        forKey key: Key
    ) throws -> KeyedDecodingContainer<NestedKey> {
        let container = MediaKeyedDecodingContainer<NestedKey, Map>(
            referencing: decoder,
            wrapping: try map.keyedContainer(forKey: key)
        )
        
        return KeyedDecodingContainer(container)
    }
    
    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        return MediaUnkeyedDecodingContainer(
            referencing: decoder,
            wrapping: try map.unkeyedContainer(forKey: key)
        )
    }
    
    func superDecoder() throws -> Decoder {
        return try _superDecoder(forKey: MapSuperKey.super)
    }
    
    func superDecoder(forKey key: Key) throws -> Decoder {
        return try _superDecoder(forKey: key)
    }
    
    func _superDecoder(forKey key: CodingKey) throws -> Decoder {
        guard let value = try map.decodeIfPresent(Map.self, forKey: key) else {
            var path = codingPath
            path.append(key)
            
            let context = DecodingError.Context(
                codingPath: path,
                debugDescription: "Key not found when expecting non-optional type \(Map.self) for coding key \"\(key)\""
            )
            
            throw DecodingError.keyNotFound(key, context)
        }
        
        return MediaDecoder<Map>(
            referencing: value,
            at: decoder.codingPath,
            userInfo: decoder.userInfo
        )
    }
}

