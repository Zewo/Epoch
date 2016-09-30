enum URLEncodedFormMapSerializerError : Error {
    case invalidMap
}

public final class URLEncodedFormMapSerializer : MapSerializer {
    private var buffer: String = ""
    private var bufferSize: Int = 0
    private var body: (UnsafeBufferPointer<Byte>) throws -> Void = { _ in }

    public init() {}

    public func serialize(_ map: Map, bufferSize: Int, body: (UnsafeBufferPointer<Byte>) throws -> Void) throws {
        self.bufferSize = bufferSize

        switch map {
        case .dictionary(let dictionary):
            for (offset: index, element: (key: key, value: map)) in dictionary.enumerated() {
                if index != 0 {
                   try append(string: "&")
                }

                try append(string: key + "=")
                let value = try map.asString(converting: true)
                try append(string: value.percentEncoded(allowing: .uriQueryAllowed))
            }
        default:
            throw URLEncodedFormMapSerializerError.invalidMap
        }
        
        try write()
    }

    private func append(string: String) throws {
        buffer += string

        if buffer.characters.count >= bufferSize {
            try write()
        }
    }

    private func write() throws {
        try buffer.withCString {
            try $0.withMemoryRebound(to: Byte.self, capacity: buffer.utf8.count) {
                try body(UnsafeBufferPointer(start: $0, count: buffer.utf8.count))
            }
        }
        buffer = ""
    }
}
