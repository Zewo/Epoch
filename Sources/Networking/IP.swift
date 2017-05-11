import POSIX
import Venice

public enum IPError: Error {
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
    case ipv4
    case ipv6
    case ipv4Prefered
    case ipv6Prefered
}

public struct IP {
    public let address: Address

    public var port: Int {
        return address.port
    }

    public var family: AddressFamily {
        return address.family
    }

    public init(address: Address) {
        self.address = address
    }

    public init(port: Int, mode: IPMode = .ipv4Prefered) throws {
        try assertValidPort(port)
        let address: Address
        
        switch mode {
        case .ipv4, .ipv4Prefered:
            address = Address(family: .ipv4, port: port)
        case .ipv6, .ipv6Prefered:
            address = Address(family: .ipv6, port: port)
        }
        
        self.init(address: address)
    }

    // TODO:
    // get address from interface name

    public init(address literal: String, port: Int, mode: IPMode = .ipv4Prefered, deadline: Deadline) throws {
        try assertValidPort(port)
        let address: Address
        
        do {
            switch mode {
            case .ipv4:
                address = try Address(family: .ipv4, address: literal, port: port)
            case .ipv4Prefered:
                do {
                    address = try Address(family: .ipv4, address: literal, port: port)
                } catch {
                    address = try Address(family: .ipv6, address: literal, port: port)
                }
            case .ipv6:
                address = try Address(family: .ipv6, address: literal, port: port)
            case .ipv6Prefered:
                do {
                    address = try Address(family: .ipv6, address: literal, port: port)
                } catch {
                    address = try Address(family: .ipv4, address: literal, port: port)
                }
            }
        } catch {
            address = try Address(address: literal, port: port, mode: mode, deadline: deadline)
        }
        
        self.init(address: address)
    }
}

func assertValidPort(_ port: Int) throws {
    guard (0...0xffff).contains(port) else {
        throw IPError.invalidPort
    }
}

extension IP : CustomStringConvertible {
    public var description: String {
        return address.description
    }
}
