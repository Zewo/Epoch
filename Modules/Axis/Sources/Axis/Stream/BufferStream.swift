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

    public func read(into readBuffer: UnsafeMutableBufferPointer<Byte>, deadline: Double) throws -> UnsafeBufferPointer<Byte> {
        guard !closed, let readPointer = readBuffer.baseAddress else {
            return UnsafeBufferPointer()
        }

        let bytesRead = min(buffer.count, readBuffer.count)
        buffer.copyBytes(to: readPointer, count: bytesRead)
        buffer = buffer.suffix(from: bytesRead)

        return UnsafeBufferPointer(start: readPointer, count: bytesRead)
    }

    public func write(_ writeBuffer: UnsafeBufferPointer<UInt8>, deadline: Double) {
        buffer.append(writeBuffer)
    }

    public func flush(deadline: Double) throws {}
}
