public struct CaseInsensitiveString {
    public let string: String

    public init(_ string: String) {
        self.string = string
    }
}

extension CaseInsensitiveString : Hashable {
    public var hashValue: Int {
        return string.lowercased().hashValue
    }
}

public func == (lhs: CaseInsensitiveString, rhs: CaseInsensitiveString) -> Bool {
    return lhs.string.lowercased() == rhs.string.lowercased()
}

extension CaseInsensitiveString : ExpressibleByStringLiteral {
    public init(stringLiteral string: String) {
        self.init(string)
    }

    public init(extendedGraphemeClusterLiteral string: String){
        self.init(string)
    }

    public init(unicodeScalarLiteral string: String){
        self.init(string)
    }
}

extension CaseInsensitiveString : CustomStringConvertible {
    public var description: String {
        return string
    }
}

extension String {
    var caseInsensitive: CaseInsensitiveString {
        return CaseInsensitiveString(self)
    }
}

public protocol CaseInsensitiveStringRepresentable {
    var caseInsensitiveString: CaseInsensitiveString { get }
}

extension String : CaseInsensitiveStringRepresentable {
    public var caseInsensitiveString: CaseInsensitiveString {
        return CaseInsensitiveString(self)
    }
}
