public final class JSONMapSerializer : MapSerializer {
    private var ordering: Bool
    private var buffer: String = ""
    private var bufferSize: Int = 0
    private typealias Body = (UnsafeBufferPointer<Byte>) throws -> Void

    public init() {
        self.ordering = false
    }

    public init(ordering: Bool) {
        self.ordering = ordering
    }

    public func serialize(_ map: Map, bufferSize: Int = 4096, body: Body) throws {
        self.bufferSize = bufferSize
        try serialize(value: map, body: body)
        try write(body: body)
    }

    private func serialize(value: Map, body: Body) throws {
        switch value {
        case .null: try append(string: "null", body: body)
        case .bool(let bool): try append(string: String(bool), body: body)
        case .double(let number): try append(string: String(number), body: body)
        case .int(let number): try append(string: String(number), body: body)
        case .string(let string): try serialize(string: string, body: body)
        case .array(let array): try serialize(array: array, body: body)
        case .dictionary(let dictionary): try serialize(dictionary: dictionary, body: body)
        default: throw MapError.incompatibleType
        }
    }

    private func serialize(array: [Map], body: Body) throws {
        try append(string: "[", body: body)

        for index in 0 ..< array.count {
            try serialize(value: array[index], body: body)

            if index != array.count - 1 {
                try append(string: ",", body: body)
            }
        }

        try append(string: "]", body: body)
    }

    private func serialize(dictionary: [String: Map], body: Body) throws {
        try append(string: "{", body: body)
        var index = 0

        if ordering {
            for (key, value) in dictionary.sorted(by: {$0.0 < $1.0}) {
                try serialize(string: key, body: body)
                try append(string: ":", body: body)
                try serialize(value: value, body: body)

                if index != dictionary.count - 1 {
                    try append(string: ",", body: body)
                }

                index += 1
            }
        } else {
            for (key, value) in dictionary{
                try serialize(string: key, body: body)
                try append(string: ":", body: body)
                try serialize(value: value, body: body)

                if index != dictionary.count - 1 {
                    try append(string: ",", body: body)
                }
                
                index += 1
            }
        }


        try append(string: "}", body: body)
    }

    private func serialize(string: String, body: Body) throws {
        try append(string: "\"", body: body)

        for character in string.characters {
            if let escapedSymbol = escapeMapping[character] {
                try append(string: escapedSymbol, body: body)
            } else {
                try append(character: character, body: body)
            }
        }

        try append(string: "\"", body: body)
    }

    private func append(character: Character, body: Body) throws {
        buffer.append(character)

        if buffer.characters.count >= bufferSize {
            try write(body: body)
        }
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

fileprivate let escapeMapping: [Character: String] = [
    "\r": "\\r",
    "\n": "\\n",
    "\t": "\\t",
    "\\": "\\\\",
    "\"": "\\\"",

    "\u{2028}": "\\u2028",
    "\u{2029}": "\\u2029",

    "\r\n": "\\r\\n"
]
