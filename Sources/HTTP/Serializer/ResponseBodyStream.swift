import Core
import Venice
import POSIX

public enum ResponseBodyStreamError : Error {
    case writeExceedsContentLength
}

final class ResponseBodyStream : WritableStream {
    enum Mode {
        case contentLength(Int)
        case chunkedEncoding
    }
    
    var bytesRemaining = 0
    
    private let stream: WritableStream
    private let mode: Mode

    init(_ stream: WritableStream, mode: Mode) {
        self.stream = stream
        self.mode = mode
        
        if case let .contentLength(contentLength) = mode {
            bytesRemaining = contentLength
        }
    }

    func open(deadline: Deadline) throws {}
    func close() {}

    func write(_ buffer: UnsafeRawBufferPointer, deadline: Deadline) throws {
        guard !buffer.isEmpty else {
            return
        }

        switch mode {
        case .contentLength:
            if bytesRemaining - buffer.count < 0 {
                throw ResponseBodyStreamError.writeExceedsContentLength
            }
            
            try stream.write(buffer, deadline: deadline)
            bytesRemaining -= buffer.count
        case .chunkedEncoding:
            let chunkLength = String(buffer.count, radix: 16) + "\r\n"
            try stream.write(chunkLength, deadline: deadline)
            try stream.write(buffer, deadline: deadline)
            try stream.write("\r\n", deadline: deadline)
        }
    }

    func flush(deadline: Deadline) throws {
        try stream.flush(deadline: deadline)
    }
}
