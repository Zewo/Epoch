public enum Body {
    case buffer(Buffer)
    case reader(InputStream)
    case writer((OutputStream) throws -> Void)
}

extension Body {
    public static var empty: Body {
        return .buffer(.empty)
    }

    public var isEmpty: Bool {
        switch self {
        case .buffer(let buffer): return buffer.isEmpty
        default: return false
        }
    }
}

extension Body {
    public var isBuffer: Bool {
        switch self {
        case .buffer: return true
        default: return false
        }
    }

    public var isReader: Bool {
        switch self {
        case .reader: return true
        default: return false
        }
    }

    public var isWriter: Bool {
        switch self {
        case .writer: return true
        default: return false
        }
    }
}

extension Body {
    public mutating func becomeBuffer(deadline: Double) throws -> Buffer {
        switch self {
        case .buffer(let buffer):
            return buffer
        case .reader(let reader):
            let buffer = try reader.drain(deadline: deadline)
            self = .buffer(buffer)
            return buffer
        case .writer(let writer):
            let bufferStream = BufferStream()
            try writer(bufferStream)
            let buffer = bufferStream.buffer
            self = .buffer(buffer)
            return buffer
        }
    }

    public mutating func becomeReader() throws -> InputStream {
        switch self {
        case .reader(let reader):
            return reader
        case .buffer(let buffer):
            let bufferStream = BufferStream(buffer: buffer)
            self = .reader(bufferStream)
            return bufferStream
        case .writer(let writer):
            let bufferStream = BufferStream()
            try writer(bufferStream)
            self = .reader(bufferStream)
            return bufferStream
        }
    }

    public mutating func becomeWriter(deadline: Double) throws -> ((OutputStream) throws -> Void) {
        switch self {
        case .buffer(let buffer):
            let writer: ((OutputStream) throws -> Void) = { writer in
                try writer.write(buffer, deadline: deadline)
                try writer.flush(deadline: deadline)
            }
            self = .writer(writer)
            return writer
        case .reader(let reader):
            let writer: ((OutputStream) throws -> Void) = { writer in
                let buffer = try reader.drain(deadline: deadline)
                try writer.write(buffer, deadline: deadline)
                try writer.flush(deadline: deadline)
            }
            self = .writer(writer)
            return writer
        case .writer(let writer):
            return writer
        }
    }
}

extension Body : Equatable {}

public func == (lhs: Body, rhs: Body) -> Bool {
    switch (lhs, rhs) {
        case let (.buffer(l), .buffer(r)) where l == r: return true
        default: return false
    }
}
