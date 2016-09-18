public enum IndexPathValue {
    case index(Int)
    case key(String)
}

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
