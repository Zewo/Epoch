#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

public enum StringError : Error {
    case invalidString
    case utf8EncodingFailed
    case invalidUTF8
    case invalidPercentEncoding
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
        return String(characters.prefix(1)).uppercased() + String(characters.dropFirst()).lowercased()
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

	public func index(of string: String) -> String.Index? {
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

extension String {
    public init(percentEncoded: String) throws {
        var reader = percentEncoded.unicodeScalars.makeIterator()
        var buffer: [UTF8.CodeUnit] = []
        var result = String.UnicodeScalarView()

        while var nextScalar = reader.next() {
            switch nextScalar {
            case "%":
                guard let hexH = reader.next(), let hexL = reader.next() else { throw StringError.invalidPercentEncoding }

                var hex = UnicodeScalarView()
                hex.append(hexH)
                hex.append(hexL)

                guard let decodedHex = UTF8.CodeUnit(String(hex), radix: 16) else { throw StringError.invalidPercentEncoding }

                buffer.append(decodedHex)
            case "+":
                nextScalar = " "
                fallthrough
            default:
                if buffer.count > 0 {
                    try result.append(contentsOf: buffer.decodeUTF8())
                    buffer.removeAll(keepingCapacity: true)
                }
                result.append(nextScalar)
            }
        }

        if buffer.count > 0 {
            try result.append(contentsOf: buffer.decodeUTF8())
        }
        
        self = String(result)
    }
}

extension String {
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

extension String.UnicodeScalarView: ExpressibleByStringLiteral {

    public init(stringLiteral value: String.StringLiteralType) {
        self = value.unicodeScalars
    }

    public init(extendedGraphemeClusterLiteral value: String.ExtendedGraphemeClusterLiteralType) {
        self = value.unicodeScalars
    }

    public init(unicodeScalarLiteral value: String.UnicodeScalarLiteralType) {
        self = value.unicodeScalars
    }
    
}
