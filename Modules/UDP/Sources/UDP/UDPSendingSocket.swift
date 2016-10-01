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
    
    /// Constructs a `UDPSendingSocket`.
    ///
    /// - note: The preferred way to build a `UDPSendingSocket` is to call `sending(to:)` on a `UDPSocket` instance.
    public convenience init(localHost: String = "0.0.0.0", localPort: Int = 5000, host: String, port: Int) throws {
        let udpSocket = try UDPSocket(localHost: localHost, localPort: localPort)
        try self.init(to: IP(remoteAddress: host, port: port, deadline: 15.seconds.fromNow()), with: udpSocket)
    }
}


extension UDPSendingSocket : OutputStream {
    public var closed: Bool {
        return udpSocket.closed
    }

    public func open(deadline: Double) throws {}

    public func close() {
        udpSocket.close()
    }
    
    public func write(_ buffer: UnsafeBufferPointer<UInt8>, deadline: Double) throws {
        try udpSocket.write(buffer, to: remoteIP)
    }
    
    public func flush() throws {
        try flush(deadline: .never)
    }
    
    public func flush(deadline: Double) throws {}
}
