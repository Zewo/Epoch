#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

private func withUnsafeMutablePointer<S, T, Result>(
    to source: inout S,
    rebindingMemoryTo target: T.Type,
    _ body: (UnsafeMutablePointer<T>
) throws -> Result) rethrows -> Result {
    return try withUnsafeMutablePointer(to: &source) { pointer in
        try pointer.withMemoryRebound(to: T.self, capacity: MemoryLayout<T>.size) { reboundPointer in
            return try body(reboundPointer)
        }
    }
}

public enum AddressFamily {
    case ipv4
    case ipv6

    init?(rawValue: Int32) {
        switch rawValue {
        case AF_INET:
            self = .ipv4
        case AF_INET6:
            self = .ipv6
        default:
            return nil
        }
    }

    var rawValue: Int32 {
        switch self {
        case .ipv4:
            return AF_INET
        case .ipv6:
            return AF_INET6
        }
    }
}

public struct Address {
    let data: (
        Int8,
        Int8,
        Int8,
        Int8,
        Int8,
        Int8,
        Int8,
        Int8,
        Int8,
        Int8,
        Int8,
        Int8,
        Int8,
        Int8,
        Int8,
        Int8,
        Int8,
        Int8,
        Int8,
        Int8,
        Int8,
        Int8,
        Int8,
        Int8,
        Int8,
        Int8,
        Int8,
        Int8,
        Int8,
        Int8,
        Int8,
        Int8
    )

    public init() {
        self.data = (
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0
        )
    }

    public init(family: AddressFamily, port: Int) {
        switch family {
        case .ipv4:
            self = Address.fromIPv4Pointer { ipv4 in
                ipv4.pointee.sin_family = sa_family_t(family.rawValue)
                ipv4.pointee.sin_addr.s_addr = htonl(INADDR_ANY)
                ipv4.pointee.sin_port = htons(UInt16(port))
            }
        case .ipv6:
            self = Address.fromIPv6Pointer { ipv6 in
                ipv6.pointee.sin6_family = sa_family_t(family.rawValue)
                var anyIPv6 = in6addr_any
                memcpy(&ipv6.pointee.sin6_addr, &anyIPv6, MemoryLayout<in6_addr>.size)
                ipv6.pointee.sin6_port = htons(UInt16(port))
            }
        }
    }

    public init(family: AddressFamily, address: String, port: Int) throws {
        switch family {
        case .ipv4:
            self = try Address.fromIPv4Pointer { ipv4 in
                try POSIX.inet_pton(family, address, &ipv4.pointee.sin_addr)
                ipv4.pointee.sin_family = sa_family_t(family.rawValue)
                ipv4.pointee.sin_port = POSIX.htons(UInt16(port))
            }
        case .ipv6:
            self = try Address.fromIPv6Pointer { ipv6 in
                try POSIX.inet_pton(family, address, &ipv6.pointee.sin6_addr)
                ipv6.pointee.sin6_family = sa_family_t(family.rawValue)
                ipv6.pointee.sin6_port = htons(UInt16(port))
            }
        }
    }

    public var family: AddressFamily {
        var address = self
        switch address.withAddressPointer(body: { Int32($0.pointee.sa_family) }) {
        case AF_INET: return .ipv4
        default: return .ipv6
        }
    }

    public var length: Int {
        return family == .ipv4 ? MemoryLayout<sockaddr_in>.size : MemoryLayout<sockaddr_in6>.size
    }

    public var port: Int {
        var address = self
        if address.family == .ipv4 {
            return address.withIPv4Pointer {
                return Int(htons($0.pointee.sin_port))
            }
        } else {
            return address.withIPv6Pointer {
                return Int(htons($0.pointee.sin6_port))
            }
        }
    }

    public static func fromAddressPointer(
        body: (UnsafeMutablePointer<sockaddr>) throws -> Void
    ) rethrows -> Address {
        var address = Address()
        try address.withAddressPointer(body: body)
        return address
    }

    public static func fromIPv4Pointer(
        body: (UnsafeMutablePointer<sockaddr_in>) throws -> Void
    ) rethrows -> Address {
        var address = Address()
        try address.withIPv4Pointer(body: body)
        return address
    }

    public static func fromIPv6Pointer(
        body: (UnsafeMutablePointer<sockaddr_in6>) throws -> Void
    ) rethrows -> Address {
        var address = Address()
        try address.withIPv6Pointer(body: body)
        return address
    }

    public mutating func withAddressPointer<Result>(
        body: (UnsafeMutablePointer<sockaddr>) throws -> Result
    ) rethrows -> Result {
        return try withUnsafeMutablePointer(to: &self, rebindingMemoryTo: sockaddr.self) {
            try body($0)
        }
    }

    fileprivate mutating func withIPv4Pointer<Result>(
        body: (UnsafeMutablePointer<sockaddr_in>
    ) throws -> Result) rethrows -> Result {
        return try withUnsafeMutablePointer(to: &self, rebindingMemoryTo: sockaddr_in.self) {
            try body($0)
        }
    }

    fileprivate mutating func withIPv6Pointer<Result>(
        body: (UnsafeMutablePointer<sockaddr_in6>) throws -> Result
    ) rethrows -> Result {
        return try withUnsafeMutablePointer(to: &self, rebindingMemoryTo: sockaddr_in6.self) {
            try body($0)
        }
    }
}

extension Address : CustomStringConvertible {
    public var description: String {
        var address = self
        if family == .ipv4 {
            return address.withIPv4Pointer {
                var bytes = [Int8](repeating: 0, count: Int(INET_ADDRSTRLEN))
                
                guard let cString = inet_ntop(family.rawValue, &$0.pointee.sin_addr, &bytes, socklen_t(INET_ADDRSTRLEN)) else {
                    return "Unable tp get ip description."
                }
                
                return String(cString: cString)
            }
        } else {
            return address.withIPv6Pointer {
                var bytes = [Int8](repeating: 0, count: Int(INET6_ADDRSTRLEN))
                
                guard let cString = inet_ntop(family.rawValue, &$0.pointee.sin6_addr, &bytes, socklen_t(INET6_ADDRSTRLEN)) else {
                    return "Unable tp get ip description."
                }
                
                return String(cString: cString)
            }
        }
    }
}

#if os(Linux)
    /**
     Converts the unsigned short integer hostshort from host byte order to network byte order.
     */
    public func htons(_ value: UInt16) -> UInt16 {
        return Glibc.htons(value)
    }

    /**
     Converts the unsigned integer hostlong from host byte order to network byte order.
     */
    public func htonl(_ value: UInt32) -> UInt32 {
        return Glibc.htonl(value)
    }
#else
    /**
     Converts the unsigned short integer hostshort from host byte order to network byte order.
    */
    public func htons(_ value: UInt16) -> UInt16 {
        return _OSSwapInt16(value)
    }

    /**
     Converts the unsigned integer hostlong from host byte order to network byte order.
     */
    public func htonl(_ value: UInt32) -> UInt32 {
        return _OSSwapInt32(value)
    }
#endif

fileprivate func inet_pton(_ addressFamily: AddressFamily, _ source: String, _ destination: UnsafeMutableRawPointer?) throws {
    let result = source.withCString({ inet_pton(addressFamily.rawValue, $0, destination) })

    switch result {
    case 0:
        throw SystemError.invalidArgument
    case -1:
        throw SystemError.lastOperationError
    default:
        break
    }
}
