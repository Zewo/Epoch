import CDNS
import POSIX
import Venice

public enum DNSError: Error {
    case unableToResolveAddress
}

private enum DNS {
    fileprivate static var configuration: UnsafeMutablePointer<dns_resolv_conf>? = {
        var result: Int32 = 0
        return dns_resconf_local(&result)
    }()

    fileprivate static var hosts: OpaquePointer? = {
        var result: Int32 = 0
        return dns_hosts_local(&result)
    }()

    fileprivate static var hints: OpaquePointer? = {
        var result: Int32 = 0
        return dns_hints_local(configuration, &result)
    }()

    fileprivate static var options = dns_options()
}

extension Address {
    public init(
        address: String,
        port: Int,
        mode: IPMode = .ipv4,
        deadline: Deadline
    ) throws {
        try assertValidPort(port)
        var result: Int32 = 0
        var options = DNS.options
        let resolver = dns_res_open(DNS.configuration, DNS.hosts, DNS.hints, nil, &options, &result)
        var addressHints = addrinfo()
        addressHints.ai_family = PF_UNSPEC
        
        guard let addressInfo = dns_ai_open(address, String(port), DNS_T_A, &addressHints, resolver, &result) else {
            throw DNSError.unableToResolveAddress
        }
        
        defer { dns_ai_close(addressInfo) }
        dns_res_close(resolver)

        var ipv4: UnsafeMutablePointer<addrinfo>? = nil
        var ipv6: UnsafeMutablePointer<addrinfo>? = nil
        var ip: UnsafeMutablePointer<addrinfo>? = nil

        loop: while true {
            result = withUnsafeMutablePointer(to: &ip) {
                dns_ai_nextent($0, addressInfo)
            }

            switch result {
            case EAGAIN, EWOULDBLOCK:
                let fileDescriptor = try FileDescriptor(dns_ai_pollfd(addressInfo))
                try fileDescriptor.poll(event: .read, deadline: deadline)
                /* There's no guarantee that the file descriptor will be reused
                 in next iteration. We have to clean the fdwait cache here
                 to be on the safe side. */
                fileDescriptor.detach()
                continue loop
            case 0:
                guard let ip = ip else {
                    throw DNSError.unableToResolveAddress
                }

                if ipv4 == nil, ip.pointee.ai_family == AF_INET {
                    ipv4 = ip
                } else if ipv6 == nil, ip.pointee.ai_family == AF_INET6 {
                    ipv6 = ip
                } else {
                    ip.deallocate(capacity: 1)
                }

                if ipv4 != nil && ipv6 != nil {
                    break loop
                }
            default:
                break loop
            }
        }

        switch mode {
        case .ipv4:
            if ipv6 != nil {
                ipv6?.deallocate(capacity: 1)
                ipv6 = nil
            }
        case .ipv6:
            if ipv4 != nil {
                ipv4?.deallocate(capacity: 1)
                ipv4 = nil
            }
        }

        if let ipv4 = ipv4 {
            self = Address.fromIPv4Pointer { address in
                memcpy(address, ipv4.pointee.ai_addr, MemoryLayout<sockaddr_in>.size)
                address.pointee.sin_port = POSIX.htons(UInt16(port))
                ipv4.deallocate(capacity: 1)
            }
            return
        }

        if let ipv6 = ipv6 {
            self = Address.fromIPv6Pointer { address in
                memcpy(address, ipv6.pointee.ai_addr, MemoryLayout<sockaddr_in6>.size)
                address.pointee.sin6_port = POSIX.htons(UInt16(port))
                ipv6.deallocate(capacity: 1)
            }
            return
        }

        throw DNSError.unableToResolveAddress
    }
}
