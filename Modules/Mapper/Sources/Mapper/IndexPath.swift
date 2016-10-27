public enum IndexPathValue {
    case index(Int)
    case key(String)
}

/// Can be represented as `IndexPathValue`.
public protocol IndexPathElement {
    var indexPathValue: IndexPathValue { get }
}

extension Int : IndexPathElement {
    public var indexPathValue: IndexPathValue {
        return .index(self)
    }
}

extension String : IndexPathElement {
    public var indexPathValue: IndexPathValue {
        return .key(self)
    }
}

extension IndexPathValue : IndexPathElement {
    public var indexPathValue: IndexPathValue {
        return self
    }
}

extension IndexPathValue : ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .index(value)
    }
}

extension IndexPathValue : ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
    public typealias UnicodeScalarLiteralType = String
    public typealias ExtendedGraphemeClusterLiteralType = String
    public init(stringLiteral value: StringLiteralType) {
        self = .key(value)
    }
    public init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        self = .key(value)
    }
    public init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
        self = .key(value)
    }
}

extension IndexPathElement where Self : RawRepresentable, Self.RawValue : IndexPathElement {
    public var indexPathValue: IndexPathValue {
        return rawValue.indexPathValue
    }
}

public enum NoKeys : IndexPathElement {
    public var indexPathValue: IndexPathValue {
        return .index(0)
    }
}
