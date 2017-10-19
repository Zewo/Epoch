import Core

class MediaDecoder<Map : DecodingMedia> : Decoder {
    var codingPath: [CodingKey]
    var userInfo: [CodingUserInfoKey: Any]
    var map: DecodingMedia
    
    init(
        referencing map: DecodingMedia,
        at codingPath: [CodingKey] = [],
        userInfo: [CodingUserInfoKey: Any]
        ) {
        self.map = map
        self.codingPath = codingPath
        self.userInfo = userInfo
    }
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
        let container = MediaKeyedDecodingContainer<Key, Map>(
            referencing: self,
            wrapping: try map.keyedContainer()
        )
        
        return KeyedDecodingContainer(container)
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        return MediaUnkeyedDecodingContainer<Map>(
            referencing: self,
            wrapping: try map.unkeyedContainer()
        )
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        return MediaSingleValueDecodingContainer<Map>(
            codingPath: codingPath,
            referencing: self,
            wrapping: try map.singleValueContainer()
        )
    }
}
