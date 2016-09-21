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
    func write(_ buffer: Buffer, deadline: Double) throws -> Buffer?
    func write(_ buffer: BufferRepresentable, deadline: Double) throws -> Buffer?
    func flush(deadline: Double) throws
}

extension OutputStream {
    public func write(_ buffer: BufferRepresentable, deadline: Double = .never) throws -> Buffer? {
        return try write(buffer.buffer, deadline: .never)
    }

    public func flush() throws {
        try flush(deadline: .never)
    }
}

public typealias Stream = InputStream & OutputStream
