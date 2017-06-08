#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

import Venice
import Core
import CLibdill

public enum IPError: Error {
    case invalidPort
    case invalidNetworkInterface
    case invalidAddress
}

extension IPError : CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidPort:
            return "Port number should be between 0 and 0xffff"
        case .invalidNetworkInterface:
            return "Local network interface with the specified name does not exist."
        case .invalidAddress:
            return "The name of the remote host cannot be resolved to an address of the specified type."
        }
    }
}

public struct IP : CustomStringConvertible {
    public enum Mode {
        case ipv4
        case ipv6
        case ipv4Prefered
        case ipv6Prefered
    }
    
    public let address: ipaddr
    public let port: Int
    public let family: Int
    public let description: String
    
    init(address: inout ipaddr) {
        self.address = address
        self.port = Int(ipaddr_port(&address))
        self.family = Int(ipaddr_family(&address))
        var buffer = [Int8](repeating: 0, count: Int(IPADDR_MAXSTRLEN))
        self.description = String(cString: ipaddr_str(&address, &buffer))
    }
    
    public init(port: Int, mode: Mode = .ipv4Prefered) throws {
        try self.init(literal: nil, port: port, mode: mode)
    }

    public init(local literal: String, port: Int, mode: Mode = .ipv4Prefered) throws {
        try self.init(literal: literal, port: port, mode: mode)
    }
    
    private init(literal: String? = nil, port: Int, mode: Mode = .ipv4Prefered) throws {
        try assertValidPort(port)
        
        var address = ipaddr()
        let result = ipaddr_local(&address, literal, Int32(port), mode.value)
        
        guard result != -1 else {
            switch errno {
            case ENODEV:
                throw IPError.invalidNetworkInterface
            default:
                throw SystemError.lastOperationError
            }
        }
        
        self.init(address: &address)
    }

    public init(
        remote literal: String,
        port: Int,
        mode: Mode = .ipv4Prefered,
        deadline: Deadline
    ) throws {
        try assertValidPort(port)
        
        var address = ipaddr()
        let result = ipaddr_remote(&address, literal, Int32(port), mode.value, deadline.value)
        
        guard result != -1 else {
            switch errno {
            case EADDRNOTAVAIL:
                throw IPError.invalidAddress
            default:
                throw SystemError.lastOperationError
            }
        }
        
        self.init(address: &address)
    }
}


extension IP.Mode {
    var value: Int32 {
        switch self {
        case .ipv4:
            return IPADDR_IPV4
        case .ipv6:
            return IPADDR_IPV6
        case .ipv4Prefered:
            return IPADDR_IPV4
        case .ipv6Prefered:
            return IPADDR_IPV6
        }
    }
}

func assertValidPort(_ port: Int) throws {
    guard (0...0xffff).contains(port) else {
        throw IPError.invalidPort
    }
}
