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
    @discardableResult
    func write(from: UnsafeBufferPointer<UInt8>, deadline: Double) throws -> Int
    func write(from: Buffer, deadline: Double) throws -> Buffer?
    func write(from: BufferRepresentable, deadline: Double) throws -> Buffer?
    func flush(deadline: Double) throws
}

extension OutputStream {
    
    public func write(from: UnsafeBufferPointer<UInt8>) throws -> Int {
        return try write(from: from, deadline: .never)
    }
    
    public func write(from buffer: Buffer, deadline: Double = .never) throws -> Buffer? {
        guard !buffer.isEmpty else {
            return nil
        }
        
        let result = try buffer.withUnsafeBytes {
            try write(from: UnsafeBufferPointer(start: $0, count: buffer.count), deadline: deadline)
        }
        
        guard result == buffer.count else {
            if result > 0 {
                return buffer.subdata(in: buffer.startIndex.advanced(by: result)..<buffer.endIndex)
            } else {
                return buffer
            }
        }
        
        return nil
    }
    
    public func write(from buffer: BufferRepresentable, deadline: Double = .never) throws -> Buffer? {
        return try write(from: buffer.buffer, deadline: .never)
    }

    public func flush() throws {
        try flush(deadline: .never)
    }
}

public typealias Stream = InputStream & OutputStream
