import Foundation

public struct Error : Swift.Error, CustomStringConvertible, CustomDebugStringConvertible {
    public enum Code {
        case connection
        case encoding
        case decoding
        case handshake
        case authentication
        case query(type: String, backtrace: String)
        case reql(backtrace: String?)
        case generic
    }

    public let code: Code
    public let reason: String
    public let underlyingError: Swift.Error?

    internal init(code: Code, reason: String, underlyingError: Swift.Error? = nil) {
        self.code = code
        self.reason = reason
        self.underlyingError = underlyingError
    }

    public var description: String {
        return ""
    }

    public var debugDescription: String {
        return ""
    }
}
