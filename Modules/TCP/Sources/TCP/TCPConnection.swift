import CLibvenice
import Core


public final class TCPConnection : Connection {
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

    public init(host: String, port: Int, deadline: Double = .never) throws {
        self.ip = try IP(remoteAddress: host, port: port, deadline: deadline)
    }

    public func open(deadline: Double = .never) throws {
        self.socket = tcpconnect(ip.address, deadline.int64milliseconds)
        try ensureLastOperationSucceeded()
        self.closed = false
    }

    public func write(_ buffer: UnsafeBufferPointer<UInt8>, deadline: Double) throws {
        guard !buffer.isEmpty else {
            return
        }
        
        let socket = try getSocket()
        try ensureStreamIsOpen()
        
        let bytesWritten = tcpsend(socket, buffer.baseAddress!, buffer.count, deadline.int64milliseconds)
        
        guard bytesWritten == buffer.count else {
            try ensureLastOperationSucceeded()
            throw SystemError.other(errorNumber: -1)
        }
    }
    
    public func read(into: UnsafeMutableBufferPointer<UInt8>, deadline: Double) throws -> Int {
        guard !into.isEmpty else {
            return 0
        }
        
        let socket = try getSocket()
        try ensureStreamIsOpen()
        
        let bytesRead = tcprecvlh(socket, into.baseAddress!, 1, into.count, deadline.int64milliseconds)
        
        if bytesRead == 0 {
            do {
                try ensureLastOperationSucceeded()
            } catch SystemError.connectionResetByPeer {
                closed = true
                throw StreamError.closedStream(buffer: Buffer())
            }
        }
        
        return bytesRead
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
            throw StreamError.closedStream(buffer: Buffer())
        }
    }

    deinit {
        if let socket = socket, !closed {
            tcpclose(socket)
        }
    }
}
