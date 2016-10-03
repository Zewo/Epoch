// This file has been modified from its original project Swift-JsonSerializer

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

public enum JSONMapParseError : Error, CustomStringConvertible {
    case unexpectedTokenError(reason: String, lineNumber: Int, columnNumber: Int)
    case insufficientTokenError(reason: String, lineNumber: Int, columnNumber: Int)
    case extraTokenError(reason: String, lineNumber: Int, columnNumber: Int)
    case nonStringKeyError(reason: String, lineNumber: Int, columnNumber: Int)
    case invalidStringError(reason: String, lineNumber: Int, columnNumber: Int)
    case invalidNumberError(reason: String, lineNumber: Int, columnNumber: Int)

    public var description: String {
        switch self {
        case .unexpectedTokenError(let r, let l, let c):
            return "UnexpectedTokenError" + infoDescription(reason: r, line: l, column: c)
        case .insufficientTokenError(let r, let l, let c):
            return "InsufficientTokenError" + infoDescription(reason: r, line: l, column: c)
        case .extraTokenError(let r, let l, let c):
            return "ExtraTokenError" + infoDescription(reason: r, line: l, column: c)
        case .nonStringKeyError(let r, let l, let c):
            return "NonStringKeyError" + infoDescription(reason: r, line: l, column: c)
        case .invalidStringError(let r, let l, let c):
            return "InvalidStringError" + infoDescription(reason: r, line: l, column: c)
        case .invalidNumberError(let r, let l, let c):
            return "InvalidNumberError" + infoDescription(reason: r, line: l, column: c)
        }
    }

    func infoDescription(reason: String, line: Int, column: Int) -> String {
        return "[Line: \(line), Column: \(column)]: \(reason)"
    }
}

public struct JSONMapParser : MapParser {
    public init() {}

    public func parse(_ data: Data) throws -> Map {
        return try GenericJSONMapParser(data).parse()
    }
}

class GenericJSONMapParser<ByteSequence: Collection> where ByteSequence.Iterator.Element == UInt8 {
    typealias Source = ByteSequence
    typealias Char = Source.Iterator.Element

    let source: Source
    var cur: Source.Index
    let end: Source.Index

    var lineNumber = 1
    var columnNumber = 1

    init(_ source: Source) {
        self.source = source
        self.cur = source.startIndex
        self.end = source.endIndex
    }

    func parse() throws -> Map {
        let data = try parseValue()
        skipWhitespaces()
        if cur == end {
            return data
        }
        throw extraTokenError(reason: "extra tokens found")
    }

    func unexpectedTokenError(reason: String) -> Error {
        return JSONMapParseError.unexpectedTokenError(reason: reason, lineNumber: lineNumber, columnNumber: columnNumber)
    }

    func insufficientTokenError(reason: String) -> Error {
        return JSONMapParseError.insufficientTokenError(reason: reason, lineNumber: lineNumber, columnNumber: columnNumber)
    }

    func extraTokenError(reason: String) -> Error {
        return JSONMapParseError.extraTokenError(reason: reason, lineNumber: lineNumber, columnNumber: columnNumber)
    }

    func nonStringKeyError(reason: String) -> Error {
        return JSONMapParseError.nonStringKeyError(reason: reason, lineNumber: lineNumber, columnNumber: columnNumber)
    }

    func invalidStringError(reason: String) -> Error {
        return JSONMapParseError.invalidStringError(reason: reason, lineNumber: lineNumber, columnNumber: columnNumber)
    }

    func invalidNumberError(reason: String) -> Error {
        return JSONMapParseError.invalidNumberError(reason: reason, lineNumber: lineNumber, columnNumber: columnNumber)
    }
}

// MARK: - Private

extension GenericJSONMapParser {
    fileprivate func parseValue() throws -> Map {
        skipWhitespaces()
        if cur == end {
            throw insufficientTokenError(reason: "unexpected end of tokens")
        }

        switch currentChar {
        case Char(ascii: "n"): return try parseSymbol("null", .null)
        case Char(ascii: "t"): return try parseSymbol("true", .bool(true))
        case Char(ascii: "f"): return try parseSymbol("false", .bool(false))
        case Char(ascii: "-"), Char(ascii: "0") ... Char(ascii: "9"): return try parseNumber()
        case Char(ascii: "\""): return try parseString()
        case Char(ascii: "{"): return try parseObject()
        case Char(ascii: "["): return try parseArray()
        case (let c): throw unexpectedTokenError(reason: "unexpected token: \(c)")
        }
    }

    private var currentChar: Char {
        return source[cur]
    }

    private var nextChar: Char {
        return source[source.index(after: cur)]
    }

    private var distanceToEnd: ByteSequence.IndexDistance {
        return source.distance(from: cur, to: end)
    }

    private var currentSymbol: Character {
        return Character(UnicodeScalar(currentChar))
    }

    private func parseSymbol(_ target: StaticString, _ iftrue: @autoclosure (Void) -> Map) throws -> Map {
        if expect(target) {
            return iftrue()
        }
        throw unexpectedTokenError(reason: "expected \"\(target)\" but \(currentSymbol)")
    }

    private func parseString() throws -> Map {
        advance()

        var buffer = [CChar]()

        while cur != end && currentChar != Char(ascii: "\"") {
            switch currentChar {
            case Char(ascii: "\\"):
                advance()

                guard cur != end else {
                    throw invalidStringError(reason: "missing double quote")
                }

                guard let escapedChar = parseEscapedChar() else {
                    throw invalidStringError(reason: "missing double quote")
                }

                String(escapedChar).utf8.forEach {
                    buffer.append(CChar(bitPattern: $0))
                }
            default:
                buffer.append(CChar(bitPattern: currentChar))
            }

            advance()
        }

        guard expect("\"") else {
            throw invalidStringError(reason: "missing double quote")
        }

        buffer.append(0) // trailing nul
        return .string(String(cString: buffer))
    }

    private func parseEscapedChar() -> UnicodeScalar? {
        let character = UnicodeScalar(currentChar)

        // 'u' indicates unicode
        guard character == "u" else {
            return unescapeMapping[character] ?? character
        }

        guard let surrogateValue = parseEscapedUnicodeSurrogate() else {
            return nil
        }

        // two consecutive \u#### sequences represent 32 bit unicode characters
        if distanceToEnd > 2 && nextChar == Char(ascii: "\\") && source[source.index(cur, offsetBy: 2)] == Char(ascii: "u") {
            advance()
            advance()

            guard let surrogatePairValue = parseEscapedUnicodeSurrogate() else {
                return nil
            }

            guard isHighSurrogate(surrogateValue) else {
                return nil
            }

            guard isLowSurrogate(surrogatePairValue) else {
                return nil
            }

            let scalar = (UInt32(surrogateValue) << 10) + UInt32(surrogatePairValue) - 0x35fdc00
            return UnicodeScalar(scalar)
        }

        if isHighOrLowSurrogate(surrogateValue) {
            return nil
        }

        return UnicodeScalar(surrogateValue)
    }

    private func isHighSurrogate(_ n: UInt32) -> Bool {
        return 0xD800 ... 0xDBFF ~= Int(n)
    }

    private func isLowSurrogate(_ n: UInt32) -> Bool {
        return 0xDC00 ... 0xDFFF ~= Int(n)
    }

    private func isHighOrLowSurrogate(_ n: UInt32) -> Bool {
        return isHighSurrogate(n) || isLowSurrogate(n)
    }

    private func parseEscapedUnicodeSurrogate() -> UInt32? {
        guard distanceToEnd > 4 else {
            return nil
        }

        let requiredLength = 4

        var length = 0
        var value: UInt32 = 0
        while true {
            guard length < requiredLength else {
                break
            }
            guard let d = hexToDigit(nextChar) else {
                break
            }
            advance()
            length += 1

            value <<= 4
            value |= d
        }

        guard length == requiredLength else { return nil }
        return value
    }

    private func parseNumber() throws -> Map {
        let sign = expect("-") ? -1.0 : 1.0
        var integer: Int64 = 0
        var actualNumberStarted = false

        while cur != end {
            if currentChar == Char(ascii: "0") && !actualNumberStarted {
                advance()
                continue
            }
            actualNumberStarted = true
            if let value = digitToInt(currentChar) {
                let (n, overflowed) = Int64.multiplyWithOverflow(integer, 10)
                if overflowed {
                    throw invalidNumberError(reason: "too large number")
                }
                integer = n + Int64(value)
            } else {
                break
            }
            advance()
        }

        if integer != Int64(Double(integer)) {
            throw invalidNumberError(reason: "too large number")
        }

        var fraction: Double = 0.0
        var hasFraction = false

        if expect(".") {
            hasFraction = true
            var factor = 0.1
            var fractionLength = 0

            while cur != end {
                if let value = digitToInt(currentChar) {
                    fraction += (Double(value) * factor)
                    factor /= 10
                    fractionLength += 1
                } else {
                    break
                }
                advance()
            }

            if fractionLength == 0 {
                throw invalidNumberError(reason: "insufficient fraction part in number")
            }
        }

        var exponent: Int64 = 0
        var expSign: Int64 = 1

        if expect("e") || expect("E") {
            if expect("-") {
                expSign = -1
            } else {
                _ = expect("+")
            }

            exponent = 0
            var exponentLength = 0

            while cur != end {
                if let value = digitToInt(currentChar) {
                    exponent = (exponent * 10) + Int64(value)
                    exponentLength += 1
                } else {
                    break
                }
                advance()
            }

            if exponentLength == 0 {
                throw invalidNumberError(reason: "insufficient exponent part in number")
            }

            exponent *= expSign
        }

        if hasFraction || expSign == -1 {
            return .double(sign * (Double(integer) + fraction) * pow(10, Double(exponent)))
        }

        return .int(Int(sign * Double(integer) * pow(10, Double(exponent))))
    }

    private func parseObject() throws -> Map {
        advance()
        skipWhitespaces()
        var object: [String: Map] = [:]

        LOOP: while cur != end && !expect("}") {
            let keyValue = try parseValue()

            switch keyValue {
            case .string(let key):
                skipWhitespaces()

                if !expect(":") {
                    throw unexpectedTokenError(reason: "missing colon (:)")
                }

                skipWhitespaces()
                let value = try parseValue()
                object[key] = value
                skipWhitespaces()

                if expect(",") {
                    break
                } else if expect("}") {
                    break LOOP
                } else {
                    throw unexpectedTokenError(reason: "missing comma (,)")
                }
            default:
                throw nonStringKeyError(reason: "unexpected value for object key")
            }
        }

        return .dictionary(object)
    }

    private func parseArray() throws -> Map {
        advance()
        skipWhitespaces()

        var array: [Map] = []

        LOOP: while cur != end && !expect("]") {
            let data = try parseValue()
            skipWhitespaces()
            array.append(data)

            if expect(",") {
                continue
            } else if expect("]") {
                break LOOP
            }
            throw unexpectedTokenError(reason: "missing comma (,) (token: \(currentSymbol))")
        }

        return .array(array)
    }


    private func expect(_ target: StaticString) -> Bool {
        if cur == end {
            return false
        }

        if !isIdentifier(target.utf8Start.pointee) {
            if target.utf8Start.pointee == currentChar {
                advance()
                return true
            }

            return false
        }

        let start = cur
        let l = lineNumber
        let c = columnNumber

        var p = target.utf8Start
        let endp = p.advanced(by: Int(target.utf8CodeUnitCount))

        while p != endp {
            if p.pointee != currentChar {
                cur = start
                lineNumber = l
                columnNumber = c
                return false
            }
            p += 1
            advance()
        }

        return true
    }

    // only "true", "false", "null" are identifiers
    private func isIdentifier(_ char: Char) -> Bool {
        switch char {
        case Char(ascii: "a") ... Char(ascii: "z"):
            return true
        default:
            return false
        }
    }

    private func advance() {
        cur = source.index(after: cur)

        if cur != end {
            switch currentChar {

            case Char(ascii: "\n"):
                lineNumber += 1
                columnNumber = 1

            default:
                columnNumber += 1
            }
        }
    }

    fileprivate func skipWhitespaces() {
        while cur != end {
            switch currentChar {
            case Char(ascii: " "), Char(ascii: "\t"), Char(ascii: "\r"), Char(ascii: "\n"):
                break
            default:
                return
            }
            advance()
        }
    }
}

let unescapeMapping: [UnicodeScalar: UnicodeScalar] = [
    "t": "\t",
    "r": "\r",
    "n": "\n"
]

let escapeMapping: [Character: String] = [
    "\r": "\\r",
    "\n": "\\n",
    "\t": "\\t",
    "\\": "\\\\",
    "\"": "\\\"",

    "\u{2028}": "\\u2028",
    "\u{2029}": "\\u2029",

    "\r\n": "\\r\\n"
]

let hexMapping: [UnicodeScalar: UInt32] = [
    "0": 0x0,
    "1": 0x1,
    "2": 0x2,
    "3": 0x3,
    "4": 0x4,
    "5": 0x5,
    "6": 0x6,
    "7": 0x7,
    "8": 0x8,
    "9": 0x9,
    "a": 0xA, "A": 0xA,
    "b": 0xB, "B": 0xB,
    "c": 0xC, "C": 0xC,
    "d": 0xD, "D": 0xD,
    "e": 0xE, "E": 0xE,
    "f": 0xF, "F": 0xF
]

let digitMapping: [UnicodeScalar:Int] = [
    "0": 0,
    "1": 1,
    "2": 2,
    "3": 3,
    "4": 4,
    "5": 5,
    "6": 6,
    "7": 7,
    "8": 8,
    "9": 9
]

func digitToInt(_ byte: UInt8) -> Int? {
    return digitMapping[UnicodeScalar(byte)]
}

func hexToDigit(_ byte: UInt8) -> UInt32? {
    return hexMapping[UnicodeScalar(byte)]
}
