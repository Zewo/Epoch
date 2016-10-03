import CLibvenice
import Axis

public final class TCPStream : Stream {
    public var ip: IP
    var socket: tcpsock?
    public private(set) var closed = true

    internal init(with socket: tcpsock) throws {
        let address = tcpaddr(socket)
        try ensureLastOperationSucceeded()
        self.ip = IP(address: address)
        self.socket = socket
        self.closed = false
    }

    public init(host: String, port: Int, deadline: Double) throws {
        self.ip = try IP(remoteAddress: host, port: port, deadline: deadline)
        try ensureLastOperationSucceeded()
    }

    public func open(deadline: Double) throws {
        guard let socket = tcpconnect(ip.address, deadline.int64milliseconds) else {
            throw SystemError.lastOperationError!
        }
        try ensureLastOperationSucceeded()
        self.socket = socket
        self.closed = false
    }

    public func write(_ buffer: UnsafeBufferPointer<UInt8>, deadline: Double) throws {
        let socket = try getSocket()
        try ensureStreamIsOpen()

        guard !buffer.isEmpty else {
            return
        }
        
        let bytesWritten = tcpsend(socket, buffer.baseAddress!, buffer.count, deadline.int64milliseconds)
        
        guard bytesWritten == buffer.count else {
            try ensureLastOperationSucceeded()
            throw SystemError.other(errorNumber: -1)
        }
    }
    
    public func read(into readBuffer: UnsafeMutableBufferPointer<Byte>, deadline: Double) throws -> UnsafeBufferPointer<Byte> {
        let socket = try getSocket()
        try ensureStreamIsOpen()

        guard let readPointer = readBuffer.baseAddress else {
            return UnsafeBufferPointer()
        }
        
        let bytesRead = tcprecvlh(socket, readPointer, 1, readBuffer.count, deadline.int64milliseconds)
        
        if bytesRead == 0 {
            do {
                try ensureLastOperationSucceeded()
            } catch SystemError.connectionResetByPeer {
                closed = true
                return UnsafeBufferPointer()
            }
        }
        
        return UnsafeBufferPointer(start: readPointer, count: bytesRead)
    }

    public func flush(deadline: Double) throws {
        let socket = try getSocket()
        try ensureStreamIsOpen()

        tcpflush(socket, deadline.int64milliseconds)
        try ensureLastOperationSucceeded()
    }

    public func close() {
        if !closed, let socket = try? getSocket() {
            tcpclose(socket)
        }

        closed = true
    }

    private func getSocket() throws -> tcpsock {
        guard let socket = self.socket else {
            throw SystemError.socketIsNotConnected
        }
        return socket
    }

    private func ensureStreamIsOpen() throws {
        if closed {
            throw StreamError.closedStream
        }
    }

    deinit {
        if let socket = socket, !closed {
            tcpclose(socket)
        }
    }
}
