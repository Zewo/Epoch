import CLibvenice

public final class TCPHost : Host {
    public let ip: IP
    private let socket: tcpsock

    public init(host: String = "0.0.0.0", port: Int = 8080, backlog: Int = 128, reusePort: Bool = false) throws {
        self.ip = try IP(localAddress: host, port: port)
        guard let socket = mill_tcplisten_(ip.address, Int32(backlog), reusePort ? 1 : 0) else {
            throw SystemError.lastOperationError!
        }
        try ensureLastOperationSucceeded()
        self.socket = socket
    }

    public func accept(deadline: Double) throws -> Stream {
        guard let acceptSocket = mill_tcpaccept_(socket, deadline.int64milliseconds) else {
            throw SystemError.lastOperationError!
        }
        try ensureLastOperationSucceeded()
        return try TCPStream(with: acceptSocket)
    }
    
    deinit {
        mill_tcpclose_(socket)
    }
}
