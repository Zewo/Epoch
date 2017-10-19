final class MediaKeyedEncodingContainer<Map : EncodingMedia, K : CodingKey> : KeyedEncodingContainerProtocol {
    typealias Key = K
    let encoder: MediaEncoder<Map>
    var codingPath: [CodingKey]
    
    init(referencing encoder: MediaEncoder<Map>, codingPath: [CodingKey]) {
        self.encoder = encoder
        self.codingPath = codingPath
    }

    func encodeNil(forKey key: K) throws {
        try encoder.stack.withTop { map in
            try map.encodeNil()
        }
    }

    func encode<T : Encodable>(_ value: T, forKey key: Key) throws {
        try encoder.stack.withTop { map in
            try map.encode(encoder.box(value), forKey: key)
        }
    }
    
    func nestedContainer<NestedKey>(
        keyedBy keyType: NestedKey.Type,
        forKey key: Key
    ) -> KeyedEncodingContainer<NestedKey> {
        do {
            try encoder.stack.withTop { map in
                try map.encode(Map.makeKeyedContainer(forKey: key), forKey: key)
            }
        } catch {
            fatalError("return a failure container")
        }
        
        let container = MediaKeyedEncodingContainer<Map, NestedKey>(
            referencing: encoder,
            codingPath: codingPath
        )
        
        return KeyedEncodingContainer(container)
    }
    
    func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        do {
            try encoder.stack.withTop { map in
                try map.encode(Map.makeUnkeyedContainer(forKey: key), forKey: key)
            }
        } catch {
            fatalError("return a failure container")
        }
        
        return MediaUnkeyedEncodingContainer(
            referencing: encoder,
            codingPath: codingPath
        )
    }
    
    func superEncoder() -> Encoder {
        return MediaReferencingEncoder(referencing: encoder, at: MapSuperKey.super) { value in
            try self.encoder.stack.withTop { map in
                try map.encode(value, forKey: MapSuperKey.super)
            }
        }
    }
    
    func superEncoder(forKey key: Key) -> Encoder {
        return MediaReferencingEncoder(referencing: encoder, at: key) { value in
            try self.encoder.stack.withTop { map in
                try map.encode(value, forKey: key)
            }
        }
    }
}
