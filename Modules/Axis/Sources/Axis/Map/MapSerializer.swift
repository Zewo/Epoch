public enum MapSerializerError : Error {
    case invalidInput
}

public protocol MapSerializer {
    init()
    func serialize(_ map: Map, bufferSize: Int, body: (UnsafeBufferPointer<Byte>) throws -> Void) throws
    static func serialize(_ map: Map, bufferSize: Int) throws -> Buffer
    static func serialize(_ map: Map, stream: OutputStream, bufferSize: Int, deadline: Double) throws
}

extension MapSerializer {
    public static func serialize(_ map: Map, bufferSize: Int = 4096) throws -> Buffer {
        let serializer = self.init()
        var buffer = Buffer()

        try serializer.serialize(map, bufferSize: bufferSize) { writeBuffer in
            buffer.append(writeBuffer)
        }

        guard !buffer.isEmpty else {
            throw MapSerializerError.invalidInput
        }

        return buffer
    }

    public static func serialize(_ map: Map, stream: OutputStream, bufferSize: Int = 4096, deadline: Double) throws {
        let serializer = self.init()

        try serializer.serialize(map, bufferSize: bufferSize) { buffer in
            try stream.write(buffer, deadline: deadline)
        }
        try stream.flush(deadline: deadline)
    }
}
