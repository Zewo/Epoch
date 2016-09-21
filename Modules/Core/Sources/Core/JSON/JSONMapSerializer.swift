// This file has been modified from its original project Swift-JsonSerializer

public struct JSONMapSerializer : MapSerializer {
    let ordering: Bool

    public init(ordering: Bool = false) {
        self.ordering = ordering
    }

    public func serialize(_ map: Map) throws -> Buffer {
        return try Buffer(serializeToString(map))
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

    func serialize(_ array: [Map]) throws -> String {
        var string = "["

        for index in 0 ..< array.count {
            string += try serializeToString(array[index])

            if index != array.count - 1 {
                string += ","
            }
        }

        return string + "]"
    }

    func serialize(_ dictionary: [String: Map]) throws -> String {
        var string = "{"
        var index = 0

        if ordering {
            for (key, value) in dictionary.sorted(by: {$0.0 < $1.0}) {
                string += try escape(key) + ":" + serializeToString(value)

                if index != dictionary.count - 1 {
                    string += ","
                }

                index += 1
            }
        } else {
            for (key, value) in dictionary {
                string += try escape(key) + ":" + serializeToString(value)

                if index != dictionary.count - 1 {
                    string += ","
                }

                index += 1
            }
        }

        return string + "}"
    }
}

func escape(_ source: String) -> String {
    var string = "\""

    for character in source.characters {
        if let escapedSymbol = escapeMapping[character] {
            string.append(escapedSymbol)
        } else {
            string.append(character)
        }
    }

    string.append("\"")
    return string
}
