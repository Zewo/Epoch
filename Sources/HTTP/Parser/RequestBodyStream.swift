#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

import Core
import Venice

final class RequestBodyStream : ReadableStream {
    var complete = false
    var bodyBuffer = UnsafeRawBufferPointer(start: nil, count: 0)
    
    private let parser: RequestParser
    
    public init(parser: RequestParser) {
        self.parser = parser
    }
    
    func open(deadline: Deadline) throws {}
    func close() {}
    
    func read(
        into buffer: UnsafeMutableRawBufferPointer,
        deadline: Deadline
    ) throws -> UnsafeRawBufferPointer {
        guard let baseAddress = buffer.baseAddress else {
            return UnsafeRawBufferPointer(start: nil, count: 0)
        }
        
        if bodyBuffer.isEmpty && !complete {
            try parser.read(deadline: deadline)
        } else if bodyBuffer.isEmpty && complete {
            close()
        }
        
        let bytesRead = min(bodyBuffer.count, buffer.count)
        memcpy(baseAddress, bodyBuffer.baseAddress, bytesRead)
        
        bodyBuffer = UnsafeRawBufferPointer(
            start: bodyBuffer.baseAddress?.advanced(by: bytesRead),
            count: bodyBuffer.count - bytesRead
        )
        
        return UnsafeRawBufferPointer(start: baseAddress, count: bytesRead)
    }
}
