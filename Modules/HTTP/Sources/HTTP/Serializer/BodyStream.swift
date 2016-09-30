public enum BodyStreamError : Error {
    case receiveUnsupported
}

final class BodyStream : Stream {
    var closed = false
    let transport: Stream

    init(_ transport: Stream) {
        self.transport = transport
    }

    public func open(deadline: Double) throws {
        closed = false
    }

    func close() {
        closed = true
    }

    func read(into readBuffer: UnsafeMutableBufferPointer<Byte>, deadline: Double) throws -> UnsafeBufferPointer<Byte> {
        throw BodyStreamError.receiveUnsupported
    }
    
    func write(_ buffer: UnsafeBufferPointer<Byte>, deadline: Double) throws {
        guard !buffer.isEmpty else {
            return
        }
        
        if closed {
            throw StreamError.closedStream
        }
        
        let newLine: [Byte] = [13, 10]
        try transport.write(String(buffer.count, radix: 16), deadline: deadline)
        try transport.write(newLine, deadline: deadline)
        try transport.write(buffer, deadline: deadline)
        try transport.write(newLine, deadline: deadline)
    }

    func flush(deadline: Double) throws {
        try transport.flush(deadline: deadline)
    }
}
