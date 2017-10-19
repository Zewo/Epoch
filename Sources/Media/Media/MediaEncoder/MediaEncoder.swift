import Core

class MediaEncoder<Map : EncodingMedia> : Encoder {
    var stack: Stack<EncodingMedia>
    var codingPath: [CodingKey]
    var userInfo: [CodingUserInfoKey: Any]
    
    init(codingPath: [CodingKey] = [], userInfo: [CodingUserInfoKey: Any]) {
        self.stack = Stack()
        self.codingPath = codingPath
        self.userInfo = userInfo
    }
    
    var canEncodeNewElement: Bool {
        // Every time a new value gets encoded, the key it's encoded for is pushed onto the coding path (even if it's a nil key from an unkeyed container).
        // At the same time, every time a container is requested, a new value gets pushed onto the storage stack.
        // If there are more values on the storage stack than on the coding path, it means the value is requesting more than one container, which violates the precondition.
        //
        // This means that anytime something that can request a new container goes onto the stack, we MUST push a key onto the coding path.
        // Things which will not request containers do not need to have the coding path extended for them (but it doesn't matter if it is, because they will not reach here).
        return stack.count == codingPath.count
    }
    
    func assertCanRequestNewContainer() {
        guard canEncodeNewElement else {
            preconditionFailure("Attempt to encode with new container when already encoded with a container.")
        }
    }
    
    func container<Key>(keyedBy: Key.Type) -> KeyedEncodingContainer<Key> {
        assertCanRequestNewContainer()
        
        do {
            try stack.push(Map.makeKeyedContainer())
        } catch {
            fatalError("return a failure container")
        }
        
        let container = MediaKeyedEncodingContainer<Map, Key>(
            referencing: self,
            codingPath: codingPath
        )
        
        return KeyedEncodingContainer(container)
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        assertCanRequestNewContainer()
        
        do {
            try stack.push(Map.makeUnkeyedContainer())
        } catch {
            fatalError("return a failure container")
        }
        
        return MediaUnkeyedEncodingContainer<Map>(
            referencing: self,
            codingPath: codingPath
        )
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        assertCanRequestNewContainer()
        return self
    }
    
    func topLevelMap() throws -> Map {
        guard stack.count > 0 else {
            let context = EncodingError.Context(
                debugDescription: "encoder did not encode any values."
            )
            
            throw EncodingError.invalidValue(self, context)
        }
        
        guard let encoded = try stack.pop().topLevel() as? Map else {
            let context = EncodingError.Context(
                debugDescription: "Encoder did not encode to the requested type \(Map.self)."
            )
            
            throw EncodingError.invalidValue(self, context)
        }
        
        return encoded
    }
}

extension MediaEncoder {
    func box<T : Encodable>(_ value: T) throws -> EncodingMedia {
        let count = stack.count
        try value.encode(to: self)
        
        guard stack.count != count else {
            return try Map.makeKeyedContainer()
        }
        
        return stack.pop()
    }
}
