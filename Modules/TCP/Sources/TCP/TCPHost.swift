import CLibvenice

public final class TCPHost : Host {
    private let socket: tcpsock?

    public init(configuration: Configuration) throws {
        let host = configuration.host
        let port = configuration.port
        let backlog = configuration.backlog
        let reusePort = configuration.reusePort

        let ip = try IP(localAddress: host, port: port)
        self.socket = tcplisten(ip.address, Int32(backlog), reusePort ? 1 : 0)
        try ensureLastOperationSucceeded()
    }

    public convenience init(host: String = "0.0.0.0", port: Int = 8080, backlog: Int = 128, reusePort: Bool = false) throws {
        try self.init(configuration: Configuration(host: host, port: port, backlog: backlog, reusePort: reusePort))
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

extension TCPHost {
    public struct Configuration {
        public let host: String
        public let port: Int
        public let backlog: Int
        public let reusePort: Bool

        public init(host: String = "0.0.0.0", port: Int = 8080, backlog: Int = 128, reusePort: Bool = false) {
            self.host = host
            self.port = port
            self.backlog = backlog
            self.reusePort = reusePort
        }
    }
}

extension TCPHost.Configuration : MapInitializable {
    public init(map: Map) throws {
        self.host = map["host"].string ?? "0.0.0.0"
        self.port = map["port"].int ?? 8080
        self.backlog = map["backlog"].int ?? 128
        self.reusePort = map["reusePort"].bool ?? false
    }
}
