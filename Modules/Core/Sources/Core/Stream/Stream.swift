public enum StreamError : Error {
    case closedStream(buffer: Buffer)
    case timeout(buffer: Buffer)
}

public protocol InputStream {
    var closed: Bool { get }
    func close()
    
    func read(into: UnsafeMutableBufferPointer<UInt8>, deadline: Double) throws -> Int
    func read(upTo: Int, deadline: Double) throws -> Buffer
}

extension InputStream {
    public func read(into: UnsafeMutableBufferPointer<UInt8>) throws -> Int {
        return try read(into: into, deadline: .never)
    }
    
    public func read(upTo count: Int, deadline: Double = .never) throws -> Buffer {
        return try Buffer(capacity: count) { try read(into: $0, deadline: deadline) }
    }
}

public protocol OutputStream {
    var closed: Bool { get }
    func close()
    
    func write(from: UnsafeBufferPointer<UInt8>, deadline: Double) throws
    func write(from: Buffer, deadline: Double) throws
    func write(from: BufferRepresentable, deadline: Double) throws
    func flush(deadline: Double) throws
}

extension OutputStream {
    
    public func write(from: UnsafeBufferPointer<UInt8>) throws {
        try write(from: from, deadline: .never)
    }
    
    public func write(from buffer: Buffer, deadline: Double = .never) throws {
        guard !buffer.isEmpty else {
            return
        }
        
        try buffer.withUnsafeBytes {
            try write(from: UnsafeBufferPointer(start: $0, count: buffer.count), deadline: deadline)
        }
    }
    
    public func write(from buffer: BufferRepresentable, deadline: Double = .never) throws {
        try write(from: buffer.buffer, deadline: .never)
    }
    
    public func write(from bytes: [UInt8], deadline: Double = .never) throws {
        guard !bytes.isEmpty else {
            return
        }
        try bytes.withUnsafeBufferPointer { try self.write(from: $0, deadline: deadline) }
    }

    public func flush() throws {
        try flush(deadline: .never)
    }
}

public typealias Stream = InputStream & OutputStream
