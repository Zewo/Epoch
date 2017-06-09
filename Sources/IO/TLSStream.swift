#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

import Venice
import Core
import CLibdill
import CBtls

public final class TLSStream : DuplexStream {
    internal typealias Handle = Int32
    internal typealias Socket = Int32
    
    private var handle: Handle
    private var socket: Socket
    public var ip: IP
    private var open: Bool
    
    internal init(handle: Handle, socket: Socket, ip: IP, open: Bool) {
        self.handle = handle
        self.socket = socket
        self.ip = ip
        self.open = open
    }
    
    deinit {
        if open {
            hclose(handle)
        }
    }
    
    public convenience init(ip: IP) {
        self.init(handle: -1, socket: -1, ip: ip, open: false)
    }
    
    public convenience init(host: String, port: Int, deadline: Deadline) throws {
        let ip = try IP(remote: host, port: port, deadline: deadline)
        self.init(ip: ip)
    }
    
    public func open(deadline: Deadline) throws {
        guard !open else {
            throw SystemError.socketIsAlreadyConnected
        }
        
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
                BTLS_DEFAULT |
                BTLS_NO_VERIFY_NAME |
                BTLS_NO_VERIFY_CERT |
                BTLS_NO_VERIFY_TIME
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
        self.open = true
    }
    
    public func read(
        _ buffer: UnsafeMutableRawBufferPointer,
        deadline: Deadline
    ) throws -> UnsafeRawBufferPointer {
        try assertOpen()
        let result = brecv(handle, buffer.baseAddress, buffer.count, deadline.value)
        
        guard result != -1 else {
            switch errno {
            default:
                throw SystemError.lastOperationError
            }
        }
        
        return UnsafeRawBufferPointer(buffer.prefix(result))
    }
    
    public func write(_ buffer: UnsafeRawBufferPointer, deadline: Deadline) throws {
        try assertOpen()
        let result = bsend(handle, buffer.baseAddress, buffer.count, deadline.value)
        
        guard result != -1 else {
            switch errno {
            default:
                throw SystemError.lastOperationError
            }
        }
    }
    
    public func close(deadline: Deadline) throws {
        try assertOpen()
        
        defer {
            open = false
        }
        
        let result = hclose(handle)
        
        guard result != -1 else {
            switch errno {
            default:
                throw SystemError.lastOperationError
            }
        }
    }
    
    private func assertOpen() throws {
        guard open else {
            throw SystemError.socketIsNotConnected
        }
    }
}
