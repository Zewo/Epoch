public enum StreamError : Error {
    case closedStream(data: Data)
    case timeout(data: Data)
}

public protocol InputStream {
    var closed: Bool { get }
    func close()
    func read(into buffer: inout Data, length: Int, deadline: Double) throws -> Int
}

extension InputStream {
    public func read(into buffer: inout Data, length: Int) throws -> Int {
        return try read(into: &buffer, length: length, deadline: .never)
    }

    public func read(into buffer: inout Data, deadline: Double = .never) throws -> Int {
        return try read(into: &buffer, length: buffer.count, deadline: deadline)
    }
}

public protocol OutputStream {
    var closed: Bool { get }
    func close()
    @discardableResult
    func write(_ buffer: Data, length: Int, deadline: Double) throws -> Int
    func flush(deadline: Double) throws
}

extension OutputStream {
    @discardableResult
    public func write(_ buffer: Data, length: Int) throws -> Int {
        return try write(buffer, length: length, deadline: .never)
    }

    @discardableResult
    public func write(_ buffer: Data, deadline: Double = .never) throws -> Int {
        return try write(buffer, length: buffer.count, deadline: deadline)
    }

    @discardableResult
    public func write(_ convertible: DataConvertible, length: Int, deadline: Double = .never) throws -> Int {
        return try write(convertible.data, length: length, deadline: deadline)
    }

    @discardableResult
    public func write(_ convertible: DataConvertible, deadline: Double = .never) throws -> Int {
        let buffer = convertible.data
        return try write(buffer, length: buffer.count, deadline: deadline)
    }

    public func flush() throws {
        try flush(deadline: .never)
    }
}

public typealias Stream = InputStream & OutputStream
