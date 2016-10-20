public struct UnicodeScalars : ExpressibleByArrayLiteral, Sequence {
    public static let whitespaceAndNewline: UnicodeScalars = [" ", "\t", "\r", "\n"]

    public static let digits: UnicodeScalars = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]

    public static let uriQueryAllowed: UnicodeScalars = [
        "!", "$", "&", "\'", "(", ")", "*", "+", ",", "-", ".", "/", "0", "1", "2", "3", "4", "5",
        "6", "7", "8", "9", ":", ";", "=", "?", "@", "A", "B", "C", "D", "E", "F", "G", "H", "I",
        "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "_",
        "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r",
        "s", "t", "u", "v", "w", "x", "y", "z", "~"
    ]

    public static let uriFragmentAllowed: UnicodeScalars = [
        "!", "$", "&", "\'", "(", ")", "*", "+", ",", "-", ".", "/", "0", "1", "2", "3", "4", "5",
        "6", "7", "8", "9", ":", ";", "=", "?", "@", "A", "B", "C", "D", "E", "F", "G", "H", "I",
        "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "_",
        "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r",
        "s", "t", "u", "v", "w", "x", "y", "z", "~"
    ]

    public static let uriPathAllowed: UnicodeScalars = [
        "!", "$", "&", "\'", "(", ")", "*", "+", ",", "-", ".", "/", "0", "1", "2", "3", "4", "5",
        "6", "7", "8", "9", ":", "=", "@", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K",
        "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "_", "a", "b",
        "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t",
        "u", "v", "w", "x", "y", "z", "~"
    ]

    public static let uriHostAllowed: UnicodeScalars = [
        "!", "$", "&", "\'", "(", ")", "*", "+", ",", "-", ".", "0", "1", "2", "3", "4", "5", "6",
        "7", "8", "9", ":", ";", "=", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L",
        "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "[", "]", "_", "a",
        "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s",
        "t", "u", "v", "w", "x", "y", "z", "~"
    ]

    public static let uriPasswordAllowed: UnicodeScalars = [
        "!", "$", "&", "\'", "(", ")", "*", "+", ",", "-", ".", "0", "1", "2", "3", "4", "5", "6",
        "7", "8", "9", ";", "=", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
        "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "_", "a", "b", "c", "d",
        "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v",
        "w", "x", "y", "z", "~"
    ]

    public static let uriUserAllowed: UnicodeScalars = [
        "!", "$", "&", "\'", "(", ")", "*", "+", ",", "-", ".", "0", "1", "2", "3", "4", "5", "6",
        "7", "8", "9", ";", "=", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
        "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "_", "a", "b", "c", "d",
        "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v",
        "w", "x", "y", "z", "~"
    ]

    private let scalars: Set<UnicodeScalar>
    public let utf8: Set<UTF8.CodeUnit>

    public init(scalars: Set<UnicodeScalar>) {
        var _utf8: Set<UTF8.CodeUnit> = []

        for scalar in scalars {
            UTF8.encode(scalar) {
                _utf8.insert($0)
            }
        }

        self.scalars = scalars
        self.utf8 = _utf8
    }

    public init(arrayLiteral elements: UnicodeScalar...) {
        self.init(scalars: Set(elements))
    }

    public func contains(_ scalar: UnicodeScalar) -> Bool {
        return scalars.contains(scalar)
    }

    public func makeIterator() -> AnyIterator<UnicodeScalar> {
        return AnyIterator(scalars.makeIterator())
    }
}
