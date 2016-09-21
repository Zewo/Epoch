public enum BodyStreamError: Error {
    case receiveUnsupported
}

final class BodyStream : Stream {
    var closed = false
    let transport: Stream

    init(_ transport: Stream) {
        self.transport = transport
    }

    func close() {
        closed = true
    }

    func read(into: UnsafeMutableBufferPointer<UInt8>, deadline: Double = .never) throws -> Int {
        throw BodyStreamError.receiveUnsupported
    }
    
    func write(from: UnsafeBufferPointer<UInt8>, deadline: Double = .never) throws {
        guard !from.isEmpty else {
            return
        }
        
        if closed {
            throw StreamError.closedStream(buffer: Buffer(bytes: from))
        }
        
        let newLine: [UInt8] = [13, 10]
        try transport.write(from: newLine, deadline: deadline)
        try transport.write(from: String(from.count, radix: 16), deadline: deadline)
        try transport.write(from: from, deadline: deadline)
        try transport.write(from: newLine, deadline: deadline)
    }

    func flush(deadline: Double = .never) throws {
        try transport.flush()
    }
}
