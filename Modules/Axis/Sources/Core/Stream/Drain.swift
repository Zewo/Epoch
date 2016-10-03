public final class Drain : DataRepresentable, Stream {
    var buffer: Data
    public var closed = false

    public var data: Data {
        return buffer
    }

    public init(stream: InputStream, deadline: Double = .never) {
        var inputBuffer = Data(count: 2048)
        var outputBuffer = Data()

        if stream.closed {
            self.closed = true
        }

        while !stream.closed {
            if let bytesRead = try? stream.read(into: &inputBuffer, deadline: deadline) {
                if bytesRead == 0 {
                    break
                }
                inputBuffer.withUnsafeBytes {
                    outputBuffer.append($0, count: bytesRead)
                }
            } else {
                break
            }
        }

        self.buffer = outputBuffer
    }

    public init(buffer: Data = Data()) {
        self.buffer = buffer
    }

    public convenience init(buffer: DataRepresentable) {
        self.init(buffer: buffer.data)
    }

    public func close() {
        closed = true
    }

    public func read(into targetBuffer: inout Data, length: Int, deadline: Double = .never) throws -> Int {
        if closed && buffer.count == 0 {
            throw StreamError.closedStream(data: Data())
        }

        if buffer.count == 0 {
            return 0
        }

        if length >= buffer.count {
            targetBuffer.replaceSubrange(0 ..< buffer.count, with: buffer)
            let read = buffer.count
            buffer = Data()
            return read
        }

        targetBuffer.replaceSubrange(0 ..< length, with: buffer[0 ..< length])
        buffer.removeFirst(length)

        return length
    }

    public func write(_ data: Data, length: Int, deadline: Double = .never) throws -> Int {
        data.withUnsafeBytes {
            buffer.append($0, count: length)
        }

        return length
    }

    public func flush(deadline: Double = .never) throws {}
}
