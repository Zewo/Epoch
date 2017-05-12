import Venice

public enum ContentSerializerError : Error {
    case invalidInput
}

public protocol ContentSerializer {
    init()
    func serialize(_ map: Content, bufferSize: Int, body: (UnsafeRawBufferPointer) throws -> Void) throws
}

extension ContentSerializer {
    public static func serialize(
        _ map: Content,
        stream: WritableStream,
        bufferSize: Int = 4096,
        deadline: Deadline
    ) throws {
        let serializer = self.init()

        try serializer.serialize(map, bufferSize: bufferSize) { buffer in
            try stream.write(buffer, deadline: deadline)
        }
        
        try stream.flush(deadline: deadline)
    }
}
