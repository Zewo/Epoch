#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

public enum StringError : Error {
    case invalidString
    case utf8EncodingFailed
}

extension String {
    // Todo: Use Swift's standard library implemenation
    // https://github.com/apple/swift/blob/7b2f91aad83a46b33c56147c224afbde8a670376/stdlib/public/core/CString.swift#L46
    // Alternative:
    //    cString.withUnsafeBufferPointer { ptr in
    //        var string = String()
    //        string.reserveCapacity(ptr.count)
    //        for i in 0..<ptr.count {
    //            string.append(UnicodeScalar((ptr.baseAddress! + i).pointee))
    //        }
    //    }
    public init(cString: UnsafePointer<Int8>, length: Int) {
        var buffer = [Int8](repeating: 0, count: length + 1)
        strncpy(&buffer, cString, length)
        self = String(cString: buffer)
    }

    public func capitalizedWord() -> String {
        return String(self.characters.prefix(1)).uppercased() + String(self.characters.dropFirst()).lowercased()
    }

    public func split(separator: UnicodeScalar, maxSplits: Int = .max, omittingEmptySubsequences: Bool = true) -> [String] {
        return unicodeScalars.split(separator: separator, maxSplits: maxSplits, omittingEmptySubsequences: omittingEmptySubsequences).map(String.init)
    }

    /// Trims whitespace from the beginning and the end of `self`.
    public func trim() -> String {
        return trim(UnicodeScalars.whitespaceAndNewline)
    }

    /// Trims given set of unicode scalars from the beginning and the end of `self`.
    public func trim(_ trimmableScalars: UnicodeScalars) -> String {
        guard let _startIndex = unicodeScalars.index(where: { !trimmableScalars.contains($0) }) else {
            return ""
        }
        guard let _endIndex = unicodeScalars.reversed().index(where: { !trimmableScalars.contains($0) })?.base else {
            return ""
        }
        return String(unicodeScalars[_startIndex..<_endIndex])
    }

    /// Trims given set of unicode scalars from the beginning of `self`.
    public func trimLeft(_ trimmableScalars: UnicodeScalars) -> String {
        guard let _startIndex = unicodeScalars.index(where: { !trimmableScalars.contains($0) }) else {
            return ""
        }
        return String(unicodeScalars[_startIndex..<unicodeScalars.endIndex])
    }

    /// Trims given set of unicode scalars from the end of `self`.
    public func trimRight(_ trimmableScalars: UnicodeScalars) -> String {
        guard let _endIndex = unicodeScalars.reversed().index(where: { !trimmableScalars.contains($0) })?.base else {
            return ""
        }
        return String(unicodeScalars[unicodeScalars.startIndex..<_endIndex])
    }

	public func index(of string: String) -> String.CharacterView.Index? {
        return characters.index(of: string.characters)
	}

	public func contains(substring: String) -> Bool {
        return unicodeScalars.index(of: substring.unicodeScalars) != nil
 	}
}

extension String {
    /// Returns `true` if `self` starts with `prefix`.
    public func has(prefix: String) -> Bool {
        guard prefix.unicodeScalars.count <= unicodeScalars.count else { return false }

        let lhs = unicodeScalars.prefix(prefix.unicodeScalars.count)
        let rhs = prefix.unicodeScalars

        return !zip(lhs, rhs).contains { $0 != $1 }
    }

    /// Returns `true` if `self` ends with `suffix`.
    public func has(suffix: String) -> Bool {
        guard suffix.unicodeScalars.count <= unicodeScalars.count else { return false }

        let lhs = unicodeScalars.suffix(suffix.unicodeScalars.count)
        let rhs = suffix.unicodeScalars

        return !zip(lhs, rhs).contains { $0 != $1 }
    }
}

extension String.CharacterView {
    func character(at i: Index, offsetBy offset: Int) -> Character? {
        var i = i
        if !formIndex(&i, offsetBy: offset, limitedBy: index(before: self.endIndex)) {
            return nil
        }
        return self[i]
    }
}

extension String {
    public init(percentEncoded: String) throws {
        let characters = percentEncoded.characters
        var decoded = ""
        var index = characters.startIndex

        while index < characters.endIndex {
            let character = characters[index]

            switch character {
            case "%":
                var encoded: [UInt8] = []

                while true {
                    guard let unicodeA = characters.character(at: index, offsetBy: 1) else {
                        throw StringError.invalidString
                    }
                    guard let unicodeB = characters.character(at: index, offsetBy: 2) else {
                        throw StringError.invalidString
                    }

                    let hexString = String(unicodeA) + String(unicodeB)

                    guard let unicodeScalar = UInt8(hexString, radix: 16) else {
                        throw StringError.invalidString
                    }

                    encoded.append(unicodeScalar)
                    characters.formIndex(&index, offsetBy: 3)

                    if index == characters.endIndex || characters[index] != "%" {
                        break
                    }
                }

                decoded += try decode(encoded: encoded)

            case "+":
                decoded.append(" ")
                characters.formIndex(after: &index)

            default:
                decoded.append(character)
                characters.formIndex(after: &index)
            }
        }

        self = decoded
    }
}

func decode(encoded: [UInt8]) throws -> String {
    var decoded = ""
    var decoder = UTF8()
    var iterator = encoded.makeIterator()
    var finished = false

    while !finished {
        switch decoder.decode(&iterator) {
        case .scalarValue(let char): decoded.unicodeScalars.append(char)
        case .emptyInput: finished = true
        case .error: throw StringError.utf8EncodingFailed
        }
    }

    return decoded
}

extension String {
    public func percentEncoded(allowing allowed: Characters) -> String {
        var string = ""
        let allowed = allowed.utf8()

        for codeUnit in self.utf8 {
            if allowed.contains(codeUnit) {
                string.append(String(UnicodeScalar(codeUnit)))
            } else {
                string.append("%")
                string.append(codeUnit.hexadecimal())
            }
        }

        return string
    }

    public func percentEncoded(allowing allowed: Set<UTF8.CodeUnit>) -> String {
        var string = ""

        for codeUnit in self.utf8 {
            if allowed.contains(codeUnit) {
                string.append(String(UnicodeScalar(codeUnit)))
            } else {
                string.append("%")
                string.append(codeUnit.hexadecimal())
            }
        }

        return string
    }
}

extension UInt8 {
    func hexadecimal() -> String {
        let hexadecimal =  String(self, radix: 16, uppercase: true)
        return (self < 16 ? "0" : "") + hexadecimal
    }
}
