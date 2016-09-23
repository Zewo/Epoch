public final class Drain : BufferRepresentable, Stream {
    public private(set) var buffer: Buffer
    public var closed = false

    public init(stream: InputStream, deadline: Double = .never) {
        if stream.closed {
            self.closed = true
        }

        var buffer = Buffer.empty
        while !stream.closed, let chunk = try? stream.read(upTo: 2048), chunk.count > 0 {
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
    
    public func read(into: UnsafeMutableBufferPointer<UInt8>, deadline: Double = .never) throws -> Int {
        if closed && buffer.count == 0 {
            throw StreamError.closedStream(buffer: Buffer.empty)
        }
        
        guard !buffer.isEmpty else {
            return 0
        }
        
        guard !into.isEmpty else {
            return 0
        }
        
        let read = min(buffer.count, into.count)
        buffer.copyBytes(to: into.baseAddress!, count: read)
        
        if buffer.count > read {
            buffer = buffer.subdata(in: buffer.startIndex.advanced(by: read)..<buffer.endIndex)
        } else {
            buffer = Buffer.empty
        }
        
        return read
    }
    
    public func write(_ buffer: UnsafeBufferPointer<UInt8>, deadline: Double = .never) {
        self.buffer.append(Buffer(bytes: buffer))
    }

    public func flush(deadline: Double = .never) throws {}
}
