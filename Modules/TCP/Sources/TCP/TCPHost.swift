import CLibvenice

public final class TCPHost : Host {
    private let socket: tcpsock?

    public init(configuration: Map) throws {
        let host = configuration["host"].string ?? "0.0.0.0"
        let port = configuration["port"].int ?? 8080
        let backlog = configuration["backlog"].int ?? 128
        let reusePort = configuration["reusePort"].bool ?? false

        let ip = try IP(localAddress: host, port: port)
        self.socket = tcplisten(ip.address, Int32(backlog), reusePort ? 1 : 0)
        try ensureLastOperationSucceeded()
    }

    public func accept(deadline: Double = .never) throws -> Stream {
        let socket = tcpaccept(self.socket, deadline.int64milliseconds)
        try ensureLastOperationSucceeded()
        return try TCPConnection(with: socket!)
    }
    
    deinit {
        if let socket = socket {
            tcpclose(socket)
        }
    }
}
