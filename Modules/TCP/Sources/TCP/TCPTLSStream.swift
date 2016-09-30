public struct TCPTLSStream : Stream {
    public let tcpStream: TCPStream
    public let sslStream: SSLStream

    public init(host: String, port: Int, verifyBundle: String? = nil, certificate: String? = nil, privateKey: String? = nil, certificateChain: String? = nil, sniHostname: String? = nil, deadline: Double) throws {
        self.tcpStream = try TCPStream(host: host, port: port, deadline: deadline)
        let context = try Context(
            verifyBundle: verifyBundle,
            certificate: certificate,
            privateKey: privateKey,
            certificateChain: certificateChain,
            sniHostname: sniHostname
        )
        self.sslStream = try SSLStream(context: context, rawStream: tcpStream)
    }

    public func open(deadline: Double) throws {
        try tcpStream.open(deadline: deadline)
        try sslStream.open(deadline: deadline)
    }

    public var closed: Bool {
        return sslStream.closed
    }

    public func read(into readBuffer: UnsafeMutableBufferPointer<Byte>, deadline: Double) throws -> UnsafeBufferPointer<Byte> {
        return try sslStream.read(into: readBuffer, deadline: deadline)
    }
    
    public func write(_ buffer: UnsafeBufferPointer<Byte>, deadline: Double) throws {
        try sslStream.write(buffer, deadline: deadline)
    }

    public func flush(deadline: Double) throws {
        try sslStream.flush(deadline: deadline)
    }

    public func close() {
        sslStream.close()
    }
}
