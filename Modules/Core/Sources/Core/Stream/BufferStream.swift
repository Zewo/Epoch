public final class BufferStream : Stream {
    public private(set) var buffer: Buffer
    public private(set) var closed = false

    public init(buffer: Buffer = Buffer()) {
        self.buffer = buffer
    }

    public convenience init(buffer bufferRepresentable: BufferRepresentable) {
        self.init(buffer: bufferRepresentable.buffer)
    }

    public func open(deadline: Double) throws {
        closed = false
    }

    public func close() {
        closed = true
    }
    
    public func read(into targetBuffer: UnsafeMutableBufferPointer<UInt8>, deadline: Double) throws -> Int {
        guard !closed else {
            throw StreamError.closedStream
        }
        
        guard let targetBaseAddress = targetBuffer.baseAddress else {
            return 0
        }
        
        let read = min(buffer.count, targetBuffer.count)
        buffer.copyBytes(to: targetBaseAddress, count: read)
        
        if read < buffer.count {
            buffer = buffer.suffix(from: read)
        } else {
            buffer = Buffer()
        }
        
        return read
    }
    
    public func write(_ sourceBuffer: UnsafeBufferPointer<UInt8>, deadline: Double) {
        buffer.append(Buffer(sourceBuffer))
    }

    public func flush(deadline: Double) throws {}
}
