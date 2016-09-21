public enum StreamError : Error {
    case closedStream(buffer: Buffer)
    case timeout(buffer: Buffer)
}

public protocol InputStream {
    var closed: Bool { get }
    func close()
    func read(upTo: Int, deadline: Double) throws -> Buffer
    func read(upTo: Int, into: UnsafeMutablePointer<UInt8>, deadline: Double) throws -> Int
}

extension InputStream {
    public func read(upTo count: Int, deadline: Double = .never) throws -> Buffer {
        let bytes = UnsafeMutablePointer<UInt8>.allocate(capacity: count)
        let bytesRead = try read(upTo: count, into: bytes, deadline: deadline)
        
        // no bytes
        guard  bytesRead > 0 else {
            defer {
                bytes.deallocate(capacity: count)
            }
            return Buffer.empty
        }
        
        let buffer = UnsafeBufferPointer(start: bytes, count: bytesRead)
        
        // bytes less than 25% of count
        guard Double(bytesRead) > Double(count) * 0.25 else {
            defer {
                bytes.deallocate(capacity: count)
            }
            return Buffer(bytes: buffer)
        }
        
        return Buffer(bytesNoCopy: buffer, deallocator: .custom(nil, {
            bytes.deallocate(capacity: count)
        }))
    }
    public func read(upTo count: Int, into: UnsafeMutablePointer<UInt8>, deadline: Double = .never) throws -> Int {
        return try read(upTo: count, into: into, deadline: deadline)
    }
}

public protocol OutputStream {
    var closed: Bool { get }
    func close()
    @discardableResult
    func write(_ buffer: Buffer, deadline: Double) throws -> Buffer?
    func flush(deadline: Double) throws
}

extension OutputStream {
    public func write(_ buffer: Buffer, deadline: Double = .never) throws -> Buffer? {
        return try write(buffer, deadline: deadline)
    }

    public func write(_ convertible: BufferConvertible, deadline: Double = .never) throws -> Buffer? {
        return try write(convertible.buffer, deadline: deadline)
    }

    public func flush() throws {
        try flush(deadline: .never)
    }
}

public typealias Stream = InputStream & OutputStream
