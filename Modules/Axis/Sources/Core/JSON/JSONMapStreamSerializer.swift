// This file has been modified from its original project Swift-JsonSerializer

public final class JSONMapStreamSerializer : MapStreamSerializer {
    let stream: Stream

    public init(stream: Stream) {
        self.stream = stream
    }

    public func serialize(_ map: Map) throws {
        try stream.write(serializeToString(map))
        try stream.flush()
    }

    public func serializeToString(_ map: Map) throws -> String {
        switch map {
        case .null: return "null"
        case .bool(let bool): return String(bool)
        case .double(let number): return String(number)
        case .int(let number): return String(number)
        case .string(let string): return escape(string)
        case .array(let array): return try serialize(array)
        case .dictionary(let dictionary): return try serialize(dictionary)
        default: throw MapError.incompatibleType
        }
    }

    private func serialize(_ array: [Map]) throws -> String {
        var string = "["

        for index in 0 ..< array.count {
            string += try serializeToString(array[index])

            if index != array.count - 1 {
                string += ","
            }
        }

        return string + "]"
    }

    private func serialize(_ dictionary: [String: Map]) throws -> String {
        var string = "{"
        var index = 0

        for (key, value) in dictionary {
            string += try escape(key) + ":" + serializeToString(value)

            if index != dictionary.count - 1 {
                string += ","
            }

            index += 1
        }

        return string + "}"
    }
}
