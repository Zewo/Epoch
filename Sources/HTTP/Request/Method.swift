public enum Method {
    case delete
    case get
    case head
    case post
    case put
    case connect
    case options
    case trace
    case patch
    case other(method: String)
}

extension Method {
    init(_ rawValue: String) {
        let method = rawValue.uppercased()
        switch method {
        case "DELETE":  self = .delete
        case "GET":     self = .get
        case "HEAD":    self = .head
        case "POST":    self = .post
        case "PUT":     self = .put
        case "CONNECT": self = .connect
        case "OPTIONS": self = .options
        case "TRACE":   self = .trace
        case "PATCH":   self = .patch
        default:        self = .other(method: method)
        }
    }
}

extension Method : CustomStringConvertible {
    public var description: String {
        switch self {
        case .delete:            return "DELETE"
        case .get:               return "GET"
        case .head:              return "HEAD"
        case .post:              return "POST"
        case .put:               return "PUT"
        case .connect:           return "CONNECT"
        case .options:           return "OPTIONS"
        case .trace:             return "TRACE"
        case .patch:             return "PATCH"
        case .other(let method): return method.uppercased()
        }
    }
}

extension Method : Hashable {
    public var hashValue: Int {
        switch self {
        case .delete:            return 0
        case .get:               return 1
        case .head:              return 2
        case .post:              return 3
        case .put:               return 4
        case .connect:           return 5
        case .options:           return 6
        case .trace:             return 7
        case .patch:             return 8
        case .other(let method): return 9 + method.hashValue
        }
    }
}

public func ==(lhs: Method, rhs: Method) -> Bool {
    return lhs.description == rhs.description
}
