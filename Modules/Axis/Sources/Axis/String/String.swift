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

    public func split(separator: Character, maxSplits: Int = .max, omittingEmptySubsequences: Bool = true) -> [String] {
        return characters.split(separator: separator, maxSplits: maxSplits, omittingEmptySubsequences: omittingEmptySubsequences).map(String.init)
    }

    public func trim() -> String {
        return trim(Characters.whitespaceAndNewline)
    }

    public func trim(_ characters: Characters) -> String {
        return trimLeft(characters).trimRight(characters)
    }

    public func trimLeft(_ characterSet: Characters) -> String {
        var start = 0

        for (index, character) in characters.enumerated() {
            if !characterSet.contains(character: character) {
                start = index
                break
            }
        }

        return self[index(startIndex, offsetBy: start) ..< endIndex]
    }

    public func trimRight(_ characterSet: Characters) -> String {
        var end = 0

        for (index, character) in characters.reversed().enumerated() {
            if !characterSet.contains(character: character) {
                end = index
                break
            }
        }

        return self[startIndex ..< index(endIndex, offsetBy: -end)]
    }

	public func index(of string: String) -> String.CharacterView.Index? {
        return characters.index(of: string.characters)
	}

	public func contains(substring: String) -> Bool {
        return index(of: substring) != nil
	}
}


extension String {
    public func has(prefix: String) -> Bool {
        return prefix == String(self.characters.prefix(prefix.characters.count))
    }

    public func has(suffix: String) -> Bool {
        return suffix == String(self.characters.suffix(suffix.characters.count))
    }
}


extension String.CharacterView {
    func index(of sequence: String.CharacterView) -> String.CharacterView.Index? {
        let seqString = String(sequence)
        for (i, _) in enumerated() {
            // Protect against range overflow errors
            if i + sequence.count > count {
                break
            } else {
                let start = index(startIndex, offsetBy: i)
                let end = index(startIndex, offsetBy: i+sequence.count)
                if String(self[start ..< end]) == seqString {
                    return start
                }
            }
        }
        return nil
    }
}

public enum CharactersError : Error {
    case characterIsNotUTF8
}

public struct Characters : ExpressibleByArrayLiteral {
	public static let whitespaceAndNewline: Characters = [" ", "\t", "\r", "\n"]

	public static let digits: Characters = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]

    public static let uriQueryAllowed: Characters = ["!", "$", "&", "\'", "(", ")", "*", "+", ",", "-", ".", "/", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ":", ";", "=", "?", "@", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "_", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "~"
    ]


    public static let uriFragmentAllowed: Characters = ["!", "$", "&", "\'", "(", ")", "*", "+", ",", "-", ".", "/", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ":", ";", "=", "?", "@", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "_", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "~"
    ]

    public static let uriPathAllowed: Characters = ["!", "$", "&", "\'", "(", ")", "*", "+", ",", "-", ".", "/", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ":", "=", "@", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "_", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "~"]

    public static let uriHostAllowed: Characters = ["!", "$", "&", "\'", "(", ")", "*", "+", ",", "-", ".", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ":", ";", "=", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "[", "]", "_", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "~"]

    public static let uriPasswordAllowed: Characters = ["!", "$", "&", "\'", "(", ")", "*", "+", ",", "-", ".", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ";", "=", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "_", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "~"]

    public static let uriUserAllowed: Characters = ["!", "$", "&", "\'", "(", ")", "*", "+", ",", "-", ".", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ";", "=", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "_", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "~"]

	private let characters: Set<Character>

	public init(characters: Set<Character>) {
		self.characters = characters
	}

	public init(arrayLiteral elements: Character...) {
		self.init(characters: Set(elements))
	}

	public func contains(character: Character) -> Bool {
		return characters.contains(character)
	}

    public func utf8() -> Set<UTF8.CodeUnit> {
        var codeUnits: Set<UTF8.CodeUnit> = []
        for character in characters {
            let utf8 = String(character).utf8
            codeUnits.insert(utf8[utf8.startIndex])
        }
        return codeUnits
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

extension UTF8 {
    public static var whitespaceAndNewline: Set<UTF8.CodeUnit> = [32, 10, 9, 13]

    public static var digits: Set<UTF8.CodeUnit> = [51, 49, 55, 53, 57, 50, 52, 48, 56, 54]

    public static var uriQueryAllowed: Set<UTF8.CodeUnit> = [41, 106, 77, 49, 38, 74, 120, 68, 99, 102, 42, 58, 47, 59, 39, 67, 46, 50, 84, 81, 108, 95, 103, 90, 118, 78, 45, 63, 43, 116, 115, 51, 64, 110, 104, 61, 66, 73, 105, 98, 79, 107, 65, 101, 117, 40, 71, 83, 82, 87, 72, 76, 70, 88, 114, 122, 109, 44, 86, 80, 113, 111, 75, 121, 55, 100, 52, 48, 56, 33, 54, 85, 89, 97, 53, 112, 36, 57, 126, 69, 119]


    public static var uriFragmentAllowed: Set<UTF8.CodeUnit> = [41, 106, 77, 49, 38, 74, 120, 68, 99, 102, 42, 58, 47, 59, 39, 67, 46, 50, 84, 81, 108, 95, 103, 90, 118, 78, 45, 63, 43, 116, 115, 51, 64, 110, 104, 61, 66, 73, 105, 98, 79, 107, 65, 101, 117, 40, 71, 83, 82, 87, 72, 76, 70, 88, 114, 122, 109, 44, 86, 80, 113, 111, 75, 121, 55, 100, 52, 48, 56, 33, 54, 85, 89, 97, 53, 112, 36, 57, 126, 69, 119]

    public static var uriPathAllowed: Set<UTF8.CodeUnit> = [41, 106, 77, 49, 38, 74, 120, 68, 99, 102, 42, 58, 47, 39, 67, 46, 50, 84, 81, 108, 95, 103, 90, 118, 78, 45, 43, 116, 115, 51, 64, 110, 104, 73, 61, 66, 105, 98, 79, 107, 65, 101, 117, 40, 71, 83, 82, 87, 72, 76, 70, 88, 114, 122, 109, 44, 86, 80, 113, 111, 75, 121, 55, 100, 52, 48, 56, 33, 54, 85, 89, 97, 53, 112, 36, 57, 126, 69, 119]

    public static var uriHostAllowed: Set<UTF8.CodeUnit> = [91, 41, 106, 93, 77, 49, 38, 74, 120, 68, 99, 102, 42, 58, 59, 39, 67, 46, 50, 84, 108, 95, 81, 103, 90, 118, 78, 45, 43, 116, 115, 51, 110, 104, 73, 61, 66, 105, 98, 79, 107, 65, 101, 117, 40, 71, 83, 82, 87, 72, 76, 70, 88, 114, 122, 109, 44, 86, 80, 113, 111, 75, 121, 55, 100, 52, 48, 56, 33, 54, 85, 89, 97, 53, 112, 36, 57, 126, 69, 119]

    public static var uriPasswordAllowed: Set<UTF8.CodeUnit> = [41, 106, 77, 49, 38, 74, 120, 68, 99, 102, 42, 59, 39, 67, 46, 50, 84, 108, 95, 81, 103, 90, 118, 78, 45, 43, 116, 115, 51, 110, 104, 73, 61, 66, 105, 98, 79, 107, 65, 101, 117, 40, 71, 83, 82, 87, 72, 76, 70, 88, 114, 122, 109, 44, 86, 80, 113, 111, 75, 121, 55, 100, 52, 48, 56, 33, 54, 85, 89, 97, 53, 112, 36, 57, 126, 69, 119]

    public static var uriUserAllowed: Set<UTF8.CodeUnit> = [41, 106, 77, 49, 38, 74, 120, 68, 99, 102, 42, 59, 39, 67, 46, 50, 84, 108, 95, 81, 103, 90, 118, 78, 45, 43, 116, 115, 51, 110, 104, 73, 61, 66, 105, 98, 79, 107, 65, 101, 117, 40, 71, 83, 82, 87, 72, 76, 70, 88, 114, 122, 109, 44, 86, 80, 113, 111, 75, 121, 55, 100, 52, 48, 56, 33, 54, 85, 89, 97, 53, 112, 36, 57, 126, 69, 119]
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
