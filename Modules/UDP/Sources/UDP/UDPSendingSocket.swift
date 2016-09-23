/// UDPSendingSocket wraps a UDPSocket and a given remote IP address such that all futures messages are sent to this IP. By using this class instead of UDPSocket, the user is relieved from specifying the IP at each time the method `write` is called.
///
/// Furthermore, this wrapping makes this class conform to the `OutputStream` protocol, allowing the `write` methods to accept several useful types.
///
/// - note: the `flush()` method is a no-op for UDP sockets
///
public final class UDPSendingSocket {
    
    /// Underlying UDPSocket class
    let udpSocket: UDPSocket
    
    /// Remote IP address the socket will send to
    public let remoteIP: IP
    
    // MARK: - Initializers
    
    /// Constructs a `UDPSendingSocket` to some remote IP address, using a given `UDPSocket`.
    ///
    /// - note: The preferred way to build a `UDPSendingSocket` is to call `sending(to:)` on a `UDPSocket` instance.
    ///
    /// - parameter remoteIP:  remote IP address and port to set for this sending socket.
    /// - parameter udpSocket: underlying `UDPSocket` used for communication
    public init(to remoteIP: IP, with udpSocket: UDPSocket) {
        self.remoteIP = remoteIP
        self.udpSocket = udpSocket
    }
    
    /// Constructs a `UDPSendingSocket` using a configuration `Map`.
    ///
    /// - note: The preferred way to build a `UDPSendingSocket` is to call `sending(to:)` on a `UDPSocket` instance.
    ///
    /// - parameter configuration: Map with fields `localHost`, `localPort`, and for the remote: `host`, and `port`.
    ///
    ///       ["localHost": "127.0.0.1",
    ///        "localPort": 5000,
    ///        "host": "192.168.1.1",
    ///        "port": 1194]
    ///
    /// - throws: `fatalError` when either `host` or `port` are missing
    public convenience init(configuration: Map) throws {
        let localHost = configuration["localHost"].string ?? "0.0.0.0"
        let localPort = configuration["localPort"].int ?? 5000
        guard let host = configuration["host"].string,
            let port = configuration["port"].int else {
                fatalError("Invalid configuration")
        }
        
        let udpSocket = try UDPSocket(localHost: localHost, localPort: localPort)
        try self.init(to: IP(remoteAddress: host, port: port), with: udpSocket)
    }
}


extension UDPSendingSocket : OutputStream {
    public func close() {
        udpSocket.close()
    }
    
    public var closed: Bool {
        return udpSocket.closed
    }
    
    public func write(_ buffer: UnsafeBufferPointer<UInt8>, deadline: Double = .never) throws {
        try udpSocket.write(buffer, to: remoteIP)
    }
    
    public func flush() throws {
        try flush(deadline: .never)
    }
    
    public func flush(deadline: Double) throws {
        if false { fatalError("No flush for udp sockets") } // no-op
    }
}
