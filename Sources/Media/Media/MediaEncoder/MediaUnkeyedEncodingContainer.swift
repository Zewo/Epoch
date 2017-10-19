final class MediaUnkeyedEncodingContainer<Map : EncodingMedia> : UnkeyedEncodingContainer {
    var count: Int
    
    let encoder: MediaEncoder<Map>
    var codingPath: [CodingKey]
    
    init(referencing encoder: MediaEncoder<Map>, codingPath: [CodingKey]) {
        self.encoder = encoder
        self.codingPath = codingPath
        self.count = 0
    }
    
    func encodeNil() throws {
        try encoder.stack.withTop { map in
            try map.encodeNil()
        }
    }
    
    func encode<T : Encodable>(_ value: T) throws {
        try encoder.stack.withTop { map in
            try map.encode(encoder.box(value))
        }
    }
    
    func nestedContainer<NestedKey>(
        keyedBy keyType: NestedKey.Type
        ) -> KeyedEncodingContainer<NestedKey> {
        do {
            try encoder.stack.withTop { map in
                try map.encode(Map.makeKeyedContainer())
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
    
    func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        do {
            try encoder.stack.withTop { map in
                try map.encode(Map.makeUnkeyedContainer())
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
        return MediaReferencingEncoder(referencing: encoder) { value in
            try self.encoder.stack.withTop { map in
                try map.encode(value)
            }
        }
    }
}
