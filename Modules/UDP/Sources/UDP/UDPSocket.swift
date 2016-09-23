import CLibvenice
import POSIX

public final class UDPSocket {

    private var socket: udpsock?
    public private(set) var closed = false

    /// Local IP port
    public var port: Int {
        return Int(udpport(socket))
    }

    // MARK: - Initializers
    
    internal init(socket: udpsock) {
        self.socket = socket
    }

    public convenience init(ip: IP) throws {
        guard let socket = udplisten(ip.address) else {
            throw SystemError.socketTypeNotSupported
        }
        try ensureLastOperationSucceeded()

        self.init(socket: socket)
    }

    public convenience init(localHost: String, localPort: Int) throws {
        let ip = try IP(localAddress: localHost, port: localPort)
        try self.init(ip: ip)
    }

    deinit {
        close()
    }

    
    // MARK: - Core functions (read, write, close)
    
    public func write(_ buffer: UnsafeBufferPointer<Byte>, to ip: IP) throws {
        try ensureStreamIsOpen()
        udpsend(socket, ip.address, buffer.baseAddress!, buffer.count)
        try ensureLastOperationSucceeded()
    }

    public func read(into buffer: UnsafeMutableBufferPointer<Byte>, deadline: Double = .never) throws -> (Int, IP) {
        try ensureStreamIsOpen()

        var senderAddress = ipaddr()
        let bytesRead = udprecv(socket, &senderAddress, buffer.baseAddress!, buffer.count, deadline.int64milliseconds)

        try ensureLastOperationSucceeded()

        let ip = IP(address: senderAddress)
        return (bytesRead, ip)
    }

    public func close() {
        if !closed, let socket = socket {
            udpclose(socket)
            try? ensureLastOperationSucceeded()
            closed = true
        }
        socket = nil
    }
    
    // MARK: - Utilities
    
    private func ensureStreamIsOpen() throws {
        if closed {
            throw StreamError.closedStream(buffer: Buffer())
        }
    }
    
    public func sending(to remoteIP: IP) -> UDPSendingSocket {
        return UDPSendingSocket(to: remoteIP, with: self)
    }
}



extension UDPSocket : InputStream {
    
    public func read(into: UnsafeMutableBufferPointer<UInt8>, deadline: Double = .never) throws -> Int {
        let (bytesRead, _) = try read(into: into, deadline: deadline)
        return bytesRead
    }
}
