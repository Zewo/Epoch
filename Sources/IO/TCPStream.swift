#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

import Core
import Venice
import POSIX

public final class TCPStream : DuplexStream {
    /* The buffer size is based on typical Ethernet MTU (1500 bytes). Making it
     smaller would yield small suboptimal packets. Making it higher would bring
     no substantial benefit. The value is made smaller to account for IPv4/IPv6
     and TCP headers. Few more bytes are subtracted to account for any possible
     IP or TCP options */
    private let bufferSize = 1500 - 68
    private lazy var writeBuffer: UnsafeMutableRawBufferPointer = UnsafeMutableRawBufferPointer
        .allocate(count: self.bufferSize)
    private var writeBufferedCount = 0
    
    private var socket: FileDescriptor?
    public private(set) var ip: IP
    

    internal init(socket: FileDescriptor, ip: IP) {
        self.socket = socket
        self.ip = ip
    }

    public init(host: String, port: Int, deadline: Deadline) throws {
        self.ip = try IP(address: host, port: port, deadline: deadline)
        self.socket = nil
    }
    
    deinit {
        writeBuffer.deallocate()
        close()
    }

    public func open(deadline: Deadline) throws {
        let address = ip.address

        guard let rawSocket = try? POSIX.socket(family: address.family, type: .stream, protocol: 0) else {
            throw TCPError.failedToCreateSocket
        }

        let socket = FileDescriptor(rawSocket)
        try tune(socket: socket)

        do {
            try POSIX.connect(socket: rawSocket, address: address)
        } catch SystemError.operationNowInProgress {
            do {
                try socket.poll(event: .write, deadline: deadline)
                try POSIX.checkError(socket: rawSocket)
            } catch VeniceError.timeout {
                try IO.close(socket: socket)
                throw VeniceError.timeout
            }
        } catch {
            try IO.close(socket: socket)
            throw TCPError.failedToConnectSocket
        }

        self.socket = socket
    }

    public func read(
        into buffer: UnsafeMutableRawBufferPointer,
        deadline: Deadline
    ) throws -> UnsafeRawBufferPointer {
        let socket = try getSocket()
        
        guard !buffer.isEmpty, let baseAddress = buffer.baseAddress else {
            return UnsafeRawBufferPointer(start: nil, count: 0)
        }

        loop: while true {
            do {
                let bytesRead = try POSIX.receive(socket: socket.fileDescriptor, buffer: buffer)
                
                guard bytesRead != 0 else {
                    close()
                    throw SystemError.connectionResetByPeer
                }
                
                return UnsafeRawBufferPointer(start: baseAddress, count: bytesRead)
            } catch {
                switch error {
                case SystemError.resourceTemporarilyUnavailable, SystemError.operationWouldBlock:
                    try socket.poll(event: .read, deadline: deadline)
                    continue loop
                default:
                    throw error
                }
            }
        }
    }
    
    public func write(_ buffer: UnsafeRawBufferPointer, deadline: Deadline) throws {
        let socket = try getSocket()
        
        guard let baseAddress = buffer.baseAddress, !buffer.isEmpty else {
            return
        }
        
        /* If it fits into the write buffer, copy it there and be done. */
        if writeBufferedCount + buffer.count <= writeBuffer.count {
            memcpy(
                writeBuffer.baseAddress!.advanced(by: writeBufferedCount),
                baseAddress,
                buffer.count
            )
            
            writeBufferedCount += buffer.count
            return
        }
        
        /* If it doesn't fit, flush the write buffer first. */
        try flush(deadline: deadline)
        
        /* Try to fit it into the buffer once again. */
        if writeBufferedCount + buffer.count <= writeBuffer.count {
            memcpy(
                writeBuffer.baseAddress!.advanced(by: writeBufferedCount),
                baseAddress,
                buffer.count
            )
            
            writeBufferedCount += buffer.count
            return
        }
        
        /* The data chunk to send is longer than the output buffer.
         Let's do the sending in-place. */
        var buffer = buffer
        try write(buffer: &buffer, socket: socket, deadline: deadline)
    }

    public func flush(deadline: Deadline) throws {
        let socket = try getSocket()
        
        guard writeBufferedCount > 0 else {
            return
        }
        
        var buffer = UnsafeRawBufferPointer(writeBuffer.prefix(writeBufferedCount))
        try write(buffer: &buffer, socket: socket, deadline: deadline)
        writeBufferedCount = 0
    }
    
    private func write(buffer: inout UnsafeRawBufferPointer, socket: FileDescriptor, deadline: Deadline) throws {
        loop: while !buffer.isEmpty {
            do {
                let bytesWritten = try POSIX.send(
                    socket: socket.fileDescriptor,
                    buffer: buffer,
                    flags: .noSignal
                )
                
                buffer = buffer.suffix(from: bytesWritten)
            } catch {
                switch error {
                case SystemError.resourceTemporarilyUnavailable, SystemError.operationWouldBlock:
                    try socket.poll(event: .write, deadline: deadline)
                    continue loop
                case SystemError.connectionResetByPeer, SystemError.brokenPipe:
                    close()
                    throw error
                default:
                    throw error
                }
            }
        }
    }

    public func close() {
        guard let socket = try? getSocket() else {
            return
        }

        socket.clean()
        try? IO.close(socket: socket)
        self.socket = nil
    }

    private func getSocket() throws -> FileDescriptor {
        guard let socket = self.socket else {
            throw SystemError.socketIsNotConnected
        }
        
        return socket
    }
}
