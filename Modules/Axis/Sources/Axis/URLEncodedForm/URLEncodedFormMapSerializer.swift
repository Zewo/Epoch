enum URLEncodedFormMapSerializerError : Error {
    case invalidMap
}

public final class URLEncodedFormMapSerializer : MapSerializer {
    private var buffer: String = ""
    private var bufferSize: Int = 0
    private typealias Body = (UnsafeBufferPointer<Byte>) throws -> Void

    public init() {}

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
                try append(string: value.percentEncoded(allowing: .uriQueryAllowed), body: body)
            }
        default:
            throw URLEncodedFormMapSerializerError.invalidMap
        }

        try write(body: body)
    }

    private func append(string: String, body: Body) throws {
        buffer += string

        if buffer.characters.count >= bufferSize {
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
