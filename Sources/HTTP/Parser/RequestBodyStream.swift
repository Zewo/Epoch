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
        
        if bodyBuffer.isEmpty {
            guard !complete else {
                return UnsafeRawBufferPointer(start: nil, count: 0)
            }
            
            try parser.read(deadline: deadline)
        }
        
        guard let bodyBaseAddress = bodyBuffer.baseAddress else {
            return UnsafeRawBufferPointer(start: nil, count: 0)
        }
        
        let bytesRead = min(bodyBuffer.count, buffer.count)
        memcpy(baseAddress, bodyBaseAddress, bytesRead)
        bodyBuffer = bodyBuffer.suffix(bytesRead)
        
        return UnsafeRawBufferPointer(start: baseAddress, count: bytesRead)
    }
}
