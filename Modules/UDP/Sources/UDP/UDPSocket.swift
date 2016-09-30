import CLibvenice
import POSIX

public enum UDPError : Error {
    case invalidReadBuffer
}

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

    public func read(into readBuffer: UnsafeMutableBufferPointer<Byte>, deadline: Double) throws -> (UnsafeBufferPointer<Byte>, IP) {
        try ensureStreamIsOpen()

        guard let readPointer = readBuffer.baseAddress else {
            throw UDPError.invalidReadBuffer
        }

        var address = ipaddr()
        let bytesRead = udprecv(socket, &address, readPointer, readBuffer.count, deadline.int64milliseconds)

        try ensureLastOperationSucceeded()

        let ip = IP(address: address)
        return (UnsafeBufferPointer(start: readPointer, count: bytesRead), ip)
    }

    public func read(upTo byteCount: Int, deadline: Double) throws -> (Buffer, IP) {
        var bytes = [Byte](repeating: 0, count: byteCount)

        let (readBuffer, ip) = try bytes.withUnsafeMutableBufferPointer {
            try read(into: $0, deadline: deadline)
        }

        return (Buffer(readBuffer), ip)
    }

    public func open(deadline: Double) throws {}

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
            throw StreamError.closedStream
        }
    }
    
    public func sending(to remoteIP: IP) -> UDPSendingSocket {
        return UDPSendingSocket(to: remoteIP, with: self)
    }
}

extension UDPSocket : InputStream {
    public func read(into readBuffer: UnsafeMutableBufferPointer<Byte>, deadline: Double = .never) throws -> UnsafeBufferPointer<Byte> {
        let (bytesRead, _) = try read(into: readBuffer, deadline: deadline)
        return bytesRead
    }
}
