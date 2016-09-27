public struct TCPTLSHost : Host {
    public let host: TCPHost
    public let context: Context

    public init(configuration: TCPHost.Configuration, context: Context) throws {
        self.host = try TCPHost(configuration: configuration)
        self.context = context
    }

    public func accept(deadline: Double) throws -> Stream {
        let stream = try host.accept(deadline: deadline)
        return try SSLConnection(context: context, rawStream: stream)
    }
}
