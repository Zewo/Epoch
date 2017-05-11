import Foundation

public struct Cookie {
    public var name: String
    public var value: String

    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }
}

extension Cookie : Hashable {
    public var hashValue: Int {
        return name.hashValue
    }
}

extension Cookie : Equatable {}

public func == (lhs: Cookie, rhs: Cookie) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

extension Cookie : CustomStringConvertible {
    public var description: String {
        return "\(name)=\(value)"
    }
}

extension Set where Element == Cookie {
    public init?(cookieHeader: String) {
        var cookies = Set<Element>()
        let tokens = cookieHeader.components(separatedBy: ";")

        for token in tokens {
            let cookieTokens = token.components(separatedBy: "=")

            guard cookieTokens.count == 2 else {
                return nil
            }

            cookies.insert(Cookie(name: cookieTokens[0].trimmingCharacters(in: .whitespacesAndNewlines), value: cookieTokens[1].trimmingCharacters(in: .whitespacesAndNewlines)))
        }

        self = cookies
    }
}
