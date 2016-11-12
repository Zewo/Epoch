extension Map : CustomStringConvertible {
    public var description: String {
        let escapeMapping: [UnicodeScalar: String.UnicodeScalarView] = [
            "\r": "\\r",
            "\n": "\\n",
            "\t": "\\t",
            "\\": "\\\\",
            "\"": "\\\"",

            "\u{2028}": "\\u2028",
            "\u{2029}": "\\u2029",
            ]

        func escape(_ source: String) -> String {
            var string: String.UnicodeScalarView = "\""

            for scalar in source.unicodeScalars {
                if let escaped = escapeMapping[scalar] {
                    string.append(contentsOf: escaped)
                } else {
                    string.append(scalar)
                }
            }

            string.append("\"")

            return String(string)
        }

        func serialize(map: Map) -> String {
            switch map {
            case .null: return "null"
            case .bool(let bool): return String(bool)
            case .double(let number): return String(number)
            case .int(let number): return String(number)
            case .string(let string): return escape(string)
            case .buffer(let buffer): return "0x" + buffer.hexadecimalString()
            case .array(let array): return serialize(array: array)
            case .dictionary(let dictionary): return serialize(dictionary: dictionary)
            }
        }

        func serialize(array: [Map]) -> String {
            var string = "["

            for index in 0 ..< array.count {
                string += serialize(map: array[index])

                if index != array.count - 1 {
                    string += ","
                }
            }

            return string + "]"
        }

        func serialize(dictionary: [String: Map]) -> String {
            var string = "{"
            var index = 0

            for (key, value) in dictionary.sorted(by: {$0.0 < $1.0}) {
                string += escape(key) + ":" + serialize(map: value)

                if index != dictionary.count - 1 {
                    string += ","
                }

                index += 1
            }

            return string + "}"
        }

        return serialize(map: self)
    }
}
