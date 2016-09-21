public final class Drain : BufferRepresentable, Stream {
    public private(set) var buffer: Buffer
    public var closed = false

    public init(stream: InputStream, deadline: Double = .never) {
        if stream.closed {
            self.closed = true
        }

        var buffer = Buffer.empty
        while !stream.closed, let chunk = try? stream.read(upTo: 2048) {
            buffer.append(chunk)
        }
        self.buffer = buffer
    }

    public init(buffer: Buffer = Buffer.empty) {
        self.buffer = buffer
    }

    public convenience init(buffer: BufferRepresentable) {
        self.init(buffer: buffer.buffer)
    }

    public func close() {
        closed = true
    }
    
    public func read(upTo count: Int, into: UnsafeMutablePointer<UInt8>, deadline: Double) throws -> Int {
        if closed && buffer.count == 0 {
            throw StreamError.closedStream(buffer: Buffer.empty)
        }
        
        guard !buffer.isEmpty else {
            return 0
        }
        
        let read = min(buffer.count, count)
        buffer.copyBytes(to: into, count: read)
        
        if buffer.count > read {
            buffer = buffer.subdata(in: buffer.startIndex.advanced(by: read)..<buffer.endIndex)
        } else {
            buffer = Buffer.empty
        }
        
        return read
    }
    
    public func write(_ chunk: Buffer, deadline: Double) throws -> Buffer? {
        buffer.append(chunk)
        return nil
    }

    public func flush(deadline: Double = .never) throws {}
}
