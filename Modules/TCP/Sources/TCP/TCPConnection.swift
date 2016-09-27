import POSIX
import Venice

public final class TCPConnection : Connection {
    private var socket: FileDescriptor?

    public private(set) var ip: IP
    public private(set) var closed: Bool

    internal init(socket: FileDescriptor, ip: IP) {
        self.ip = ip
        self.socket = socket
        self.closed = false
    }

    public init(host: String, port: Int, deadline: Double = 1.minute.fromNow()) throws {
        self.ip = try IP(address: host, port: port, deadline: deadline)
        self.socket = nil
        self.closed = true
    }

    public func open(deadline: Double = 1.minute.fromNow()) throws {
        let address = ip.address

        guard let socket = try? POSIX.socket(family: address.family, type: .stream, protocol: 0) else {
            throw TCPError.failedToCreateSocket
        }

        try TCP.tune(socket: socket)

        do {
            try POSIX.connect(socket: socket, address: address)
        } catch SystemError.operationNowInProgress {
            do {
                try poll(socket, events: .write, deadline: deadline)
            } catch PollError.timeout {
                try TCP.close(socket: socket)
                throw TCPError.connectTimedOut
            }
            try POSIX.checkError(socket: socket)
        } catch {
            try TCP.close(socket: socket)
            throw TCPError.failedToConnectSocket
        }

        self.socket = socket
        self.closed = false
    }
    
    public func write(_ buffer: UnsafeBufferPointer<UInt8>, deadline: Double) throws {
        guard !buffer.isEmpty else {
            return
        }
        
        let socket = try getSocket()
        try ensureStillOpen()
        
        loop: while true {
            var remaining: UnsafeBufferPointer<UInt8> = buffer
            do {
                let bytesWritten = try POSIX.send(socket: socket, buffer: remaining.baseAddress!, count: remaining.count, flags: .noSignal)
                guard bytesWritten > 0 else {
                    throw SystemError.other(errorNumber: -1)
                }
                guard bytesWritten < remaining.count else {
                    return
                }
                
                let remainingCount = remaining.startIndex.advanced(by: bytesWritten).distance(to: remaining.endIndex)
                remaining = UnsafeBufferPointer<UInt8>(start: remaining.baseAddress!.advanced(by: bytesWritten), count: remainingCount)
            } catch {
                switch error {
                case SystemError.resourceTemporarilyUnavailable, SystemError.operationWouldBlock:
                    do {
                        try poll(socket, events: .write, deadline: deadline)
                    } catch PollError.timeout {
                        throw StreamError.timeout(buffer: Buffer())
                    }
                    continue loop
                case SystemError.connectionResetByPeer, SystemError.brokenPipe:
                    close()
                    throw StreamError.closedStream(buffer: Buffer())
                default:
                    throw error
                }
            }
        }
    }
    
    public func read(into: UnsafeMutableBufferPointer<UInt8>, deadline: Double) throws -> Int {
        guard !into.isEmpty else {
            return 0
        }
        
        let socket = try getSocket()
        try ensureStillOpen()
        
        loop: while true {
            do {
                
                let bytesRead = try POSIX.receive(socket: socket, buffer: into.baseAddress!, count: into.count)
                guard bytesRead != 0 else {
                    close()
                    throw StreamError.closedStream(buffer: Buffer())
                }
                return bytesRead
            } catch {
                switch error {
                case SystemError.resourceTemporarilyUnavailable, SystemError.operationWouldBlock:
                    do {
                        try poll(socket, events: .read, deadline: deadline)
                    } catch PollError.timeout {
                        throw StreamError.timeout(buffer: Buffer())
                    }
                    continue loop
                default:
                    throw error
                }
            }
        }
    }

    public func flush(deadline: Double) throws {
        try getSocket()
        try ensureStillOpen()
    }

    public func close() {
        guard !closed, let socket = try? getSocket() else {
            return
        }

        try? TCP.close(socket: socket)
        self.socket = nil
        self.closed = true
    }

    @discardableResult
    private func getSocket() throws -> FileDescriptor {
        guard let socket = self.socket else {
            throw SystemError.socketIsNotConnected
        }
        return socket
    }

    private func ensureStillOpen() throws {
        if closed {
            throw StreamError.closedStream(buffer: Buffer())
        }
    }

    deinit {
        close()
    }
}
