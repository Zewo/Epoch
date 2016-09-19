import CLibvenice
import POSIX

public enum UDPError : Error {
    case writeFailed(error: SystemError, remaining: Data)
    case readFailed(error: SystemError, received: Data)
}

extension UDPError : CustomStringConvertible {
    public var description: String {
        switch self {
        case .writeFailed(let error, _): return "\(error)"
        case .readFailed(let error, _): return "\(error)"
        }
    }
}

public final class UDPSocket {
    private var socket: udpsock?
    public private(set) var closed = false

    public var port: Int {
        return Int(udpport(socket))
    }

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

    public convenience init(host: String, port: Int) throws {
        let ip = try IP(remoteAddress: host, port: port)
        try self.init(ip: ip)
    }

    deinit {
        close()
    }

    public func write(_ data: Data, to ip: IP, timingOut deadline: Double = .never) throws {
        try ensureStreamIsOpen()

        data.withUnsafeBytes { (ptr: UnsafePointer<Data>) -> Void in
            udpsend(socket, ip.address, ptr, data.count)
        }

        try ensureLastOperationSucceeded()
    }

    public func read(into buffer: inout Data, length: Int, deadline: Double = .never) throws -> (Int, IP) {
        let byteCount = min(buffer.count, length)
        try ensureStreamIsOpen()

        var address = ipaddr()
        let received = buffer.withUnsafeMutableBytes {
            udprecv(socket, &address, $0, byteCount, deadline.int64milliseconds)
        }

        do {
            try ensureLastOperationSucceeded()
        } catch let error as SystemError where received > 0 {
            throw UDPError.readFailed(error: error, received: buffer)
        }

        let ip = IP(address: address)
        return (received, ip)
    }

    public func close() {
        if !closed, let socket = socket {
            udpclose(socket)
            try? ensureLastOperationSucceeded()
            closed = true
        }
        socket = nil
    }

    private func ensureStreamIsOpen() throws {
        if closed {
            throw StreamError.closedStream(data: Data())
        }
    }
}
