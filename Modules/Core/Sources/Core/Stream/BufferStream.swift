public final class BufferStream : Stream {
    public private(set) var buffer: Buffer
    public private(set) var closed = false

    public init(buffer: Buffer = Buffer.empty) {
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
        guard !closed && !buffer.isEmpty else {
            throw StreamError.closedStream
        }
        
        guard let targetBaseAddress = targetBuffer.baseAddress else {
            return 0
        }
        
        let read = min(buffer.count, targetBuffer.count)
        buffer.copyBytes(to: targetBaseAddress, count: read)
        
        if read < buffer.count {
            buffer = buffer.subdata(in: read..<buffer.count)
        } else {
            buffer = Buffer.empty
        }
        
        return read
    }
    
    public func write(_ sourceBuffer: UnsafeBufferPointer<UInt8>, deadline: Double) {
        buffer.append(Buffer(bytes: sourceBuffer))
    }

    public func flush(deadline: Double) throws {}
}
