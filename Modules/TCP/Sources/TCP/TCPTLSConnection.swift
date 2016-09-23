public struct TCPTLSConnection : Connection {
    public let tcpConnection: TCPConnection
    public let sslConnection: SSLConnection

    public init(host: String, port: Int, verifyBundle: String? = nil, certificate: String? = nil, privateKey: String? = nil, certificateChain: String? = nil, sniHostname: String? = nil, deadline: Double = .never) throws {
        self.tcpConnection = try TCPConnection(host: host, port: port, deadline: deadline)
        let context = try Context(
            verifyBundle: verifyBundle,
            certificate: certificate,
            privateKey: privateKey,
            certificateChain: certificateChain,
            sniHostname: sniHostname
        )
        self.sslConnection = try SSLConnection(context: context, rawStream: tcpConnection)
    }

    public func open(deadline: Double) throws {
        try tcpConnection.open(deadline: deadline)
        try sslConnection.open(deadline: deadline)
    }

    public var closed: Bool {
        return sslConnection.closed
    }

    public func read(into: UnsafeMutableBufferPointer<UInt8>, deadline: Double) throws -> Int {
        return try sslConnection.read(into: into, deadline: deadline)
    }
    
    public func write(_ buffer: UnsafeBufferPointer<UInt8>, deadline: Double) throws {
        try sslConnection.write(buffer, deadline: deadline)
    }

    public func flush(deadline: Double) throws {
        try sslConnection.flush(deadline: deadline)
    }

    public func close() {
        sslConnection.close()
    }
}
