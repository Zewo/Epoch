public final class TCPTLSHost : Host {
    public let host: TCPHost
    public let context: Context

    public init(host: String = "0.0.0.0", port: Int = 8080, backlog: Int = 128, reusePort: Bool = false, bufferSize: Int = 4096, certificatePath: String, privateKeyPath: String, certificateChainPath: String? = nil) throws {
        self.host = try TCPHost(
            host: host,
            port: port,
            backlog: backlog,
            reusePort: reusePort
        )
        self.context = try Context(
            certificatePath: certificatePath,
            privateKeyPath: privateKeyPath,
            certificateChainPath: certificateChainPath
        )
    }

    public func accept(deadline: Double) throws -> Stream {
        let rawStream = try host.accept(deadline: deadline)
        return try SSLStream(context: context, rawStream: rawStream)
    }
}
