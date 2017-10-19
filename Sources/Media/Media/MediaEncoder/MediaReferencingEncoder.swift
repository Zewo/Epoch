class MediaReferencingEncoder<Map : EncodingMedia> : MediaEncoder<Map> {
    let encoder: MediaEncoder<Map>
    let write: (EncodingMedia) throws -> Void
    
    init(
        referencing encoder: MediaEncoder<Map>,
        at key: CodingKey,
        write: @escaping (EncodingMedia) throws -> Void
    ) {
        self.encoder = encoder
        self.write = write
        super.init(codingPath: encoder.codingPath, userInfo: encoder.userInfo)
        self.codingPath.append(key)
    }
    
    init(
        referencing encoder: MediaEncoder<Map>,
        write: @escaping (EncodingMedia) throws -> Void
        ) {
        self.encoder = encoder
        self.write = write
        super.init(codingPath: encoder.codingPath, userInfo: encoder.userInfo)
    }
    
    override var canEncodeNewElement: Bool {
        // With a regular encoder, the storage and coding path grow together.
        // A referencing encoder, however, inherits its parents coding path, as well as the key it was created for.
        // We have to take this into account.
        return stack.count == codingPath.count - encoder.codingPath.count - 1
    }
    
    deinit {
        let value: EncodingMedia
        
        switch stack.count {
        case 0: value = try! Map.makeKeyedContainer()
        case 1: value = stack.pop()
        default: fatalError("Referencing encoder deallocated with multiple containers on stack.")
        }
        
        do {
            try write(value)
        } catch {
            fatalError("Could not write to container.")
        }
    }
}
