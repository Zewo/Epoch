public enum StreamError : Error {
    case closedStream
    case timeout
}

public protocol InputStream {
    var closed: Bool { get }
    func open(deadline: Double) throws
    func close()
    
    func read(into readBuffer: UnsafeMutableBufferPointer<Byte>, deadline: Double) throws -> UnsafeBufferPointer<Byte>
    func read(upTo byteCount: Int, deadline: Double) throws -> Buffer
}


extension InputStream {
    public func read(upTo byteCount: Int, deadline: Double) throws -> Buffer {
        var bytes = [Byte](repeating: 0, count: byteCount)

        let bytesRead = try bytes.withUnsafeMutableBufferPointer {
            try read(into: $0, deadline: deadline).count
        }

        return Buffer(bytes[0..<bytesRead])
    }

    /// Drains the `Stream` and returns the contents in a `Buffer`. At the end of this operation the stream will be closed.
    public func drain(deadline: Double) throws -> Buffer {
        var buffer = Buffer()

        while !self.closed, let chunk = try? self.read(upTo: 2048, deadline: deadline), chunk.count > 0 {
            buffer.append(chunk)
        }

        return buffer
    }
}

public protocol OutputStream {
    var closed: Bool { get }
    func open(deadline: Double) throws
    func close()
    
    func write(_ buffer: UnsafeBufferPointer<Byte>, deadline: Double) throws
    func write(_ buffer: Buffer, deadline: Double) throws
    func write(_ buffer: BufferRepresentable, deadline: Double) throws
    func flush(deadline: Double) throws
}

extension OutputStream {
    public func write(_ buffer: Buffer, deadline: Double) throws {
        guard !buffer.isEmpty else {
            return
        }
        
        try buffer.bytes.withUnsafeBufferPointer {
            try write($0, deadline: deadline)
        }
    }

    public func write(_ converting: BufferRepresentable, deadline: Double) throws {
        try write(converting.buffer, deadline: deadline)
    }
    
    public func write(_ bytes: [Byte], deadline: Double) throws {
        guard !bytes.isEmpty else {
            return
        }
        try bytes.withUnsafeBufferPointer { try self.write($0, deadline: deadline) }
    }
}

public typealias Stream = InputStream & OutputStream
