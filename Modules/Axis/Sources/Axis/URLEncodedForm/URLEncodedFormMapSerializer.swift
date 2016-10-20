enum URLEncodedFormMapSerializerError : Error {
    case invalidMap
}

public final class URLEncodedFormMapSerializer : MapSerializer {
    private var buffer: String = ""
    private var bufferSize: Int = 0
    private typealias Body = (UnsafeBufferPointer<Byte>) throws -> Void

    public init() {}

    /// Serializes input `map` into URL-encoded form using a buffer of speficied size.
    ///
    /// - parameters:
    ///   - map: The `Map` to encode/serialize.  Only `.dictionary` is supported.
    ///   - bufferSize: The size of the internal buffer to be use as intermediate storage before writing the results out to `body` closure.
    ///   - body: The closure to pass the results of the serialization to.
    public func serialize(_ map: Map, bufferSize: Int, body: Body) throws {
        self.bufferSize = bufferSize

        switch map {
        case .dictionary(let dictionary):
            for (offset: index, element: (key: key, value: map)) in dictionary.enumerated() {
                if index != 0 {
                   try append(string: "&", body: body)
                }

                try append(string: key + "=", body: body)
                let value = try map.asString(converting: true)
                try append(string: value.percentEncoded(allowing: UnicodeScalars.uriQueryAllowed.utf8), body: body)
            }
        default:
            throw URLEncodedFormMapSerializerError.invalidMap
        }

        try write(body: body)
    }

    private func append(string: String, body: Body) throws {
        buffer += string

        if buffer.unicodeScalars.count >= bufferSize {
            try write(body: body)
        }
    }

    private func write(body: Body) throws {
        try buffer.withCString {
            try $0.withMemoryRebound(to: Byte.self, capacity: buffer.utf8.count) {
                try body(UnsafeBufferPointer(start: $0, count: buffer.utf8.count))
            }
        }
        buffer = ""
    }
}
