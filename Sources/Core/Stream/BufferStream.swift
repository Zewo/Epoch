#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

import Venice

public final class BufferReadable : Readable {
    var buffer: UnsafeRawBufferPointer
    
    public init(buffer: UnsafeRawBufferPointer) {
        self.buffer = buffer
    }
    
    public func read(
        _ buffer: UnsafeMutableRawBufferPointer,
        deadline: Deadline
    ) throws -> UnsafeRawBufferPointer {
        guard !buffer.isEmpty && !self.buffer.isEmpty else {
            return UnsafeRawBufferPointer(start: nil, count: 0)
        }
        
        guard let destination = buffer.baseAddress, let origin = self.buffer.baseAddress else {
            return UnsafeRawBufferPointer(start: nil, count: 0)
        }
        
        let readCount = min(buffer.count, self.buffer.count)
        memcpy(destination, origin, readCount)
        let read = self.buffer.prefix(readCount)
        self.buffer = self.buffer.suffix(from: readCount)
        return UnsafeRawBufferPointer(read)
    }
}

extension BufferReadable {
    public static var empty: BufferReadable = BufferReadable(
        buffer: UnsafeRawBufferPointer(start: nil, count: 0)
    )
}
