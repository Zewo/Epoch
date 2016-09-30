// This file has been modified from its original project Swift-JsonSerializer

public final class JSONMapSerializer : MapSerializer {
    private var ordering: Bool
    private var buffer: String = ""
    private var bufferSize: Int = 0
    private var body: (UnsafeBufferPointer<Byte>) throws -> Void = { _ in }

    public init() {
        self.ordering = false
    }

    public init(ordering: Bool) {
        self.ordering = ordering
    }

    public func serialize(_ map: Map, bufferSize: Int, body: (UnsafeBufferPointer<Byte>) throws -> Void) throws {
        self.bufferSize = bufferSize
        try serialize(value: map)
        try write()
    }

    private func serialize(value: Map) throws {
        switch value {
        case .null: try append(string: "null")
        case .bool(let bool): try append(string: String(bool))
        case .double(let number): try append(string: String(number))
        case .int(let number): try append(string: String(number))
        case .string(let string): try serialize(string: string)
        case .array(let array): try serialize(array: array)
        case .dictionary(let dictionary): try serialize(dictionary: dictionary)
        default: throw MapError.incompatibleType
        }
    }

    private func serialize(array: [Map]) throws {
        try append(string: "[")

        for index in 0 ..< array.count {
            try serialize(value: array[index])

            if index != array.count - 1 {
                try append(string: ",")
            }
        }

        try append(string: "]")
    }

    private func serialize(dictionary: [String: Map]) throws {
        try append(string: "{")
        var index = 0

        if ordering {
            for (key, value) in dictionary.sorted(by: {$0.0 < $1.0}) {
                try serialize(string: key)
                try append(string: ":")
                try serialize(value: value)

                if index != dictionary.count - 1 {
                    try append(string: ",")
                }

                index += 1
            }
        } else {
            for (key, value) in dictionary{
                try serialize(string: key)
                try append(string: ":")
                try serialize(value: value)

                if index != dictionary.count - 1 {
                    try append(string: ",")
                }
                
                index += 1
            }
        }


        try append(string: "}")
    }

    private func serialize(string: String) throws {
        try append(string: "\"")

        for character in string.characters {
            if let escapedSymbol = escapeMapping[character] {
                try append(string: escapedSymbol)
            } else {
                try append(character: character)
            }
        }

        try append(string: "\"")
    }

    private func append(character: Character) throws {
        buffer.append(character)

        if buffer.characters.count >= bufferSize {
            try write()
        }
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
