#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

import Venice
import Core
import CLibdill
import CDsock

public final class TLSStream : Handle, DuplexStream {
    public var ip: IP
    private var socket: Int32
    
    init(handle: HandleDescriptor, socket: Int32, ip: IP) {
        self.ip = ip
        self.socket = socket
        super.init(handle: handle)
    }
    
    public init(ip: IP) {
        self.ip = ip
        self.socket = -1
        super.init(handle: -1)
    }
    
    public convenience init(host: String, port: Int, deadline: Deadline) throws {
        let ip = try IP(remote: host, port: port, deadline: deadline)
        self.init(ip: ip)
    }
    
    public func open(deadline: Deadline) throws {
        var address = ip.address
        var result = tcp_connect(&address, deadline.value)
        
        guard result != -1 else {
            switch errno {
            default:
                throw SystemError.lastOperationError
            }
        }
        
        let socket = result
        
        result = btls_attach_client(
            socket,
            UInt64(
                DSOCK_BTLS_DEFAULT |
                DSOCK_BTLS_NO_VERIFY_NAME |
                DSOCK_BTLS_NO_VERIFY_CERT |
                DSOCK_BTLS_NO_VERIFY_TIME
            ),
            0,
            nil,
            nil,
            nil
        )
        
        guard result != -1 else {
            switch errno {
            default:
                throw SystemError.lastOperationError
            }
        }
        
        self.handle = result
        self.socket = socket
    }
    
    public func read(
        _ buffer: UnsafeMutableRawBufferPointer,
        deadline: Deadline
        ) throws -> UnsafeRawBufferPointer {
        let result = brecv(handle, buffer.baseAddress, buffer.count, deadline.value)
        
        guard result != -1 else {
            switch errno {
            default:
                throw SystemError.lastOperationError
            }
        }
        
        return UnsafeRawBufferPointer(buffer).prefix(result)
    }
    
    public func write(_ buffer: UnsafeRawBufferPointer, deadline: Deadline) throws {
        let result = bsend(handle, buffer.baseAddress, buffer.count, deadline.value)
        
        guard result != -1 else {
            switch errno {
            default:
                throw SystemError.lastOperationError
            }
        }
    }
}
