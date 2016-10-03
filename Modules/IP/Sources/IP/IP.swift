@_exported import Axis
import CLibvenice

public enum IPError : Error {
    case invalidPort
}

extension IPError : CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidPort: return "Port number should be between 0 and 0xffff"
        }
    }
}

public enum IPMode {
    case ipV4
    case ipV6
    case ipV4Prefered
    case ipV6Prefered

    var code: Int32 {
        switch self {
        case .ipV4: return 1
        case .ipV6: return 2
        case .ipV4Prefered: return 3
        case .ipV6Prefered: return 4
        }
    }
}

public struct IP {
    public let address: ipaddr

    public init(address: ipaddr) {
        self.address = address
    }

    public init(port: Int = 0, mode: IPMode = .ipV4Prefered) throws {
        try IP.assertValid(port)
        let address = iplocal(nil, Int32(port), mode.code)
        try ensureLastOperationSucceeded()
        self.init(address: address)
    }

    public init(localAddress: String, port: Int = 0, mode: IPMode = .ipV4Prefered) throws {
        try IP.assertValid(port)
        let address = iplocal(localAddress, Int32(port), mode.code)
        try ensureLastOperationSucceeded()
        self.init(address: address)
    }

    public init(remoteAddress: String, port: Int, mode: IPMode = .ipV4Prefered, deadline: Double) throws {
        try IP.assertValid(port)
        let address = ipremote(remoteAddress, Int32(port), mode.code, deadline.int64milliseconds)
        try ensureLastOperationSucceeded()
        self.init(address: address)
    }

    private static func assertValid(_ port: Int) throws {
        if port < 0 || port > 0xffff {
            throw IPError.invalidPort
        }
    }
}

extension IP : CustomStringConvertible {
    public var description: String {
        var buffer = [Int8](repeating: 0, count: 46)
        ipaddrstr(address, &buffer)
        return String(cString: buffer)
    }
}
