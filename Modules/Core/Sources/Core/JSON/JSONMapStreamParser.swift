// This file has been modified from its original project Swift-JsonSerializer

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

public enum JSONMapStreamParseError : Error, CustomStringConvertible {
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

public final class JSONMapStreamParser : MapStreamParser {
    let stream: Stream
    var buffer: Buffer

    public init(stream: Stream) {
        self.stream = stream
        self.buffer = Buffer.empty
    }

    var lineNumber = 1
    var columnNumber = 1

    public func parse() throws -> Map {
        return try parseValue()
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

extension JSONMapStreamParser {
    fileprivate func parseValue() throws -> Map {
        try skipWhitespaces()
        switch try getCurrentByte() {
        case Byte(ascii: "n"): return try parseSymbol("null", .null)
        case Byte(ascii: "t"): return try parseSymbol("true", .bool(true))
        case Byte(ascii: "f"): return try parseSymbol("false", .bool(false))
        case Byte(ascii: "-"), Byte(ascii: "0") ... Byte(ascii: "9"): return try parseNumber()
        case Byte(ascii: "\""): return try parseString()
        case Byte(ascii: "{"): return try parseObject()
        case Byte(ascii: "["): return try parseArray()
        case (let c): throw unexpectedTokenError(reason: "unexpected token: \(c)")
        }
    }

    private func readChunk() throws {
        guard !stream.closed else {
            throw insufficientTokenError(reason: "unexpected end of tokens")
        }
        let chunk = try stream.read(upTo: 1024)
        guard !chunk.isEmpty else {
            throw insufficientTokenError(reason: "unexpected end of tokens")
        }
        buffer.append(chunk)
    }

    private var bytesInBuffer: Int {
        return buffer.count
    }

    private func getCurrentByte() throws -> Byte {
        if bytesInBuffer == 0 {
            try readChunk()
        }
        guard bytesInBuffer >= 1 else {
            throw insufficientTokenError(reason: "unexpected end of tokens")
        }
        return buffer[0]
    }

    private func getCurrentSymbol() throws -> Character {
        return try Character(UnicodeScalar(getCurrentByte()))
    }

    private func parseSymbol(_ target: StaticString, _ iftrue: @autoclosure (Void) -> Map) throws -> Map {
        if try expect(target) {
            return iftrue()
        }
        let symbol = try getCurrentSymbol()
        throw unexpectedTokenError(reason: "expected \"\(target)\" but got \(symbol)")
    }

    private func parseString() throws -> Map {
        try advance()

        var buffer = [CChar]()

        while try getCurrentByte() != Byte(ascii: "\"") {
            switch try getCurrentByte() {
            case Byte(ascii: "\\"):
                guard let escapedChar = try parseEscapedCharacter() else {
                    throw invalidStringError(reason: "invalid escaped character")
                }

                String(escapedChar).utf8.forEach {
                    buffer.append(CChar(bitPattern: $0))
                }
            default:
                buffer.append(CChar(bitPattern: try getCurrentByte()))
            }
            try advance()
        }

        guard try expect("\"") else {
            throw invalidStringError(reason: "missing double quote")
        }
        
        buffer.append(0) // trailing nul
        return .string(String(cString: buffer))
    }

    private func parseEscapedCharacter() throws -> UnicodeScalar? {
        try advance()

        let character = UnicodeScalar(try getCurrentByte())

        // 'u' indicates unicode
        guard character == "u" else {
            return unescapeMapping[character] ?? character
        }

        guard let surrogateValue = try parseEscapedUnicodeSurrogate() else {
            return nil
        }

        if isHighSurrogate(surrogateValue) {
            try advance()
            guard try getCurrentByte() == Byte(ascii: "\\") else {
                throw invalidStringError(reason: "Invalid escaped character.")
            }

            try advance()
            guard try getCurrentByte() == Byte(ascii: "u") else {
                throw invalidStringError(reason: "Invalid escaped character.")
            }

            guard let surrogatePairValue = try parseEscapedUnicodeSurrogate() else {
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

    private func parseEscapedUnicodeSurrogate() throws -> UInt32? {
        let requiredLength = 4

        var length = 0
        var value: UInt32 = 0
        while true {
            guard length < requiredLength else {
                break
            }
            try advance()
            guard let digit = hexToDigit(try getCurrentByte()) else {
                break
            }

            length += 1

            value <<= 4
            value |= digit
        }

        guard length == requiredLength else { return nil }
        return value
    }

    private func parseNumber() throws -> Map {
        let sign = try expect("-") ? -1.0 : 1.0
        var integer: Int64 = 0
        var actualNumberStarted = false

        while true {
            if try getCurrentByte() == Byte(ascii: "0") && !actualNumberStarted {
                try advance()
                continue
            }
            actualNumberStarted = true
            if let value = digitToInt(try getCurrentByte()) {
                let (n, overflowed) = Int64.multiplyWithOverflow(integer, 10)
                if overflowed {
                    throw invalidNumberError(reason: "too large number")
                }
                integer = n + Int64(value)
            } else {
                break
            }
            try advance()
        }

        if integer != Int64(Double(integer)) {
            throw invalidNumberError(reason: "too large number")
        }

        var fraction: Double = 0.0
        var hasFraction = false

        if try expect(".") {
            hasFraction = true
            var factor = 0.1
            var fractionLength = 0

            while true {
                if let value = digitToInt(try getCurrentByte()) {
                    fraction += (Double(value) * factor)
                    factor /= 10
                    fractionLength += 1
                } else {
                    break
                }
                try advance()
            }

            if fractionLength == 0 {
                throw invalidNumberError(reason: "insufficient fraction part in number")
            }
        }

        var exponent: Int64 = 0
        var expSign: Int64 = 1

        if try expect("e") || expect("E") {
            if try expect("-") {
                expSign = -1
            } else {
                _ = try expect("+")
            }

            exponent = 0
            var exponentLength = 0

            while true {
                if let value = digitToInt(try getCurrentByte()) {
                    exponent = (exponent * 10) + Int64(value)
                    exponentLength += 1
                } else {
                    break
                }
                try advance()
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
        try advance()
        try skipWhitespaces()
        var object: [String: Map] = [:]

        LOOP: while try !expect("}") {
            let keyValue = try parseValue()

            switch keyValue {
            case .string(let key):
                try skipWhitespaces()

                if try !expect(":") {
                    throw unexpectedTokenError(reason: "missing colon (:)")
                }

                try skipWhitespaces()
                let value = try parseValue()
                object[key] = value
                try skipWhitespaces()

                if try expect(",") {
                    break
                } else if try expect("}") {
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
        try advance()
        try skipWhitespaces()

        var array: [Map] = []

        LOOP: while try !expect("]") {
            let data = try parseValue()
            try skipWhitespaces()
            array.append(data)

            if try expect(",") {
                continue
            } else if try expect("]") {
                break LOOP
            }
            let symbol = try getCurrentSymbol()
            throw unexpectedTokenError(reason: "missing comma (,) (token: \(symbol))")
        }

        return .array(array)
    }


    private func expect(_ target: StaticString) throws -> Bool {
        if !isIdentifier(target.utf8Start.pointee) {
            let currentByte = try getCurrentByte()
            if target.utf8Start.pointee == currentByte {
                try advance()
                return true
            }

            return false
        }

        let current = buffer
        let l = lineNumber
        let c = columnNumber

        var p = target.utf8Start
        let endp = p.advanced(by: Int(target.utf8CodeUnitCount))

        while p != endp {
            let currentByte = try getCurrentByte()
            if p.pointee != currentByte {
                buffer = current
                lineNumber = l
                columnNumber = c
                return false
            }
            p += 1
            try advance()
        }

        return true
    }

    // only "true", "false", "null" are identifiers
    private func isIdentifier(_ char: Byte) -> Bool {
        switch char {
        case Byte(ascii: "a") ... Byte(ascii: "z"):
            return true
        default:
            return false
        }
    }

    private func advance() throws {
        if !buffer.isEmpty {
            buffer = buffer.subdata(in: buffer.startIndex.advanced(by: 1)..<buffer.endIndex)
        }
        
        if bytesInBuffer > 0 {
            switch try getCurrentByte() {

            case Byte(ascii: "\n"):
                lineNumber += 1
                columnNumber = 1

            default:
                columnNumber += 1
            }
        }
    }

    fileprivate func skipWhitespaces() throws {
        while true {
            switch try getCurrentByte() {
            case Byte(ascii: " "), Byte(ascii: "\t"), Byte(ascii: "\r"), Byte(ascii: "\n"):
                break
            default:
                return
            }
            try advance()
        }
    }
}
